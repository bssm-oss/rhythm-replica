# DMG Packaging

`scripts/package-dmg.sh`는 Release 빌드에서 생성한 `.app`을 `build/RhythmReplica.dmg`로 묶습니다.

## 목적

- GitHub Release 업로드용 아카이브 생성
- Homebrew Cask에서 사용할 고정 URL + SHA256 기반 배포

## 검증

1. DMG 마운트
2. Applications로 드래그 가능 여부 확인
3. 앱 실행 여부 확인
