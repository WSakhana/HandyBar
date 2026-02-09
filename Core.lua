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
    self:Print("Configuration reset to defaults.")
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

    if input == "test" then
        self:ToggleTestMode()
    elseif input == "lock" then
        self:ToggleLock()
    elseif input == "reset" then
        self:ResetAllCooldowns()
        self:Print("All cooldowns reset.")
    elseif input == "config" or input == "options" or input == "" then
        self:OpenOptions()
    else
        self:Print("|cff00ff00HandyBar Commands:|r")
        self:Print("  /hb          - Open configuration")
        self:Print("  /hb test     - Toggle Test Mode")
        self:Print("  /hb lock     - Toggle bar locking")
        self:Print("  /hb reset    - Reset all cooldowns")
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
    if self.db.profile.locked then
        self:LockBars()
        self:Print("Bars |cffff0000locked|r.")
    else
        self:UnlockBars()
        self:Print("Bars |cff00ff00unlocked|r.")
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
        point = "CENTER", relativePoint = "CENTER", x = 0, y = 350,
    }

    -- Offensives bar (centered, bottom)
    self.db.profile.bars["Offensives"] = self:GetBarDefaults("Offensives")
    self.db.profile.bars["Offensives"].spells = offSpells
    self.db.profile.bars["Offensives"].position = {
        point = "CENTER", relativePoint = "CENTER", x = 0, y = -250,
    }
end

function HB:GetBarDefaults(name)
    return {
        name = name,
        enabled = true,
        spells = {},
        iconSize = 36,
        spacing = 2,
        growDirection = "RIGHT",
        showCooldownText = true,
        showIconBorder = true,
        maxIcons = 0,
        maxPerRow = 12,
        position = nil,
    }
end
