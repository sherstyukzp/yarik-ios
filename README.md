# Yarik

Messenger for iOS and macOS. The app sources live in `Yarik/`.

**Bundle ID:** `com.ukropsoft.yarik` · **App group:** `group.com.ukropsoft.yarik`  
**Schemes:** `Yarik (iOS)`, `Yarik (macOS)`

## Build

Requires macOS with full Xcode.

```bash
cp Configs/Local.xcconfig.example Configs/Local.xcconfig
# Edit DEVELOPMENT_TEAM

xcodebuild -project Yarik.xcodeproj \
  -scheme "Yarik (iOS)" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Or open `Yarik.xcodeproj` and run **Yarik (iOS)** / **Yarik (macOS)**.

```bash
just build      # macOS app
just test       # unit tests via Xcode
```

## Layout

| Path | Purpose |
|------|---------|
| `Yarik/` | App sources, assets, localizations |
| `YarikShareExtension/` | Share extension |
| `YarikMeshTests/` | Unit tests |
| `Configs/` | Shared xcconfig + iOS Info.plist keys |
| `localPackages/` | BitFoundation, BitLogger, Arti/Tor |
