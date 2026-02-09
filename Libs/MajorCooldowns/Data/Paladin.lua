-- ============================================================================
-- MajorCooldowns | Data > Paladin
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

local S = lib.Specs
local C = lib.Category
local P = lib.Priority

lib:RegisterBatch({
    {
        key      = "PAL_BUBBLE",
        class    = "PALADIN",
        specs    = {},
        spellID  = 642,
        duration = 300,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "PAL_BOP",
        class    = "PALADIN",
        specs    = {},
        spellID  = 1022,
        duration = 300,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "PAL_AURA_MASTERY",
        class    = "PALADIN",
        specs    = { S.PALADIN_HOLY.id },
        spellID  = 31821,
        duration = 180,
        category = C.UTILITY,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "PAL_GUARDIAN",
        class    = "PALADIN",
        specs    = { S.PALADIN_PROT.id },
        spellID  = 86659,
        duration = 300,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "PAL_ARDENT",
        class    = "PALADIN",
        specs    = { S.PALADIN_PROT.id },
        spellID  = 31850,
        duration = 120,
        category = C.DEFENSIVE,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "PAL_AW",
        class    = "PALADIN",
        specs    = { S.PALADIN_RET.id },
        spellID  = 31884,
        duration = 120,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = false,
    },
    {
        key      = "PAL_LOH",
        class    = "PALADIN",
        specs    = {},
        spellID  = 633,
        duration = 600,
        category = C.UTILITY,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
}, lib.CooldownType.CLASS_ABILITY)
