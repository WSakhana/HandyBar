-- ============================================================================
-- MajorCooldowns | Data > Demon Hunter
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

local S = lib.Specs
local C = lib.Category
local P = lib.Priority

lib:RegisterBatch({
    {
        key      = "DH_DARKNESS",
        class    = "DEMONHUNTER",
        specs    = { S.DH_HAVOC.id },
        spellID  = 196718,
        duration = 180,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "DH_NETHER",
        class    = "DEMONHUNTER",
        specs    = { S.DH_HAVOC.id, S.DH_DEVOURER.id },
        spellID  = 196555,
        duration = 180,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "DH_META",
        class    = "DEMONHUNTER",
        specs    = { S.DH_HAVOC.id, S.DH_DEVOURER.id },
        spellID  = 187827,
        duration = 240,
        category = C.BURST,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "DH_SPIKES",
        class    = "DEMONHUNTER",
        specs    = { S.DH_VENGEANCE.id },
        spellID  = 203720,
        duration = 40,
        category = C.DEFENSIVE,
        priority = P.NORMAL,
        defaultEnabled = true,
    },
}, lib.CooldownType.CLASS_ABILITY)
