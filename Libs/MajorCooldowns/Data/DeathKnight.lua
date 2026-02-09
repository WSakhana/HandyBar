-- ============================================================================
-- MajorCooldowns | Data > Death Knight
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

local S = lib.Specs
local C = lib.Category
local P = lib.Priority

lib:RegisterBatch({
    {
        key      = "DK_IBF",
        class    = "DEATHKNIGHT",
        specs    = {},
        spellID  = 48792,
        duration = 180,
        category = C.DEFENSIVE,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "DK_VAMP_BLOOD",
        class    = "DEATHKNIGHT",
        specs    = { S.DK_BLOOD.id },
        spellID  = 55233,
        duration = 90,
        category = C.DEFENSIVE,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "DK_DRW",
        class    = "DEATHKNIGHT",
        specs    = { S.DK_BLOOD.id },
        spellID  = 49028,
        duration = 120,
        category = C.DEFENSIVE,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "DK_PILLAR",
        class    = "DEATHKNIGHT",
        specs    = { S.DK_FROST.id },
        spellID  = 51271,
        duration = 60,
        category = C.BURST,
        priority = P.MEDIUM,
        defaultEnabled = true,
    },
    {
        key      = "DK_APOCALYPSE",
        class    = "DEATHKNIGHT",
        specs    = { S.DK_UNHOLY.id },
        spellID  = 275699,
        duration = 90,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = false,
    },
    {
        key      = "DK_ZONE",
        class    = "DEATHKNIGHT",
        specs    = {},
        spellID  = 51052,
        duration = 120,
        category = C.DEFENSIVE,
        priority = P.HIGH,
        defaultEnabled = true,
    },
}, lib.CooldownType.CLASS_ABILITY)
