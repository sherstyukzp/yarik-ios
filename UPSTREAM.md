# Upstream mesh integration

Yarik vendors mesh client logic from [permissionlesstech/bitchat](https://github.com/permissionlesstech/bitchat) directly in `Yarik/`.

| Field | Value |
|--------|--------|
| Upstream repository | https://github.com/permissionlesstech/bitchat |
| Integrated commit (full SHA) | `5e9287fae1e5fea80ca741d4ea669829dc16f144` |
| Integration date | 2026-10-23 |
| Method | Vendor copy into `Yarik/` |
| License | Unlicense / public domain (see upstream `LICENSE`) |

## Yarik-specific deltas

- **App:** `Yarik/` is the product (SwiftUI messenger + mesh stack)
- **Bundle:** `com.ukropsoft.yarik`, app group `group.com.ukropsoft.yarik`
- **Module name:** `YarikMesh` (kept so unit tests stay `@testable import YarikMesh`)
- `DEVELOPMENT_TEAM` is set in ignored `Configs/Local.xcconfig` for device signing
- **swift-secp256k1** pinned to **0.23.2**

Protocol and mesh layers match the pinned upstream SHA so Yarik remains wire-compatible with other clients built from the same commit.

## Refreshing from upstream

```bash
UPSTREAM_SHA=<new-sha>
git fetch https://github.com/permissionlesstech/bitchat.git "$UPSTREAM_SHA"
# Merge into Yarik/ (exclude upstream @main app entry).
# Re-apply Yarik deltas above and run YarikMeshTests on macOS.
```

Update this file’s SHA row after each refresh.
