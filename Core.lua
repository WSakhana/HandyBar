------------------------------------------------------------------------
-- HandyBar - Core
-- Manual cooldown tracking addon for PvP Arenas
------------------------------------------------------------------------
local addonName, ns = ...

------------------------------------------------------------------------
-- Addon Creation
------------------------------------------------------------------------
local HB = LibStub("AceAddon-3.0"):NewAddon(addonName,
    "AceConsole-3.0",
    "AceEvent-3.0",
    "AceTimer-3.0"
)
ns.HB = HB

-- Library references
HB.MC = LibStub("MajorCooldowns")
HB.L = LibStub("AceLocale-3.0"):GetLocale(addonName)

------------------------------------------------------------------------
-- Spell Info Cache
------------------------------------------------------------------------
local spellInfoCache = {}

function HB:GetSpellData(spellID)
    if spellInfoCache[spellID] then
        return spellInfoCache[spellID]
    end

    local name, icon

    -- Modern WoW API (11.0+)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            name = info.name
            icon = info.iconID
        end
    end

    -- Legacy fallback
    if not name and GetSpellInfo then
        name, _, icon = GetSpellInfo(spellID)
    end

    local data = {
        name = name or ("Spell #" .. spellID),
        icon = icon or 134400, -- Question mark icon
    }

    spellInfoCache[spellID] = data
    return data
end

------------------------------------------------------------------------
-- Database Defaults
------------------------------------------------------------------------
local defaults = {
    profile = {
        bars = {},
        locked = false,
        debug = false,
        durationOverrides = {},  -- [spellKey] = seconds (0 = use default)
        customSpells = {},       -- [spellID] = { spellID, duration, class, category }
    },
}

------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------
function HB:OnInitialize()
    -- Setup saved variables
    self.db = LibStub("AceDB-3.0"):New("HandyBarDB", defaults, true)

    -- Runtime-only state (not persisted)
    self.runtime = self.runtime or {}
    self.runtime.testMode = false

    -- Backward compat cleanup: test mode is no longer persisted
    self.db.profile.testMode = nil

    -- Profile change callbacks
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    -- Runtime state
    self.barFrames = {}
    self.enemyClasses = {}
    self.enemySpecsByClass = {}
    self.inArena = false

    -- Create default bars on first use
    if next(self.db.profile.bars) == nil then
        self:CreateDefaultBars()
    end

    -- Load user-defined custom spells into MajorCooldowns registry
    self:LoadCustomSpells()

    -- Setup configuration UI
    self:SetupOptions()

    -- Slash commands
    self:RegisterChatCommand("handybar", "SlashCommand")
    self:RegisterChatCommand("hb", "SlashCommand")
end

function HB:OnEnable()
    -- Create all bar frames from saved config
    self:CreateAllBars()

    -- Register arena-related events
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", "OnArenaPrepOpponentSpecs")
    self:RegisterEvent("ARENA_OPPONENT_UPDATE", "OnArenaOpponentUpdate")

    -- Initial visibility update
    self:UpdateAllBars()
end

------------------------------------------------------------------------
-- Zone Change
------------------------------------------------------------------------

function HB:OnZoneChanged()
    -- Requirement: test mode should never persist through zone changes
    local didDisable = self:DisableTestMode(true, true)
    if didDisable then
        self:UpdateAllBars()
    end
end

------------------------------------------------------------------------
-- Full Configuration Reset
------------------------------------------------------------------------

function HB:ResetConfiguration()
    -- Reset everything back to defaults (bars/settings/profiles).
    self:DisableTestMode(true, true)
    self.db:ResetDB()

    if next(self.db.profile.bars) == nil then
        self:CreateDefaultBars()
    end

    self:RefreshConfig()
    self:RefreshOptions()
    self:Print(self.L["Configuration reset to defaults."])
end

function HB:OnDisable()
    self:UnregisterAllEvents()
    self:HideAllBars()
end

------------------------------------------------------------------------
-- Slash Commands
------------------------------------------------------------------------
function HB:SlashCommand(input)
    input = (input or ""):trim():lower()

    local L = self.L
    if input == "test" then
        self:ToggleTestMode()
    elseif input == "lock" then
        self:ToggleLock()
    elseif input == "reset" then
        self:ResetAllCooldowns()
        self:Print(L["All cooldowns reset."])
    elseif input == "config" or input == "options" or input == "" then
        self:OpenOptions()
    else
        self:Print(L["HandyBar Commands:"])
        self:Print(L["CMD_CONFIG"])
        self:Print(L["CMD_TEST"])
        self:Print(L["CMD_LOCK"])
        self:Print(L["CMD_RESET"])
    end
end

