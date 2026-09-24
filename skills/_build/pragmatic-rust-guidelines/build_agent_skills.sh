#!/usr/bin/env bash

# Script to build agent skills from Pragmatic Rust Guidelines
# Generates:
#   - skills/pragmatic-rust-guidelines/SKILL.md (Index & Routing Guide)
#   - skills/pragmatic-rust-guidelines/parts/*.md (source context and guideline parts)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
SRC_GUIDELINES="$PROJECT_ROOT/src/guidelines"
SKILLS_DIR="$PROJECT_ROOT/skills/pragmatic-rust-guidelines"
PARTS_DIR="$SKILLS_DIR/parts"
SKILL_FILE="$SKILLS_DIR/SKILL.md"


# Categories follow the requested public-book order. Libraries are split into
# their four subcategories and retain the parent number as a dotted prefix.
CATEGORIES=(
    "01-universal:universal:Universal Guidelines"
    "02.1-libs-interop:libs/interop:Libraries - Interoperability"
    "02.2-libs-ux:libs/ux:Libraries - API UX"
    "02.3-libs-resilience:libs/resilience:Libraries - Resilience & Robustness"
    "02.4-libs-building:libs/building:Libraries - Building & Cargo Features"
    "03-macros:macros:Macro Design & Safety"
    "04-apps:apps:Application Binary Design"
    "05-ffi:ffi:FFI & Native Interoperability"
    "06-correctness:correctness:Correctness & Bug Prevention"
    "07-performance:performance:Performance & Resource Optimization"
    "08-project:project:Project Structure & CI"
    "09-docs:docs:Documentation Best Practices"
    "10-ai:ai:Designing for AI Assistance"
)
declare -A PART_BY_SOURCE_DIR=()
declare -A PART_BY_RULE_ID=()

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
        elif [[ "$target_file" == "$PARTS_DIR/00-overview.md" && "$anchor" == "meta-design-principles" ]]; then
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

load_source_map

echo "Building Pragmatic Rust Guidelines Agent Skills..."
echo "Target directory: $SKILLS_DIR"
echo ""

# Validate image hashes and descriptions before replacing generated files.
bash "$SCRIPT_DIR/transform_images.sh" --check
echo ""

mkdir -p "$PARTS_DIR"
rm -f "$PARTS_DIR"/*.md



# Metadata collector for SKILL.md routing table
declare -a ROUTING_ENTRIES=()
TOTAL_RULES=0
TOTAL_PARTS=2

clean_guideline() {
    local file="$1"
    local part_name="$2"
    cat "$file" \
        | tr -d '\r' \
        | sed -E '/<!--.*Copyright.*-->/d; /<!--.*Copyright/,/-->/d' \
        | sed -E 's/^(##+ .*) \{ #([A-Za-z0-9_-]+) \}$/<a id="\2"><\/a>\n\n\1/' \
        | sed -E 's/<why>(.*)<\/why>/> **Rationale**: \1/' \
        | sed -E 's/<version>[^<]*<\/version>//g' \
        | bash "$SCRIPT_DIR/transform_images.sh" --transform \
        | rewrite_markdown_links "$file" "$part_name" \
        | awk 'NF{print $0; b=0} !NF{if(!b){print ""; b=1}}'
}

clean_overview() {
    clean_guideline "$SRC_GUIDELINES/README.md" "00-overview.md" \
        | sed -E '/^<div id="build-date">.*<\/div>$/d'
}


# Preserve the source overview and master checklist as generated skill parts.
clean_overview > "$PARTS_DIR/00-overview.md"
clean_guideline "$SRC_GUIDELINES/checklist/README.md" "00-checklist.md" > "$PARTS_DIR/00-checklist.md"
# Process each category
for entry in "${CATEGORIES[@]}"; do
    IFS=":" read -r part_prefix cat_dir cat_title <<< "$entry"
    full_cat_dir="$SRC_GUIDELINES/$cat_dir"
    part_file="$PARTS_DIR/${part_prefix}.md"

    if [[ ! -d "$full_cat_dir" ]]; then
        echo "Warning: Directory $full_cat_dir not found, skipping."
        continue
    fi

    # Preserve the order declared by the category README, which is the order
    # used by the published book. Fall back to filename order if no README exists.
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

    # Start writing Part file
    cat > "$part_file" << EOF
# $cat_title

> Pragmatic Rust Guidelines - Part $(echo "$part_prefix" | cut -d'-' -f1)
> Source category: \`$cat_dir\`

EOF

    # Add introduction from category README.md if available
    readme_file="$full_cat_dir/README.md"
    if [[ -f "$readme_file" ]]; then
        # Extract content excluding copyright and title
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

    # Generate Table of Contents for this Part
    echo "## Table of Contents" >> "$part_file"
    echo "" >> "$part_file"
    
    rule_ids=()
    for m_file in "${m_files[@]}"; do
        # Extract rule ID and title
        raw_header=$(grep -m 1 '^## ' "$m_file" | tr -d '\r' | sed -E 's/^(##+ .*) \{ #[A-Za-z0-9_-]+ \}/\1/')
        title="${raw_header#\#\# }"
        
        # Extract rule ID like M-FOO
        rule_id=$(echo "$title" | grep -oE '\(M-[A-Z0-9-]+\)' | tr -d '()' || true)
        if [[ -n "$rule_id" ]]; then
            rule_ids+=("\`$rule_id\`")
        fi
        
        # Extract rationale if present
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

    # Append cleaned guidelines
    for m_file in "${m_files[@]}"; do
        clean_guideline "$m_file" "${part_prefix}.md" >> "$part_file"
        echo "" >> "$part_file"
        echo "---" >> "$part_file"
        echo "" >> "$part_file"
    done

    # Save routing metadata for SKILL.md
    rule_ids_str=""
    if [[ ${#rule_ids[@]} -gt 0 ]]; then
        rule_ids_str=$(printf ", %s" "${rule_ids[@]}")
        rule_ids_str="${rule_ids_str:2}"
    fi
    ROUTING_ENTRIES+=("${part_prefix}.md|${cat_title}|${rule_count}|${rule_ids_str}")

    TOTAL_RULES=$((TOTAL_RULES + rule_count))
    TOTAL_PARTS=$((TOTAL_PARTS + 1))
done

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

for support_part in 00-overview.md 00-checklist.md; do
    if [[ ! -f "$PARTS_DIR/$support_part" ]]; then
        echo "Error: Generated support part is missing: $support_part" >&2
        exit 1
    fi
done

# Generate SKILL.md
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
Read the [source overview](parts/00-overview.md) for the full design principles and applicability guidance, and use the [master checklist](parts/00-checklist.md) to review coverage.

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

validate_generated_links
echo "Generated Markdown links and anchors validated."

echo ""
echo "=========================================="
echo " Agent Skills Build Complete!"
echo " - Total Parts Generated : $TOTAL_PARTS"
echo " - Total Guidelines Cleaned: $TOTAL_RULES"
echo " - Skills Directory        : $SKILLS_DIR"
echo " - Entrypoint              : $SKILL_FILE"
echo "=========================================="
