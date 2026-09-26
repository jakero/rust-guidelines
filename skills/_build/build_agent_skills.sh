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
SKILL_TEMPLATE="$SCRIPT_DIR/SKILL.md.template"


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

# 반영된 upstream 리비전 및 커밋 날짜 전역 변수
UPSTREAM_COMMIT_FULL=""
UPSTREAM_COMMIT_DATE=""

# upstream 리비전 식별 및 소스 디렉터리 무결성을 검증하는 함수
verify_upstream_source_revision() {
    local upstream_ref="refs/remotes/upstream/main"
    if ! git -C "$PROJECT_ROOT" rev-parse --verify --quiet "$upstream_ref" >/dev/null; then
        echo "Error: Upstream reference '$upstream_ref' is not found in the local repository." >&2
        echo "Run 'git fetch upstream main' to update the local upstream reference before building." >&2
        return 1
    fi

    local -a merge_bases=()
    mapfile -t merge_bases < <(git -C "$PROJECT_ROOT" merge-base --all HEAD "$upstream_ref")
    if [[ "${#merge_bases[@]}" -eq 0 ]]; then
        echo "Error: No common merge-base commit found between HEAD and '$upstream_ref'." >&2
        return 1
    elif [[ "${#merge_bases[@]}" -gt 1 ]]; then
        echo "Error: Multiple merge-base commits found between HEAD and '$upstream_ref': ${merge_bases[*]}" >&2
        return 1
    fi

    local candidate_sha="${merge_bases[0]}"
    local rel_src_dir="src/guidelines"

    # 1. 후보 리비전과 HEAD의 src/guidelines 트리가 완전히 일치하는지 검증
    local tree_diff
    tree_diff=$(git -C "$PROJECT_ROOT" diff-tree -r --no-commit-id "$candidate_sha" HEAD -- "$rel_src_dir")
    if [[ -n "$tree_diff" ]]; then
        echo "Error: The source guidelines in HEAD differ from the incorporated upstream revision ($candidate_sha)." >&2
        return 1
    fi

    # 2. 작업 트리 내 src/guidelines의 staged/unstaged 변경 여부 검증
    # (Git LFS 파일은 로컬 바이너리 체크아웃과 git index 포인터 간 차이로 WSL/Windows 환경에서 diff가 뜰 수 있으므로 filter!=lfs 파일만 검사)
    local modified_files=()
    mapfile -t modified_files < <(
        { git -C "$PROJECT_ROOT" diff --name-only -- "$rel_src_dir"; \
          git -C "$PROJECT_ROOT" diff --cached --name-only -- "$rel_src_dir"; } | sort -u
    )
    local non_lfs_modifications=()
    for mod_file in "${modified_files[@]}"; do
        [[ -z "$mod_file" ]] && continue
        local filter_attr
        filter_attr=$(git -C "$PROJECT_ROOT" check-attr filter -- "$mod_file" | awk -F': ' '{print $3}')
        if [[ "$filter_attr" != "lfs" ]]; then
            non_lfs_modifications+=("$mod_file")
        fi
    done
    if [[ "${#non_lfs_modifications[@]}" -gt 0 ]]; then
        echo "Error: The source guidelines directory has uncommitted tracked modifications:" >&2
        printf ' - %s\n' "${non_lfs_modifications[@]}" >&2
        return 1
    fi

    # 3. 작업 트리 내 src/guidelines의 untracked 및 ignored 파일 존재 여부 검증
    local extra_files
    extra_files=$(git -C "$PROJECT_ROOT" status --porcelain --ignored -- "$rel_src_dir" | grep -E '^(\?\?|!!)' || true)
    if [[ -n "$extra_files" ]]; then
        echo "Error: The source guidelines directory contains untracked or ignored files:" >&2
        echo "$extra_files" >&2
        return 1
    fi

    UPSTREAM_COMMIT_FULL="$candidate_sha"
    UPSTREAM_COMMIT_DATE=$(git -C "$PROJECT_ROOT" log -1 --format="%cI" "$candidate_sha")
    if [[ -z "$UPSTREAM_COMMIT_DATE" ]]; then
        echo "Error: Failed to extract commit date for upstream revision $candidate_sha." >&2
        return 1
    fi
}

