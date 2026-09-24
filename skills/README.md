# Build Pragmatic Rust Guidelines Skills

이 프로젝트는 Microsoft Pragmatic Rust Guidelines를 AI 에이전트가 활용하기 쉬운 스킬로 재구성합니다. 이를 통해 에이전트는 Rust 코드를 작성하거나 검토할 때 전체 가이드라인을 한꺼번에 읽는 대신, 작업에 맞는 지침을 선택적으로 참고할 수 있습니다.

## 참고 자료

- Upstream 저장소: [microsoft/rust-guidelines](https://github.com/microsoft/rust-guidelines)
- 공식 가이드라인 사이트: [Pragmatic Rust Guidelines](https://microsoft.github.io/rust-guidelines/)

## 구성

- `pragmatic-rust-guidelines/SKILL.md`: 스킬의 진입점과 가이드라인 탐색 안내
- `pragmatic-rust-guidelines/parts/`: 분야별로 나눈 생성 결과
- `_build/pragmatic-rust-guidelines/`: 스킬 생성 도구와 입력 자료
  - `build_agent_skills.sh`: `src/guidelines/`를 바탕으로 스킬 생성
  - `transform_images.sh`: 원본 이미지 해시를 확인하고 생성 중 지원되는 이미지 마크업을 텍스트 설명으로 대체
  - `image_manifest.txt`: 검토된 가이드라인 이미지의 해시 목록
  - `image_texts/`: 이미지에 대응하는 텍스트 설명

## 카테고리 설명

`parts/`의 각 파일은 다음 범주의 가이드라인을 담습니다.

- `01-universal.md`: Rust 전반의 공통 관행, 정적 검증과 lint, 공개 타입의 출력, 명명 및 로깅.
- `02.1-libs-interop.md`: 라이브러리 API와 Rust·외부 타입 및 trait, I/O 간의 상호운용.
- `02.2-libs-ux.md`: 사용하기 쉬운 라이브러리 API를 위한 추상화, 오류 표현, 생성 패턴 및 메서드 설계.
- `02.3-libs-resilience.md`: 테스트 가능성, 강한 타입, 전역 상태와 로깅 등 견고한 라이브러리 구현.
- `02.4-libs-building.md`: 라이브러리의 시작 경험, 시스템 의존 크레이트 및 Cargo 기능 설계.
- `03-macros.md`: 매크로 사용 기준과 선언형·프로시저 매크로의 설계 및 구현.
- `04-apps.md`: 애플리케이션 바이너리의 오류 처리, 할당자 및 대상 CPU 설정.
- `05-ffi.md`: FFI 경계의 상태 격리, 값 변환 및 이름 지정.
- `06-correctness.md`: `unsafe` 코드의 soundness와 정의되지 않은 동작, panic 처리.
- `07-performance.md`: 처리량과 hot path, 메모리·할당, 간접 참조, 해싱 및 비동기 스택 최적화.
- `08-project.md`: Cargo workspace와 크레이트 구조, Rust edition 및 MSRV 관리.
- `09-docs.md`: 문서의 첫 문장, 모듈 문서, 정본 링크 및 인라인 문서 작성.
- `10-ai.md`: AI 지원을 고려한 설계, 항목별 탐색, 유효한 테스트 및 Rust다운 해결 방식.

## 다른 프로젝트에서 사용

대상 프로젝트에서 사용하는 AI 에이전트가 스킬을 검색하는 디렉터리를 확인한 뒤, `pragmatic-rust-guidelines` 폴더 전체를 그 위치에 복사합니다. 스킬의 상대 경로 참조가 유지되도록 `SKILL.md`와 `parts/`를 함께 복사해야 합니다.

```bash
# TARGET_SKILLS_DIR을 대상 프로젝트의 스킬 검색 디렉터리로 설정합니다.
cp -R skills/pragmatic-rust-guidelines "$TARGET_SKILLS_DIR/"
```

복사된 폴더 구조는 다음과 같습니다.

```text
<대상 프로젝트>/
└── skills/
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

### 스크립트 작동 방식

`build_agent_skills.sh`는 mdBook의 `src/guidelines/` 원본에서 AI 에이전트용 스킬을 생성합니다.

1. `transform_images.sh --check`가 이미지 manifest 누락, 이미지 변경·누락·추가를 검사합니다. 문제가 있으면 빌드를 중단합니다. 이미지 참조에 대응하는 `image_texts/NAME.md`가 없을 때도 변환이 실패합니다.
2. 스크립트에 정의된 공개 가이드북 순서로 범주를 처리하고, 각 범주의 `README.md` include 순서를 따릅니다. 잘못된 include, 중복 include, 파일이 누락된 include, README에서 빠진 `M-*.md`는 빌드 오류입니다.
3. `parts/00-overview.md`와 `parts/00-checklist.md`에 원본 개요·적용 지침과 master checklist를 보존하고, `parts/01-*.md`부터 분야별 규칙을 생성합니다. 저작권 주석과 `<version>` 태그를 정리하고, 제목 anchor는 HTML anchor로 보존하며 `<why>`는 근거 문장으로 바꿉니다.
4. source-relative 규칙 링크를 생성된 `parts/` 파일과 규칙 anchor로 변환합니다. 삭제되거나 알 수 없는 `M-*` anchor는 해당 파트로 연결하고 경고합니다. `SKILL.md`는 적용 지침과 checklist 링크, 범주별 routing table을 제공합니다.

`transform_images.sh --transform`은 이미지 대신 검토된 텍스트 설명을 삽입하고 단독 `<div>` 래퍼를 제거합니다. 설명은 `image_texts/`에서 관리하며 자동 생성하지 않습니다.

입력 범주와 이미지 검증은 기존 생성 파일을 지우기 전에 수행합니다. 빌드가 성공하면 생성 결과가 `skills/pragmatic-rust-guidelines/`에 기록됩니다. 원본 변경과 함께 결과를 검토하세요.

이 빌드 흐름은 기존 `scripts/agents_summary.sh`와 별개입니다. 해당 스크립트는 `src/agents/all.txt`와 `src/agents/all.meta`를 생성합니다.

## 브랜치 운영 의도

`main`은 upstream 변경사항을 반영하는 용도로 유지합니다. `custom`에는 이 디렉터리의 스킬 생성 도구와 생성된 스킬을 둡니다. upstream 변경을 `main`에서 `custom`으로 반영한 뒤 관련 가이드라인이 바뀌었다면 스킬을 다시 생성합니다. custom 전용 변경은 `main`에 병합하지 않습니다.
