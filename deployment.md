# Deployment Process (CurseForge + GitHub)

This repo uses the CurseForge webhook packaging flow. Follow this checklist for every release.

## Release Type
Each deployment must be tagged as **Alpha**, **Beta**, or **Release** via the tag name:
- **Alpha**: tag contains `alpha` (example: `v7.0.6-alpha.1`)
- **Beta**: tag contains `beta` (example: `v7.0.6-beta.1`)
- **Release**: tag does **not** include `alpha` or `beta` (example: `v7.0.6`)

CurseForge will package the tag and automatically set the file type based on the tag name.

## Pre-Release Checklist
1. Ensure `ClickableRaidBuffs.toc` version matches the tag (e.g., `7.0.6`).
2. Update release notes in all locations:
   - `CHANGELOG.txt`
   - `README.md`
   - `RELEASE_NOTES.md`
   - `curseforge.md`
3. Run formatting and checks:
   - `make fmt`
   - `make check` (LLS warnings are acceptable if reviewed)

## Packaging (CurseForge Webhook)
- Push the tagged commit to GitHub; CurseForge will package automatically.
- Webhook URL format (keep token secret):
  - `https://www.curseforge.com/api/projects/{projectID}/package?token={token}`

## Tag + Push Flow
1. Commit changes.
2. Create tag:
   - Release: `git tag -a v7.0.6 -m "v7.0.6"`
   - Beta: `git tag -a v7.0.6-beta.1 -m "v7.0.6-beta.1"`
   - Alpha: `git tag -a v7.0.6-alpha.1 -m "v7.0.6-alpha.1"`
3. Push:
   - `git push origin main`
   - `git push origin <tag>`

## GitHub Release
Create the GitHub release from `RELEASE_NOTES.md`:
- `gh release create <tag> --title "<tag>" --notes-file RELEASE_NOTES.md`

## Packaging Exclusions (End-User Clean)
Ensure these **do not** ship to CurseForge. Use `.pkgmeta` or `pkgmeta.yaml` if needed:
- Development configs: `.luarc.json`, `.stylua.toml`, `Makefile`
- Tooling: `Tools/`
- Release staging files: `RELEASE_NOTES.md`, `curseforge.md`
- VCS/CI: `.git/`, `.github/`
- OS junk: `*:Zone.Identifier`

## Optional: .pkgmeta Example
If we need explicit packaging rules, create a `.pkgmeta` with:
```
ignore:
  - Tools
  - .luarc.json
  - .stylua.toml
  - Makefile
  - RELEASE_NOTES.md
  - curseforge.md
  - .github
```

## Notes
- If you retag a release, you must force-push the tag: `git push -f origin <tag>`.
- If CurseForge packaged the wrong type, check the tag name for `alpha`/`beta`.