# 원본 가이드라인 내 과거/변경 전 규칙 ID 별칭 매핑
declare -A RULE_ID_ALIASES=(
    ["M-ABSTRACTIONS-DONT-NEST"]="M-SIMPLE-ABSTRACTIONS"
    ["M-DOC-FIRST-SENTENCE"]="M-FIRST-DOC-SENTENCE"
)

# 원본 가이드라인에서 참조하지만 현재 실체가 없는 규칙 ID 집합 (링크 비활성화 처리)
declare -A UNRESOLVED_RULE_REFS=(
    ["M-RUNTIME-ABSTRACTED"]=1
)

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

    if [[ -n "$anchor" && -n "${RULE_ID_ALIASES[$anchor]+x}" ]]; then
        anchor="${RULE_ID_ALIASES[$anchor]}"
    fi

    if [[ -n "$anchor" && -n "${UNRESOLVED_RULE_REFS[$anchor]+x}" ]]; then
        echo "Notice: Leaving unresolved source reference '$anchor' in $source_file unlinked." >&2
        return 2
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
            echo "Error: Source link '$destination' in $source_file references unknown rule ID '$anchor'." >&2
            return 1
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
    local in_fence_char=""
    local in_fence_len=0
    local open_fence_pattern='^[[:space:]]*([>][[:space:]]*)*(`{3,}|~{3,})'
    local reference_pattern='^([[:space:]]*\[[^]]+\]:[[:space:]]+)(<[^>]+>|[^[:space:]]+)(.*)$'
    local inline_pattern='(.*)(\]\()([^)]*)(\).*)'

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -n "$in_fence_char" ]]; then
            local close_fence_pattern='^[[:space:]]*([>][[:space:]]*)*('"$in_fence_char"'{'"$in_fence_len"',})[[:space:]]*$'
            if [[ "$line" =~ $close_fence_pattern ]]; then
                in_fence_char=""
                in_fence_len=0
            fi
            printf '%s\n' "$line"
            continue
        fi

        if [[ "$line" =~ $open_fence_pattern ]]; then
            local fence_str="${BASH_REMATCH[2]}"
            in_fence_char="${fence_str:0:1}"
            in_fence_len="${#fence_str}"
            printf '%s\n' "$line"
            continue
        fi

        if [[ "$line" =~ $reference_pattern ]]; then
            local prefix="${BASH_REMATCH[1]}"
            local destination="${BASH_REMATCH[2]}"
            local suffix="${BASH_REMATCH[3]}"
            local rewritten
            local status=0
            rewritten=$(rewrite_link_destination "$source_file" "$source_part" "$destination") || status=$?
            if [[ "$status" -eq 2 ]]; then
                # 링크 정의 대신 배포된 스킬에서도 읽을 수 있는 안내를 남깁니다.
                printf '\n> **Unavailable source reference**: %s is absent from the current source guidelines. The reference is left unlinked; do not infer its contents or substitute another rule.\n\n' "${prefix%: *}"
                continue
            elif [[ "$status" -ne 0 ]]; then
                return 1
            fi
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
            local status=0
            rewritten=$(rewrite_link_destination "$source_file" "$source_part" "$destination") || status=$?
            if [[ "$status" -eq 2 ]]; then
                local before_bracket="${prefix%\[*}"
                local inner_text="${prefix#$before_bracket\[}"
                prefix="${before_bracket}${inner_text}"
                opener=""
                rewritten=""
            elif [[ "$status" -ne 0 ]]; then
                return 1
            fi
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
            local expected_part="${PART_BY_RULE_ID[$anchor]}"
            if [[ -z "$expected_part" ]] \
                || [[ "$(basename "$target_file")" != "$expected_part" ]] \
                || ! grep -Fq "<a id=\"$anchor\"></a>" "$target_file"; then
                echo "Error: Generated Markdown link '$destination' in $source_file has no matching rule anchor." >&2
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
    local search_dir="${1:-$SKILLS_DIR}"
    local file
    local line
    local in_fence_char=""
    local in_fence_len=0
    local open_fence_pattern='^[[:space:]]*([>][[:space:]]*)*(`{3,}|~{3,})'
    local reference_pattern='^([[:space:]]*\[[^]]+\]:[[:space:]]+)(<[^>]+>|[^[:space:]]+)(.*)$'
    local inline_pattern='(.*)(\]\()([^)]*)(\).*)'

    while IFS= read -r file; do
        in_fence_char=""
        in_fence_len=0
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ -n "$in_fence_char" ]]; then
                local close_fence_pattern='^[[:space:]]*([>][[:space:]]*)*('"$in_fence_char"'{'"$in_fence_len"',})[[:space:]]*$'
                if [[ "$line" =~ $close_fence_pattern ]]; then
                    in_fence_char=""
                    in_fence_len=0
                fi
                continue
            fi

            if [[ "$line" =~ $open_fence_pattern ]]; then
                local fence_str="${BASH_REMATCH[2]}"
                in_fence_char="${fence_str:0:1}"
                in_fence_len="${#fence_str}"
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
    done < <(find "$search_dir" -type f -name "*.md" | sort)
}


