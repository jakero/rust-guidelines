# Build Pragmatic Rust Guidelines Skills

이 디렉터리에는 Pragmatic Rust Guidelines를 에이전트용으로 구성한 스킬이 있습니다. AI 에이전트가 Rust 코드를 작성하거나 검토할 때 전체 가이드라인을 한꺼번에 읽는 대신, 작업에 맞는 지침을 찾아 선택적으로 참고하도록 하는 것이 목표입니다.

## 구성

- `pragmatic-rust-guidelines/SKILL.md`: 스킬의 진입점과 가이드라인 탐색 안내
- `pragmatic-rust-guidelines/parts/`: 분야별로 나눈 생성 결과
- `_build/pragmatic-rust-guidelines/`: 스킬 생성 도구와 입력 자료
  - `build_agent_skills.sh`: `src/guidelines/`를 바탕으로 스킬 생성
  - `transform_images.sh`: 원본 이미지 해시를 확인하고 생성 중 지원되는 이미지 마크업을 텍스트 설명으로 대체
  - `image_manifest.txt`: 검토된 가이드라인 이미지의 해시 목록
  - `image_texts/`: 이미지에 대응하는 텍스트 설명

## 다른 프로젝트에서 사용

대상 프로젝트에서 사용하는 AI 에이전트가 스킬을 검색하는 디렉터리를 확인한 뒤, `pragmatic-rust-guidelines` 폴더 전체를 그 위치에 복사합니다. 스킬의 상대 경로 참조가 유지되도록 `SKILL.md`와 `parts/`를 함께 복사해야 합니다.

```bash
# TARGET_SKILLS_DIR을 대상 프로젝트의 스킬 검색 디렉터리로 설정합니다.
cp -R skills/pragmatic-rust-guidelines "$TARGET_SKILLS_DIR/"
```

복사된 폴더 구조는 다음과 같습니다.

```text
<대상 프로젝트>/
└── <에이전트가 검색하는 스킬 디렉터리>/
    └── pragmatic-rust-guidelines/
        ├── SKILL.md
        └── parts/
```

스킬 검색 경로와 호출 방식은 사용하는 에이전트 도구에 따라 다릅니다. 해당 도구가 스킬을 인식하도록 설정한 뒤, `pragmatic-rust-guidelines`를 참고해 Rust 코드를 작성하거나 검토해 달라고 요청하세요.

## 빌드

가이드라인이나 이미지 설명을 수정한 뒤 저장소 루트에서 실행합니다.

```bash
bash skills/_build/pragmatic-rust-guidelines/build_agent_skills.sh
```

생성 파일은 `skills/pragmatic-rust-guidelines/`에 기록됩니다. 원본 변경과 생성 결과를 함께 검토하세요.

이 빌드 흐름은 기존 `scripts/agents_summary.sh`와 별개입니다. 해당 스크립트는 `src/agents/all.txt`와 `src/agents/all.meta`를 생성합니다.

## 브랜치 운영 의도

`main`은 upstream 변경사항을 반영하는 용도로 유지합니다. `custom`에는 이 디렉터리의 스킬 생성 도구와 생성된 스킬을 둡니다. upstream 변경을 `main`에서 `custom`으로 반영한 뒤 관련 가이드라인이 바뀌었다면 스킬을 다시 생성합니다. custom 전용 변경은 `main`에 병합하지 않습니다.
