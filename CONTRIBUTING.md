# Contributing

## 개발 환경 준비

1. Xcode 15 이상 설치
2. XcodeGen 설치
3. 저장소 루트에서 `xcodegen generate`
4. `RhythmReplica.xcodeproj` 열기

## 권장 작업 흐름

1. 이슈 또는 작업 목적을 명확히 정리합니다.
2. 기능 단위 브랜치를 만듭니다.
3. 로직 변경은 테스트부터 보강합니다.
4. UI 변경은 수동 검증 시나리오를 함께 남깁니다.
5. 문서와 코드가 같은 사실을 말하는지 확인합니다.

## 커밋 메시지 예시

- `feat(game): add audio-time based judgement flow`
- `test(core): cover chart validator overlap cases`
- `docs(readme): explain local install and release flow`

## Pull Request 체크리스트

- [ ] 빌드 또는 테스트를 실제로 실행했다
- [ ] 변경 이유를 설명했다
- [ ] 문서 반영 여부를 적었다
- [ ] 수동 검증 결과를 적었다
- [ ] 남은 리스크를 숨기지 않았다
