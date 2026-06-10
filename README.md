# motion-test

Photo thumbnail **slots motion** prototype — tap a thumbnail to spread a vertical stack upward.

## What's inside

```
V1/
├── src/components/PhotoThumbnailGroup.tsx   # Web reference implementation
├── Swift/PhotoThumbnailGroup.swift        # SwiftUI reference for Xcode
├── SWIFT_MIGRATION.md                     # Mac migration guide
└── package.json                           # Vite + React + Motion
```

## Run on Windows / Mac (web)

```bash
cd V1
npm install
npm run dev
```

Open `http://localhost:5173` in Chrome or Edge.

## Migrate to iOS

See **[V1/SWIFT_MIGRATION.md](V1/SWIFT_MIGRATION.md)** — drop `V1/Swift/PhotoThumbnailGroup.swift` into an Xcode SwiftUI project.

## Interaction

- Tap a thumbnail in the bottom row → stack spreads **upward** above that slot
- Tap the same thumbnail again → collapse
- Tap another thumbnail → stack moves and reorders