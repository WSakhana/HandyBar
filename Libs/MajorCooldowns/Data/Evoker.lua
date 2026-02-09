-- ============================================================================
-- MajorCooldowns | Data > Evoker
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

local S = lib.Specs
local C = lib.Category
local P = lib.Priority

lib:RegisterBatch({
    {
        key      = "EVO_DRAGONRAGE",
        class    = "EVOKER",
        specs    = { S.EVOKER_DEV.id },
        spellID  = 375087,
        duration = 120,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "EVO_STASIS",
        class    = "EVOKER",
        specs    = { S.EVOKER_PRES.id },
        spellID  = 370537,
        duration = 90,
        category = C.UTILITY,
        priority = P.MEDIUM,
        defaultEnabled = true,
    },
    {
        key      = "EVO_REWIND",
        class    = "EVOKER",
        specs    = { S.EVOKER_PRES.id },
        spellID  = 363534,
        duration = 240,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "EVO_DREAMFLIGHT",
        class    = "EVOKER",
        specs    = { S.EVOKER_PRES.id },
        spellID  = 359816,
        duration = 120,
        category = C.UTILITY,
        priority = P.HIGH,
        defaultEnabled = true,
    },
}, lib.CooldownType.CLASS_ABILITY)
