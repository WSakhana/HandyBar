# Changelog - HandyBar

All notable changes for HandyBar are documented here.

## 1.1.1 (2026-02-10)

### Changed

- Release packaging polish (CurseForge): TOC metadata cleanup and updated `Notes-frFR` text
- Debug: standardized output via `HB:Print()` (instead of direct `print()`)
- Robustness: Test Mode is forcibly disabled on `ZONE_CHANGED_NEW_AREA` (never persists through zone changes)

## 1.1.0 (Production Launch)

### Added

- Manual-first enemy cooldown tracking for PvP Arenas (click an icon when you see the spell used)
- Configurable spell bars: icon size, spacing, grow direction, wrapping (`Max Icons Per Row`), and display limits
- Arena-only visibility, with a runtime Test Mode for layout/configuration outside arenas
- Arena opponent detection using the Retail prep API (`ARENA_PREP_OPPONENT_SPECIALIZATIONS`), with `UnitClass("arenaX")` fallback
- Per-bar visibility targeting: `All Enemies` or a specific slot (`Arena1` / `Arena2` / `Arena3`)
- Optional duplication of the same class/spec entries to track multiple opponents sharing a class/spec
- Cooldown spiral + optional remaining-time text (with urgency coloring)
- Optional class-colored icon borders
- Support for charge-based abilities (stack/charges) with per-charge recharge timers
- Global cooldown duration overrides (applies across all bars)
- Custom spell registration by Spell ID (integrated into the spell selection UI)
- Profiles support via AceDB (Blizzard Profiles panel)
- Slash commands: `/hb`, `/hb test`, `/hb lock`, `/hb reset`

### Localization

- English (`enUS`) and French (`frFR`)
