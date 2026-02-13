# ClickableRaidBuffs v7.1.10 Release Notes

- Removed legacy Midnight bootstrap wrapping and moved expansion metadata initialization into normal addon startup
- Fixed multiple secret-value aura handling paths that could trigger Lua errors in buff, raid scan, food, shaman shield, flask, rogue poison, fixed-target, and gate checks
- Fixed augment rune reminders incorrectly showing while a persistent rune buff is active
- Added Draconic Augment Rune tracking (`itemID 201325`, `buffID 393438`)
