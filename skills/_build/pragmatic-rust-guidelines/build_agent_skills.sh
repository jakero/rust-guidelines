#!/usr/bin/env bash

# Pragmatic Rust Guidelines로부터 AI 에이전트 스킬을 빌드하는 스크립트
# 생성 파일:
#   - skills/pragmatic-rust-guidelines/SKILL.md (색인 및 라우팅 가이드)
#   - skills/pragmatic-rust-guidelines/parts/*.md (원본 컨텍스트 및 분야별 가이드라인 파트)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
SRC_GUIDELINES="$PROJECT_ROOT/src/guidelines"
SKILLS_DIR="$PROJECT_ROOT/skills/pragmatic-rust-guidelines"
PARTS_DIR="$SKILLS_DIR/parts"
SKILL_FILE="$SKILLS_DIR/SKILL.md"


# 카테고리는 공식 가이드북의 공개 순서를 따릅니다.
# 라이브러리(Libraries)는 4개의 하위 카테고리로 분할되며 부모 번호를 하이픈형 계층 번호 접두사로 유지합니다.
CATEGORIES=(
    "01-universal:universal:Universal Guidelines"
    "02-1-libs-interop:libs/interop:Libraries - Interoperability"
    "02-2-libs-ux:libs/ux:Libraries - API UX"
    "02-3-libs-resilience:libs/resilience:Libraries - Resilience & Robustness"
    "02-4-libs-building:libs/building:Libraries - Building & Cargo Features"
    "03-macros:macros:Macro Design & Safety"
    "04-apps:apps:Application Binary Design"
    "05-ffi:ffi:FFI & Native Interoperability"
    "06-correctness:correctness:Correctness & Bug Prevention"
    "07-performance:performance:Performance & Resource Optimization"
    "08-project:project:Project Structure & CI"
    "09-docs:docs:Documentation Best Practices"
    "10-ai:ai:Designing for AI Assistance"
)

# 소스 디렉터리 경로별 파트 파일 매핑 및 규칙 ID별 파트 매핑 연관 배열
declare -A PART_BY_SOURCE_DIR=()
declare -A PART_BY_RULE_ID=()

# 원본 가이드라인 디렉터리를 스캔하여 파트 매핑 및 규칙 ID 색인을 구성하는 함수
load_source_map() {
    for entry in "${CATEGORIES[@]}"; do
        IFS=":" read -r part_prefix cat_dir cat_title <<< "$entry"
        local full_cat_dir="$SRC_GUIDELINES/$cat_dir"
        local part_name="${part_prefix}.md"
        local readme_file="$full_cat_dir/README.md"
        local -a m_files=()

        if [[ ! -d "$full_cat_dir" ]]; then
            echo "Error: Guideline category directory not found: $full_cat_dir" >&2
            return 1
        fi

        PART_BY_SOURCE_DIR["$(realpath -m "$full_cat_dir")"]="$part_name"

        if [[ -f "$readme_file" ]]; then
            local include_count
            include_count=$(grep -cE '\{\{#include' "$readme_file" || true)
            local -a included_files=()
            mapfile -t included_files < <(
                sed -nE 's/.*\{\{#include (M-[^}]+\.md)\}\}.*/\1/p' "$readme_file"
            )
            if [[ "$include_count" -ne "${#included_files[@]}" ]]; then
                echo "Error: Unrecognized guideline include in $readme_file" >&2
                return 1
            fi

            unset seen_includes
            declare -A seen_includes=()
            for included_file in "${included_files[@]}"; do
                local source_file="$full_cat_dir/$included_file"
                if [[ ! -f "$source_file" ]]; then
                    echo "Error: Included guideline not found: $source_file" >&2
                    return 1
                fi
                if [[ -n "${seen_includes[$included_file]+x}" ]]; then
                    echo "Error: Duplicate guideline include $included_file in $readme_file" >&2
                    return 1
                fi
                seen_includes["$included_file"]=1
                m_files+=("$source_file")
            done

            local -a source_files=()
            mapfile -t source_files < <(find "$full_cat_dir" -maxdepth 1 -type f -name "M-*.md" | sort)
            for source_file in "${source_files[@]}"; do
                local relative_file="${source_file#"$full_cat_dir"/}"
                if [[ -z "${seen_includes[$relative_file]+x}" ]]; then
                    echo "Error: Guideline is not included by $readme_file: $source_file" >&2
                    return 1
                fi
            done
        else
            mapfile -t m_files < <(find "$full_cat_dir" -maxdepth 1 -type f -name "M-*.md" | sort)
        fi

        for source_file in "${m_files[@]}"; do
            local raw_header
            raw_header=$(grep -m 1 '^## ' "$source_file" | tr -d '\r' || true)
            local rule_id
            rule_id=$(printf '%s\n' "$raw_header" | grep -oE '\(M-[A-Z0-9-]+\)' | tr -d '()' || true)
            if [[ -z "$rule_id" ]]; then
                echo "Error: Guideline heading has no recognized ID: $source_file" >&2
                return 1
            fi
            if [[ -n "${PART_BY_RULE_ID[$rule_id]+x}" ]]; then
                echo "Error: Duplicate guideline ID $rule_id in $source_file" >&2
                return 1
            fi
            PART_BY_RULE_ID["$rule_id"]="$part_name"
        done
    done
}

