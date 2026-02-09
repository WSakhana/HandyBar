-- ============================================================================
-- MajorCooldowns | Registry
-- Registration, indexing, and query API for cooldown entries.
-- ============================================================================

local lib = LibStub:GetLibrary("MajorCooldowns", true)
if not lib then return end

-- ---------------------------------------------------------------------------
-- Internal Storage
-- ---------------------------------------------------------------------------

local CooldownType = lib.CooldownType

local registry = lib.registry or {
    [CooldownType.CLASS_ABILITY] = {},
    [CooldownType.RACIAL]       = {},
    [CooldownType.TRINKET]      = {},
    [CooldownType.ITEM]         = {},
}
lib.registry = registry

-- Indices
local byKey     = lib._idxKey     or {}
local byClass   = lib._idxClass   or {}
local bySpec    = lib._idxSpec    or {}
local bySpellID = lib._idxSpell   or {}
local byItemID  = lib._idxItem    or {}

lib._idxKey   = byKey
lib._idxClass = byClass
lib._idxSpec  = bySpec
lib._idxSpell = bySpellID
lib._idxItem  = byItemID

-- ---------------------------------------------------------------------------
-- Validation
-- ---------------------------------------------------------------------------

local validators = {
    [CooldownType.CLASS_ABILITY] = function(d)
        assert(d.class,   "CLASS_ABILITY requires 'class'")
        assert(d.spellID, "CLASS_ABILITY requires 'spellID'")
    end,
    [CooldownType.RACIAL] = function(d)
        assert(d.spellID, "RACIAL requires 'spellID'")
    end,
    [CooldownType.TRINKET] = function(d)
        assert(d.itemID or d.spellID, "TRINKET requires 'itemID' or 'spellID'")
    end,
    [CooldownType.ITEM] = function(d)
        assert(d.itemID or d.spellID, "ITEM requires 'itemID' or 'spellID'")
    end,
}

local function validate(data, cdType)
    assert(data.key, "Cooldown entry must have a unique 'key'")
    assert(validators[cdType], "Unknown cooldownType: " .. tostring(cdType))

    if data.stack ~= nil then
        assert(type(data.stack) == "number" and data.stack >= 1,
            "stack must be a number >= 1")
    end

    validators[cdType](data)
end

-- ---------------------------------------------------------------------------
-- Indexing
-- ---------------------------------------------------------------------------

