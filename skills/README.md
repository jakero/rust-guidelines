# Pragmatic Rust Guidelines 에이전트 스킬

Microsoft [Pragmatic Rust Guidelines](https://microsoft.github.io/rust-guidelines/)를 AI 에이전트가 분야와 규칙별로 찾아볼 수 있도록 재구성한 스킬입니다. 원본 저장소는 [microsoft/rust-guidelines](https://github.com/microsoft/rust-guidelines)입니다.

이 문서는 스킬을 설치·관리하는 사람을 위한 안내입니다. 에이전트가 Rust 코드를 작성하거나 검토할 때 참고할 진입점은 [`SKILL.md`](pragmatic-rust-guidelines/SKILL.md)입니다.

## 다른 프로젝트에서 사용

1. 대상 프로젝트에서 에이전트의 스킬 검색 디렉터리를 확인합니다.
2. 이 저장소의 루트에서 스킬 폴더 전체를 복사합니다. 상대 경로 링크가 유지되려면 `SKILL.md`와 `parts/`가 함께 있어야 합니다.

   ```bash
   # TARGET_SKILLS_DIR: 대상 프로젝트의 스킬 검색 디렉터리
   cp -R skills/pragmatic-rust-guidelines "$TARGET_SKILLS_DIR/"
   ```

3. 대상 에이전트 도구에 스킬 검색 경로를 설정하고 `pragmatic-rust-guidelines`를 참고해 Rust 코드를 작성하거나 검토해 달라고 요청합니다. 검색 경로 설정과 호출 방법은 도구마다 다릅니다.

## 포함된 파일

- [`SKILL.md`](pragmatic-rust-guidelines/SKILL.md): 적용 지침, 작업별 빠른 색인, 분야별 색인, 반영된 원본 저장소(upstream)의 리비전 정보. 에이전트의 시작점입니다. 상단에 원본 스타일의 저작권 및 라이선스 출처 식별 주석이 포함되어 있습니다.
- [`parts/`](pragmatic-rust-guidelines/parts/): 분야별 목차와 각 규칙의 근거·본문. 아래 표에서 직접 열 수 있습니다.
- [`LICENSE.md`](pragmatic-rust-guidelines/LICENSE.md): 원본 Microsoft Pragmatic Rust Guidelines의 MIT 라이선스 저작권 고지(Copyright notice) 및 허가문 전문(Permission notice). MIT 라이선스 요건을 온전히 충족하려면 단순 주석만이 아닌 본 전문 파일이 함께 배포되어야 합니다.
- [`_build/`](_build/): 생성 스크립트와 진입점 템플릿. 다른 프로젝트에서 스킬을 **사용**할 때는 복사할 필요가 없습니다.

### 분야별 지침

| 분야 | 다루는 내용 |
| :--- | :--- |
| [공통](pragmatic-rust-guidelines/parts/01-universal.md) | Rust 전반의 관행, 정적 검증, 명명, 로깅 |
| [라이브러리 · 상호운용](pragmatic-rust-guidelines/parts/02-1-libs-interop.md) | Rust·외부 타입과 trait, I/O |
| [라이브러리 · API UX](pragmatic-rust-guidelines/parts/02-2-libs-ux.md) | 추상화, 오류, 생성 패턴, 메서드 설계 |
| [라이브러리 · 견고성](pragmatic-rust-guidelines/parts/02-3-libs-resilience.md) | 테스트 가능성, 강한 타입, 전역 상태, 로깅 |
| [라이브러리 · 빌드](pragmatic-rust-guidelines/parts/02-4-libs-building.md) | 시작 경험, 시스템 의존 크레이트, Cargo 기능 |
| [매크로](pragmatic-rust-guidelines/parts/03-macros.md) | 선언형·프로시저 매크로 설계 |
| [애플리케이션](pragmatic-rust-guidelines/parts/04-apps.md) | 바이너리 오류 처리, 할당자, 대상 CPU |
| [FFI](pragmatic-rust-guidelines/parts/05-ffi.md) | 상태 격리, 값 변환, 이름 지정 |
| [정확성](pragmatic-rust-guidelines/parts/06-correctness.md) | `unsafe`, soundness, panic |
| [성능](pragmatic-rust-guidelines/parts/07-performance.md) | 처리량, 메모리·할당, 해싱, 비동기 스택 |
| [프로젝트](pragmatic-rust-guidelines/parts/08-project.md) | Cargo workspace, 크레이트 구조, MSRV |
| [문서](pragmatic-rust-guidelines/parts/09-docs.md) | 첫 문장, 모듈 문서, 정본 링크, 인라인 문서 |
| [AI 지원](pragmatic-rust-guidelines/parts/10-ai.md) | 항목별 탐색, 테스트, Rust다운 설계 |

## 원본과 생성 스킬의 차이

원본 저장소는 에이전트용으로 지침을 모은 단일 파일 `src/agents/all.txt`를 제공합니다. 이 프로젝트는 같은 원본 가이드라인을 `SKILL.md` 진입점과 분야별 `parts/`로 나누어, 에이전트가 현재 작업에 필요한 지침을 선택적으로 찾아 읽도록 구성합니다.

`SKILL.md`의 작업별·분야별 색인에서 관련 규칙으로 이동하고, 해당 규칙의 근거·예외·코드 예시를 확인하는 흐름입니다. 단순히 문서를 분할하는 데 그치지 않고, 규칙별 앵커와 내부 링크, 적용 지침을 함께 제공해 탐색과 적용을 돕습니다.

분야별 규칙의 텍스트 본문·근거·코드 예시는 포함하되, 링크와 표시 형식은 스킬에 맞게 정리합니다.

| 구분 | 처리 방식 |
| :--- | :--- |
| 개요·체크리스트 | `src/guidelines/README.md`의 가이드북 소개·기고 절차와 `src/guidelines/checklist/README.md`의 전체 점검표는 포함하지 않습니다. 핵심 적용 원칙(`must/should`의 유연성, `Spirit Over Letter`)은 `SKILL.md`에 담습니다. |
| 이미지 | `src/guidelines/docs/`의 rustdoc 화면 캡처 4개와 `src/guidelines/libs/interop/M-TYPES-SEND.png`의 성능 그래프를 포함하지 않습니다. |
| 표시 형식 | PNG 이미지 태그와 단독 `<div>` 래퍼를 생략하고, 원본의 보충 설명·주의 표식(`<tip></tip>`, `<alert></alert>`)을 `Tip: `·`Caution: `으로 바꿉니다. |
| 규칙 참조 | 과거 ID `M-ABSTRACTIONS-DONT-NEST`와 `M-DOC-FIRST-SENTENCE`는 현재 규칙의 앵커로 연결합니다. 원본에 대응 규칙이 없는 `M-RUNTIME-ABSTRACTED`는 링크 없이 보존하고, 관련 규칙에 `Unavailable source reference` 안내를 넣습니다. |

**이미지의 시각 정보는 스킬에 없습니다.** 화면 배치나 성능 그래프의 비교가 필요하면 원본 문서를 확인하세요. `#[doc(inline)]` 사용 조건, 첫 문장 길이, `Send` 호환성과 성능상 주의점은 텍스트 본문에 남아 있습니다. 미해결 규칙 참조의 내용은 추측하거나 다른 규칙으로 대체하지 않습니다.

각 규칙에는 고유 ID 기반 앵커(`<a id="M-..."></a>`)가 있습니다. `SKILL.md`의 색인은 이 앵커를 가리키며, 앵커 이동을 지원하지 않는 도구에서는 해당 ID를 검색해 규칙을 찾을 수 있습니다.

## 갱신 및 재생성

원본 저장소의 변경을 `main`에 반영하고 `custom`에 적용한 뒤, 스킬에 영향을 주는 변경이 있으면 저장소 루트에서 재생성합니다. `main`은 원본 동기화 전용이고 스킬 생성 도구와 생성물은 `custom`에서만 관리합니다. `custom` 전용 변경은 `main`에 병합하지 않으며, 이 작업 브랜치에서 `src/`를 수정하지 않습니다.

```bash
bash skills/_build/build_agent_skills.sh
```

빌드 결과는 `skills/pragmatic-rust-guidelines/`의 `SKILL.md`와 13개 분야별 파트입니다. `SKILL.md`의 **Source Revision**에서 반영된 원본 커밋 SHA와 커밋 날짜를 확인할 수 있습니다. 이 빌드는 `scripts/agents_summary.sh`가 생성하는 `src/agents/all.txt`·`src/agents/all.meta`와 별개입니다.

### 스킬이 생성되는 과정

`skills/_build/build_agent_skills.sh`를 실행하면 스크립트는 다음 10단계를 거쳐 스킬을 안전하게 만듭니다.

1. **반영된 원본 리비전 확인**: 로컬 `upstream/main`과 현재 `HEAD`의 공통 조상 커밋을 찾고, 그 시점의 `src/guidelines` 트리가 `HEAD`의 원본 디렉터리와 일치하는지 확인합니다. 이 단계에서 출처 표시에 쓸 upstream 커밋 SHA와 커밋 날짜(ISO-8601)를 확보합니다. (외부 저장소에서 최신 커밋을 자동으로 fetch하지는 않으므로 필요 시 사전에 `git fetch upstream`을 수행해야 합니다.)
2. **원본 규칙 목록 구성**: 13개 분야 디렉터리와 각 분야 `README.md`의 include 구문을 분석합니다. 누락된 파일, 중복 include, 누락되거나 중복된 규칙 ID를 검사하고, 각 규칙 ID가 어떤 파트로 들어갈지 매핑하는 목록을 메모리에 구축합니다.
3. **템플릿 조기 검증**: 기존 출력 디렉터리를 변경하기 전에 `SKILL.md.template` 파일의 존재 및 CRLF 줄바꿈을 감안한 필수 치환 표식(`ROUTING_TABLE_ENTRIES`, `UPSTREAM_SOURCE_REVISION`)의 포함 여부를 미리 확인합니다.
4. **임시 스테이징 디렉터리 준비**: 기존 스킬 파일을 즉시 삭제하지 않고 격리된 임시 작업 디렉터리를 생성하여 파트 파일들과 라이선스(`LICENSE.md`)를 먼저 안전하게 생성할 수 있도록 준비합니다.
5. **분야별 파트 작성**: 공식 공개 순서대로 13개 파트 파일을 스테이징 공간에 작성합니다. 각 파일에는 분야 소개, 목차(TOC)와 규칙별 Rationale 요약, 그리고 정제된 규칙 본문이 들어갑니다. 코드 블록(fence)을 정밀 추적(기호 및 길이 일치)하여 내부 내용은 온전히 보존하며, 코드 외부의 고유 앵커 삽입, `<why>`의 `Rationale` 변환, 버전 태그 및 이미지 생략, `Tip: `·`Caution: ` 라벨 정규화, 파트 간 링크 재작성을 적용합니다.
6. **파트와 규칙 앵커 확인**: 실제 생성된 총 규칙 수가 2단계에서 파악한 원본 규칙 수와 정확히 일치하는지, 각 파트 파일에 해당 규칙의 고유 앵커(`<a id="M-..."></a>`)가 빠짐없이 들어갔는지 스테이징 공간에서 검사합니다.
7. **`SKILL.md` 작성**: `_build/SKILL.md.template`을 읽어 분야별 색인 표와 출처 리비전 정보를 실제 생성 데이터로 치환한 `SKILL.md`를 스테이징 공간에 작성합니다.
8. **생성 문서의 연결 전수 검사**: 스테이징 공간에 생성된 모든 Markdown 파일 내의 상대 링크와 규칙 앵커 대상이 실제로 존재하는지 전수 검사합니다. 아울러 `SKILL.md`에 언급된 모든 규칙 ID가 2단계의 원본 규칙 목록에 존재하는 유효한 ID인지 검증합니다.
9. **백업 및 복원 트랜잭션을 통한 최종 반영**: 모든 검증을 통과한 경우, 기존 배포 디렉터리를 임시 백업으로 이동한 뒤 검증된 스테이징 디렉터리를 배포 위치로 승격합니다(`mv`). 승격 도중 예기치 않은 오류가 발생하더라도 `EXIT`/`INT`/`TERM` 트랩이 백업을 원래 위치로 자동 복원하므로 배포 디렉터리가 비어 있거나 불완전한 상태로 방치되지 않고 기존 정상 산출물이 100% 보존됩니다. (동일 파일시스템 내 디렉터리 rename 전환 시점의 극히 짧은 가시성 공백 외에는 안전한 트랜잭션을 유지합니다.)
10. **완료 결과 출력**: 생성된 파트 수(13개), 정제된 규칙 수(89개), 스킬 디렉터리 및 진입점 파일 경로를 콘솔에 출력하고 종료합니다.