# 원본 마크다운 링크 대상을 생성 파트 경로(./<part>.md#<rule-id>)로 재작성하는 함수
rewrite_link_destination() {
    local source_file="$1"
    local source_part="$2"
    local destination="$3"
    local target trailing=""
    if [[ "$destination" =~ ^(<[^>]+>|[^[:space:]]+)(.*)$ ]]; then
        target="${BASH_REMATCH[1]}"
        trailing="${BASH_REMATCH[2]}"
    else
        target="$destination"
    fi

    local use_angle=0
    if [[ "$target" == \<*\> ]]; then
        target="${target#<}"
        target="${target%>}"
        use_angle=1
    fi

    if [[ "$target" =~ ^[A-Za-z][A-Za-z0-9+.-]*: ]] || [[ "$target" == //* || "$target" == /* ]]; then
        printf '%s' "$destination"
        return 0
    fi

    local target_path="$target"
    local anchor=""
    if [[ "$target" == *#* ]]; then
        target_path="${target%%#*}"
        anchor="${target#*#}"
    fi

    local target_part=""
    if [[ -n "$anchor" ]] && [[ -n "${PART_BY_RULE_ID[$anchor]+x}" ]]; then
        target_part="${PART_BY_RULE_ID[$anchor]}"
    else
        local source_dir
        source_dir="$(dirname "$source_file")"
        local resolved_path
        if [[ -n "$target_path" ]]; then
            resolved_path="$(realpath -m "$source_dir/$target_path")"
        else
            resolved_path="$(realpath -m "$source_dir")"
        fi
        if [[ -f "$resolved_path" ]]; then
            resolved_path="$(dirname "$resolved_path")"
        fi
        target_part="${PART_BY_SOURCE_DIR[$resolved_path]-}"
    fi

    if [[ -z "$target_part" ]]; then
        if [[ -z "$target_path" && "$anchor" != M-* ]]; then
            printf '%s' "$destination"
            return 0
        fi
        echo "Error: Cannot map source link '$destination' in $source_file to a generated guideline part." >&2
        return 1
    fi

    if [[ -n "$anchor" ]]; then
        if [[ -z "${PART_BY_RULE_ID[$anchor]+x}" && "$anchor" == M-* ]]; then
            echo "Warning: Source link '$destination' in $source_file has no matching guideline ID; linking to the part without an anchor." >&2
            anchor=""
        fi
    fi

    local rewritten
    if [[ "$source_part" == "$target_part" ]]; then
        rewritten=""
        if [[ -z "$anchor" ]]; then
            rewritten="#"
        fi
    else
        rewritten="./$target_part"
    fi
    if [[ -n "$anchor" ]]; then
        rewritten+="#$anchor"
    fi
    if [[ "$use_angle" -eq 1 ]]; then
        rewritten="<$rewritten>"
    fi
    printf '%s%s' "$rewritten" "$trailing"
}

# 마크다운 본문의 코드 블록(fence)을 보존하면서 참조 링크 및 인라인 링크를 재작성하는 함수
rewrite_markdown_links() {
    local source_file="$1"
    local source_part="$2"
    local line
    local in_fence=0
    local fence_pattern='^[[:space:]]*([>][[:space:]]*)*(`{3,}|~{3,})'
    local reference_pattern='^([[:space:]]*\[[^]]+\]:[[:space:]]+)(<[^>]+>|[^[:space:]]+)(.*)$'
    local inline_pattern='(.*)(\]\()([^)]*)(\).*)'

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ $fence_pattern ]]; then
            if [[ "$in_fence" -eq 0 ]]; then
                in_fence=1
            else
                in_fence=0
            fi
            printf '%s\n' "$line"
            continue
        fi
        if [[ "$in_fence" -eq 1 ]]; then
            printf '%s\n' "$line"
            continue
        fi

        if [[ "$line" =~ $reference_pattern ]]; then
            local prefix="${BASH_REMATCH[1]}"
            local destination="${BASH_REMATCH[2]}"
            local suffix="${BASH_REMATCH[3]}"
            local rewritten
            rewritten=$(rewrite_link_destination "$source_file" "$source_part" "$destination") || return 1
            printf '%s%s%s\n' "$prefix" "$rewritten" "$suffix"
            continue
        fi

        local link_tail=""
        while [[ "$line" =~ $inline_pattern ]]; do
            local prefix="${BASH_REMATCH[1]}"
            local opener="${BASH_REMATCH[2]}"
            local destination="${BASH_REMATCH[3]}"
            local suffix="${BASH_REMATCH[4]}"
            local rewritten
            rewritten=$(rewrite_link_destination "$source_file" "$source_part" "$destination") || return 1
            link_tail="${opener}${rewritten}${suffix}${link_tail}"
            line="$prefix"
        done
        printf '%s%s\n' "$line" "$link_tail"
    done
}

# 생성된 마크다운 링크의 대상 파일 및 규칙 앵커 유효성을 검증하는 함수
validate_generated_destination() {
    local source_file="$1"
    local destination="$2"
    local target
    if [[ "$destination" =~ ^(<[^>]+>|[^[:space:]]+)(.*)$ ]]; then
        target="${BASH_REMATCH[1]}"
    else
        target="$destination"
    fi
    if [[ "$target" == \<*\> ]]; then
        target="${target#<}"
        target="${target%>}"
    fi

    if [[ "$target" =~ ^[A-Za-z][A-Za-z0-9+.-]*: ]] || [[ "$target" == //* || "$target" == /* ]]; then
        return 0
    fi

    local target_path="$target"
    local anchor=""
    if [[ "$target" == *#* ]]; then
        target_path="${target%%#*}"
        anchor="${target#*#}"
    fi

    local target_file="$source_file"
    if [[ -n "$target_path" ]]; then
        target_file="$(realpath -m "$(dirname "$source_file")/$target_path")"
    fi
    if [[ ! -f "$target_file" ]]; then
        echo "Error: Generated Markdown link '$destination' in $source_file has no target file." >&2
        return 1
    fi

    if [[ -n "$anchor" ]]; then
        if [[ "$anchor" == M-* ]]; then
            if [[ -z "${PART_BY_RULE_ID[$anchor]+x}" ]] \
                || [[ "$target_file" != "$PARTS_DIR/${PART_BY_RULE_ID[$anchor]}" ]] \
                || ! grep -Fq "<a id=\"$anchor\"></a>" "$target_file"; then
                echo "Error: Generated Markdown link '$destination' in $source_file has no matching rule anchor." >&2
                return 1
            fi
        elif [[ "$target_file" == "$PARTS_DIR/00-1-overview.md" && "$anchor" == "meta-design-principles" ]]; then
            if ! grep -Fq "## Meta Design Principles" "$target_file"; then
                echo "Error: Generated overview anchor '$anchor' is missing." >&2
                return 1
            fi
        else
            echo "Error: Generated Markdown link '$destination' in $source_file has an unsupported local anchor." >&2
            return 1
        fi
    fi
}

# 생성된 모든 마크다운 파일 내 링크를 전수 검사하는 함수
validate_generated_links() {
    local file
    local line
    local in_fence=0
    local fence_pattern='^[[:space:]]*([>][[:space:]]*)*(`{3,}|~{3,})'
    local reference_pattern='^([[:space:]]*\[[^]]+\]:[[:space:]]+)(<[^>]+>|[^[:space:]]+)(.*)$'
    local inline_pattern='(.*)(\]\()([^)]*)(\).*)'

    while IFS= read -r file; do
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" =~ $fence_pattern ]]; then
                if [[ "$in_fence" -eq 0 ]]; then
                    in_fence=1
                else
                    in_fence=0
                fi
                continue
            fi
            if [[ "$in_fence" -eq 1 ]]; then
                continue
            fi

            if [[ "$line" =~ $reference_pattern ]]; then
                validate_generated_destination "$file" "${BASH_REMATCH[2]}" || return 1
                continue
            fi

            local remaining="$line"
            while [[ "$remaining" =~ $inline_pattern ]]; do
                local prefix="${BASH_REMATCH[1]}"
                local destination="${BASH_REMATCH[3]}"
                validate_generated_destination "$file" "$destination" || return 1
                remaining="$prefix"
            done
        done < "$file"
        in_fence=0
    done < <(find "$SKILLS_DIR" -type f -name "*.md" | sort)
}

# ==============================================================================
# 스크립트 실행 흐름 (작동 단계별 순서)
# ==============================================================================

# [1단계] 원본 가이드라인 소스 매핑 및 규칙 ID 인덱싱
# 각 카테고리 디렉터리와 README.md의 include 구문 유효성을 검증하고 규칙 ID 매핑을 구축합니다.
load_source_map

echo "Building Pragmatic Rust Guidelines Agent Skills..."
echo "Target directory: $SKILLS_DIR"
echo ""

# [2단계] 출력 대상 디렉터리 준비 및 초기화
# 기존 생성된 parts/*.md 파일들을 정리하고 대상 디렉터리를 초기화합니다.
mkdir -p "$PARTS_DIR"
rm -f "$PARTS_DIR"/*.md

# SKILL.md 라우팅 테이블 생성을 위한 메타데이터 수집 변수 초기화
declare -a ROUTING_ENTRIES=()
TOTAL_RULES=0
TOTAL_PARTS=1
# 에이전트용 출력에서 이미지 태그와 단독 div 래퍼를 생략하는 필터
strip_agent_images() {
    local div_regex='^>?[[:space:]]*</?[dD][iI][vV][^>]*>[[:space:]]*$'
    local img_regex='!\[[^]]*\]\(([A-Za-z0-9_-]+)\.png\)'
    local line

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ $div_regex || "$line" =~ $img_regex ]]; then
            continue
        fi
        echo "$line"
    done
}


# 개별 가이드라인 마크다운 정제 함수 (저작권 제거, 앵커/근거 변환, 이미지 생략, 링크 재작성)
clean_guideline() {
    local file="$1"
    local part_name="$2"
    cat "$file" \
        | tr -d '\r' \
        | sed -E '/<!--.*Copyright.*-->/d; /<!--.*Copyright/,/-->/d' \
        | sed -E 's/^(##+ .*) \{ #([A-Za-z0-9_-]+) \}$/<a id="\2"><\/a>\n\n\1/' \
        | sed -E 's/<why>(.*)<\/why>/> **Rationale**: \1/' \
        | sed -E 's/<version>[^<]*<\/version>//g' \
        | strip_agent_images \
        | rewrite_markdown_links "$file" "$part_name" \
        | awk 'NF{print $0; b=0} !NF{if(!b){print ""; b=1}}'
}

# 원본 개요 문서 정제 함수 (빌드 일자 div 태그 제거 등)
clean_overview() {
    clean_guideline "$SRC_GUIDELINES/README.md" "00-1-overview.md" \
        | sed -E '/^<div id="build-date">.*<\/div>$/d'
}

# [3단계] 공통 안내 문서(개요) 파트 생성
# 원본 개요(00-1-overview.md)를 정제하여 보존합니다.
clean_overview > "$PARTS_DIR/00-1-overview.md"

# [4단계] 카테고리별 파트 파일(parts/*.md) 생성 및 가이드라인 정제
# 각 범주를 순회하며 목차(TOC), Rationale 요약, 본문 정제 및 라우팅 메타데이터를 수집합니다.
for entry in "${CATEGORIES[@]}"; do
    IFS=":" read -r part_prefix cat_dir cat_title <<< "$entry"
    full_cat_dir="$SRC_GUIDELINES/$cat_dir"
    part_file="$PARTS_DIR/${part_prefix}.md"

    if [[ ! -d "$full_cat_dir" ]]; then
        echo "Warning: Directory $full_cat_dir not found, skipping."
        continue
    fi

    # 공식 출판 순서인 카테고리 README.md의 include 순서를 보존합니다.
    # README가 없는 경우 파일명 정렬 순서로 대체합니다.
    readme_file="$full_cat_dir/README.md"
    if [[ -f "$readme_file" ]]; then
        mapfile -t included_files < <(
            sed -nE 's/.*\{\{#include (M-[^}]+\.md)\}\}.*/\1/p' "$readme_file"
        )
        m_files=()
        for included_file in "${included_files[@]}"; do
            if [[ -f "$full_cat_dir/$included_file" ]]; then
                m_files+=("$full_cat_dir/$included_file")
            fi
        done
    else
        mapfile -t m_files < <(find "$full_cat_dir" -maxdepth 1 -name "M-*.md" | sort)
    fi
    rule_count="${#m_files[@]}"

    if [[ "$rule_count" -eq 0 ]]; then
        echo "Skipping $cat_dir: No guideline files found."
        continue
    fi

    echo "Processing [$part_prefix] $cat_title ($rule_count rules)..."

    part_number="${part_prefix%%-*}"
    if [[ "$part_prefix" == 02-[1-4]-libs-* ]]; then
        part_number+=".${part_prefix:3:1}"
    fi

    # 파트 파일 생성 시작: 제목 및 출처 메타데이터 작성
    cat > "$part_file" << EOF
# $cat_title

> Pragmatic Rust Guidelines - Part $part_number
> Source category: \`$cat_dir\`

EOF

    # 카테고리 README.md에 소개글이 있는 경우 추가
    readme_file="$full_cat_dir/README.md"
    if [[ -f "$readme_file" ]]; then
        # 저작권 주석과 제목을 제외한 소개 본문 추출
        readme_desc=$(cat "$readme_file" \
            | tr -d '\r' \
            | sed -E '/<!--.*Copyright.*-->/d; /<!--.*Copyright/,/-->/d' \
            | sed -E '/^# /d' \
            | sed -E '/\{\{#include/d' \
            | rewrite_markdown_links "$readme_file" "${part_prefix}.md" \
            | awk 'NF{print $0; b=0} !NF{if(!b){print ""; b=1}}' \
            | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba')
        if [[ -n "${readme_desc// }" ]]; then
            echo "$readme_desc" >> "$part_file"
            echo "" >> "$part_file"
        fi
    fi

    # 해당 파트의 목차(TOC) 생성
    echo "## Table of Contents" >> "$part_file"
    echo "" >> "$part_file"
    
    rule_ids=()
    for m_file in "${m_files[@]}"; do
        # 규칙 ID 및 제목 추출
        raw_header=$(grep -m 1 '^## ' "$m_file" | tr -d '\r' | sed -E 's/^(##+ .*) \{ #[A-Za-z0-9_-]+ \}/\1/')
        title="${raw_header#\#\# }"
        
        # M-FOO 형태의 규칙 ID 추출
        rule_id=$(echo "$title" | grep -oE '\(M-[A-Z0-9-]+\)' | tr -d '()' || true)
        if [[ -n "$rule_id" ]]; then
            rule_ids+=("\`$rule_id\`")
        fi
        
        # <why> 태그에서 근거(Rationale) 추출
        rationale=$(grep -m 1 '<why>' "$m_file" | tr -d '\r' | sed -E 's/.*<why>(.*)<\/why>.*/\1/' || true)
        if [[ -n "$rationale" ]]; then
            echo "- **$title**: $rationale" >> "$part_file"
        else
            echo "- **$title**" >> "$part_file"
        fi
    done
    echo "" >> "$part_file"
    echo "---" >> "$part_file"
    echo "" >> "$part_file"

    # 정제된 가이드라인 본문 추가
    for m_file in "${m_files[@]}"; do
        clean_guideline "$m_file" "${part_prefix}.md" >> "$part_file"
        echo "" >> "$part_file"
        echo "---" >> "$part_file"
        echo "" >> "$part_file"
    done

    # SKILL.md 라우팅 테이블용 메타데이터 저장
    rule_ids_str=""
    if [[ ${#rule_ids[@]} -gt 0 ]]; then
        rule_ids_str=$(printf ", %s" "${rule_ids[@]}")
        rule_ids_str="${rule_ids_str:2}"
    fi
    ROUTING_ENTRIES+=("${part_prefix}.md|${cat_title}|${rule_count}|${rule_ids_str}")

    TOTAL_RULES=$((TOTAL_RULES + rule_count))
    TOTAL_PARTS=$((TOTAL_PARTS + 1))
done

# [5단계] 생성된 파트 및 규칙 앵커 무결성 검증
# 생성된 총 규칙 수 일치 여부와 각 파트 파일 내 규칙 HTML 앵커 존재를 검증합니다.
if [[ "$TOTAL_RULES" -ne "${#PART_BY_RULE_ID[@]}" ]]; then
    echo "Error: Generated $TOTAL_RULES rules, but the source map contains ${#PART_BY_RULE_ID[@]}." >&2
    exit 1
fi

for rule_id in "${!PART_BY_RULE_ID[@]}"; do
    generated_part="$PARTS_DIR/${PART_BY_RULE_ID[$rule_id]}"
    if [[ ! -f "$generated_part" ]] || ! grep -Fq "<a id=\"$rule_id\"></a>" "$generated_part"; then
        echo "Error: Generated part is missing the anchor for $rule_id: $generated_part" >&2
        exit 1
    fi
done

# 개요 파트(00-1-overview.md) 생성 확인
if [[ ! -f "$PARTS_DIR/00-1-overview.md" ]]; then
    echo "Error: Generated support part is missing: 00-1-overview.md" >&2
    exit 1
fi

# [6단계] 에이전트 스킬 진입점 인덱스 파일(SKILL.md) 생성
# 메타데이터(Frontmatter), 사용 지침, 범주별 라우팅 테이블, AI 에이전트 모범 사례를 작성합니다.
echo "Generating $SKILL_FILE..."

cat > "$SKILL_FILE" << 'EOF'
---
name: pragmatic-rust-guidelines
description: Pragmatic Rust design guidelines covering universal idioms, API UX, resilience, performance, correctness, macros, and FFI. Use when writing, reviewing, or refactoring Rust code to ensure safety, efficiency, and maintainability.
---

# Pragmatic Rust Guidelines

A comprehensive collection of pragmatic design guidelines helping Rust developers and AI agents produce idiomatic, safe, and high-performance code that scales.

## When to Use This Skill
- **Writing new Rust code**: Refer to naming conventions, type modeling, and ergonomic API design patterns.
- **Code reviews & refactoring**: Check for anti-patterns, unsoundness, unhandled panics, and allocation bloat.
- **Performance optimization**: Review hasher selection, memory pre-allocation, zero-copy practices, and cache efficiency.
- **Safety & Error handling**: Ensure predictable error boundaries, avoid premature unwraps/panics, and properly guard unsafe blocks.


## Applying These Guidelines
Treat `must` as expected to always hold; `should` allows flexibility. Teams may apply the guidelines as appropriate to their project.
Understand each guideline's rationale before making exceptions; do not follow its letter when doing so would violate its purpose.
Read the [source overview](parts/00-1-overview.md) for the full design principles and applicability guidance. For each task, use the routing table to select relevant parts, then read their table of contents, rationale, and guideline text before applying a rule.

## Guidelines Routing Table (Parts Index)
Choose and inspect the relevant part file based on your current task:

| Part File | Domain | Rules | Key Guidelines (IDs) |
| :--- | :--- | :---: | :--- |
EOF

for entry in "${ROUTING_ENTRIES[@]}"; do
    IFS="|" read -r p_file p_title p_count p_ids <<< "$entry"
    echo "| [\`$p_file\`](parts/$p_file) | $p_title | $p_count | $p_ids |" >> "$SKILL_FILE"
done

cat >> "$SKILL_FILE" << 'EOF'

## Best Practices for AI Agents Using This Skill
1. **Targeted Reading**: Do not load the entire guideline corpus at once. Look at the routing table above, locate the specific domain file (e.g., `parts/07-performance.md`), and inspect only that file.
2. **Spirit Over Letter**: The guidelines exist to safeguard safety, efficiency, and clarity. Understand the rationale behind each guideline before applying or making exceptions.
3. **Rust-Shaped Solutions**: Do not directly transliterate C++/Java/C# OOP patterns into Rust. Follow Rust idioms (ownership, traits, exhaustive matching, explicit errors).
EOF

# [7단계] 생성된 마크다운 문서 간의 링크 및 앵커 최종 유효성 검증
# 모든 생성 파일의 상대 링크와 규칙 앵커 대상이 실제로 존재하는지 전수 검사합니다.
validate_generated_links
echo "Generated Markdown links and anchors validated."

# [8단계] 빌드 완료 요약 정보 출력
echo ""
echo "=========================================="
echo " Agent Skills Build Complete!"
echo " - Total Parts Generated : $TOTAL_PARTS"
echo " - Total Guidelines Cleaned: $TOTAL_RULES"
echo " - Skills Directory        : $SKILLS_DIR"
echo " - Entrypoint              : $SKILL_FILE"
echo "=========================================="
