-- ============================================================================
-- MajorCooldowns | Data > Rogue
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

local S = lib.Specs
local C = lib.Category
local P = lib.Priority

lib:RegisterBatch({
    {
        key      = "ROG_CLOAK",
        class    = "ROGUE",
        specs    = {},
        spellID  = 31224,
        duration = 60,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "ROG_CHEAT_DEATH",
        class    = "ROGUE",
        specs    = {},
        spellID  = 31230,
        duration = 360,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "ROG_EVASION",
        class    = "ROGUE",
        specs    = {},
        spellID  = 5277,
        duration = 120,
        category = C.DEFENSIVE,
        priority = P.MEDIUM,
        defaultEnabled = true,
    },
    {
        key      = "ROG_VANISH",
        class    = "ROGUE",
        specs    = {},
        spellID  = 1856,
        duration = 120,
        category = C.UTILITY,
        priority = P.MEDIUM,
        defaultEnabled = true,
    },
    {
        key      = "ROG_SHADOW_BLADES",
        class    = "ROGUE",
        specs    = { S.ROGUE_SUB.id },
        spellID  = 121471,
        duration = 180,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "ROG_DEATHMARK",
        class    = "ROGUE",
        specs    = { S.ROGUE_ASSA.id },
        spellID  = 360194,
        duration = 120,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "ROG_SMOKE_BOMB",
        class    = "ROGUE",
        specs    = {},
        spellID  = 212182,
        duration = 180,
        category = C.UTILITY,
        priority = P.HIGH,
        defaultEnabled = true,
    },
}, lib.CooldownType.CLASS_ABILITY)
