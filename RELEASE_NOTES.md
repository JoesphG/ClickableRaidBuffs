# ClickableRaidBuffs v7.1.0 Release Notes

- Added profile import/export so you can share and apply full addon configurations between players and characters
- Added a new Profiles options tab with export, copy, import preview, and two import modes (replace all or merge)
- Added validation and safety for imports (schema/version checks, sanitization, checksum verification, and automatic pre-import backup)
- Added new slash command support for profile flows: `/crb export` and `/crb import`
- Fixed raid trinket reminders (including So'leah's Secret Technique) not showing or refreshing correctly in some apply/falloff scenarios
- Fixed raid/party rebuff icons sometimes not returning out of combat (self and group cases)
- Hardened gate handling so gate errors/secret values no longer suppress rebuff visibility updates
- General stability and maintenance updates
