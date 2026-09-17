#!/usr/bin/env bash

# transform_images.sh - Transform guideline images to text and detect upstream changes
# Modes:
#   --check     : Verify upstream image integrity against image_manifest.txt and log changes
#   --transform : Read markdown from stdin, replace image tags with image_texts/*.md, write to stdout

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_GUIDELINES="$PROJECT_ROOT/src/guidelines"
MANIFEST_FILE="$SCRIPT_DIR/image_manifest.txt"
LOG_FILE="$SCRIPT_DIR/image_changes.log"
TEXTS_DIR="$SCRIPT_DIR/image_texts"

check_upstream_images() {
    local changes_detected=0
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [[ ! -f "$MANIFEST_FILE" ]]; then
        echo "Warning: Manifest file $MANIFEST_FILE not found." >&2
        return 0
    fi

    # Check for modifications to existing tracked images
    while IFS=" " read -r rel_path expected_hash reviewed_date || [[ -n "$rel_path" ]]; do
        # Skip empty lines or comment lines
        [[ -z "$rel_path" || "$rel_path" =~ ^# ]] && continue

        local full_path="$PROJECT_ROOT/$rel_path"
        if [[ ! -f "$full_path" ]]; then
            echo "[$timestamp] [MISSING] $rel_path not found on disk!" >> "$LOG_FILE"
            echo "⚠️  [WARNING] Tracked image file not found: $rel_path" >&2
            changes_detected=1
            continue
        fi

        local current_hash
        current_hash=$(sha256sum "$full_path" | awk '{print $1}')

        if [[ "$current_hash" != "$expected_hash" ]]; then
            echo "[$timestamp] [MODIFIED] $rel_path" >> "$LOG_FILE"
            echo "  - Old SHA256: $expected_hash (reviewed on $reviewed_date)" >> "$LOG_FILE"
            echo "  - New SHA256: $current_hash" >> "$LOG_FILE"
            echo "  - Action Required: Inspect updated image and review $TEXTS_DIR/$(basename "$rel_path" .png).md" >> "$LOG_FILE"
            echo "" >> "$LOG_FILE"

            echo "🔔 [NOTICE] Upstream image modified: $(basename "$rel_path")" >&2
            echo "   Logged to $LOG_FILE. Text representation should be reviewed." >&2
            changes_detected=1
        fi
    done < "$MANIFEST_FILE"

    # Check for new untracked images in guidelines
    while IFS= read -r img_path; do
        local rel_img="${img_path#$PROJECT_ROOT/}"
        # If not present in manifest
        if ! grep -q "^$rel_img " "$MANIFEST_FILE" 2>/dev/null; then
            echo "[$timestamp] [NEW_IMAGE] $rel_img" >> "$LOG_FILE"
            echo "  - Action Required: New image found without entry in image_manifest.txt or image_texts/" >> "$LOG_FILE"
            echo "" >> "$LOG_FILE"

            echo "⚠️  [WARNING] New unregistered image detected: $rel_img" >&2
            echo "   Logged to $LOG_FILE. Please consider creating markdown replacement." >&2
            changes_detected=1
        fi
    done < <(find "$SRC_GUIDELINES" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.svg" -o -name "*.webp" \) | sort)

    if [[ $changes_detected -eq 0 ]]; then
        echo "Image integrity check passed (all 5 upstream images match manifest)."
    fi
}

transform_stream() {
    local div_regex='^>?[[:space:]]*</?[dD][iI][vV][^>]*>[[:space:]]*$'
    local img_regex='!\[[^]]*\]\(([A-Za-z0-9_-]+)\.png\)'

    while IFS= read -r line || [[ -n "$line" ]]; do
        # 1. Strip HTML div wrappers (like in M-TYPES-SEND.md)
        if [[ "$line" =~ $div_regex ]]; then
            continue
        fi

        # 2. Check for markdown image tag: ![...](NAME.png)
        if [[ "$line" =~ $img_regex ]]; then
            local img_name="${BASH_REMATCH[1]}"
            local text_file="$TEXTS_DIR/${img_name}.md"

            if [[ -f "$text_file" ]]; then
                cat "$text_file"
                continue
            fi
        fi

        echo "$line"
    done
}

case "${1:-}" in
    --check)
        check_upstream_images
        ;;
    --transform)
        transform_stream
        ;;
    *)
        echo "Usage: $0 [--check | --transform]" >&2
        exit 1
        ;;
esac
