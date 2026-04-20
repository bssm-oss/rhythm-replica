# Rhythm Replica Chart Format

Rhythm Replica는 내부 표준 포맷을 우선 사용합니다. 이 포맷은 편집기와 플레이어가 같은 데이터를 공유하도록 설계되어 있으며, LUMINA 스타일 시간 기반 JSON을 가져오기 위한 어댑터를 별도로 둡니다.

## 내부 표준 포맷

```json
{
  "schemaVersion": 1,
  "title": "Sample Track",
  "artist": "Rhythm Replica",
  "audioFileName": "sample-track.m4a",
  "bpm": 120,
  "totalBeats": 64,
  "offset": 0.0,
  "difficulty": "Normal",
  "notes": [
    {
      "id": "0E83F091-6BEA-4F57-9C4A-39CA2C3A520A",
      "beat": 4.0,
      "lane": 0,
      "type": "normal",
      "durationBeats": 0.0
    }
  ]
}
```

## 필드 정의

### Chart

- `schemaVersion`: 현재 스키마 버전. 현재 값은 `1`
- `title`: 곡 제목
- `artist`: 아티스트 이름
- `audioFileName`: 연결된 오디오 파일명
- `bpm`: 기본 BPM
- `totalBeats`: 총 비트 수
- `offset`: 초 단위 오프셋
- `difficulty`: 난이도 문자열
- `notes`: 노트 배열

### Note

- `id`: UUID 문자열
- `beat`: 노트 시작 비트
- `lane`: 0~3
- `type`: `normal` | `long` | `specialLeft` | `specialRight`
- `durationBeats`: 롱 노트 길이. 일반/특수 노트는 `0`

## 검증 규칙

- lane은 `0...3`
- beat는 음수가 될 수 없음
- beat는 `totalBeats`를 초과할 수 없음
- long note는 `durationBeats > 0`
- long note 끝 beat가 `totalBeats`를 넘을 수 없음
- 같은 lane에서 long note가 겹치면 오류

## 시간 변환

- 1 beat 길이 = `60 / bpm` 초
- 실제 재생 시간 = `offset + beat * (60 / bpm)`
- long note 종료 시간 = `offset + (beat + durationBeats) * (60 / bpm)`

## LUMINA 스타일 JSON 가져오기

Rhythm Replica는 아래 형태의 시간 기반 스펙을 감지하면 내부 포맷으로 변환합니다.

```json
[
  { "type": "normal", "lane": 0, "time": 1.5 },
  { "type": "long", "lane": 1, "time": 2.0, "endTime": 3.0 },
  { "type": "special", "dir": "left", "time": 4.0 }
]
```

변환 규칙:

- 현재 부트스트랩 구현에서는 원본 절대 시간을 보존하기 위해 `bpm = 60`, `offset = 0`으로 두고 `time`/`endTime` 값을 그대로 beat처럼 저장
- 즉, 이 가져오기 경로에서 `1 beat == 1 second`가 되며, 이후 에디터에서 BPM을 바꾸면 시간 의미도 함께 바뀔 수 있음
- `special + dir=left` → `specialLeft`
- `special + dir=right` → `specialRight`
- special 노트의 lane은 입력 힌트를 위해 `left=0`, `right=3`으로 저장

## 호환성 정책

- 내부 포맷이 우선이며, 외부 형식은 어댑터로 추가
- 외부 형식이 불완전하면 손실 없는 절대시간 보존을 우선하고, 내보내기는 내부 포맷 기준으로 동작
