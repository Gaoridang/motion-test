# Slots Motion → SwiftUI 마이그레이션 가이드

Windows에서 확정한 **Photo Thumbnail Group (slots motion)** 을 MacBook + Xcode로 그대로 이어받기 위한 문서입니다.

---

## 1. 이 문서의 목적

| 환경 | 역할 |
|------|------|
| **Windows** (`V1/`) | UX·모션 확정, 웹으로 빠른 반복 |
| **MacBook** (Xcode) | 동일 동작을 SwiftUI로 구현, 시뮬레이터/실기기 검증 |

이 문서는 **웹 구현을 Swift로 1:1 옮기는 스펙**입니다.  
예전 `Versions/No1~3` Swift 프로토타입의 복잡한 스크럽/베지어 로직은 **사용하지 않습니다.**

---

## 2. 소스 오브 트루스 (Windows)

맥북으로 프로젝트를 옮길 때 아래 파일이 기준입니다.

```
motion-test/
└── V1/
    ├── SWIFT_MIGRATION.md          ← 이 문서
    ├── Swift/
    │   └── PhotoThumbnailGroup.swift  ← Xcode에 바로 넣을 참조 구현
    └── src/
        ├── components/PhotoThumbnailGroup.tsx  ← 핵심 로직
        ├── index.css                         ← 레이아웃·상수
        └── App.tsx
```

### Windows에서 마지막으로 확인

```powershell
cd V1
npm install
npm run dev
```

브라우저에서 `http://localhost:5173` 열고 아래 시나리오를 눈으로 확인한 뒤 Mac으로 넘어가세요.

---

## 3. 동작 스펙 (Behavior)

### 3.1 기본 구조

화면은 **2층**입니다.

```
┌─────────────────────────────┐
│  stack-zone (높이 가변)       │  ← 탭 시 위로 펼쳐지는 스택
│  [D]                        │
│  [C]                        │
│  [A]                        │
│  [B] ← active, bottom 고정   │
├─────────────────────────────┤  divider
│  [A] [B] [C] [D]            │  ← 항상 보이는 가로 줄 (탭 대상)
└─────────────────────────────┘
```

### 3.2 인터랙션

| 동작 | 결과 |
|------|------|
| 가로 줄에서 썸네일 **첫 탭** | 해당 슬롯 위로 스택 펼침 |
| **같은** 썸네일 다시 탭 | 접힘 (`activeIndex = nil`) |
| 펼친 상태에서 **다른** 썸네일 탭 | 스택이 새 슬롯 위치로 이동·재정렬 |
| 펼친 슬롯의 row 썸네일 | `opacity 0.45`로 dim |

### 3.3 스택 순서 알고리즘 (필수)

```ts
function getStackOrder(activeIndex: number): number[] {
  const after = indices > activeIndex, reversed
  const before = indices < activeIndex, reversed
  return [...after, ...before, activeIndex]
}
```

**예시: B(1) 탭**

| 단계 | 배열 | 시각 (아래→위) |
|------|------|----------------|
| `after` | `[3, 2]` | D, C |
| `before` | `[0]` | A |
| `active` | `1` | B (맨 아래, y=0) |
| **최종** | `[3, 2, 0, 1]` | 위: D→C→A / 아래: B |

**예시: D(3) 탭** → `[2, 1, 0, 3]` → 위: C→B→A / 아래: D

### 3.4 Y 위치 (가장 중요)

```ts
const y = -(stackOrder.length - 1 - stackPos) * (THUMB_SIZE + STACK_GAP)
```

| 규칙 | 설명 |
|------|------|
| active | `y = 0` (가로 줄 바로 위) |
| 나머지 | **음수** offset → 위로 쌓임 |
| 양수 y 사용 | ❌ 중앙/아래로 펼쳐지는 버그 발생 |

### 3.5 수평 정렬

스택 컨테이너의 왼쪽 위치:

```
stackLeft = activeIndex * (THUMB_SIZE + ROW_GAP)
         = activeIndex * 84
```

가로 줄의 N번째 슬롯과 **수직으로 정렬**됩니다.

---

## 4. 레이아웃 상수

웹 CSS / TS에서 쓰는 값 — Swift에서도 동일하게 사용하세요.

| 상수 | 값 | 용도 |
|------|-----|------|
| `THUMB_SIZE` | `72` | 썸네일 한 변 (pt) |
| `STACK_GAP` | `10` | 스택 아이템 간 세로 간격 |
| `ROW_GAP` | `12` | 가로 줄 슬롯 간격 |
| `SLOT_WIDTH` | `84` | `THUMB_SIZE + ROW_GAP` |
| `STACK_STEP` | `82` | `THUMB_SIZE + STACK_GAP` |
| `CORNER_RADIUS` | `12` | 모서리 |
| `DIVIDER_MARGIN` | `16` | 구분선 상하 여백 |

