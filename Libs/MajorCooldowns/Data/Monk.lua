-- ============================================================================
-- MajorCooldowns | Data > Monk
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

local S = lib.Specs
local C = lib.Category
local P = lib.Priority

lib:RegisterBatch({
    {
        key      = "MNK_DAMPEN",
        class    = "MONK",
        specs    = {},
        spellID  = 122278,
        duration = 120,
        category = C.DEFENSIVE,
        priority = P.MEDIUM,
        defaultEnabled = true,
    },
    {
        key      = "MNK_DIFFUSE",
        class    = "MONK",
        specs    = {},
        spellID  = 122783,
        duration = 90,
        category = C.DEFENSIVE,
        priority = P.MEDIUM,
        defaultEnabled = true,
    },
    {
        key      = "MNK_TOD",
        class    = "MONK",
        specs    = { S.MONK_WW.id, S.MONK_BREW.id },
        spellID  = 115080,
        duration = 180,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = false,
    },
    {
        key      = "MNK_FORT",
        class    = "MONK",
        specs    = { S.MONK_BREW.id },
        spellID  = 115203,
        duration = 420,
        category = C.DEFENSIVE,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "MNK_XUEN",
        class    = "MONK",
        specs    = { S.MONK_WW.id },
        spellID  = 123904,
        duration = 120,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "MNK_REVIVAL",
        class    = "MONK",
        specs    = { S.MONK_MW.id },
        spellID  = 115310,
        duration = 180,
        category = C.UTILITY,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
}, lib.CooldownType.CLASS_ABILITY)
