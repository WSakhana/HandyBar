-- ============================================================================
-- MajorCooldowns | Data > Warlock
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

local S = lib.Specs
local C = lib.Category
local P = lib.Priority

lib:RegisterBatch({
    {
        key      = "WL_UNENDING",
        class    = "WARLOCK",
        specs    = {},
        spellID  = 104773,
        duration = 180,
        category = C.DEFENSIVE,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "WL_DARKSOUL",
        class    = "WARLOCK",
        specs    = { S.WARLOCK_AFF.id },
        spellID  = 113860,
        duration = 120,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "WL_DARKGLARE",
        class    = "WARLOCK",
        specs    = { S.WARLOCK_AFF.id },
        spellID  = 205180,
        duration = 180,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = false,
    },
    {
        key      = "WL_TYRANT",
        class    = "WARLOCK",
        specs    = { S.WARLOCK_DEMO.id },
        spellID  = 265187,
        duration = 90,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "WL_INFERNAL",
        class    = "WARLOCK",
        specs    = { S.WARLOCK_DESTRO.id },
        spellID  = 1122,
        duration = 180,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
}, lib.CooldownType.CLASS_ABILITY)
