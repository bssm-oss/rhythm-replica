# Rhythm Replica Design System

Rhythm Replica는 macOS 네이티브 생산성 앱의 명확한 구조와 리듬게임의 집중감 있는 분위기를 동시에 유지합니다. 기본 방향은 `opencode.ai` 디자인 레퍼런스의 warm-dark, monospace-first 성격을 가져오되, Apple HIG에 맞게 AppKit 컨트롤과 키보드 접근성을 우선합니다.

## 분위기

- 기본 테마: 다크
- 성격: 따뜻한 거의 검정에 가까운 배경, 선명한 오프화이트 텍스트, 얇은 윤곽선
- 키보드 조작 중심이므로 포커스와 선택 상태를 강하게 드러냄

## 색상 토큰

- `background/base`: `#201D1D`
- `background/elevated`: `#302C2C`
- `text/primary`: `#FDFCFC`
- `text/secondary`: `#9A9898`
- `border/subtle`: `rgba(15, 0, 0, 0.12)`
- `accent/blue`: `#007AFF`
- `accent/green`: `#30D158`
- `accent/orange`: `#FF9F0A`
- `accent/red`: `#FF3B30`

## 타이포그래피

- 기본 폰트: `Berkeley Mono`, fallback으로 시스템 monospace 체인 사용
- 화면 제목: 28~38pt bold
- 섹션 제목: 16pt semibold
- 본문/라벨: 13~15pt regular/medium
- 숫자/타이밍 정보는 탭 정렬이 쉬운 monospace 유지

## 간격 체계

- 기본 단위: 8pt
- 세밀 단위: 4pt
- 섹션 간 기본 간격: 16pt 또는 24pt

## 모서리 / 윤곽 / 깊이

- 기본 corner radius: 4pt
- 입력 필드: 6pt
- 그림자는 거의 사용하지 않고, 배경 단계 차이 + 윤곽선으로 깊이 표현

## 컴포넌트 규칙

### 버튼
- Primary: dark fill + light text
- Secondary: outline + muted background
- 위험 동작: red tone 사용

### 카드
- `background/elevated`
- 1px subtle border
- 12~16pt 내부 패딩

### 입력 필드
- elevated surface
- 1px border
- 활성화/포커스 시 accent blue border

### 에디터 그리드
- 기본 배경은 base
- bar line은 더 밝고, subdivision line은 더 얇고 어둡게
- 재생 헤드는 accent blue
- 선택 노트는 outline + fill 강조

## 상태 규칙

- hover: 약한 배경 상승 또는 border 강조
- focus: blue outline / border
- disabled: 대비 낮춘 text-secondary + interaction 차단
- error: red text + 설명 문구 동반

## 접근성

- VoiceOver 라벨 제공
- 텍스트 대비 충분히 유지
- 키보드만으로 주요 기능 접근 가능해야 함
- 움직임이 큰 애니메이션은 필수가 아니면 생략
