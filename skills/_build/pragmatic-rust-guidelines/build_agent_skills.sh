#!/usr/bin/env bash

# Script to build agent skills from Pragmatic Rust Guidelines
# Generates:
#   - skills/pragmatic-rust-guidelines/SKILL.md (Index & Routing Guide)
#   - skills/pragmatic-rust-guidelines/parts/*.md (Domain-specific guidelines)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
SRC_GUIDELINES="$PROJECT_ROOT/src/guidelines"
SKILLS_DIR="$PROJECT_ROOT/skills/pragmatic-rust-guidelines"
PARTS_DIR="$SKILLS_DIR/parts"
SKILL_FILE="$SKILLS_DIR/SKILL.md"

mkdir -p "$PARTS_DIR"
rm -f "$PARTS_DIR"/*.md

# Define categories in logical reading order matching SUMMARY.md
CATEGORIES=(
    "01-universal:universal:Universal Guidelines"
    "02-libs-interop:libs/interop:Libraries - Interoperability"
    "03-libs-ux:libs/ux:Libraries - API UX"
    "04-libs-resilience:libs/resilience:Libraries - Resilience & Robustness"
    "05-libs-building:libs/building:Libraries - Building & Cargo Features"
    "06-correctness:correctness:Correctness & Bug Prevention"
    "07-performance:performance:Performance & Resource Optimization"
    "08-apps:apps:Application Binary Design"
    "09-ffi:ffi:FFI & Native Interoperability"
    "10-macros:macros:Macro Design & Safety"
    "11-project:project:Project Structure & CI"
    "12-docs:docs:Documentation Best Practices"
    "13-ai:ai:Designing for AI Assistance"
)

echo "Building Pragmatic Rust Guidelines Agent Skills..."
echo "Target directory: $SKILLS_DIR"
echo ""

# Verify upstream image integrity and log any changes
bash "$SCRIPT_DIR/transform_images.sh" --check
echo ""

# Metadata collector for SKILL.md routing table
declare -a ROUTING_ENTRIES=()
TOTAL_RULES=0
TOTAL_PARTS=0

# Clean-up function for a single guideline file
clean_guideline() {
    local file="$1"
    cat "$file" \
        | tr -d '\r' \
        | sed -E '/<!--.*Copyright.*-->/d; /<!--.*Copyright/,/-->/d' \
        | sed -E 's/^(##+ .*) \{ #[A-Za-z0-9_-]+ \}/\1/' \
        | sed -E 's/<why>(.*)<\/why>/> **Rationale**: \1/' \
        | sed -E 's/<version>[^<]*<\/version>//g' \
        | bash "$SCRIPT_DIR/transform_images.sh" --transform \
        | awk 'NF{print $0; b=0} !NF{if(!b){print ""; b=1}}'
}

# Process each category
for entry in "${CATEGORIES[@]}"; do
    IFS=":" read -r part_prefix cat_dir cat_title <<< "$entry"
    full_cat_dir="$SRC_GUIDELINES/$cat_dir"
    part_file="$PARTS_DIR/${part_prefix}.md"

    if [[ ! -d "$full_cat_dir" ]]; then
        echo "Warning: Directory $full_cat_dir not found, skipping."
        continue
    fi

    # Check if there are M-*.md files
    mapfile -t m_files < <(find "$full_cat_dir" -maxdepth 1 -name "M-*.md" | sort)
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
            | awk 'NF{print $0; b=0} !NF{if(!b){print ""; b=1}}' \
            | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba' || true)
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
        clean_guideline "$m_file" >> "$part_file"
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

echo ""
echo "=========================================="
echo " Agent Skills Build Complete!"
echo " - Total Parts Generated : $TOTAL_PARTS"
echo " - Total Guidelines Cleaned: $TOTAL_RULES"
echo " - Skills Directory        : $SKILLS_DIR"
echo " - Entrypoint              : $SKILL_FILE"
echo "=========================================="
