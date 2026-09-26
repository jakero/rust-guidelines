# @Pragmatic Rust Guidelines 에이전트 스킬

이 프로젝트는 Microsoft Pragmatic Rust Guidelines를 AI 에이전트가 작업에 필요한 규칙을 효율적으로 참고할 수 있도록 **스킬 형태로 재구성**합니다. 원본 가이드라인을 분야별 파트로 나누고 규칙을 찾는 경로를 제공합니다.

이 README는 스킬을 설치하고 관리하는 **사용자**를 위한 문서입니다. 에이전트가 Rust 코드를 작성하거나 검토할 때 읽을 진입점은 [`SKILL.md`](pragmatic-rust-guidelines/SKILL.md)입니다.

- 원본 저장소: [microsoft/rust-guidelines](https://github.com/microsoft/rust-guidelines)
- 공식 가이드라인: [Pragmatic Rust Guidelines](https://microsoft.github.io/rust-guidelines/)

## 다른 프로젝트에서 사용

대상 프로젝트에서 AI 에이전트가 스킬을 찾는 디렉터리를 확인하고, 저장소 루트에서 스킬 폴더 전체를 복사합니다. 상대 경로 링크가 유지되도록 `SKILL.md`와 `parts/`를 함께 옮겨야 합니다.

```bash
# TARGET_SKILLS_DIR: 대상 프로젝트의 스킬 검색 디렉터리
cp -R skills/pragmatic-rust-guidelines "$TARGET_SKILLS_DIR/"
```

대상 에이전트 도구에서 스킬 검색 경로를 설정한 뒤, `pragmatic-rust-guidelines`를 참고하여 Rust 코드를 작성하거나 검토해 달라고 요청하세요. 검색 경로와 호출 방법은 도구마다 다릅니다.

## 스킬 구성

- [`SKILL.md`](pragmatic-rust-guidelines/SKILL.md): 적용 지침, 작업별 빠른 색인(Quick Index), 분야별 라우팅 테이블. 에이전트가 규칙을 찾는 시작점입니다.
- `parts/`의 분야별 파일: 목차, 규칙의 근거와 본문. 아래 목록에서 직접 열어볼 수 있습니다.
- `_build/`: 생성 도구(`build_agent_skills.sh`) 및 진입점 템플릿(`SKILL.md.template`). 스킬을 **사용**할 때는 복사할 필요가 없습니다.

### 분야별 파트

| 분야 | 파일 | 다루는 내용 |
| :--- | :--- | :--- |
| 공통 | [`01-universal.md`](pragmatic-rust-guidelines/parts/01-universal.md) | Rust 전반의 관행, 정적 검증, 명명, 로깅 |
| 라이브러리 · 상호운용 | [`02-1-libs-interop.md`](pragmatic-rust-guidelines/parts/02-1-libs-interop.md) | Rust·외부 타입과 trait, I/O |
| 라이브러리 · API UX | [`02-2-libs-ux.md`](pragmatic-rust-guidelines/parts/02-2-libs-ux.md) | 추상화, 오류, 생성 패턴, 메서드 설계 |
| 라이브러리 · 견고성 | [`02-3-libs-resilience.md`](pragmatic-rust-guidelines/parts/02-3-libs-resilience.md) | 테스트 가능성, 강한 타입, 전역 상태, 로깅 |
| 라이브러리 · 빌드 | [`02-4-libs-building.md`](pragmatic-rust-guidelines/parts/02-4-libs-building.md) | 시작 경험, 시스템 의존 크레이트, Cargo 기능 |
| 매크로 | [`03-macros.md`](pragmatic-rust-guidelines/parts/03-macros.md) | 선언형·프로시저 매크로 설계 |
| 애플리케이션 | [`04-apps.md`](pragmatic-rust-guidelines/parts/04-apps.md) | 바이너리 오류 처리, 할당자, 대상 CPU |
| FFI | [`05-ffi.md`](pragmatic-rust-guidelines/parts/05-ffi.md) | 상태 격리, 값 변환, 이름 지정 |
| 정확성 | [`06-correctness.md`](pragmatic-rust-guidelines/parts/06-correctness.md) | `unsafe`, soundness, panic |
| 성능 | [`07-performance.md`](pragmatic-rust-guidelines/parts/07-performance.md) | 처리량, 메모리·할당, 해싱, 비동기 스택 |
| 프로젝트 | [`08-project.md`](pragmatic-rust-guidelines/parts/08-project.md) | Cargo workspace, 크레이트 구조, MSRV |
| 문서 | [`09-docs.md`](pragmatic-rust-guidelines/parts/09-docs.md) | 첫 문장, 모듈 문서, 정본 링크, 인라인 문서 |
| AI 지원 | [`10-ai.md`](pragmatic-rust-guidelines/parts/10-ai.md) | 항목별 탐색, 테스트, Rust다운 설계 |

## 원본과 생성 스킬의 차이

생성 스킬은 원본 13개 분야별 규칙의 본문·근거·코드 예시를 온전히 유지합니다. 다음 자료는 **사람이 전체 항목을 훑거나 시각적으로 확인할 때** 유용하지만, 에이전트가 규칙을 선별해 적용하는 데에는 필요하지 않아 제외합니다.

- 원본 개요 `src/guidelines/README.md`: 가이드북 소개, 버전, 새 지침 기고 절차 및 채택 심사 기준 등 사람을 위한 메타 정보 위주로 구성되어 있습니다. 에이전트에게 필요한 핵심 적용 원칙(`must/should`의 유연성, `Spirit Over Letter`)은 진입점인 `SKILL.md`에 직접 포함되어 있어 별도 파트로 생성하지 않습니다.
- 원본 체크리스트 `src/guidelines/checklist/README.md`: 제목·체크박스 위주의 전체 점검표. 에이전트는 `SKILL.md`의 라우팅 테이블과 파트별 목차·본문으로 필요한 규칙을 찾습니다.
- 원본 이미지 5개: `src/guidelines/docs/`의 rustdoc 화면 캡처 4개와 `src/guidelines/libs/interop/M-TYPES-SEND.png`의 성능 그래프. 스킬에는 이미지와 대체 요약이 없으므로 화면 배치와 그래프의 시각적 비교는 원본 문서에서 확인해야 합니다. `#[doc(inline)]` 사용 조건, 첫 문장 길이, `Send` 호환성과 성능상 주의점은 규칙 본문과 코드 예시에 남습니다.

원본 `src/`의 문서와 이미지는 변경하지 않습니다. 빌드 스크립트에 포함된 이미지 정제 단계가 현재 원본에서 사용하는 PNG 이미지 태그와 단독 `<div>` 래퍼를 생성 문서에서 생략합니다.

### 에이전트 탐색을 위한 커스텀 앵커 삽입

에이전트가 특정 규칙을 검색할 때 파트 상단의 목차(TOC)와 본문 헤딩이 중복 매칭되는 문제를 방지하고, 목표 지침으로 즉시 직행할 수 있도록 빌드 과정에서 각 규칙의 고유 ID(`Key Guidelines`)가 포함된 헤더 바로 위에 커스텀 앵커(`<a id="M-..."></a>`)를 삽입합니다. 이를 통해 에이전트는 큰 파트 파일 전체를 context로 읽지 않고도 `SKILL.md`의 작업별 색인(Quick Index)에 포함된 직접 링크(`parts/<file>.md#M-...`)나 라우팅 표를 통해 목표 규칙의 앵커 위치로 즉시 직행하여 본문과 근거만 선별 조회할 수 있습니다.

## 갱신 및 빌드

upstream 가이드라인 변경을 `main`에 반영하고 `custom`에 적용한 뒤, 스킬에 영향을 주는 변경이 있으면 저장소 루트에서 재생성합니다. `src/`는 이 작업 브랜치에서 직접 수정하지 않습니다.

```bash
bash skills/_build/build_agent_skills.sh
```

빌드 스크립트는 다음 7단계를 순서대로 실행합니다.
1. **원본 구조와 규칙 ID 확인**: 13개 분야 디렉터리와 `README.md`의 include 선언을 확인하고, 빠진 파일·중복 include·중복 규칙 ID 등 입력 오류를 생성 전에 검사합니다.
2. **기존 파트 초기화**: 출력 디렉터리를 준비하고 이전 빌드에서 생성한 `parts/*.md`를 지웁니다.
3. **분야별 파트 생성**: 원본 공개 순서와 분야별 include 순서로 13개 파트를 만듭니다. 각 파트에는 분야 소개, 규칙 목차와 근거, 정제한 본문을 담고, 이미지 태그와 단독 `<div>` 래퍼를 생략하며 내부 링크를 생성 파트로 바꿉니다. 대상 규칙 ID가 없는 원본 링크는 경고 후 앵커 없이 해당 파트로 연결합니다. 동시에 `SKILL.md`의 라우팅 표에 쓸 분야·규칙 메타데이터를 모읍니다.
4. **파트와 앵커 확인**: 생성한 규칙 수가 원본 색인과 일치하는지, 모든 규칙 앵커가 해당 파트에 있는지 검사합니다.
5. **`SKILL.md` 생성**: `_build/SKILL.md.template`을 바탕으로 작업별 빠른 색인과 적용 지침, 에이전트 활용 가이드를 유지한 채 분야별 라우팅 표 항목을 동적으로 채워 `SKILL.md`를 작성합니다.
6. **생성 링크 및 규칙 ID 검증**: 생성된 Markdown의 로컬 파일 링크와 규칙 앵커가 실제 대상에 연결되는지 전수 확인하고, `SKILL.md`에 언급된 모든 규칙 ID가 실제 유효한지 검증합니다.
7. **빌드 결과 출력**: 생성한 파트 수와 정제한 규칙 수, 출력 디렉터리 및 `SKILL.md` 경로를 표시합니다.

이 작업은 `scripts/agents_summary.sh`가 생성하는 `src/agents/all.txt`·`src/agents/all.meta`와 별개입니다. `main`은 upstream 반영 전용이며 스킬 생성 도구와 생성물은 `custom`에서만 관리합니다. custom 전용 변경은 `main`에 병합하지 않습니다.