------------------------------------------------------------------------
-- Config Refresh (on profile change)
------------------------------------------------------------------------
function HB:RefreshConfig()
    self:DestroyAllBars()
    self:CreateAllBars()
    self:UpdateAllBars()
end

------------------------------------------------------------------------
-- Lock / Unlock
------------------------------------------------------------------------
function HB:ToggleLock()
    self.db.profile.locked = not self.db.profile.locked
    local L = self.L
    if self.db.profile.locked then
        self:LockBars()
        self:Print(L["Bars locked."])
    else
        self:UnlockBars()
        self:Print(L["Bars unlocked."])
    end
end

------------------------------------------------------------------------
-- Default Bars (first-run setup)
------------------------------------------------------------------------
function HB:CreateDefaultBars()
    local MC = self.MC
    local allSpells = MC:GetAll()

    local defSpells = {}
    local offSpells = {}

    for _, spell in ipairs(allSpells) do
        if spell.defaultEnabled then
            if spell.category == MC.Category.DEFENSIVE then
                defSpells[spell.key] = true
            elseif spell.category == MC.Category.BURST
                or spell.category == MC.Category.OFFENSIVE then
                offSpells[spell.key] = true
            end
        end
    end

    -- Defensives bar (centered, top)
    self.db.profile.bars["Defensives"] = self:GetBarDefaults("Defensives")
    self.db.profile.bars["Defensives"].spells = defSpells
    self.db.profile.bars["Defensives"].position = {
        point = "CENTER", relativePoint = "CENTER", x = 0, y = 320,
    }

    -- Offensives bar (centered, bottom)
    self.db.profile.bars["Offensives"] = self:GetBarDefaults("Offensives")
    self.db.profile.bars["Offensives"].spells = offSpells
    self.db.profile.bars["Offensives"].position = {
        point = "CENTER", relativePoint = "CENTER", x = 0, y = -230,
    }
end

function HB:GetBarDefaults(name)
    return {
        name = name,
        enabled = true,
        spells = {},
        iconSize = 34,
        spacing = 2,
        growDirection = "RIGHT",
        showCooldownText = true,
        showIconBorder = true,
        duplicateSameSpecClass = true,
        arenaVisibility = "ALL",  -- ALL, ARENA1, ARENA2, ARENA3
        maxIcons = 24,
        maxPerRow = 12,
        position = nil,
    }
end

------------------------------------------------------------------------
-- Effective Spell Duration (with overrides)
------------------------------------------------------------------------
function HB:GetEffectiveDuration(spellData)
    -- Check user override first
    local override = self.db.profile.durationOverrides[spellData.key]
    if override and override > 0 then
        return override
    end
    return spellData.duration
end

------------------------------------------------------------------------
-- Custom Spell Management
------------------------------------------------------------------------
function HB:RegisterCustomSpell(spellID, duration, classID, category, specs)
    local MC = self.MC
    local key = "custom_" .. spellID

    -- Save to DB
    self.db.profile.customSpells[spellID] = {
        spellID = spellID,
        duration = duration,
        class = classID,
        category = category or MC.Category.UTILITY,
        specs = specs or {},
    }

    -- Register or update in MajorCooldowns
    local existing = MC:GetByKey(key)
    if existing then
        -- Update existing entry fields
        existing.duration = duration
        existing.class = classID
        existing.category = category or MC.Category.UTILITY
        existing.specs = specs or {}
    else
        MC:Register({
            key = key,
            spellID = spellID,
            duration = duration,
            class = classID,
            specs = specs or {},
            category = category or MC.Category.UTILITY,
            defaultEnabled = false,
            priority = MC.Priority.NORMAL,
        }, MC.CooldownType.CLASS_ABILITY)
    end

    return key
end

function HB:RemoveCustomSpell(spellID)
    self.db.profile.customSpells[spellID] = nil
    -- Note: we can't truly unregister from MC, but removing from DB
    -- and bars is sufficient since the spell won't be enabled anywhere.
    for _, barDB in pairs(self.db.profile.bars) do
        local key = "custom_" .. spellID
        barDB.spells[key] = nil
    end
end

function HB:LoadCustomSpells()
    if not self.db.profile.customSpells then return end
    local MC = self.MC
    for spellID, data in pairs(self.db.profile.customSpells) do
        local key = "custom_" .. spellID
        if not MC:GetByKey(key) then
            MC:Register({
                key = key,
                spellID = spellID,
                duration = data.duration,
                class = data.class,
                specs = data.specs or {},
                category = data.category or MC.Category.UTILITY,
                defaultEnabled = false,
                priority = MC.Priority.NORMAL,
            }, MC.CooldownType.CLASS_ABILITY)
        end
    end
end
