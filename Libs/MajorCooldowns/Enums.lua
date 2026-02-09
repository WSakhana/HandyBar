-- ============================================================================
-- MajorCooldowns | Enums
-- Class, Spec, CooldownType, Category, and Priority definitions.
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

-- ---------------------------------------------------------------------------
-- Classes
-- ---------------------------------------------------------------------------

---@class ClassInfo
---@field id string
---@field name string
---@field color string  Hex color code (no leading #)

---@type table<string, ClassInfo>
lib.Classes = {
    WARRIOR     = { id = "WARRIOR",     name = "Warrior",      color = "C79C6E" },
    PALADIN     = { id = "PALADIN",     name = "Paladin",      color = "F58CBA" },
    PRIEST      = { id = "PRIEST",      name = "Priest",       color = "FFFFFF" },
    SHAMAN      = { id = "SHAMAN",      name = "Shaman",       color = "0070DE" },
    DEATHKNIGHT = { id = "DEATHKNIGHT", name = "Death Knight",  color = "C41F3B" },
    DEMONHUNTER = { id = "DEMONHUNTER", name = "Demon Hunter",  color = "A330C9" },
    MAGE        = { id = "MAGE",        name = "Mage",         color = "40C7EB" },
    DRUID       = { id = "DRUID",       name = "Druid",        color = "FF7D0A" },
    ROGUE       = { id = "ROGUE",       name = "Rogue",        color = "FFF569" },
    HUNTER      = { id = "HUNTER",      name = "Hunter",       color = "A9D271" },
    WARLOCK     = { id = "WARLOCK",     name = "Warlock",      color = "8787ED" },
    MONK        = { id = "MONK",        name = "Monk",         color = "00FF96" },
    EVOKER      = { id = "EVOKER",      name = "Evoker",       color = "33937F" },
}

-- ---------------------------------------------------------------------------
-- Specs
-- ---------------------------------------------------------------------------

---@class SpecInfo
---@field id number   Specialization ID used by the WoW API
---@field class string  Parent class identifier
---@field name string   Display name

---@type table<string, SpecInfo>
lib.Specs = {
    -- Warrior
    WARRIOR_ARMS = { id = 71,   class = "WARRIOR",     name = "Arms" },
    WARRIOR_FURY = { id = 72,   class = "WARRIOR",     name = "Fury" },
    WARRIOR_PROT = { id = 73,   class = "WARRIOR",     name = "Protection" },
    -- Paladin
    PALADIN_HOLY = { id = 65,   class = "PALADIN",     name = "Holy" },
    PALADIN_PROT = { id = 66,   class = "PALADIN",     name = "Protection" },
    PALADIN_RET  = { id = 70,   class = "PALADIN",     name = "Retribution" },
    -- Priest
    PRIEST_DISC   = { id = 256, class = "PRIEST",      name = "Discipline" },
    PRIEST_HOLY   = { id = 257, class = "PRIEST",      name = "Holy" },
    PRIEST_SHADOW = { id = 258, class = "PRIEST",      name = "Shadow" },
    -- Mage
    MAGE_ARCANE = { id = 62,    class = "MAGE",        name = "Arcane" },
    MAGE_FIRE   = { id = 63,    class = "MAGE",        name = "Fire" },
    MAGE_FROST  = { id = 64,    class = "MAGE",        name = "Frost" },
    -- Druid
    DRUID_BALANCE  = { id = 102, class = "DRUID",      name = "Balance" },
    DRUID_FERAL    = { id = 103, class = "DRUID",      name = "Feral" },
    DRUID_GUARDIAN = { id = 104, class = "DRUID",      name = "Guardian" },
    DRUID_RESTO    = { id = 105, class = "DRUID",      name = "Restoration" },
    -- Rogue
    ROGUE_ASSA   = { id = 259,  class = "ROGUE",       name = "Assassination" },
    ROGUE_OUTLAW = { id = 260,  class = "ROGUE",       name = "Outlaw" },
    ROGUE_SUB    = { id = 261,  class = "ROGUE",       name = "Subtlety" },
    -- Hunter
    HUNTER_BM   = { id = 253,   class = "HUNTER",      name = "Beast Mastery" },
    HUNTER_MM   = { id = 254,   class = "HUNTER",      name = "Marksmanship" },
    HUNTER_SURV = { id = 255,   class = "HUNTER",      name = "Survival" },
    -- Shaman
    SHAMAN_ELE   = { id = 262,  class = "SHAMAN",      name = "Elemental" },
    SHAMAN_ENH   = { id = 263,  class = "SHAMAN",      name = "Enhancement" },
    SHAMAN_RESTO = { id = 264,  class = "SHAMAN",      name = "Restoration" },
    -- Warlock
    WARLOCK_AFF    = { id = 265, class = "WARLOCK",    name = "Affliction" },
    WARLOCK_DEMO   = { id = 266, class = "WARLOCK",    name = "Demonology" },
    WARLOCK_DESTRO = { id = 267, class = "WARLOCK",    name = "Destruction" },
    -- Death Knight
    DK_BLOOD  = { id = 250,     class = "DEATHKNIGHT", name = "Blood" },
    DK_FROST  = { id = 251,     class = "DEATHKNIGHT", name = "Frost" },
    DK_UNHOLY = { id = 252,     class = "DEATHKNIGHT", name = "Unholy" },
    -- Monk
    MONK_BREW = { id = 268,     class = "MONK",        name = "Brewmaster" },
    MONK_WW   = { id = 269,     class = "MONK",        name = "Windwalker" },
    MONK_MW   = { id = 270,     class = "MONK",        name = "Mistweaver" },
    -- Demon Hunter
    DH_HAVOC     = { id = 577,  class = "DEMONHUNTER", name = "Havoc" },
    DH_VENGEANCE = { id = 581,  class = "DEMONHUNTER", name = "Vengeance" },
    DH_DEVOURER  = { id = 586,  class = "DEMONHUNTER", name = "Devourer" },
    -- Evoker
    EVOKER_DEV  = { id = 1467,  class = "EVOKER",      name = "Devastation" },
    EVOKER_PRES = { id = 1468,  class = "EVOKER",      name = "Preservation" },
    EVOKER_AUG  = { id = 1473,  class = "EVOKER",      name = "Augmentation" },
}

-- Reverse lookup: specID (number) -> SpecInfo
---@type table<number, SpecInfo>
lib.SpecByID = {}
for _, spec in pairs(lib.Specs) do
    lib.SpecByID[spec.id] = spec
end

-- ---------------------------------------------------------------------------
-- Cooldown Type
-- ---------------------------------------------------------------------------

lib.CooldownType = {
    CLASS_ABILITY = "CLASS_ABILITY",
    RACIAL        = "RACIAL",
    TRINKET       = "TRINKET",
    ITEM          = "ITEM",
}

-- ---------------------------------------------------------------------------
-- Category
-- ---------------------------------------------------------------------------

lib.Category = {
    DEFENSIVE     = "Defensive",
    OFFENSIVE     = "Offensive",
    BURST         = "Burst",
    UTILITY       = "Utility",
    HEALING       = "Healing",
    MOVEMENT      = "Movement",
    CROWD_CONTROL = "Crowd Control",
}

-- ---------------------------------------------------------------------------
-- Priority
-- ---------------------------------------------------------------------------

lib.Priority = {
    CRITICAL  = 15,
    VERY_HIGH = 12,
    HIGH      = 10,
    MEDIUM    = 8,
    NORMAL    = 6,
    LOW       = 4,
}
