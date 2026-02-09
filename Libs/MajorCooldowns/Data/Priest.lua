-- ============================================================================
-- MajorCooldowns | Data > Priest
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

local S = lib.Specs
local C = lib.Category
local P = lib.Priority

lib:RegisterBatch({
    {
        key      = "PRI_PAIN_SUP",
        class    = "PRIEST",
        specs    = { S.PRIEST_DISC.id },
        spellID  = 33206,
        duration = 180,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
        stack    = 2,
    },
    {
        key      = "PRI_BARRIER",
        class    = "PRIEST",
        specs    = { S.PRIEST_DISC.id },
        spellID  = 62618,
        duration = 180,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "PRI_DIVINE_HYMN",
        class    = "PRIEST",
        specs    = { S.PRIEST_HOLY.id },
        spellID  = 64843,
        duration = 180,
        category = C.UTILITY,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "PRI_VAMP_EMBRACE",
        class    = "PRIEST",
        specs    = { S.PRIEST_SHADOW.id },
        spellID  = 15286,
        duration = 75,
        category = C.UTILITY,
        priority = P.MEDIUM,
        defaultEnabled = false,
    },
    {
        key      = "PRI_PI",
        class    = "PRIEST",
        specs    = {},
        spellID  = 10060,
        duration = 120,
        category = C.UTILITY,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
}, lib.CooldownType.CLASS_ABILITY)
