# Yarik (iOS / macOS)

Personal fork of [Bitchat](https://github.com/permissionlesstech/bitchat) for the Yarik messenger MVP. Mesh protocol and client logic come from upstream; branding and bundle ID are Yarik-specific.

See [UPSTREAM.md](./UPSTREAM.md) for the pinned upstream commit and merge notes.

## Build (iOS)

Requires **macOS** with full **Xcode** (not Command Line Tools only).

```bash
# Optional: signing for physical devices
cp Configs/Local.xcconfig.example Configs/Local.xcconfig
# Edit DEVELOPMENT_TEAM and optionally PRODUCT_BUNDLE_IDENTIFIER suffix

# Simulator / device build (Debug)
xcodebuild -project bitchat.xcodeproj \
  -scheme "bitchat (iOS)" \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath .DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build

# Or use upstream Justfile recipes on macOS:
just build    # macOS app
just test     # SwiftPM unit tests (BitFoundation + bitchatTests)
just test-ios # XCTest on iPhone simulator
```

Open `bitchat.xcodeproj` in Xcode, select scheme **bitchat (iOS)**, choose a simulator or your team for a device, then **Product → Run**.

## First mesh message (manual test)

**Simulator limitation:** Core Bluetooth mesh between two simulators is **not** a supported test path; use **two physical iPhones** (or one iPhone + one official Bitchat iOS build on another device).

1. Install Yarik on **Phone A** and **Phone B** (same build, Bluetooth and Local Network permissions allowed).
2. On both: open the app, stay on the default **`#bluetooth`** mesh channel (no Nostr required for this test).
3. Wait until each device shows the other in the peer list / `/who` (typically within ~30s with screens on and devices within BLE range).
4. On Phone A: send a public mesh message (main composer) or `/msg <peer> hello from Yarik`.
5. Confirm the message appears on Phone B and optionally reply from B → A.

Optional interoperability check: repeat with **Phone A = Yarik** and **Phone B = App Store Bitchat** at the same upstream protocol generation (see `UPSTREAM.md` SHA).

## Repository layout

Same as upstream: `bitchat/` app sources, `localPackages/` (BitFoundation, BitLogger, Arti/Tor), `bitchat.xcodeproj`, root `Package.swift` for `swift test`.