local function indexCooldown(cd)
    byKey[cd.key] = cd

    if cd.class then
        byClass[cd.class] = byClass[cd.class] or {}
        byClass[cd.class][#byClass[cd.class] + 1] = cd
    end

    if cd.specs then
        for i = 1, #cd.specs do
            local sid = cd.specs[i]
            bySpec[sid] = bySpec[sid] or {}
            bySpec[sid][#bySpec[sid] + 1] = cd
        end
    end

    if cd.spellID then
        bySpellID[cd.spellID] = cd
    end

    if cd.itemID then
        byItemID[cd.itemID] = cd
    end
end

-- ---------------------------------------------------------------------------
-- Entry Builder
-- ---------------------------------------------------------------------------

local function buildEntry(data, cdType)
    return {
        key            = data.key,
        type           = cdType,
        class          = data.class,
        specs          = data.specs          or {},
        races          = data.races          or {},
        spellID        = data.spellID,
        itemID         = data.itemID,
        duration       = data.duration,
        category       = data.category       or lib.Category.UTILITY,
        priority       = data.priority       or lib.Priority.NORMAL,
        defaultEnabled = data.defaultEnabled or false,
        stack          = data.stack          or 1,
        name           = data.name,
        icon           = data.icon,
    }
end

-- ===========================================================================
-- REGISTRATION API
-- ===========================================================================

--- Register a single cooldown entry.
---@param data table          Cooldown definition table
---@param cooldownType string One of lib.CooldownType.*
---@return table              The registered (or existing) cooldown entry
function lib:Register(data, cooldownType)
    if byKey[data.key] then return byKey[data.key] end

    validate(data, cooldownType)

    local cd = buildEntry(data, cooldownType)
    local bucket = registry[cooldownType]
    bucket[#bucket + 1] = cd
    indexCooldown(cd)
    return cd
end

--- Register a batch of cooldowns of the same type.
---@param list table[]        Array of cooldown definition tables
---@param cooldownType string One of lib.CooldownType.*
function lib:RegisterBatch(list, cooldownType)
    for i = 1, #list do
        self:Register(list[i], cooldownType)
    end
end

-- Convenience wrappers (backwards-compat)
function lib:RegisterClassAbility(data)
    return self:Register(data, CooldownType.CLASS_ABILITY)
end

function lib:RegisterRacial(data)
    return self:Register(data, CooldownType.RACIAL)
end

-- ===========================================================================
-- QUERY API
-- ===========================================================================

--- Retrieve a single cooldown by its unique key.
---@param key string
---@return table|nil
function lib:GetByKey(key)
    return byKey[key]
end

--- Retrieve a single cooldown by spellID.
---@param spellID number
---@return table|nil
function lib:GetBySpellID(spellID)
    return bySpellID[spellID]
end

--- Retrieve a single cooldown by itemID.
---@param itemID number
---@return table|nil
function lib:GetByItemID(itemID)
    return byItemID[itemID]
end

--- Get all cooldowns for a given class (unfiltered).
---@param classID string  e.g. "WARRIOR"
---@return table[]
function lib:GetByClass(classID)
    return byClass[classID] or {}
end

--- Get all cooldowns registered for a specific spec.
---@param specID number
---@return table[]
function lib:GetBySpec(specID)
    return bySpec[specID] or {}
end

--- Get all cooldowns applicable to a class + spec combination.
--- A cooldown is applicable if it belongs to the class AND either has an empty
--- specs list (shared by all specs) or explicitly includes the given specID.
---@param classID string
---@param specID number
---@param category? string  Optional category filter (lib.Category.*)
---@return table[]
function lib:GetApplicable(classID, specID, category)
    local result = {}
    local classCDs = byClass[classID]
    if not classCDs then return result end

    for i = 1, #classCDs do
        local cd = classCDs[i]
        if cd.type == CooldownType.CLASS_ABILITY then
            local match = (#cd.specs == 0)
            if not match then
                for j = 1, #cd.specs do
                    if cd.specs[j] == specID then
                        match = true
                        break
                    end
                end
            end
            if match and (not category or cd.category == category) then
                result[#result + 1] = cd
            end
        end
    end
    return result
end

--- Get all cooldowns of a specific category.
---@param category string  One of lib.Category.*
---@return table[]
function lib:GetByCategory(category)
    local result = {}
    for _, bucket in pairs(registry) do
        for i = 1, #bucket do
            if bucket[i].category == category then
                result[#result + 1] = bucket[i]
            end
        end
    end
    return result
end

--- Get all cooldowns matching a minimum priority threshold.
---@param minPriority number  Minimum priority value (inclusive)
---@param classID? string     Optional class filter
---@param specID? number      Optional spec filter
---@return table[]
function lib:GetByPriority(minPriority, classID, specID)
    local source
    if classID and specID then
        source = self:GetApplicable(classID, specID)
    elseif classID then
        source = byClass[classID] or {}
    else
        source = self:GetAll()
    end

    local result = {}
    for i = 1, #source do
        if source[i].priority >= minPriority then
            result[#result + 1] = source[i]
        end
    end
    return result
end

--- Get only cooldowns flagged as defaultEnabled.
---@param classID? string
---@param specID? number
---@return table[]
function lib:GetDefaultEnabled(classID, specID)
    local source
    if classID and specID then
        source = self:GetApplicable(classID, specID)
    elseif classID then
        source = byClass[classID] or {}
    else
        source = self:GetAll()
    end

    local result = {}
    for i = 1, #source do
        if source[i].defaultEnabled then
            result[#result + 1] = source[i]
        end
    end
    return result
end

--- Get every registered cooldown across all types.
---@return table[]
function lib:GetAll()
    local all = {}
    for _, bucket in pairs(registry) do
        for i = 1, #bucket do
            all[#all + 1] = bucket[i]
        end
    end
    return all
end

--- Count registered cooldowns, optionally filtered by type.
---@param cooldownType? string  Filter by lib.CooldownType.*
---@return number
function lib:Count(cooldownType)
    if cooldownType then
        return #(registry[cooldownType] or {})
    end
    local n = 0
    for _, bucket in pairs(registry) do
        n = n + #bucket
    end
    return n
end
