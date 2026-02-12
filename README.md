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

## Release Notes (v7.1.1)
- Fixed an options panel startup error on clients where `SetMinResize` is unavailable
- Restored options access from both the minimap button and Blizzard AddOns/Settings entry after options panel init failures
- Added a compatibility fallback for Blizzard Interface Options category registration
- Improved Info tab layout by moving control checkboxes to a dedicated footer below the text area
- Reduced oversized Info tab text to fit cleanly in the panel without overlap
- General stability and UI maintenance updates
