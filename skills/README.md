# Build Pragmatic Rust Guidelines Skills

이 프로젝트는 Microsoft Pragmatic Rust Guidelines를 AI 에이전트가 활용하기 쉬운 스킬로 재구성합니다. 이를 통해 에이전트는 Rust 코드를 작성하거나 검토할 때 전체 가이드라인을 한꺼번에 읽는 대신, 작업에 맞는 지침을 선택적으로 참고할 수 있습니다.

## 참고 자료

- Upstream 저장소: [microsoft/rust-guidelines](https://github.com/microsoft/rust-guidelines)
- 공식 가이드라인 사이트: [Pragmatic Rust Guidelines](https://microsoft.github.io/rust-guidelines/)

## 구성

- `pragmatic-rust-guidelines/SKILL.md`: 스킬의 진입점과 가이드라인 탐색 안내
- `pragmatic-rust-guidelines/parts/`: 분야별로 나눈 생성 결과
- `_build/pragmatic-rust-guidelines/`: 스킬 생성 도구
  - `build_agent_skills.sh`: `src/guidelines/`를 바탕으로 스킬 생성
  - `transform_images.sh`: 생성 중 마크다운 이미지 태그 및 불필요한 div 래퍼를 생략

## 카테고리 설명

`parts/`의 각 파일은 다음 범주의 가이드라인을 담습니다.

- `01-universal.md`: Rust 전반의 공통 관행, 정적 검증과 lint, 공개 타입의 출력, 명명 및 로깅.
- `02-1-libs-interop.md`: 라이브러리 API와 Rust·외부 타입 및 trait, I/O 간의 상호운용.
- `02-2-libs-ux.md`: 사용하기 쉬운 라이브러리 API를 위한 추상화, 오류 표현, 생성 패턴 및 메서드 설계.
- `02-3-libs-resilience.md`: 테스트 가능성, 강한 타입, 전역 상태와 로깅 등 견고한 라이브러리 구현.
- `02-4-libs-building.md`: 라이브러리의 시작 경험, 시스템 의존 크레이트 및 Cargo 기능 설계.
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

가이드라인 원본이나 스크립트를 수정한 뒤 저장소 루트에서 실행합니다.

```bash
bash skills/_build/pragmatic-rust-guidelines/build_agent_skills.sh
```

### 스크립트 작동 방식

`build_agent_skills.sh`는 mdBook의 `src/guidelines/` 원본에서 AI 에이전트용 스킬을 생성하며, 다음 9단계 순서로 동작합니다.

1. **원본 가이드라인 소스 매핑 및 규칙 ID 인덱싱 (`load_source_map`)**:
   - 정의된 범주별 디렉터리 존재 여부와 각 범주 `README.md`의 `{{#include M-*.md}}` 구문을 검증합니다.
   - 잘못된 include, 중복 include, 누락된 가이드라인 파일, 또는 README에 포함되지 않은 `M-*.md` 파일이 있으면 즉시 빌드를 중단합니다.
   - 각 가이드라인 헤더에서 고유한 규칙 ID(`M-*`)를 추출하여 중복 여부를 검사하고, 소스 디렉터리 및 규칙 ID와 매핑될 파트 파일 정보를 메모리에 인덱싱합니다.
2. **가이드라인 이미지 처리 검사 (`transform_images.sh --check`)**:
   - 에이전트 스킬에서 모든 가이드라인 이미지를 제외하는 정책이 적용되어 있는지 점검합니다.
3. **출력 대상 디렉터리 준비 및 초기화**:
   - 기존 생성 파일 삭제 전에 앞선 1~2단계 검증이 통과된 경우에만 진행합니다.
   - 출력 디렉터리(`skills/pragmatic-rust-guidelines/parts/`)를 생성하고 기존 생성된 마크다운 파일(`*.md`)을 초기화합니다.
4. **공통 안내 문서(개요) 파트 생성**:
   - `src/guidelines/README.md`를 정제하여 `parts/00-1-overview.md`를 생성합니다 (빌드 일자 div 등 불필요 마크업 제거).
5. **카테고리별 파트 파일(`parts/*.md`) 생성 및 가이드라인 정제**:
   - 정의된 공개 가이드북 순서 및 각 카테고리 `README.md`의 include 선언 순서대로 가이드라인을 처리합니다.
   - 각 파트별 메타데이터, 카테고리 소개글, 규칙 제목과 `<why>` 태그 기반의 근거(Rationale) 요약이 포함된 목차(Table of Contents)를 자동 구성합니다.
   - 각 규칙 파일 본문을 정제합니다: 저작권 주석 및 `<version>` 태그 제거, mdBook 헤더 앵커를 HTML 앵커(`<a id="..."></a>`)로 변환, `<why>` 태그를 Rationale 인용구로 변환, `transform_images.sh --transform`을 통한 이미지 태그 및 불필요한 div 래퍼 생략, 마크다운 링크 재작성을 수행합니다.
   - 동시에 `SKILL.md` 라우팅 테이블 구성을 위한 메타데이터(파트 파일명, 도메인 제목, 규칙 개수, 규칙 ID 목록)를 수집합니다.
6. **생성된 파트 및 규칙 앵커 무결성 검증**:
   - 소스 매핑에서 인덱싱한 총 규칙 수와 실제 생성된 규칙 수가 일치하는지 확인합니다.
   - 모든 규칙 ID의 HTML 앵커가 해당 파트 파일에 누락 없이 존재하는지 확인하고, 개요 파트 파일 존재 여부도 점검합니다.
7. **에이전트 스킬 진입점 인덱스 파일(`SKILL.md`) 생성**:
   - AI 에이전트를 위한 스킬 메타데이터(Frontmatter), 스킬 활용 시점 및 적용 지침을 작성합니다.
   - 5단계에서 수집한 메타데이터를 기반으로 분야별 파트 링크, 도메인명, 포함 규칙 수, 핵심 규칙 ID 목록이 담긴 라우팅 테이블(Routing Table)을 생성합니다.
   - AI 에이전트의 효율적 탐색을 위한 모범 사례(Targeted Reading, Spirit Over Letter, Rust-Shaped Solutions)를 추가합니다.
8. **생성된 마크다운 문서 간의 링크 및 앵커 최종 유효성 검증 (`validate_generated_links`)**:
   - 생성된 모든 마크다운 파일 내의 상대 링크와 규칙 앵커(`M-*`)를 전수 검사하여 누락된 파일이나 깨진 앵커가 없는지 검증합니다.
   - 알 수 없거나 삭제된 앵커 링크가 있으면 경고하고 해당 파트 파일로 정상 유도되었는지 확인합니다.
9. **빌드 완료 요약 정보 출력**:
   - 총 생성된 파트 수, 정제된 규칙 수, 출력 디렉터리 및 진입점 파일 경로를 콘솔에 출력합니다.

원본 `src/guidelines/checklist/README.md`는 규칙 제목과 체크박스를 나열해 사람이 전체 항목을 점검할 때 유용하지만, 규칙의 근거와 예시가 없어 에이전트의 독립적인 적용 자료로는 부족하므로 생성 스킬에 포함하지 않습니다. 에이전트는 `SKILL.md` 라우팅 테이블로 해당 분야를 찾고, 파트별 목차와 규칙 본문의 근거·예시를 읽어 작업에 필요한 규칙만 적용합니다.

`transform_images.sh --transform`은 사람용 원본 문서에 포함된 시각적 UI 화면 캡처 및 그래프 이미지(`*.png`)와 단독 `<div>` 래퍼를 생성 문서에서 생략합니다.

에이전트용 스킬로 재구성하면서 원본 가이드라인의 모든 이미지(`src/guidelines/docs/`의 rustdoc 화면 캡처 4종, `src/guidelines/libs/interop/M-TYPES-SEND.png` 벤치마크 그래프)는 제외되었습니다. 이 이미지들은 사람이 문서를 시각적으로 확인할 때 필요한 참고 자료이며, 에이전트가 Rust 지침을 이해하고 코드를 작성·검토하는 데에는 이미지 참조가 불필요합니다. 관련된 핵심 지침(`#[doc(inline)]` 적용 조건, 문서 첫 문장의 15단어 요약 규칙, `Send` 구현 요건 및 벤치마크 성능 고려사항 등)은 마크다운 본문과 코드 예시만으로 충분히 전달됩니다. 이에 따라 이미지 대체 텍스트(`image_texts/`) 및 해시 매니페스트(`image_manifest.txt`)도 제거하여 빌드 파이프라인을 단순화했습니다. 원본 `src/`의 문서와 이미지 파일은 읽기 전용으로 유지됩니다.

입력 범주와 이미지 검증은 기존 생성 파일을 지우기 전에 수행합니다. 빌드가 성공하면 생성 결과가 `skills/pragmatic-rust-guidelines/`에 기록됩니다. 원본 변경과 함께 결과를 검토하세요.

이 빌드 흐름은 기존 `scripts/agents_summary.sh`와 별개입니다. 해당 스크립트는 `src/agents/all.txt`와 `src/agents/all.meta`를 생성합니다.

## 브랜치 운영 의도

`main`은 upstream 변경사항을 반영하는 용도로 유지합니다. `custom`에는 이 디렉터리의 스킬 생성 도구와 생성된 스킬을 둡니다. upstream 변경을 `main`에서 `custom`으로 반영한 뒤 관련 가이드라인이 바뀌었다면 스킬을 다시 생성합니다. custom 전용 변경은 `main`에 병합하지 않습니다.
