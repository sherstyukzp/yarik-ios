# Yarik (iOS / macOS)

[Yarik](https://ukropsoft.atlassian.net/jira/software/projects/YI) messenger for iOS and macOS.

- **App target (`Yarik/`)** — SwiftUI starter shell (SwiftData). This is what opens in Xcode as the product UI.
- **Mesh stack (`Packages/YarikMesh`)** — Bluetooth mesh, Noise, Nostr, and related services vendored from upstream; see [UPSTREAM.md](./UPSTREAM.md).

**Bundle ID:** `com.yarik` · **App group:** `group.com.yarik` · **Display name:** Yarik  
**Schemes:** `Yarik (iOS)`, `Yarik (macOS)`

## Build (macOS + Xcode)

Requires **macOS** with full **Xcode** (not Command Line Tools only). Builds are not run in the Linux cloud agent environment.

```bash
# Optional: signing for physical devices
cp Configs/Local.xcconfig.example Configs/Local.xcconfig
# Edit DEVELOPMENT_TEAM in Local.xcconfig

# iOS Simulator (Debug, no signing)
xcodebuild -project Yarik.xcodeproj \
  -scheme "Yarik (iOS)" \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath .DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build

# macOS app (Debug, no signing)
xcodebuild -project Yarik.xcodeproj \
  -scheme "Yarik (macOS)" \
  -configuration Debug \
  -derivedDataPath .DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Open `Yarik.xcodeproj`, choose **Yarik (iOS)** or **Yarik (macOS)**, then **Product → Run**.

SwiftPM mesh unit tests (from repo root):

```bash
swift test --package-path Packages/YarikMesh   # library compile check
swift test                                     # YarikMeshTests via root Package.swift
```

On macOS you can also use the repo `Justfile`:

```bash
just build      # macOS Yarik app
just test       # SwiftPM tests
just test-ios   # XCTest on iPhone simulator
```

List simulators if the destination name fails:

```bash
xcodebuild -showdestinations -project Yarik.xcodeproj -scheme "Yarik (iOS)"
```

## Linking YarikMesh from the app

The shell imports the mesh module so Xcode links the package:

```swift
import YarikMesh
```

Use `@testable import YarikMesh` in unit tests. Public surface today is minimal (`YarikMeshKit`); mesh APIs remain internal until Yarik UI wires them in.

## Repository layout

| Path | Purpose |
|------|---------|
| `Yarik.xcodeproj` | Xcode project (Yarik app, share extension, mesh tests) |
| `Yarik/` | App shell (SwiftUI starter) |
| `Packages/YarikMesh` | Mesh / protocol Swift package |
| `YarikMeshTests/` | XCTest suite for YarikMesh |
| `localPackages/` | BitFoundation, BitLogger, Arti/Tor |
| `Package.swift` | SwiftPM test manifest for CI |
| `UPSTREAM.md` | Pinned upstream commit and refresh notes |

## License

Upstream mesh client is public domain (Unlicense). Yarik-specific configuration and documentation follow the repository license unless noted otherwise.
