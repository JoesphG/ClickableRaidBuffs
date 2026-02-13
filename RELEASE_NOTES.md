# ClickableRaidBuffs v7.1.7 Release Notes

- Added a new Expansions panel in Customize options with toggles for The War Within and Midnight consumables/runes
- Added expansion-aware filtering so disabled expansions are hidden from reminders and Ignore-list item sections
- Added expansion metadata normalization for consumable/rune data and removed `[TWW]` name-prefix reliance
- Fixed consumable cleanup so disabled-expansion items are removed immediately instead of lingering while still in bags
- Refined raid range gate behavior to better handle in-combat/out-of-combat transitions and mid-dungeon state updates
- Fixed raid buff reminders failing to return in some Mythic+ out-of-combat scenarios after buffs dropped during combat
