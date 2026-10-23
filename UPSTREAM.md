# Upstream mesh integration

Yarik iOS vendors mesh client logic from [permissionlesstech/bitchat](https://github.com/permissionlesstech/bitchat) inside the **`YarikMesh`** Swift package (`Packages/YarikMesh`). The Xcode **app target** is the Yarik SwiftUI shell from `main`; it does not ship the upstream chat UI.

| Field | Value |
|--------|--------|
| Upstream repository | https://github.com/permissionlesstech/bitchat |
| Integrated commit (full SHA) | `5e9287fae1e5fea80ca741d4ea669829dc16f144` |
| Integration date | 2026-10-23 |
| Method | Vendor copy into `Packages/YarikMesh` |
| License | Unlicense / public domain (see upstream `LICENSE`) |

## Yarik-specific deltas

- **App:** `Yarik/` SwiftUI starter (SwiftData list shell), bundle `com.yarik`, display name **Yarik**
- **Mesh:** `Packages/YarikMesh` module name **YarikMesh** (protocol, BLE, Noise, Nostr, services)
- **Upstream UI:** kept only inside `YarikMesh` for reference and unit tests; not linked as the app entry point
- `Configs/Release.xcconfig`: `PRODUCT_BUNDLE_IDENTIFIER = com.yarik`, `APP_GROUP_ID = group.com.yarik`
- `DEVELOPMENT_TEAM` cleared — set in ignored `Configs/Local.xcconfig` for device signing
- **swift-secp256k1** pinned to **0.23.2** (Swift 6 / UInt256 compatibility)

Protocol and mesh layers match the pinned upstream SHA so Yarik remains wire-compatible with other clients built from the same commit.

## Refreshing from upstream

```bash
UPSTREAM_SHA=<new-sha>
git fetch https://github.com/permissionlesstech/bitchat.git "$UPSTREAM_SHA"
# Merge into Packages/YarikMesh/Sources/YarikMesh (exclude upstream @main app entry).
# Re-apply Yarik deltas above and run YarikMeshTests on macOS.
```

Update this file’s SHA row after each refresh.
