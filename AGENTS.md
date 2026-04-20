# AGENTS.md

## 프로젝트 목적

Rhythm Replica는 macOS용 네이티브 리듬게임 + 채보 편집기입니다. 오디오 재생 시간 기준의 정확한 플레이 경험과 키보드 중심의 에디팅 경험을 동시에 유지하는 것이 핵심입니다.

## 빠른 시작

```bash
xcodegen generate
open RhythmReplica.xcodeproj
```

CLI 빌드:

```bash
xcodebuild -project RhythmReplica.xcodeproj -scheme RhythmReplica -destination 'platform=macOS' build
```

테스트:

```bash
xcodebuild -project RhythmReplica.xcodeproj -scheme RhythmReplica -destination 'platform=macOS' test
```

## 기본 작업 순서

1. `README.md`, `AGENTS.md`, `docs/`부터 읽기
2. `project.yml` 기준으로 Xcode 프로젝트 재생성
3. 수정 범위와 영향 모듈 파악
4. 로직 변경 시 테스트 먼저 추가 또는 수정
5. UI 변경 시 수동 검증 시나리오 기록
6. 문서 갱신
7. 빌드/테스트/수동 검증 후 마무리

## 완료 조건

- 수정 요청이 실제 코드에 반영됨
- 관련 테스트가 추가/수정되고 실행됨
- `xcodebuild build` 또는 `test`가 요구 범위에서 통과함
- README/AGENTS/docs가 실제 동작과 일치함
- 사용자 관점 검증 결과가 남아 있음

## 코드 스타일 원칙

- AppKit 컨트롤러는 화면 조합과 사용자 이벤트만 담당
- 순수 계산 로직은 `Core` / `Game` 안에 두고 테스트 가능하게 유지
- 실제 판정/점수는 오디오 시간 기준으로 계산
- 타입 안정성을 깨는 우회(`as!`, 억지 캐스팅, 타입 무시) 금지
- 사용자 오류 메시지는 이해 가능한 문장으로 작성

## 파일 구조 원칙

- `RhythmReplica/App`: 앱 진입, 윈도우, 내비게이션
- `RhythmReplica/Core`: 모델, 포맷, 검증, 저장소
- `RhythmReplica/Audio`: 재생, 파형, 시간 동기
- `RhythmReplica/Game`: 판정, 점수, 입력, 플레이 상태
- `RhythmReplica/Editor`: 타임라인, 렌더링, 편집 명령
- `RhythmReplica/Import`: 파일/YouTube 가져오기
- `RhythmReplica/Settings`: 환경설정, 키 바인딩

## 문서화 원칙

- 채보 포맷 변경 시 `docs/chart-format.md` 필수 갱신
- UI/디자인 토큰 변경 시 `docs/design-system.md` 갱신
- 릴리즈 절차 변경 시 `docs/release.md` 또는 `docs/packaging-dmg.md` 갱신

## 테스트 원칙

- 순수 계산 로직은 XCTest로 보호
- 회귀 버그는 재현 테스트 추가
- AppKit 상호작용은 자동화가 어려우면 수동 검증 절차를 문서화

## 브랜치 / 커밋 / PR 규칙

- 기본 브랜치에서 직접 작업하지 않음
- 권장 브랜치: `feat/...`, `fix/...`, `docs/...`, `ci/...`
- 구현, 테스트, 문서는 가능하면 분리 커밋
- PR에는 배경, 변경점, 테스트, 수동 검증, 리스크를 적음

## 민감한 경로 / 주의 경로

- `RhythmReplica/Audio/`: 타이밍 정확도에 직접 영향
- `RhythmReplica/Game/`: 판정, 점수, HP 규칙
- `docs/chart-format.md`: 외부 호환 계약 문서
- `.github/workflows/`: 배포 파이프라인

## 작업 전 체크리스트

- 프로젝트 생성 또는 갱신이 필요한가?
- 변경이 채보 포맷에 영향 주는가?
- 테스트 fixture 수정이 필요한가?
- 사용자 설정/자동 저장에 영향이 있는가?

## 작업 후 체크리스트

- 빌드/테스트 실행
- 수동 검증 결과 기록
- 문서 갱신 확인
- 불완전 기능은 UI에 Disabled/TODO 상태로 명시했는가?

## 절대 하면 안 되는 것

- 실행하지 않은 테스트를 통과했다고 보고하지 않기
- 오디오 시간 대신 프레임 타이머만 믿고 판정하지 않기
- 외부 다운로드 도구를 앱 내부 숨은 로직처럼 동작시키지 않기
- 권한/약관 우회 기능 추가하지 않기
- 문서와 실제 동작을 불일치 상태로 두지 않기
