# ClickableRaidBuffs

ClickableRaidBuffs is a World of Warcraft addon that scans player and raid state plus inventory to surface missing buffs and consumables as clickable icons. It covers raid buff coverage, consumables (food, flask, weapon enchants), and class or module specific helpers.

## Features
- Missing raid buffs and consumables shown as clickable icons
- Inventory and enchant scanning with thresholds and cooldown awareness
- Module based helpers for class buffs, weapon enchants, pets, durability, Mythic+, and more
- Configurable options UI

## Install
1. Download the addon.
2. Extract the `ClickableRaidBuffs` folder into your WoW `Interface/AddOns` directory.
3. Restart WoW and enable the addon in the AddOns list.

## Development
- Entry point and load order live in `ClickableRaidBuffs.toc`.
- Core logic is under `Core/`, data tables in `Data/`, and UI in `UI/`.
- Options UI lives under `Options/`.

## Support
For support and downloads, see the links in `CHANGELOG.txt`.

## Release Notes (v7.1.0)
- Added profile import/export so you can share and apply full addon configurations between players and characters
- Added a new Profiles options tab with export, copy, import preview, and two import modes (replace all or merge)
- Added validation and safety for imports (schema/version checks, sanitization, checksum verification, and automatic pre-import backup)
- Added new slash command support for profile flows: `/crb export` and `/crb import`
- Fixed raid trinket reminders (including So'leah's Secret Technique) not showing or refreshing correctly in some apply/falloff scenarios
- Fixed raid/party rebuff icons sometimes not returning out of combat (self and group cases)
- Hardened gate handling so gate errors/secret values no longer suppress rebuff visibility updates
- General stability and maintenance updates
