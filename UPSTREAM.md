# Upstream integration

Yarik iOS ships the [permissionlesstech/bitchat](https://github.com/permissionlesstech/bitchat) iOS/macOS client as a **vendor copy** (full tree import, not a submodule).

| Field | Value |
|--------|--------|
| Upstream repository | https://github.com/permissionlesstech/bitchat |
| Integrated commit (full SHA) | `5e9287fae1e5fea80ca741d4ea669829dc16f144` |
| Integration date | 2026-10-23 |
| Method | Vendor copy into `yarik-ios` (replace empty template) |
| License | Unlicense / public domain (see upstream `LICENSE`) |

## Yarik-specific deltas

- `Configs/Release.xcconfig`: `PRODUCT_BUNDLE_IDENTIFIER = com.yarik`, `APP_GROUP_ID = group.com.yarik`
- Xcode `INFOPLIST_KEY_CFBundleDisplayName = Yarik` (iOS/macOS app + share extension)
- `DEVELOPMENT_TEAM` cleared — set in ignored `Configs/Local.xcconfig` for device signing

Protocol, BLE mesh, and Noise layers are unchanged from upstream at the pinned SHA so Yarik remains wire-compatible with official Bitchat clients for mesh messaging.

## Refreshing from upstream

```bash
UPSTREAM_SHA=<new-sha>
git fetch https://github.com/permissionlesstech/bitchat.git "$UPSTREAM_SHA"
# Diff and merge manually, or re-vendor with rsync/cp excluding .git, then re-apply Yarik deltas above.
```

Update this file’s SHA row after each refresh.
