# Release Guide

## 로컬 릴리즈 빌드

전체 Xcode 앱이 설치된 환경을 기준으로 합니다. Command Line Tools만 있는 환경에서는 `/usr/bin/xcodebuild`가 동작하지 않으므로 `swift build`와 `swift run RhythmReplicaSelfCheck`로 핵심 로직만 먼저 검증할 수 있습니다.

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
