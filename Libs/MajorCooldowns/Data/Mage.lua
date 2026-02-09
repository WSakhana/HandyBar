-- ============================================================================
-- MajorCooldowns | Data > Mage
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

local S = lib.Specs
local C = lib.Category
local P = lib.Priority

lib:RegisterBatch({
    {
        key      = "MAG_ICEBLOCK",
        class    = "MAGE",
        specs    = {},
        spellID  = 45438,
        duration = 240,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "MAG_COMBUST",
        class    = "MAGE",
        specs    = { S.MAGE_FIRE.id },
        spellID  = 190319,
        duration = 120,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "MAG_ICYVEINS",
        class    = "MAGE",
        specs    = { S.MAGE_FROST.id },
        spellID  = 12472,
        duration = 180,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "MAG_ARCANE_SURGE",
        class    = "MAGE",
        specs    = { S.MAGE_ARCANE.id },
        spellID  = 365362,
        duration = 90,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "MAG_ARCANE_POWER",
        class    = "MAGE",
        specs    = { S.MAGE_ARCANE.id },
        spellID  = 12042,
        duration = 90,
        category = C.BURST,
        priority = P.MEDIUM,
        defaultEnabled = false,
    },
    {
        key      = "MAG_TEMPORAL",
        class    = "MAGE",
        specs    = {},
        spellID  = 198111,
        duration = 45,
        category = C.DEFENSIVE,
        priority = P.NORMAL,
        defaultEnabled = false,
    },
}, lib.CooldownType.CLASS_ABILITY)
