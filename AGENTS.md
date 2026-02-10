# ClickableRaidBuffs - Project Context

## Purpose
ClickableRaidBuffs is a World of Warcraft addon that scans player/raid state and inventory to show missing buffs/consumables as clickable icons. It supports raid buff coverage, consumables (food/flask/weapon enchants), and various module-specific helpers.

## Entry Points
- `ClickableRaidBuffs.toc` lists load order and modules. The load order is important: libraries, media, core, gates, data tables, modules, UI, options, then `Core/MidnightBootstrap.lua`.
- The addon namespace is stored in `ns` and exported as `_G[addonName]` in `Core/Base.lua`.

## Core Architecture
### Namespace + Globals
- `ns` is the shared namespace (module functions are attached to it).
- Saved variables: `ClickableRaidBuffsDB` (settings) and `ClickableRaidBuffsMinimapDB`.
- Runtime cache: `clickableRaidBuffCache` with `displayable` (UI list), `playerInfo`, `functions`.

### Data Flow (High Level)
1. **Events** (`Core/Events.lua`) listen to WoW events and call module hooks and `ns.PokeUpdateBus()`.
2. **Update Bus** (`Core/UpdateBus.lua`) batches flags (bags/roster/auras/options/gates) and runs a single update pass:
   - recompute gates
   - scan bags (`scanAllBags`) + raid buffs (`scanRaidBuffs`)
   - module-specific rebuilds
   - `ns.RebuildDisplayables` + `ns.RefreshEverything` (when options change)
   - queue render
3. **Scanners** populate `clickableRaidBuffCache.displayable`:
   - `Core/BagScan.lua` for consumables/enchants.
   - `Core/RaidBuffsScan.lua` for raid buffs.
4. **UI Render** (`UI/Render.lua`) builds and displays buttons from `displayable`.

### Combat / Lockdown Safety
- Most logic is suppressed during combat/encounter/death using `ns.ExecutionLocked()` and checks throughout.
- `Core/MidnightBootstrap.lua` wraps `ns` functions to short-circuit during lock and records violations.

## Core Modules
- **Core scanning and helpers**:
  - `Core/BagScan.lua`: inventories, thresholds, cooldowns, weapon enchants.
  - `Core/RaidBuffsScan.lua`: raid buff coverage by class data tables.
  - `Core/Buffs.lua`: aura lookups + expiration helpers.
  - `Core/PlayerInfo.lua`, `Core/RosterWatch.lua`: cached player/raid info.
  - `Core/UpdateBus.lua`: batching, render scheduling.
  - `Core/Events.lua`: event dispatch + throttling.
  - `Core/Order.lua`: category ordering.
  - `Core/Click.lua`: click handling and action setup.
  - `Core/GateCheck.lua`: gate evaluation.

## Gates
- Gates are registered via `ns.RegisterGate(name, fn)` in `Core/GateCheck.lua`.
- Each gate lives in `Gates/*.lua` and typically calls `ns.RegisterGate(...)` (example: `Gates/Instance_Gate.lua`).
- Data rows include `gates = {"name", ...}` and optional `minLevel` to filter eligibility.

## Data Tables
- `Data/*.lua` define consumable/spell tables (e.g., `Flask_Table.lua`, `RaidBuffs_Table.lua`).
- These tables populate `_G.ClickableRaidData` and are read by scanners and modules.

## Modules (Feature Add-ons)
Modules attach behavior to events and rendering by defining `ns.<Feature>_*` hooks and sometimes wrapping `ns.RenderAll`.
Common examples:
- `Modules/FoodStatus.lua` tracks food/buffs and drives displayable items.
- `Modules/Flask.lua` computes flask state and applies “fleeting” gate.
- `Modules/WeaponEnchants.lua`, `Modules/CastableWeaponEnchants.lua`, `Modules/DKWeaponEnchantCheck.lua` add weapon enchant logic.
- `Modules/RoguePoisons.lua`, `Modules/ShamanShields.lua` handle class-specific buffs.
- `Modules/Healthstone.lua`, `Modules/Pets.lua`, `Modules/Durability.lua`, `Modules/MythicPlus.lua`, `Modules/Delves.lua` add UI and logic.
- `Modules/Exclusions.lua` filters displayables and hooks render/rebuild functions.

## UI Layer
- `UI/Render.lua` builds the button list from `clickableRaidBuffCache.displayable`, sorts by category and custom order, and renders textures/glows/cooldowns.
- Supporting files: `UI/VisualCore.lua`, `UI/Cooldown.lua`, `UI/Glow.lua`, `UI/TextStyles.lua`, `UI/Fonts.lua`.
- Rendering is often wrapped by modules to apply extra logic (ex: `Modules/Flask.lua`, `Modules/CastableWeaponEnchants.lua`).

## Options
- Defaults are in `Options/Defaults.lua` and applied in `Core/Base.lua` on `ADDON_LOADED`.
- Options UI files live under `Options/` and `Options/Tabs/`.
- Changes typically call `ns.RequestRebuild()` or set `optionsDirty` to let UpdateBus rebuild displayables.

## Patterns to Follow for Modifications
- Add new displayable types by:
  - Extending `Data/*.lua` tables and updating scanners or modules to read them.
  - Writing module-specific hooks that set entries in `clickableRaidBuffCache.displayable`.
- Use `ns.PokeUpdateBus()` and `ns.Mark*Dirty()` to update state. Avoid direct UI updates inside event handlers.
- Respect combat/lockdown restrictions. If new logic touches secure frames or UI, guard with `InCombatLockdown()` or `ns.ExecutionLocked()`.
- If hooking `ns.RenderAll`, wrap only once and preserve original behavior. Several modules already do this.
- For thresholds/cooldowns, follow patterns in `Core/BagScan.lua` (apply thresholds, use `showAt` to defer visibility).

## Key Files for Quick Orientation
- `ClickableRaidBuffs.toc`
- `Core/Base.lua`
- `Core/Events.lua`
- `Core/UpdateBus.lua`
- `Core/BagScan.lua`
- `Core/RaidBuffsScan.lua`
- `UI/Render.lua`
- `Options/Defaults.lua`
