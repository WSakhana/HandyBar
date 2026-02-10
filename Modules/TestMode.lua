------------------------------------------------------------------------
-- HandyBar - Test Mode Module
-- Allows layout configuration and testing outside of Arena
------------------------------------------------------------------------
local addonName, ns = ...
local HB = ns.HB

------------------------------------------------------------------------
-- Test Mode Toggle
------------------------------------------------------------------------

function HB:ToggleTestMode()
    if self:IsTestMode() then
        self:DisableTestMode()
    else
        self:EnableTestMode()
    end
end

function HB:EnableTestMode(deferUpdate)
    self.runtime = self.runtime or {}
    self.runtime.testMode = true
    self:Print(self.L["Test Mode enabled."])

    -- Show unlocked state during test mode for easier configuration
    if self.db.profile.locked then
        self:UnlockBars()
    end

    if not deferUpdate then
        self:UpdateAllBars()
    end

    self:RefreshOptions()
end

function HB:DisableTestMode(silent, deferUpdate)
    if not self:IsTestMode() then
        return false
    end

    self.runtime.testMode = false
    if not silent then
        self:Print(self.L["Test Mode disabled."])
    end

    -- Restore lock state
    if self.db.profile.locked then
        self:LockBars()
    end

    if not deferUpdate then
        self:UpdateAllBars()
    end

    self:RefreshOptions()
    return true
end

function HB:IsTestMode()
    return (self.runtime and self.runtime.testMode) or false
end
