# ClickableRaidBuffs v7.1.0 (Retail 12.0.1)

## Changelog
- Added profile import/export so players can share full ClickableRaidBuffs configurations
- Added a new Profiles tab with export, copy, import preview, and two import modes (replace all or merge)
- Added import safety checks (schema/version validation, sanitization, checksum verification, and automatic backup before apply)
- Added new slash commands: `/crb export` and `/crb import`
- Fixed raid trinket reminders (including So'Leah's Secret Technique) not showing or refreshing correctly in some apply/falloff scenarios
- Fixed raid/party rebuff icons sometimes not returning out of combat (self and group cases)
- Hardened gate handling so gate errors/secret values no longer suppress rebuff visibility updates
- General stability and maintenance updates

## Game Version
- Retail 12.0.1+

## Release Type
- Release

## Known Issues
- None known. Please report issues via the support links in CHANGELOG.txt.

## Install
- Extract the ClickableRaidBuffs folder into your WoW Interface/AddOns directory.