# ==============================================================================
# 스크립트 실행 흐름 (작동 단계별 순서)
# ==============================================================================
# [1단계] upstream 소스 리비전 및 입력 무결성 검증
# 출력 파일을 수정하기 전에 upstream 리비전 존재 및 src/guidelines 트리의 변경 여부를 확인합니다.
verify_upstream_source_revision

# [2단계] 원본 가이드라인 소스 매핑 및 규칙 ID 인덱싱
# 각 카테고리 디렉터리와 README.md의 include 구문 유효성을 검증하고 규칙 ID 매핑을 구축합니다.
load_source_map

# [3단계] 템플릿 조기 검증 (출력 수정 전 수행)
# SKILL.md.template의 존재 및 CRLF를 감안한 필수 치환 표식 포함 여부를 미리 확인합니다.
if [[ ! -f "$SKILL_TEMPLATE" ]]; then
    echo "Error: Skill template not found: $SKILL_TEMPLATE" >&2
    exit 1
fi

marker_routing="<!-- ROUTING_TABLE_ENTRIES -->"
marker_upstream="<!-- UPSTREAM_SOURCE_REVISION -->"

marker_routing_count=$(tr -d '\r' < "$SKILL_TEMPLATE" | grep -cFx "$marker_routing" || true)
if [[ "$marker_routing_count" -ne 1 ]]; then
    echo "Error: Skill template must contain exactly one '$marker_routing' marker (found $marker_routing_count)." >&2
    exit 1
fi

marker_upstream_count=$(tr -d '\r' < "$SKILL_TEMPLATE" | grep -cFx "$marker_upstream" || true)
if [[ "$marker_upstream_count" -ne 1 ]]; then
    echo "Error: Skill template must contain exactly one '$marker_upstream' marker (found $marker_upstream_count)." >&2
    exit 1
fi

echo "Building Pragmatic Rust Guidelines Agent Skills..."
echo "Target directory: $SKILLS_DIR"
echo ""

# [4단계] 임시 스테이징 디렉터리 준비 (트랜잭션 빌드 보장)
# 기존 스킬 파일을 즉시 삭제하지 않고, 임시 작업 공간에 먼저 완전하게 생성한 뒤 원자적으로 교체합니다.
STAGE_DIR=$(mktemp -d "${PROJECT_ROOT}/skills/.build_stage.XXXXXX")
BACKUP_CONTAINER=""
BACKUP_PREVIOUS=""
PUBLICATION_COMMITTED=0
cleanup() {
    local exit_code=$?
    local signal="${1:-}"
    trap - EXIT INT TERM

    # 실제 백업된 이전 배포본($BACKUP_PREVIOUS)이 존재하는 경우에만 복원 수행
    if [[ "$PUBLICATION_COMMITTED" -eq 0 && -n "$BACKUP_PREVIOUS" && -d "$BACKUP_PREVIOUS" ]]; then
        echo "Build failed during publication! Restoring previous distribution from backup..." >&2
        rm -rf "$SKILLS_DIR"
        mv "$BACKUP_PREVIOUS" "$SKILLS_DIR"
        echo "Previous distribution restored." >&2
    fi
    if [[ -n "$BACKUP_CONTAINER" && -d "$BACKUP_CONTAINER" ]]; then
        rm -rf "$BACKUP_CONTAINER"
    fi
    if [[ -n "$STAGE_DIR" && -d "$STAGE_DIR" ]]; then
        rm -rf "$STAGE_DIR"
    fi

    if [[ -n "$signal" ]]; then
        kill -"$signal" $$
    else
        exit "$exit_code"
    fi
}
trap 'cleanup' EXIT
trap 'cleanup INT' INT
trap 'cleanup TERM' TERM