### 스택 존 높이

```
stackHeight = THUMB_SIZE + (stackOrder.count - 1) * STACK_STEP
```

접힘 상태: `stackHeight = 0`

### 화면 배치 (웹 기준)

| 영역 | CSS | SwiftUI 대응 |
|------|-----|--------------|
| 타이틀 | 상단 `padding-top: 18vh` | `Spacer()` + 상단 패딩 |
| 썸네일 그룹 | `margin-top: auto`, `padding-bottom: 8vh` | `VStack` + 하단 `Spacer()` |
| 그룹 최대 너비 | `360` | `.frame(maxWidth: 360)` |

---

## 5. 애니메이션 스펙

### 5.1 스택 아이템 (Motion spring)

| 속성 | enter | exit |
|------|-------|------|
| `y` | `0` → target | target → `0` |
| `scale` | `0.88` → `1` (active: `1.05`) | → `0.88` |
| `opacity` | `0` → `1` | → `0` |
| spring | stiffness `420`, damping `32` | duration `0.18s` |
| stagger | `delay = stackPos * 0.04` | — |

### 5.2 SwiftUI spring 근사값

```swift
.spring(response: 0.32, dampingFraction: 0.78)
```

`response`를 `0.28`~`0.36`, `dampingFraction`을 `0.72`~`0.82` 사이에서 미세 조정하세요.

### 5.3 스택 존 높이

```css
transition: height 0.35s cubic-bezier(0.22, 1, 0.36, 1)
```

SwiftUI:

```swift
.animation(.timingCurve(0.22, 1.0, 0.36, 1.0, duration: 0.35), value: activeIndex)
```

### 5.4 가로 줄

| 효과 | 값 |
|------|-----|
| active dim | `opacity: 0.45` |
| tap scale | `0.94` |
| opacity 전환 | `0.2s ease` |

---

## 6. 웹 → SwiftUI 매핑

| 웹 | SwiftUI |
|----|---------|
| `useState<number \| null>` | `@State private var activeIndex: Int? = nil` |
| `AnimatePresence` | `if let activeIndex` + `.transition` |
| `stack-zone` height | `.frame(height: stackHeight)` |
| `stack { bottom: 0 }` | `ZStack(alignment: .bottomLeading)` |
| `stack-item` + `y` offset | `.offset(y: yOffset)` (**음수**) |
| `left: activeIndex * 84` | `.padding(.leading, CGFloat(activeIndex) * slotWidth)` |
| `horizontal-row` | `HStack(spacing: rowGap)` |
| `whileTap scale 0.94` | `Button` + `.scaleEffect` 또는 `simultaneousGesture` |
| `aria-pressed` | `.accessibilityAddTraits(.isSelected)` |

### 좌표계

SwiftUI `offset(y:)` 와 CSS `translateY` 동일:

- **양수** → 아래
- **음수** → 위

---

## 7. MacBook에서 시작하기

### 7.1 프로젝트 가져오기

Windows 폴더 전체를 Mac으로 복사 (USB, 클라우드, git 등).

```bash
# Mac 터미널
cd ~/Desktop/motion-test/V1
npm install
npm run dev
```

웹 동작이 Windows와 같은지 먼저 확인합니다.

### 7.2 Xcode 프로젝트 생성

1. Xcode → **File → New → Project**
2. **iOS → App**
3. 설정:
   - Product Name: `PhotoThumbnailGroup`
   - Interface: **SwiftUI**
   - Language: **Swift**
4. Minimum Deployment: **iOS 17** (또는 팀 기준)

### 7.3 Swift 파일 추가

1. `V1/Swift/PhotoThumbnailGroup.swift` 를 Xcode 프로젝트에 드래그
2. `ContentView.swift` 를 아래처럼 교체:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        PhotoThumbnailGroupView()
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
```

### 7.4 시뮬레이터 실행

- **⌘R** 또는 Product → Run
- iPhone 15 / 16 시뮬레이터 권장
- Canvas Preview: **⌥⌘P** 로 `#Preview` 확인

---

## 8. 검증 체크리스트

Mac 시뮬레이터에서 웹과 나란히 비교하세요.

### 레이아웃

- [ ] 접힘 상태: 가로 줄만 보임, stack-zone 높이 0
- [ ] B 탭: 스택이 **B 슬롯 위**에서 **위로** 펼쳐짐
- [ ] B는 스택 **맨 아래**, D·C·A가 위에 순서대로
- [ ] 스택이 화면 **중앙**에서 퍼지지 않음 (bottom anchor)
- [ ] divider가 스택과 가로 줄 사이에 있음

### 애니메이션

