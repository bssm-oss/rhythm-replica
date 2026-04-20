# Rhythm Replica

Rhythm Replica는 macOS 데스크톱에서 오디오 파일과 JSON 채보를 불러와 플레이하고, 같은 앱 안에서 채보를 편집할 수 있도록 설계한 AppKit 기반 리듬게임입니다. 웹 리듬게임의 빠른 반복 플레이와 키보드 중심 에디팅 흐름을 macOS다운 창, 메뉴, 단축키, 사이드바 경험으로 재해석하는 것이 목표입니다.

## 무엇을 해결하나요?

- 로컬 음악 파일과 채보 JSON을 바로 연결해서 테스트 플레이할 수 있습니다.
- BPM, 오프셋, 스냅, 노트 배치 중심의 채보 편집을 macOS 네이티브 UI로 제공합니다.
- 플레이어와 에디터가 같은 데이터 모델을 공유해서 수정 후 즉시 테스트하기 쉽습니다.
- 릴리즈 산출물을 `.app`, `.dmg`, Homebrew Cask 흐름까지 고려해 배포할 수 있습니다.

## 현재 구현 범위

- AppKit 기반 기본 앱 구조
- 시작 / 플레이어 / 에디터 / 설정 화면 골격
- 시작 / 플레이어 / 에디터 / 설정 / 결과 창 기본 흐름
- 내부 표준 채보 포맷과 LUMINA 스타일 시간 기반 JSON 가져오기 어댑터
- 채보 검증, 판정 계산, 점수 계산, 비트/시간 변환 테스트
- 오디오 재생 서비스와 오디오 시간 기준 게임 엔진 기초
- 에디터 타임라인, 파형 뷰, 자동 저장, 테스트 플레이 핸드오프
- YouTube 메타데이터 조회 + 외부 도구 기반 가져오기 UI, 진행률/취소 훅
- 설정 화면에서 키 바인딩 변경과 캐시 관리
- GitHub Actions / DMG / Homebrew Cask 예시 파일

## 스크린샷

- `docs/screenshots/start.png` 예정
- `docs/screenshots/player.png` 예정
- `docs/screenshots/editor.png` 예정

## 기술 스택

- Swift
- AppKit
- AVFoundation
- XcodeGen으로 생성한 Xcode 프로젝트
- Swift Package Manager 기반 로컬 검증 경로
- XCTest

## 요구 환경

- macOS 13 이상 권장
- Xcode 15 이상
- XcodeGen 2.45+
- 선택 기능: `yt-dlp`, `ffmpeg`, Homebrew

## 가장 쉽게 설치하는 방법

정식 릴리즈가 올라온 뒤에는 아래 둘 중 하나로 설치할 수 있습니다.

### 1) GitHub Releases에서 DMG 다운로드

1. Releases 페이지에서 최신 `RhythmReplica.dmg`를 다운로드합니다.
2. DMG를 열고 `Rhythm Replica.app`을 Applications 폴더로 드래그합니다.
3. 처음 실행 시 macOS 보안 경고가 보이면 시스템 설정에서 허용합니다.

### 2) Homebrew Cask

```bash
brew tap bssm-oss/tap
brew install --cask rhythm-replica
```

> 현재 저장소에는 Cask 예시 파일만 포함되어 있습니다. 실제 설치 가능 상태는 GitHub Release와 SHA256이 준비된 뒤입니다.

## 로컬 개발 시작

```bash
xcodegen generate
open RhythmReplica.xcodeproj
```

또는 CLI 빌드:

```bash
xcodegen generate
xcodebuild -project RhythmReplica.xcodeproj -scheme RhythmReplica -destination 'platform=macOS' build
```

이 환경처럼 전체 Xcode 앱이 없고 Command Line Tools만 있는 경우에는 아래 경로로 로컬 검증이 가능합니다.

```bash
swift build
swift run RhythmReplicaSelfCheck
swift run RhythmReplica
```

## 테스트 실행

```bash
xcodegen generate
xcodebuild -project RhythmReplica.xcodeproj -scheme RhythmReplica -destination 'platform=macOS' test
```

