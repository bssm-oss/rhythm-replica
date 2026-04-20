# Release Guide

## 로컬 릴리즈 빌드

전체 Xcode 앱이 설치된 환경을 우선 기준으로 합니다. 다만 Command Line Tools만 있는 환경에서는 `scripts/build-release.sh`가 SwiftPM release binary와 resource bundle을 사용해 fallback `.app` 번들을 만듭니다.

또한 현재 이 로컬 Command Line Tools 환경은 SwiftPM test target에 필요한 Apple test framework를 제공하지 않아 `swift test`는 표준 검증 경로로 보지 않습니다. 번들 테스트는 full Xcode 환경의 `xcodebuild ... test` 또는 GitHub Actions CI 결과를 기준으로 확인합니다.

```bash
xcodegen generate
./scripts/build-release.sh
./scripts/package-dmg.sh
./scripts/sha256.sh build/RhythmReplica.dmg
```

## GitHub Secrets

- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APP_SPECIFIC_PASSWORD`
- `DEVELOPER_ID_APPLICATION`
- `CERTIFICATE_P12`
- `CERTIFICATE_PASSWORD`

Secrets가 없으면 unsigned local build만 수행합니다.

## 서명 / 공증 동작

- GitHub Actions `tag-release.yml`은 시크릿이 모두 있는 경우에만 Developer ID 인증서 import, codesign, notarization, stapling 단계를 실행합니다.
- 시크릿이 없으면 unsigned `.app` / `.dmg`를 계속 생성합니다.

## Homebrew Cask 갱신

릴리즈가 생성되고 SHA256이 계산된 뒤 아래 스크립트로 Cask를 갱신합니다.

```bash
./scripts/update-cask.sh 0.1.4 <sha256>
```

최신 릴리즈 기준 현재 Cask SHA는 이미 반영되어 있습니다. 이후 버전 릴리즈 시 같은 스크립트를 반복 사용하면 됩니다.
