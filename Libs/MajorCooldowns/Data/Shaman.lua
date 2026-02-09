-- ============================================================================
-- MajorCooldowns | Data > Shaman
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

local S = lib.Specs
local C = lib.Category
local P = lib.Priority

lib:RegisterBatch({
    {
        key      = "SHA_LINK",
        class    = "SHAMAN",
        specs    = { S.SHAMAN_RESTO.id },
        spellID  = 98008,
        duration = 180,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "SHA_HEALING_TIDE",
        class    = "SHAMAN",
        specs    = { S.SHAMAN_RESTO.id },
        spellID  = 108280,
        duration = 180,
        category = C.UTILITY,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "SHA_ASC_RESTO",
        class    = "SHAMAN",
        specs    = { S.SHAMAN_RESTO.id },
        spellID  = 114052,
        duration = 180,
        category = C.BURST,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "SHA_ASC_ELE",
        class    = "SHAMAN",
        specs    = { S.SHAMAN_ELE.id },
        spellID  = 114051,
        duration = 180,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "SHA_FERAL_SPIRIT",
        class    = "SHAMAN",
        specs    = { S.SHAMAN_ENH.id },
        spellID  = 51533,
        duration = 90,
        category = C.BURST,
        priority = P.MEDIUM,
        defaultEnabled = false,
    },
}, lib.CooldownType.CLASS_ABILITY)
