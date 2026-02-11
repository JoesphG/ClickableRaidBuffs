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

## Release Notes (v7.0.9)
- Fixed an issue where raid/party rebuff icons could stay hidden out of combat when targets moved into range
- General stability and maintenance updates