STAGE_PARTS_DIR="$STAGE_DIR/parts"
STAGE_SKILL_FILE="$STAGE_DIR/SKILL.md"
mkdir -p "$STAGE_PARTS_DIR"

# 라이선스 파일 보존 (루트 LICENSE.md가 존재하면 스테이징 디렉터리에 복사)
if [[ -f "$PROJECT_ROOT/LICENSE.md" ]]; then
    cp "$PROJECT_ROOT/LICENSE.md" "$STAGE_DIR/LICENSE.md"
elif [[ -f "$SKILLS_DIR/LICENSE.md" ]]; then
    cp "$SKILLS_DIR/LICENSE.md" "$STAGE_DIR/LICENSE.md"
fi

# SKILL.md 라우팅 테이블 생성을 위한 메타데이터 수집 변수 초기화
declare -a ROUTING_ENTRIES=()
TOTAL_RULES=0
TOTAL_PARTS=0
# 에이전트용 출력에서 이미지 태그와 단독 div 래퍼를 생략하는 필터 (코드 블록 내부 보존)
strip_agent_images() {
    local div_regex='^[[:space:]]*([>][[:space:]]*)*</?[dD][iI][vV][^>]*>[[:space:]]*$'
    local full_img_regex='^[[:space:]]*([>][[:space:]]*)*!\[[^]]*\]\(([A-Za-z0-9_-]+)\.png\)[[:space:]]*$'
    local open_fence_pattern='^[[:space:]]*([>][[:space:]]*)*(`{3,}|~{3,})'
    local in_fence_char=""
    local in_fence_len=0
    local line

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -n "$in_fence_char" ]]; then
            local close_fence_pattern='^[[:space:]]*([>][[:space:]]*)*('"$in_fence_char"'{'"$in_fence_len"',})[[:space:]]*$'
            if [[ "$line" =~ $close_fence_pattern ]]; then
                in_fence_char=""
                in_fence_len=0
            fi
            printf '%s\n' "$line"
            continue
        fi

        if [[ "$line" =~ $open_fence_pattern ]]; then
            local fence_str="${BASH_REMATCH[2]}"
            in_fence_char="${fence_str:0:1}"
            in_fence_len="${#fence_str}"
            printf '%s\n' "$line"
            continue
        fi

        # 단독 이미지 줄 및 단독 div 래퍼 줄은 완전히 생략
        if [[ "$line" =~ $div_regex || "$line" =~ $full_img_regex ]]; then
            continue
        fi

        # 인라인으로 삽입된 이미지 태그가 있는 경우 주변 설명 문장은 남기고 이미지 마크다운만 제거
        local stripped
        stripped=$(printf '%s\n' "$line" | sed -E 's/!\[[^]]*\]\([A-Za-z0-9_-]+\.png\)//g')
        printf '%s\n' "$stripped"
    done
}

