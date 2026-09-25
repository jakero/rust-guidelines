#!/usr/bin/env bash

# 가이드라인 이미지의 변경을 감지하고 에이전트용 텍스트로 변환합니다.
# 실행 모드:
#   --check     : 원본 이미지와 image_manifest.txt의 해시를 대조하고 변경 사항을 기록
#   --transform : 표준 입력의 마크다운 이미지 참조를 image_texts/*.md 내용으로 대체해 출력

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
SRC_GUIDELINES="$PROJECT_ROOT/src/guidelines"
MANIFEST_FILE="$SCRIPT_DIR/image_manifest.txt"
LOG_FILE="$SCRIPT_DIR/image_changes.log"
TEXTS_DIR="$SCRIPT_DIR/image_texts"
# M-TYPES-SEND 벤치마크 그래프의 요지는 본문에 이미 설명되어 있습니다.
# 스킬 생성과 이미지 무결성 검사에서 제외하고 원본 이미지는 그대로 둡니다.
OMITTED_IMAGE="M-TYPES-SEND"

# [--check 1단계] 이미지 매니페스트 존재 여부 확인
check_upstream_images() {
    local changes_detected=0
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [[ ! -f "$MANIFEST_FILE" ]]; then
        echo "Error: Image manifest $MANIFEST_FILE not found." >&2
        return 1
    fi

    # [--check 2단계] 등록된 원본 이미지의 존재 여부와 해시 검사
    while IFS=" " read -r rel_path expected_hash reviewed_date || [[ -n "$rel_path" ]]; do
        # 빈 줄과 주석은 검사 대상에서 제외합니다.
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

    # [--check 3단계] 새 이미지가 매니페스트에서 누락되었는지 확인
    while IFS= read -r img_path; do
        local rel_img="${img_path#$PROJECT_ROOT/}"
        [[ "$rel_img" == "src/guidelines/libs/interop/$OMITTED_IMAGE.png" ]] && continue
        # 제외 대상 외의 이미지만 매니페스트 등록 여부를 검사합니다.
        if ! grep -q "^$rel_img " "$MANIFEST_FILE" 2>/dev/null; then
            echo "[$timestamp] [NEW_IMAGE] $rel_img" >> "$LOG_FILE"
            echo "  - Action Required: New image found without entry in image_manifest.txt or image_texts/" >> "$LOG_FILE"
            echo "" >> "$LOG_FILE"

            echo "⚠️  [WARNING] New unregistered image detected: $rel_img" >&2
            echo "   Logged to $LOG_FILE. Please consider creating markdown replacement." >&2
            changes_detected=1
        fi
    done < <(find "$SRC_GUIDELINES" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.svg" -o -name "*.webp" \) | sort)

    # [--check 4단계] 변경이 있으면 실패하고, 없으면 검사한 이미지 수 출력
    if [[ $changes_detected -ne 0 ]]; then
        return 1
    fi

    local manifest_count
    manifest_count=$(grep -cEv '^[[:space:]]*(#|$)' "$MANIFEST_FILE")
    echo "Image integrity check passed ($manifest_count upstream images match manifest)."
}

# [--transform 1단계] 입력의 HTML div 래퍼 제거
transform_stream() {
    local div_regex='^>?[[:space:]]*</?[dD][iI][vV][^>]*>[[:space:]]*$'
    local img_regex='!\[[^]]*\]\(([A-Za-z0-9_-]+)\.png\)'

    while IFS= read -r line || [[ -n "$line" ]]; do
        # 단독 HTML div 래퍼는 생성 문서에 포함하지 않습니다.
        if [[ "$line" =~ $div_regex ]]; then
            continue
        fi

        # [--transform 2단계] 마크다운 이미지 참조를 찾아 제외하거나 텍스트로 대체
        if [[ "$line" =~ $img_regex ]]; then
            local img_name="${BASH_REMATCH[1]}"
            # 본문으로 충분히 설명되는 그래프는 생성 문서에서 생략합니다.
            if [[ "$img_name" == "$OMITTED_IMAGE" ]]; then
                continue
            fi
            local text_file="$TEXTS_DIR/${img_name}.md"

            # 나머지 이미지는 검토된 설명 파일의 내용으로 대체합니다.
            if [[ -f "$text_file" ]]; then
                cat "$text_file"
                continue
            fi

            echo "Error: No text description found for guideline image $img_name.png." >&2
            return 1
        fi

        # [--transform 3단계] 이미지가 아닌 본문은 그대로 출력
        echo "$line"
    done
}

# 지정된 실행 모드의 단계만 수행합니다.
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
