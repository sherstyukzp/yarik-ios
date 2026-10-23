# Yarik (iOS / macOS)

Decentralized Bluetooth mesh messenger for the [Yarik](https://ukropsoft.atlassian.net/jira/software/projects/YI) project. Client logic and wire protocol come from an integrated upstream open-source mesh client; see [UPSTREAM.md](./UPSTREAM.md) for the pinned commit and refresh procedure.

**Bundle ID:** `com.yarik` · **App group:** `group.com.yarik` · **Display name:** Yarik

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

Open `Yarik.xcodeproj` in Xcode, select scheme **Yarik (iOS)** or **Yarik (macOS)**, then **Product → Run**.

On macOS you can also use the repo `Justfile`:

```bash
just build      # macOS app
just test       # SwiftPM unit tests (BitFoundation + app tests)
just test-ios   # XCTest on iPhone simulator
```

List available simulators if the destination name fails:

```bash
xcodebuild -showdestinations -project Yarik.xcodeproj -scheme "Yarik (iOS)"
```

## First mesh message (manual test)

**Simulators are not sufficient** for BLE mesh between two instances; use **two physical iPhones** (or one Yarik build and another mesh client on the same protocol generation — see `UPSTREAM.md`).

1. Install Yarik on **Phone A** and **Phone B** (Bluetooth and Local Network allowed).
2. On both devices, stay on the default **`#bluetooth`** mesh channel.
3. Wait until peers appear in the list or `/who` (often within ~30s, devices in BLE range, screens on).
4. On Phone A, send a public mesh message or `/msg <peer> hello from Yarik`.
5. Confirm delivery on Phone B and reply B → A.

## Repository layout

| Path | Purpose |
|------|---------|
| `Yarik.xcodeproj` | Xcode project (iOS, macOS, share extension, tests) |
| `bitchat/` | App sources (upstream folder name retained for easier merges) |
| `localPackages/` | BitFoundation, BitLogger, Arti/Tor |
| `Package.swift` | SwiftPM tests |
| `docs/` | Upstream technical documentation |
| `UPSTREAM.md` | Integrated upstream commit and Yarik-specific deltas |

## License

Upstream client is public domain (Unlicense). Yarik-specific configuration and documentation follow the same repository license unless noted otherwise.
