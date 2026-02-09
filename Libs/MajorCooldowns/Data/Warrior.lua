-- ============================================================================
-- MajorCooldowns | Data > Warrior
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

local S = lib.Specs
local C = lib.Category
local P = lib.Priority

lib:RegisterBatch({
    {
        key      = "WAR_RALLY",
        class    = "WARRIOR",
        specs    = {},
        spellID  = 97462,
        duration = 180,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "WAR_DIE_SWORD",
        class    = "WARRIOR",
        specs    = { S.WARRIOR_ARMS.id },
        spellID  = 118038,
        duration = 120,
        category = C.DEFENSIVE,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "WAR_WALL",
        class    = "WARRIOR",
        specs    = { S.WARRIOR_PROT.id },
        spellID  = 871,
        duration = 240,
        category = C.DEFENSIVE,
        priority = P.VERY_HIGH,
        defaultEnabled = true,
    },
    {
        key      = "WAR_LAST_STAND",
        class    = "WARRIOR",
        specs    = { S.WARRIOR_PROT.id },
        spellID  = 12975,
        duration = 180,
        category = C.DEFENSIVE,
        priority = P.HIGH,
        defaultEnabled = true,
    },
    {
        key      = "WAR_AVATAR",
        class    = "WARRIOR",
        specs    = { S.WARRIOR_ARMS.id },
        spellID  = 107574,
        duration = 90,
        category = C.BURST,
        priority = P.MEDIUM,
        defaultEnabled = true,
    },
    {
        key      = "WAR_BLADESTORM",
        class    = "WARRIOR",
        specs    = { S.WARRIOR_ARMS.id },
        spellID  = 227847,
        duration = 60,
        category = C.BURST,
        priority = P.MEDIUM,
        defaultEnabled = false,
    },
    {
        key      = "WAR_RECK",
        class    = "WARRIOR",
        specs    = { S.WARRIOR_FURY.id },
        spellID  = 1719,
        duration = 90,
        category = C.BURST,
        priority = P.HIGH,
        defaultEnabled = true,
    },
}, lib.CooldownType.CLASS_ABILITY)
