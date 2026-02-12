# Session Context Summary

## Current Release State
- Latest release commit: `v7.0.9`
- CurseForge webhook: firing successfully with `{"success":true}`, but files are not appearing; manual upload is required for now.
- Manual CurseForge package path (latest): `/home/trist/ClickableRaidBuffs/ClickableRaidBuffs-v7.0.8.zip`

## Recent Feature Changes
- Fixed post-combat update bus retries so dirty state does not get stranded while locked.
- Fixed range-gated raid rebuff visibility when range status changes out of combat.
- Added `/crb debug` diagnostics to print hidden raid buff gate/visibility reasons.
- Discord release autopost now sends concise functional bullet points only (no release URL).

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
- Release notes body must use concise functional bullet points only.
- Do not include a GitHub release link in the release notes body.
- `.pkgmeta` excludes tooling and non-user files from packages.
- Run `make release-check` before tagging.

## Packaging Excludes (.pkgmeta)
- `Tools/`, `.luarc.json`, `.stylua.toml`, `Makefile`
- `RELEASE_NOTES.md`, `curseforge.md`, `.github/`, `deployment.md`
- `*.Zone.Identifier`

## Outstanding Issues
- CurseForge webhook: success response but no files appear. Likely queue delay or internal CF packaging issue; manual upload used as fallback.
