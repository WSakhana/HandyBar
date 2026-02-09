# MajorCooldowns

A **LibStub** library for World of Warcraft (Retail) that provides a centralized, queryable registry of major class cooldowns, racials, trinkets, and items — designed to be embedded in any addon.

---

## Table of Contents

- [Project Structure](#project-structure)
- [Installation & Embedding](#installation--embedding)
- [Getting the Library Reference](#getting-the-library-reference)
- [Enums Reference](#enums-reference)
  - [Classes](#classes)
  - [Specs](#specs)
  - [CooldownType](#cooldowntype)
  - [Category](#category)
  - [Priority](#priority)
- [Cooldown Entry Schema](#cooldown-entry-schema)
- [Registration API](#registration-api)
  - [Register()](#registerdatacooldowntype)
  - [RegisterBatch()](#registerbatchlistcooldowntype)
  - [RegisterClassAbility()](#registerclassabilitydata)
  - [RegisterRacial()](#registerracialdata)
- [Query API](#query-api)
  - [GetByKey()](#getbykeykey)
  - [GetBySpellID()](#getbyspellidspellid)
  - [GetByItemID()](#getbyitemiditemid)
  - [GetByClass()](#getbyclassclassid)
  - [GetBySpec()](#getbyspecspecid)
  - [GetApplicable()](#getapplicableclassidspecidcategory)
  - [GetByCategory()](#getbycategorycategory)
  - [GetByPriority()](#getbypriorityminpriorityclassidspecid)
  - [GetDefaultEnabled()](#getdefaultenabledclassidspecid)
  - [GetAll()](#getall)
  - [Count()](#countcooldowntype)
- [Practical Examples](#practical-examples)
- [Adding New Cooldowns](#adding-new-cooldowns)
- [Internal Indices (Debug)](#internal-indices-debug)

---

## Project Structure

```
MajorCooldowns/
├── MajorCooldowns.toc   # Addon TOC (LoadOnDemand library)
├── MajorCooldowns.xml   # Master XML loader (embed this in your addon)
├── Core.lua                  # LibStub init — creates the lib table
├── Enums.lua                 # Classes, Specs, CooldownType, Category, Priority
├── Registry.lua              # Registration + Query API
├── README.md                 # This file
└── Data/
    ├── Data.xml              # XML loader for all class data files
    ├── Warrior.lua
    ├── Paladin.lua
    ├── Priest.lua
    ├── Shaman.lua
    ├── DeathKnight.lua
    ├── DemonHunter.lua
    ├── Mage.lua
    ├── Druid.lua
    ├── Rogue.lua
    ├── Hunter.lua
    ├── Warlock.lua
    ├── Monk.lua
    └── Evoker.lua
```

**Load order** (enforced by `MajorCooldowns.xml`):

1. `Core.lua` — creates the library via LibStub
2. `Enums.lua` — populates enums onto the library table
3. `Registry.lua` — defines registration + query functions
4. `Data/*.lua` — each file calls `RegisterBatch()` to populate cooldowns

---

## Installation & Embedding

Place the `MajorCooldowns` folder inside your addon's `Libs/` directory.

In your addon's `.toc` or `.xml`:

```xml
<Include file="Libs\MajorCooldowns\MajorCooldowns.xml"/>
```

Or in your `.toc` file directly:

```toc
Libs\MajorCooldowns\MajorCooldowns.xml
```

> **Dependency:** Requires [LibStub](https://www.wowace.com/projects/libstub) to be loaded before this library.

---

## Getting the Library Reference

```lua
local MCD = LibStub("MajorCooldowns")
```

All enums, registration functions, and query functions are methods/fields on this `lib` table.

---

## Enums Reference

### Classes

**Access:** `lib.Classes`
**Type:** `table<string, ClassInfo>`

Each entry has:

| Field   | Type     | Description                          |
|---------|----------|--------------------------------------|
| `id`    | `string` | Uppercase class token (e.g. `"WARRIOR"`) |
| `name`  | `string` | Display name (e.g. `"Death Knight"`) |
| `color` | `string` | Hex color code without `#` (e.g. `"C79C6E"`) |

**Available keys:** `WARRIOR`, `PALADIN`, `PRIEST`, `SHAMAN`, `DEATHKNIGHT`, `DEMONHUNTER`, `MAGE`, `DRUID`, `ROGUE`, `HUNTER`, `WARLOCK`, `MONK`, `EVOKER`

```lua
local warriorColor = lib.Classes.WARRIOR.color  -- "C79C6E"
```

### Specs

**Access:** `lib.Specs`
**Type:** `table<string, SpecInfo>`

Each entry has:

| Field   | Type     | Description                        |
|---------|----------|------------------------------------|
| `id`    | `number` | WoW API specialization ID          |
| `class` | `string` | Parent class token                 |
| `name`  | `string` | Display name (e.g. `"Arms"`)       |

**Available keys:**

| Warrior | Paladin | Priest | Mage |
|---|---|---|---|
| `WARRIOR_ARMS` (71) | `PALADIN_HOLY` (65) | `PRIEST_DISC` (256) | `MAGE_ARCANE` (62) |
| `WARRIOR_FURY` (72) | `PALADIN_PROT` (66) | `PRIEST_HOLY` (257) | `MAGE_FIRE` (63) |
| `WARRIOR_PROT` (73) | `PALADIN_RET` (70) | `PRIEST_SHADOW` (258) | `MAGE_FROST` (64) |

| Druid | Rogue | Hunter | Shaman |
|---|---|---|---|
| `DRUID_BALANCE` (102) | `ROGUE_ASSA` (259) | `HUNTER_BM` (253) | `SHAMAN_ELE` (262) |
| `DRUID_FERAL` (103) | `ROGUE_OUTLAW` (260) | `HUNTER_MM` (254) | `SHAMAN_ENH` (263) |
| `DRUID_GUARDIAN` (104) | `ROGUE_SUB` (261) | `HUNTER_SURV` (255) | `SHAMAN_RESTO` (264) |
| `DRUID_RESTO` (105) | | | |

| Warlock | Death Knight | Monk | Demon Hunter | Evoker |
|---|---|---|---|---|
| `WARLOCK_AFF` (265) | `DK_BLOOD` (250) | `MONK_BREW` (268) | `DH_HAVOC` (577) | `EVOKER_DEV` (1467) |
| `WARLOCK_DEMO` (266) | `DK_FROST` (251) | `MONK_WW` (269) | `DH_VENGEANCE` (581) | `EVOKER_PRES` (1468) |
| `WARLOCK_DESTRO` (267) | `DK_UNHOLY` (252) | `MONK_MW` (270) | `DH_DEVOURER` (586) | `EVOKER_AUG` (1473) |

**Reverse lookup by numeric ID:** `lib.SpecByID[specID]` → `SpecInfo`

```lua
local specInfo = lib.SpecByID[71]  -- { id = 71, class = "WARRIOR", name = "Arms" }
```

### CooldownType

**Access:** `lib.CooldownType`

| Key             | Value             | Description                    |
|-----------------|-------------------|--------------------------------|
| `CLASS_ABILITY` | `"CLASS_ABILITY"` | Class/spec spells              |
| `RACIAL`        | `"RACIAL"`        | Racial abilities               |
| `TRINKET`       | `"TRINKET"`       | Trinket on-use effects         |
| `ITEM`          | `"ITEM"`          | Other equippable item effects  |

### Category

**Access:** `lib.Category`

| Key             | Value             |
|-----------------|-------------------|
| `DEFENSIVE`     | `"Defensive"`     |
| `OFFENSIVE`     | `"Offensive"`     |
| `BURST`         | `"Burst"`         |
| `UTILITY`       | `"Utility"`       |
| `HEALING`       | `"Healing"`       |
| `MOVEMENT`      | `"Movement"`      |
| `CROWD_CONTROL` | `"Crowd Control"` |

### Priority

**Access:** `lib.Priority`

| Key         | Value | Intended Use                        |
|-------------|-------|-------------------------------------|
| `CRITICAL`  | 15    | Game-changing CDs (Spirit Link, etc.) |
| `VERY_HIGH` | 12    | Major raid CDs (Rallying Cry, etc.) |
| `HIGH`      | 10    | Important spec CDs                  |
| `MEDIUM`    | 8     | Moderate CDs                        |
| `NORMAL`    | 6     | Minor CDs                           |
| `LOW`       | 4     | Situational / rarely tracked        |

Higher number = higher priority. Use with `GetByPriority()` to filter.

---

## Cooldown Entry Schema

Every registered cooldown is stored as a table with these fields:

| Field            | Type       | Required | Default               | Description |
|------------------|------------|----------|-----------------------|-------------|
| `key`            | `string`   | **Yes**  | —                     | Unique identifier (e.g. `"WAR_RALLY"`) |
| `type`           | `string`   | Auto     | —                     | Set by the registration function (`CooldownType.*`) |
| `class`          | `string`   | *Varies* | `nil`                 | Class token. Required for `CLASS_ABILITY` |
| `specs`          | `number[]` | No       | `{}`                  | Spec IDs this applies to. Empty = all specs of the class |
| `races`          | `string[]` | No       | `{}`                  | Race tokens (for `RACIAL` type) |
| `spellID`        | `number`   | *Varies* | `nil`                 | WoW spell ID |
| `itemID`         | `number`   | *Varies* | `nil`                 | WoW item ID (for `TRINKET`/`ITEM`) |
| `duration`       | `number`   | No       | `nil`                 | Cooldown duration in seconds |
| `category`       | `string`   | No       | `"Utility"`           | One of `lib.Category.*` |
| `priority`       | `number`   | No       | `6` (NORMAL)          | One of `lib.Priority.*` |
| `defaultEnabled` | `boolean`  | No       | `false`               | Whether tracked by default in UI |
| `stack`          | `number`   | No       | `1`                   | Number of charges (>= 1) |
| `name`           | `string`   | No       | `nil`                 | Override display name (otherwise use `GetSpellInfo()`) |
| `icon`           | `string`   | No       | `nil`                 | Override icon texture path |

---

## Registration API

### `Register(data, cooldownType)`

Register a single cooldown of any type. Duplicate keys are silently ignored (returns existing entry).

```lua
lib:Register({
    key      = "MY_CUSTOM_CD",
    class    = "WARRIOR",
    specs    = { 71 },
    spellID  = 12345,
    duration = 120,
    category = lib.Category.BURST,
    priority = lib.Priority.HIGH,
    defaultEnabled = true,
}, lib.CooldownType.CLASS_ABILITY)
```

**Returns:** The registered cooldown entry table.

### `RegisterBatch(list, cooldownType)`

Register multiple cooldowns of the same type at once.

```lua
lib:RegisterBatch({
    { key = "CD_A", class = "MAGE", spellID = 111, duration = 60 },
    { key = "CD_B", class = "MAGE", spellID = 222, duration = 90 },
}, lib.CooldownType.CLASS_ABILITY)
```

### `RegisterClassAbility(data)`

Shorthand for `Register(data, CooldownType.CLASS_ABILITY)`. Backwards-compatible wrapper.

### `RegisterRacial(data)`

Shorthand for `Register(data, CooldownType.RACIAL)`. Backwards-compatible wrapper.

---

## Query API

### `GetByKey(key)`

Look up a single cooldown by its unique string key.

```lua
local cd = lib:GetByKey("WAR_RALLY")
-- cd.spellID == 97462, cd.duration == 180
```

**Returns:** `table|nil`

### `GetBySpellID(spellID)`

Look up a single cooldown by its WoW spell ID.

```lua
local cd = lib:GetBySpellID(97462)
-- cd.key == "WAR_RALLY"
```

**Returns:** `table|nil`

### `GetByItemID(itemID)`

Look up a single cooldown by its WoW item ID (for trinkets/items).

```lua
local cd = lib:GetByItemID(207168)
```

**Returns:** `table|nil`

### `GetByClass(classID)`

Get all cooldowns belonging to a class (all specs, all types).

```lua
local warriorCDs = lib:GetByClass("WARRIOR")
-- Returns array of all Warrior cooldown entries
```

**Params:** `classID` — uppercase class token (e.g. `"WARRIOR"`)
**Returns:** `table[]` (may be empty)

### `GetBySpec(specID)`

Get all cooldowns explicitly registered for a given spec ID. Does **not** include class-wide cooldowns with empty `specs`.

```lua
local armsCDs = lib:GetBySpec(71)
```

**Params:** `specID` — numeric specialization ID
**Returns:** `table[]`

### `GetApplicable(classID, specID [, category])`

Get cooldowns applicable to a class+spec combination. This **includes** class-wide abilities (empty `specs` list) plus spec-specific ones. Only returns `CLASS_ABILITY` type entries. Optional category filter.

```lua
-- All applicable cooldowns for Arms Warrior
local cds = lib:GetApplicable("WARRIOR", 71)

-- Only defensive cooldowns for Arms Warrior
local defensives = lib:GetApplicable("WARRIOR", 71, lib.Category.DEFENSIVE)
```

**Params:**
- `classID` — uppercase class token
- `specID` — numeric spec ID
- `category` *(optional)* — one of `lib.Category.*`

**Returns:** `table[]`

### `GetByCategory(category)`

Get all cooldowns across all classes that match a category.

```lua
local allDefensives = lib:GetByCategory(lib.Category.DEFENSIVE)
```

**Returns:** `table[]`

### `GetByPriority(minPriority [, classID, specID])`

Get cooldowns at or above a priority threshold. Optionally scoped by class and/or spec.

```lua
-- All VERY_HIGH+ cooldowns in the game
local important = lib:GetByPriority(lib.Priority.VERY_HIGH)

-- Only for Resto Shaman
local shamanImportant = lib:GetByPriority(lib.Priority.HIGH, "SHAMAN", 264)
```

**Params:**
- `minPriority` — numeric threshold (inclusive). Use `lib.Priority.*` constants
- `classID` *(optional)* — class filter
- `specID` *(optional)* — spec filter (requires `classID`)

**Returns:** `table[]`

### `GetDefaultEnabled(classID, specID)`

Get cooldowns that are flagged as default-enabled (for UI initial state). Optionally scoped.

```lua
-- Default-on cooldowns for Holy Paladin
local defaults = lib:GetDefaultEnabled("PALADIN", 65)

-- All default-on cooldowns in the library
local allDefaults = lib:GetDefaultEnabled()
```

**Params:** Both optional. If both nil, returns all default-enabled entries.
**Returns:** `table[]`

### `GetAll()`

Returns every registered cooldown across all types.

```lua
local everything = lib:GetAll()
```

**Returns:** `table[]`

### `Count([cooldownType])`

Count registered entries, optionally by type.

```lua
local total = lib:Count()                              -- all entries
local classCount = lib:Count(lib.CooldownType.CLASS_ABILITY) -- only class abilities
```

**Returns:** `number`

---

## Practical Examples

### Build a cooldown tracker for the current player

```lua
local MCD = LibStub("MajorCooldowns")

local _, playerClass = UnitClass("player")
local specID = GetSpecializationInfo(GetSpecialization())

-- Get all trackable cooldowns for this player
local myCooldowns = MCD:GetApplicable(playerClass, specID)

for _, cd in ipairs(myCooldowns) do
    local name = cd.name or GetSpellInfo(cd.spellID)
    print(string.format("[%s] %s — %ds CD (priority %d)",
        cd.category, name, cd.duration, cd.priority))
end
```

### Show only high-priority defensives in a raid frame

```lua
local MCD = LibStub("MajorCooldowns")

local importantDefensives = {}
for _, cd in ipairs(MCD:GetByCategory(MCD.Category.DEFENSIVE)) do
    if cd.priority >= MCD.Priority.HIGH then
        importantDefensives[cd.spellID] = cd
    end
end

-- In your COMBAT_LOG_EVENT handler:
-- if importantDefensives[spellID] then ... show icon ... end
```

### Color a player name by class

```lua
local MCD = LibStub("MajorCooldowns")
local classInfo = MCD.Classes["PALADIN"]
local colored = string.format("|cff%s%s|r", classInfo.color, "Playername")
```

### Resolve spec name from ID at runtime

```lua
local MCD = LibStub("MajorCooldowns")
local spec = MCD.SpecByID[264]  -- Restoration Shaman
print(spec.name)   -- "Restoration"
print(spec.class)  -- "SHAMAN"
```

### Register a custom trinket from your addon

```lua
local MCD = LibStub("MajorCooldowns")

MCD:Register({
    key      = "TRINKET_NYMUES_CORE",
    itemID   = 208614,
    spellID  = 422146,
    duration = 120,
    category = MCD.Category.BURST,
    priority = MCD.Priority.HIGH,
    defaultEnabled = true,
    name     = "Nymue's Unraveling Spindle",
}, MCD.CooldownType.TRINKET)
```

---

## Adding New Cooldowns

### Add a new spell to an existing class

1. Open the corresponding file in `Data/` (e.g. `Data/Warrior.lua`)
2. Add a new entry to the `RegisterBatch` array:

```lua
{
    key      = "WAR_NEW_ABILITY",     -- unique key (PREFIX_DESCRIPTION)
    class    = "WARRIOR",             -- must match lib.Classes key
    specs    = { S.WARRIOR_FURY.id }, -- empty {} = all specs
    spellID  = 999999,                -- WoW spell ID
    duration = 120,                   -- cooldown in seconds
    category = C.BURST,               -- lib.Category.*
    priority = P.HIGH,                -- lib.Priority.*
    defaultEnabled = true,            -- tracked by default?
    -- stack = 2,                     -- optional: charges
},
```

### Add a new class (future expansion)

1. Add the class to `lib.Classes` in `Enums.lua`
2. Add specs to `lib.Specs` in `Enums.lua`
3. Create `Data/NewClass.lua` following the same pattern
4. Add `<Script file="NewClass.lua"/>` to `Data/Data.xml`

### Key naming convention

Use the pattern: `PREFIX_ABILITY_NAME`

| Class | Prefix | Class | Prefix |
|---|---|---|---|
| Warrior | `WAR_` | Hunter | `HUN_` |
| Paladin | `PAL_` | Warlock | `WL_` |
| Priest | `PRI_` | Monk | `MNK_` |
| Shaman | `SHA_` | Demon Hunter | `DH_` |
| Death Knight | `DK_` | Evoker | `EVO_` |
| Mage | `MAG_` | Druid | `DRU_` |
| Rogue | `ROG_` | | |

---

## Internal Indices (Debug)

These are exposed on the lib table for debugging. **Do not mutate directly.**

| Field        | Type                          | Description                      |
|--------------|-------------------------------|----------------------------------|
| `lib.registry`  | `table<CooldownType, table[]>` | Raw storage buckets by type |
| `lib._idxKey`   | `table<string, table>`         | Key → cooldown entry       |
| `lib._idxClass` | `table<string, table[]>`       | ClassID → cooldown entries |
| `lib._idxSpec`  | `table<number, table[]>`       | SpecID → cooldown entries  |
| `lib._idxSpell` | `table<number, table>`         | SpellID → cooldown entry   |
| `lib._idxItem`  | `table<number, table>`         | ItemID → cooldown entry    |

---

## Pre-registered Cooldowns Summary

The library ships with cooldowns for all 13 classes (39 specs). Below is the count per class:

| Class | Count | Class | Count |
|---|---|---|---|
| Warrior | 7 | Hunter | 5 |
| Paladin | 7 | Warlock | 5 |
| Priest | 5 | Monk | 6 |
| Shaman | 5 | Demon Hunter | 4 |
| Death Knight | 6 | Evoker | 4 |
| Mage | 6 | | |
| Druid | 7 | | |
| Rogue | 7 | **Total** | **~79** |

---

*Library version: 2 · Interface: 11.1.0 (Retail)*