# 에이전트용 출력에서 코드 블록(fence) 외부의 <tip></tip>, <alert></alert> 마커를 일반 텍스트 라벨로 변환하는 필터
transform_advisory_markers() {
    local open_fence_pattern='^[[:space:]]*([>][[:space:]]*)*(`{3,}|~{3,})'
    local in_fence_char=""
    local in_fence_len=0
    local line

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -n "$in_fence_char" ]]; then
            local close_fence_pattern='^[[:space:]]*([>][[:space:]]*)*('"$in_fence_char"'{'"$in_fence_len"',})[[:space:]]*$'
            if [[ "$line" =~ $close_fence_pattern ]]; then
                in_fence_char=""
                in_fence_len=0
            fi
            printf '%s\n' "$line"
            continue
        fi

        if [[ "$line" =~ $open_fence_pattern ]]; then
            local fence_str="${BASH_REMATCH[2]}"
            in_fence_char="${fence_str:0:1}"
            in_fence_len="${#fence_str}"
            printf '%s\n' "$line"
            continue
        fi

        # <tip></tip> 및 <alert></alert> 마커를 의미가 명확한 일반 Markdown 라벨로 정규화
        line="${line//<tip><\/tip>[[:space:]]/Tip: }"
        line="${line//<tip><\/tip>/Tip: }"
        line="${line//<alert><\/alert>[[:space:]]/Caution: }"
        line="${line//<alert><\/alert>/Caution: }"
        printf '%s\n' "$line"
    done
}

# 개별 가이드라인 마크다운 정제 함수 (저작권 제거, 앵커/근거 변환, 권고 마커 정규화, 이미지 생략, 링크 재작성)
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
        | transform_advisory_markers \
        | rewrite_markdown_links "$file" "$part_name" \
        | awk 'NF{print $0; b=0} !NF{if(!b){print ""; b=1}}'
}
# [5단계] 카테고리별 파트 파일(parts/*.md) 생성 및 가이드라인 정제
# 각 범주를 순회하며 목차(TOC), Rationale 요약, 본문 정제 및 라우팅 메타데이터를 스테이징 디렉터리에 수집합니다.
for entry in "${CATEGORIES[@]}"; do
    IFS=":" read -r part_prefix cat_dir cat_title <<< "$entry"
    full_cat_dir="$SRC_GUIDELINES/$cat_dir"
    part_file="$STAGE_PARTS_DIR/${part_prefix}.md"

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

# [6단계] 생성된 파트 및 규칙 앵커 무결성 검증
# 생성된 총 규칙 수 일치 여부와 각 파트 파일 내 규칙 HTML 앵커 존재를 스테이징 공간에서 검증합니다.
if [[ "$TOTAL_RULES" -ne "${#PART_BY_RULE_ID[@]}" ]]; then
    echo "Error: Generated $TOTAL_RULES rules, but the source map contains ${#PART_BY_RULE_ID[@]}." >&2
    exit 1
fi

for rule_id in "${!PART_BY_RULE_ID[@]}"; do
    generated_part="$STAGE_PARTS_DIR/${PART_BY_RULE_ID[$rule_id]}"
    if [[ ! -f "$generated_part" ]] || ! grep -Fq "<a id=\"$rule_id\"></a>" "$generated_part"; then
        echo "Error: Generated part is missing the anchor for $rule_id: $generated_part" >&2
        exit 1
    fi
done

# [7단계] 에이전트 스킬 진입점 인덱스 파일(SKILL.md) 생성
# _build의 템플릿(SKILL.md.template)을 읽어 라우팅 테이블 및 출처 표식을 동적 데이터로 치환합니다.
echo "Generating $SKILL_FILE from template..."

while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "$marker_routing" ]]; then
        for entry in "${ROUTING_ENTRIES[@]}"; do
            IFS="|" read -r p_file p_title p_count p_ids <<< "$entry"
            echo "| [\`$p_file\`](parts/$p_file) | $p_title | $p_count | $p_ids |" >> "$STAGE_SKILL_FILE"
        done
    elif [[ "$line" == "$marker_upstream" ]]; then
        echo "- Repository: https://github.com/microsoft/rust-guidelines" >> "$STAGE_SKILL_FILE"
        echo "- Incorporated revision: [\`$UPSTREAM_COMMIT_FULL\`](https://github.com/microsoft/rust-guidelines/commit/$UPSTREAM_COMMIT_FULL)" >> "$STAGE_SKILL_FILE"
        echo "- Revision committed at: $UPSTREAM_COMMIT_DATE" >> "$STAGE_SKILL_FILE"
    else
        echo "$line" >> "$STAGE_SKILL_FILE"
    fi
