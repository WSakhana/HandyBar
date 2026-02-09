-- ============================================================================
-- MajorCooldowns | Data > Hunter
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

local S = lib.Specs
local C = lib.Category
local P = lib.Priority

lib:RegisterBatch({
    {
        key      = "HUN_TURTLE",
        class    = "HUNTER",
        specs    = {},
        spellID  = 186265,
        duration = 180,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "HUN_WILD",
        class    = "HUNTER",
        specs    = { S.HUNTER_BM.id },
        spellID  = 193530,
        duration = 120,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "HUN_COOR_ASSAULT",
        class    = "HUNTER",
        specs    = { S.HUNTER_SURV.id },
        spellID  = 266779,
        duration = 120,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "HUN_TRUESHOT",
        class    = "HUNTER",
        specs    = { S.HUNTER_MM.id },
        spellID  = 288613,
        duration = 120,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "HUN_EXHIL",
        class    = "HUNTER",
        specs    = {},
        spellID  = 109304,
        duration = 120,
        category = C.DEFENSIVE,
        priority = P.NORMAL,
        defaultEnabled = false,
    },
}, lib.CooldownType.CLASS_ABILITY)
