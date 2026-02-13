# Deployment Process (CurseForge + GitHub)

This repo uses the CurseForge webhook packaging flow.
This process is mandatory and must be followed for every release.

## Release Type
Each deployment must be tagged as **Alpha**, **Beta**, or **Release** via the tag name:
- **Alpha**: tag contains `alpha` (example: `v7.0.6-alpha.1`)
- **Beta**: tag contains `beta` (example: `v7.0.6-beta.1`)
- **Release**: tag does **not** include `alpha` or `beta` (example: `v7.0.6`)

CurseForge will package the tag and automatically set the file type based on the tag name.

## Pre-Release Checklist
1. Ensure `ClickableRaidBuffs.toc` version matches the tag (e.g., `7.0.6`).
2. Update release documentation:
   - `CHANGELOG.txt` (running history; add new release entry and keep prior history)
   - `RELEASE_NOTES.md` (current tag only; fully replace with notes for the tag being released)
   - **Guideline**: notes must be user-facing and functional only. Exclude backend/dev workflow details.
3. Release-notes gate (required):
   - Verify `RELEASE_NOTES.md` reflects the exact tag/version being created.
   - Do not create or push a release tag until this is confirmed.
4. Run formatting and checks:
   - `make fmt`
   - `make check` (LLS warnings are acceptable if reviewed)
   - `make release-check` (version sync + concise release-note policy checks)

## Packaging (CurseForge Webhook)
- Push the tagged commit to GitHub; CurseForge will package automatically.
- Webhook URL format (keep token secret):
  - `https://www.curseforge.com/api/projects/{projectID}/package?token={token}`
- If creating a manual release zip, it must contain a single top-level addon folder named `ClickableRaidBuffs/` (do not zip loose files at archive root).

## Packaging (Wago via GitHub Actions)
- Wago packaging runs on tag pushes via `.github/workflows/release.yml` using the BigWigs packager.
- Ensure `## X-Wago-ID: mNwQE5Ko` is present in `ClickableRaidBuffs.toc`.
- Set `WAGO_API_TOKEN` in GitHub repo secrets before tagging.

## Manual Zip Packaging (Required Structure)
Use this command format so all files are inside the addon-named parent folder:

`git archive --format=zip --prefix=ClickableRaidBuffs/ --output=/tmp/ClickableRaidBuffs-vX.Y.Z.zip vX.Y.Z`

Structure requirement:
- Top-level folder in zip: `ClickableRaidBuffs/`
- Addon files/folders must live under that folder (e.g. `ClickableRaidBuffs/ClickableRaidBuffs.toc`)

## Tag + Push Flow
Do this only after every pre-release checklist item is complete.

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

## Discord Auto-Post (GitHub Actions)
- Workflow: `.github/workflows/discord-release-notes.yml`
- Trigger: GitHub release `published`
- Required secret: `DISCORD_WEBHOOK_URL` (Discord channel webhook URL)
- Behavior: posts the release title, tag, URL, and body (from `RELEASE_NOTES.md`) to Discord automatically.

## Packaging Exclusions (End-User Clean)
Ensure these **do not** ship to CurseForge. Use `.pkgmeta` or `pkgmeta.yaml` if needed:
- Development configs: `.luarc.json`, `.stylua.toml`, `Makefile`
- Tooling: `Tools/`
- Release staging files: `RELEASE_NOTES.md`
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
  - .github
```

## Notes
- If you retag a release, you must force-push the tag: `git push -f origin <tag>`.
- If CurseForge packaged the wrong type, check the tag name for `alpha`/`beta`.
