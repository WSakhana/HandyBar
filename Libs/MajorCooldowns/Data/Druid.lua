-- ============================================================================
-- MajorCooldowns | Data > Druid
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

local S = lib.Specs
local C = lib.Category
local P = lib.Priority

lib:RegisterBatch({
    {
        key      = "DRU_BARKSKIN",
        class    = "DRUID",
        specs    = {},
        spellID  = 22812,
        duration = 60,
        category = C.DEFENSIVE,
        priority = P.NORMAL,
        defaultEnabled = true,
    },
    {
        key      = "DRU_SURVIVAL",
        class    = "DRUID",
        specs    = { S.DRUID_FERAL.id, S.DRUID_GUARDIAN.id },
        spellID  = 61336,
        duration = 180,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "DRU_INCARN_TREE",
        class    = "DRUID",
        specs    = { S.DRUID_RESTO.id },
        spellID  = 33891,
        duration = 180,
        category = C.BURST,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "DRU_INCARN_FERAL",
        class    = "DRUID",
        specs    = { S.DRUID_FERAL.id },
        spellID  = 102543,
        duration = 180,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "DRU_INCARN_BALANCE",
        class    = "DRUID",
        specs    = { S.DRUID_BALANCE.id },
        spellID  = 102560,
        duration = 180,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "DRU_TRANQ",
        class    = "DRUID",
        specs    = { S.DRUID_RESTO.id },
        spellID  = 740,
        duration = 180,
        category = C.UTILITY,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "DRU_RENEWAL",
        class    = "DRUID",
        specs    = {},
        spellID  = 108238,
        duration = 90,
        category = C.DEFENSIVE,
        priority = P.LOW,
        defaultEnabled = false,
    },
}, lib.CooldownType.CLASS_ABILITY)
