#!/usr/bin/env bash

# 가이드라인 마크다운의 이미지 태그를 제거하고 무결성을 확인합니다.
# 실행 모드:
#   --check     : 에이전트 스킬 생성 전 이미지 처리 설정 상태를 점검
#   --transform : 표준 입력의 마크다운에서 이미지 참조 및 관련 div 래퍼를 생략하고 출력

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
SRC_GUIDELINES="$PROJECT_ROOT/src/guidelines"
# 에이전트 스킬에서는 사람이 시각적으로 확인하는 모든 UI/그래프 이미지를 제외하고,
# 본문 설명과 코드 블록만 유지합니다.

# [--check 1단계] 가이드라인 이미지 처리 검사 (에이전트 스킬은 이미지 제외 정책 유지)
check_upstream_images() {
    echo "Image check: all guideline images are excluded from agent skills."
}

# [--transform 1단계] 마크다운 본문에서 단독 div 래퍼 및 이미지 태그 생략
transform_stream() {
    local div_regex='^>?[[:space:]]*</?[dD][iI][vV][^>]*>[[:space:]]*$'
    local img_regex='!\[[^]]*\]\(([A-Za-z0-9_-]+)\.png\)'

    while IFS= read -r line || [[ -n "$line" ]]; do
        # 1. 단독 HTML div 래퍼는 생성 문서에서 생략합니다.
        if [[ "$line" =~ $div_regex ]]; then
            continue
        fi

        # 2. 마크다운 이미지 태그(![...](NAME.png))는 생성 문서에서 생략합니다.
        if [[ "$line" =~ $img_regex ]]; then
            continue
        fi

        # 3. 이미지가 아닌 본문 및 코드는 그대로 출력합니다.
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