또는 SwiftPM 기반 핵심 로직 검증:

```bash
swift run RhythmReplicaSelfCheck
```

## 폴더 구조

```text
RhythmReplica/
├─ App/
├─ Audio/
├─ Core/
├─ DesignSystem/
├─ Editor/
├─ Export/
├─ Game/
├─ Import/
├─ Resources/
├─ Settings/
└─ Utils/
```

## 아키텍처 개요

- `App`: 앱 진입점, 윈도우 구성, 환경 객체
- `Core`: 채보 모델, 로더/익스포터, 검증기, 저장소
- `Audio`: 실제 재생 시간 기준 재생 서비스와 파형 추출
- `Game`: 판정, 점수, 입력, 플레이 상태 계산
- `Editor`: 타임라인, 노트 렌더링, 편집 명령, 자동 저장
- `Import`: 로컬 파일 / YouTube 외부 도구 감지 및 가져오기
- `Settings`: 키 바인딩, 테마, 입력 지연, 캐시 관리

## YouTube 가져오기 주의사항

이 기능은 편의 기능이며, 사용자가 권리를 가진 영상이나 사용이 허용된 콘텐츠만 대상으로 해야 합니다.

- 본인이 업로드한 영상
- Creative Commons 등 사용 허가가 명확한 영상
- 권리자로부터 별도 허락을 받은 영상

Rhythm Replica는 DRM 우회, 로그인 우회, 유료 콘텐츠 우회, 지역 제한 우회를 구현하지 않습니다. 앱 내부에 추출 로직을 내장하지 않고, 사용자가 따로 설치한 `yt-dlp`와 `ffmpeg`를 감지해서 선택적으로 사용하도록 설계합니다. 시작 화면에서 YouTube Import 창을 열면 권리 안내, 도구 감지 상태, 메타데이터 조회, 가져오기 시작/취소 UI를 확인할 수 있습니다.

## 채보 포맷 문서

- 내부 포맷: [`docs/chart-format.md`](docs/chart-format.md)
- 디자인 시스템: [`docs/design-system.md`](docs/design-system.md)

## 주요 스크립트

- `scripts/build-release.sh`: Release 빌드
- `scripts/package-dmg.sh`: DMG 생성
- `scripts/sha256.sh`: SHA256 계산

## CI 개요

- `ci.yml`: 빌드 + 테스트
- `release.yml`: 태그 푸시 시 앱 빌드, DMG 패키징, 체크섬, GitHub Release 업로드

## 알려진 제한 사항

- 첫 단계에서는 내부 표준 포맷을 우선 지원합니다.
- LUMINA 호환은 제공된 시간 기반 스펙을 기준으로 어댑터를 구현합니다.
- 코드서명/공증은 GitHub Secrets가 있을 때만 자동화됩니다.
- YouTube 기능은 `yt-dlp`가 없는 환경에서는 메타데이터/가져오기 대신 설치 안내 수준으로 제한됩니다.
- 현재 자동 검증은 SwiftPM self-check와 런치 스모크를 기준으로 수행했습니다. Xcode 테스트 번들은 전체 Xcode 앱이 있는 환경에서 추가 확인이 필요합니다.
- LUMINA 시간 기반 가져오기는 현재 절대 시간을 보존하기 위해 `bpm = 60` 어댑터를 사용합니다. 이 부분은 후속 버전에서 더 정교한 변환기로 확장될 수 있습니다.

## 로드맵

- [x] 기본 앱/문서/프로젝트 구조
- [x] 채보 모델, 검증기, 테스트
- [ ] 실제 플레이어 완성도 향상
- [ ] 에디터 다중 선택 / 드래그 편집 고도화
- [ ] LUMINA 변환 어댑터 확장
- [ ] 오디오 장치 선택 UI 고도화
- [ ] 릴리즈 서명 / 공증 실환경 검증

## 라이선스

현재 저장소에는 MIT 라이선스 초안을 포함했습니다. 조직 정책 확정 전까지는 최종 라이선스 결정이 필요합니다.