- [ ] 펼칠 때 아이템이 아래(y=0)에서 위로 순차 등장
- [ ] stagger 딜레이 느껴짐 (~40ms 간격)
- [ ] active 썸네일 scale 약간 큼 (1.05)
- [ ] stack-zone 높이가 부드럽게 늘어남
- [ ] 접을 때 아이템이 아래로 모이며 사라짐

### 인터랙션

- [ ] 같은 슬롯 재탭 → 접힘
- [ ] B 펼친 뒤 D 탭 → 스택이 D 위치로 이동
- [ ] row에서 active 항목 dim (opacity ~0.45)
- [ ] 탭 시 scale 0.94 피드백

### 흔한 실패 패턴

| 증상 | 원인 | 해결 |
|------|------|------|
| 중앙에서 펼쳐짐 | `ZStack` center anchor | `.bottomLeading` + 음수 y |
| 아래로 펼쳐짐 | y가 양수 | y 공식에 `-` 확인 |
| 순서 이상 | `getStackOrder` 다름 | TS 코드와 배열 비교 |
| 스택 위치 어긋남 | `leading` padding 누락 | `activeIndex * 84` 적용 |
| 전환 끊김 | `activeIndex` 바뀔 때 뷰 ID 충돌 | `ForEach(photo.id)` 사용 |

---

## 9. 데이터 모델

웹의 4개 슬롯 — Swift에서도 동일:

```swift
struct PhotoItem: Identifiable, Equatable {
    let id: String
    let label: String
    let colors: [Color]  // gradient start/end
}
```

| id | label | colors (start → end) |
|----|-------|----------------------|
| a | A | orange `#f97316` → `#ea580c` |
| b | B | blue `#3b82f6` → `#1d4ed8` |
| c | C | green `#22c55e` → `#15803d` |
| d | D | purple `#a855f7` → `#7e22ce` |

실제 앱에서는 `PhotoItem`을 `UIImage` / `PhotosPicker` 로 교체하면 됩니다. **모션 로직은 그대로** 유지하세요.

---

## 10. 구현 순서 (권장)

맥북에서 아래 순서로 하면 디버깅이 쉽습니다.

1. **정적 레이아웃** — 가로 줄 4개만
2. **`getStackOrder`** — print로 B, D 탭 시 배열 확인
3. **스택 정적 배치** — 애니메이션 없이 음수 y로 위치만
4. **`stackHeight`** — activeIndex에 따라 높이 변경
5. **spring 애니메이션** — offset + scale + opacity
6. **stagger delay** — `stackPos * 0.04`
7. **탭 토글** — 같은 슬롯 재탭 시 접기
8. **polish** — haptic, accessibility, safe area

---

## 11. iOS에서 추가하면 좋은 것 (선택)

웹에 없지만 iOS에서 자연스러운 보완:

```swift
import UIKit

func lightHaptic() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
}
```

- 펼침/접힘/전환 시 `light` haptic
- `accessibilityLabel("Spread photo \(label)")`
- Dynamic Type는 썸네일 UI에 맞게 조정

---

## 12. 이후 확장 시 주의

| 확장 | 권장 |
|------|------|
| 사진 4장 → N장 | `getStackOrder`와 `stackHeight` 공식은 그대로, `PHOTOS`만 교체 |
| 드래그 스크럽 추가 | **별도 버전**으로 분리 (이 스펙과 섞지 말 것) |
| `matchedGeometryEffect` | row↔stack 연결 polish용, 1차 마이그레이션 후 추가 |
| Hero 대형 프리뷰 | 스택 위에 별도 뷰 추가, 스택 로직은 변경 없음 |

---

## 13. 빠른 참조 — 핵심 공식

```swift
// 스택 순서
func stackOrder(active: Int, count: Int) -> [Int] {
    let after = (0..<count).filter { $0 > active }.reversed()
    let before = (0..<count).filter { $0 < active }.reversed()
    return Array(after) + Array(before) + [active]
}

// 높이
var stackHeight: CGFloat {
    guard activeIndex != nil else { return 0 }
    let n = stackOrder.count
    return thumbSize + CGFloat(n - 1) * stackStep
}

// Y offset (음수 = 위)
func yOffset(stackPos: Int, count: Int) -> CGFloat {
    -CGFloat(count - 1 - stackPos) * stackStep
}

// 수평 정렬
var stackLeading: CGFloat {
    CGFloat(activeIndex ?? 0) * slotWidth
}
```

---

## 14. 문의·수정 시

Windows에서 모션을 바꿨다면 **반드시** 아래를 이 문서와 함께 업데이트하세요.

1. `PhotoThumbnailGroup.tsx`
2. `index.css` 상수
3. 이 문서의 §3~§5
4. `Swift/PhotoThumbnailGroup.swift`

---

**다음 단계:** `V1/Swift/PhotoThumbnailGroup.swift` 를 Xcode에 추가하고 §8 체크리스트로 시뮬레이터 검증.
