# Session Context Summary

## Current Release State
- Latest release commit: `v7.0.7`
- CurseForge webhook: firing successfully with `{"success":true}`, but files are not appearing; manual upload is required for now.
- Manual CurseForge package path (latest): `/tmp/crb-release/ClickableRaidBuffs-7.0.7.zip`

## Recent Feature Changes
- Added Holy Paladin beacon support (Beacon of Light `53563`, Beacon of Faith `156910`) with mutual suppression when either beacon is active.
- Added Frost Mage Water Elemental support in the Pets module (spell `31687`).
- Fixed icons not restoring after resurrection by restoring render on `PLAYER_UNGHOST`/`PLAYER_ALIVE`.
- Added eating aura ID `452319` to EATING list for correct food timer/icon updates.
- Added secret-value guards for aura/cooldown handling (Retail 12.0+).

## Integration Setup
- CurseForge webhook URL format:
  - `https://www.curseforge.com/api/projects/{projectID}/package?token={token}`
- Project ID used: `1346089`
- Repo is public; repo URL was missing in CurseForge settings and has now been set.

## Wago Integration
- `## X-Wago-ID: mNwQE5Ko` added to `ClickableRaidBuffs.toc`.
- GitHub Actions packager workflow: `.github/workflows/release.yml`
- Requires GitHub secret: `WAGO_API_TOKEN`.

## Deployment Process
- `deployment.md` documents tag conventions and packaging steps.
- Release notes must be user-facing only (no backend/dev details).
- `.pkgmeta` excludes tooling and non-user files from packages.

## Packaging Excludes (.pkgmeta)
- `Tools/`, `.luarc.json`, `.stylua.toml`, `Makefile`
- `RELEASE_NOTES.md`, `curseforge.md`, `.github/`, `deployment.md`
- `*.Zone.Identifier`

## Outstanding Issues
- CurseForge webhook: success response but no files appear. Likely queue delay or internal CF packaging issue; manual upload used as fallback.