done < <(tr -d '\r' < "$SKILL_TEMPLATE")

# [8단계] 생성된 마크다운 문서 간의 링크 및 앵커 최종 유효성 검증 (스테이징 공간 전수 검사)
validate_generated_links "$STAGE_DIR"

# SKILL.md 내에 언급된 모든 규칙 ID가 실제 유효한 규칙 ID인지 전수 검증합니다.
skill_rule_ids=()
mapfile -t skill_rule_ids < <(grep -oE '`M-[A-Z0-9-]+`' "$STAGE_SKILL_FILE" | tr -d '`' | sort -u)
for r_id in "${skill_rule_ids[@]}"; do
    if [[ -z "${PART_BY_RULE_ID[$r_id]+x}" ]]; then
        echo "Error: Unrecognized guideline ID '$r_id' found in $STAGE_SKILL_FILE." >&2
        exit 1
    fi
done
echo "Generated Markdown links, anchors, and SKILL.md rule IDs validated."
# [9단계] 검증 완료된 스테이징 산출물을 백업/복원 트랜잭션을 통해 최종 대상 위치로 반영
# 1) 기존 배포 디렉터리가 존재하는 경우 임시 컨테이너 내부의 'previous' 하위 경로로 안전하게 이동
# 2) 스테이징 디렉터리를 최종 배포 디렉터리로 승격
# 3) 승격 성공 시 백업 컨테이너 정리, 실패 시 trap cleanup을 통해 'previous' 존재 시에만 100% 복원
if [[ -d "$SKILLS_DIR" ]]; then
    BACKUP_CONTAINER=$(mktemp -d "${PROJECT_ROOT}/skills/.build_backup.XXXXXX")
    BACKUP_PREVIOUS="$BACKUP_CONTAINER/previous"

    # 테스트용: 백업 rename 직전(컨테이너만 생성된 시점) 실패/인터럽트 주입 지점
    if [[ "${TEST_INJECT_PRE_BACKUP_FAILURE:-0}" -eq 1 ]]; then
        echo "Error: Injected simulated failure before backup rename!" >&2
        exit 1
    elif [[ "${TEST_INJECT_PRE_BACKUP_SIGNAL:-}" == "INT" ]]; then
        echo "Sending SIGINT before backup rename..." >&2
        kill -INT $$
    elif [[ "${TEST_INJECT_PRE_BACKUP_SIGNAL:-}" == "TERM" ]]; then
        echo "Sending SIGTERM before backup rename..." >&2
        kill -TERM $$
    fi

    mv "$SKILLS_DIR" "$BACKUP_PREVIOUS"
fi

# 테스트용: 백업 rename 직후(승격 직전) 실패/인터럽트 주입 지점
if [[ "${TEST_INJECT_PUBLICATION_FAILURE:-0}" -eq 1 ]]; then
    echo "Error: Injected simulated publication failure!" >&2
    exit 1
elif [[ "${TEST_INJECT_POST_BACKUP_SIGNAL:-}" == "INT" ]]; then
    echo "Sending SIGINT after backup rename..." >&2
    kill -INT $$
elif [[ "${TEST_INJECT_POST_BACKUP_SIGNAL:-}" == "TERM" ]]; then
    echo "Sending SIGTERM after backup rename..." >&2
    kill -TERM $$
fi

mv "$STAGE_DIR" "$SKILLS_DIR"
PUBLICATION_COMMITTED=1
# [10단계] 빌드 완료 요약 정보 출력
echo ""
echo "=========================================="
echo " Agent Skills Build Complete!"
echo " - Total Parts Generated : $TOTAL_PARTS"
echo " - Total Guidelines Cleaned: $TOTAL_RULES"
echo " - Skills Directory        : $SKILLS_DIR"
echo " - Entrypoint              : $SKILL_FILE"
echo "=========================================="
