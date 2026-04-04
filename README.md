# HandyBar (Retail 12.0.1+)

HandyBar is a PvP arena addon for tracking enemy cooldowns with a hybrid workflow:

- automatic detection for many visible enemy cooldowns
- manual click tracking as a reliable fallback

Version: `1.3.0`

Saved variables: `HandyBarDB`

Embedded libraries: Ace3 + MajorCooldowns

## Highlights

- Configurable spell bars
- Arena-only visibility with a runtime Test Mode
- Enemy class/spec detection from the Retail arena prep API
- Per-bar visibility targeting: `All Enemies`, `Arena 1`, `Arena 2`, `Arena 3`
- Optional duplication when multiple enemies share the same class/spec
- Manual left-click start and right-click reset
- Cooldown spiral, optional timer text, and class-colored borders
- Charge support for spells that use multiple charges
- Global cooldown overrides
- Custom spell support
- AceDB profiles

## Automatic Enemy Cooldown Detection

HandyBar can automatically start many enemy cooldowns in arena by combining:

- `UNIT_AURA`
- `UNIT_SPELLCAST_SUCCEEDED`
- `UNIT_FLAGS`
- `UNIT_ABSORB_AMOUNT_CHANGED`
- Blizzard aura filters:
  - `HELPFUL|BIG_DEFENSIVE`
  - `HELPFUL|EXTERNAL_DEFENSIVE`
  - `HELPFUL|IMPORTANT`

The implementation is designed for Midnight-era addon restrictions:

- no secret value comparisons
- no direct reads of secret aura `spellId`, `duration`, or `expirationTime`
- tracking is built around `auraInstanceID`, public filter membership, and timing evidence

This is intentionally a best-effort arena tracker. It works well for many visible defensives, externals, and important offensives, but spells without a visible/public aura still require manual clicks.

## Installation

Install the addon to:

`World of Warcraft/_retail_/Interface/AddOns/HandyBar/`

Then reload the UI with `/reload` or restart the game.

## Quick Start

1. Open the options with `/hb`
2. Enable `Test Mode` outside arena to place your bars
3. Unlock the bars, move them, then lock them again
4. Enable the spells you want to track in `Bars -> <Bar Name> -> Spells`
5. Enable `Automatic Enemy Cooldown Detection` in `General` if you want hybrid tracking

## Match Usage

### Automatic mode

When automatic tracking is enabled, HandyBar tries to start tracked enemy cooldowns on its own whenever a visible/public arena signal is strong enough.

### Manual mode

- Left-click an icon to start the cooldown manually
- Right-click an icon to reset it

Manual mode always remains available, even when automatic detection is enabled.

## Slash Commands

- `/hb` opens the options
- `/hb test` toggles Test Mode
- `/hb lock` toggles bar locking
- `/hb reset` resets all active cooldowns

## Configuration Overview

### General

- `Test Mode`
- `Lock Bars`
- `Automatic Enemy Cooldown Detection`
- `Debug Mode`
- `Reset All Cooldowns`
- `Reset Configuration`

### Bars

Each bar supports:

- enable/disable
- icon size
- spacing
- growth direction
- max icons per row
- icon display limit
- cooldown text
- class borders
- arena visibility filter
- duplicate same class/spec handling

### Customize

- Global cooldown overrides for existing MajorCooldowns entries
- Custom spell registration by Spell ID
- Automatic tooltip-based cooldown extraction for custom spells

## Arena Detection

HandyBar primarily uses:

- `ARENA_PREP_OPPONENT_SPECIALIZATIONS`
- `GetNumArenaOpponentSpecs()`
- `GetArenaOpponentSpec(i)`
- `GetSpecializationInfoByID(specID)`

If prep spec data is not immediately available, it falls back to `UnitClass("arenaX")` and keeps the best-known slot/spec mapping as the match progresses.

## Troubleshooting

### I see no icons in arena

Check the following:

1. The bar is enabled
2. The relevant spells are enabled in that bar
3. Arena visibility is not filtering the spell away
4. You are actually in arena, or Test Mode is enabled

### Automatic tracking misses some spells

That is expected for some abilities. Automatic tracking only works when HandyBar can infer the cooldown from public arena information. Hidden, aura-less, or highly ambiguous spells may still require manual clicks.

If you want to inspect what the tracker is seeing:

1. Enable `Debug Mode`
2. Enter an arena
3. Look for logs such as:
   - `Tracking aura ...`
   - `Generic match ...`
   - `No rule match ...`

### Test Mode turns itself off

This is intentional. Test Mode is runtime-only and is automatically disabled on reloads, zone changes, and real arena entry.

## Important Files

- `HandyBar.toc`: addon metadata and load order
- `Core.lua`: addon setup, DB, slash commands, shared helpers
- `Modules/Bar.lua`: buttons, layout, timers, click handling
- `Modules/Arena.lua`: arena enemy detection and slot/spec mapping
- `Modules/EnemyCooldowns.lua`: automatic enemy cooldown detection
- `Modules/TestMode.lua`: runtime test mode
- `Options.lua`: AceConfig options UI

## Notes

HandyBar ships with Ace3 and MajorCooldowns inside `Libs/`.

Automatic detection is meant to reduce manual workload, not fully replace manual arena awareness. If a spell is not auto-detected, you can still track it immediately with a click.
