------------------------------------------------------------------------
-- HandyBar - Arena Module
-- Detects arena opponents and filters spells by enemy class
------------------------------------------------------------------------
local addonName, ns = ...
local HB = ns.HB

------------------------------------------------------------------------
-- Event Handlers
------------------------------------------------------------------------

function HB:OnPlayerEnteringWorld()
    -- Requirement: test mode must not persist across loads/reloads/zone transitions.
    -- Defer updates; this handler already calls UpdateAllBars() at the end.
    self:DisableTestMode(true, true)

    local _, instanceType = IsInInstance()
    local wasInArena = self.inArena
    self.inArena = (instanceType == "arena")

    if self.db.profile.debug then
        print("|cFF00FF00[HandyBar]|r PLAYER_ENTERING_WORLD: instanceType=", instanceType, "inArena=", tostring(self.inArena))
    end

    if self.inArena then
        -- Entering arena: reset state for fresh match
        self.enemyClasses = {}
        self:ResetAllCooldowns()
        self:DetectArenaOpponents()
    elseif wasInArena then
        -- Leaving arena: clear enemy data
        self.enemyClasses = {}
    end

    self:UpdateAllBars()
end

function HB:OnArenaPrepOpponentSpecs()
    -- CRITICAL: This event can fire BEFORE PLAYER_ENTERING_WORLD
    -- So we check instance type directly instead of relying on self.inArena
    local _, instanceType = IsInInstance()
    local isInArena = (instanceType == "arena")
    
    if self.db.profile.debug then
        print("|cFF00FF00[HandyBar]|r ARENA_PREP_OPPONENT_SPECIALIZATIONS: instanceType=", instanceType)
    end
    
    if not isInArena then return end
    
    -- Auto-disable test mode when entering real arena
    self:DisableTestMode(true, true)
    
    -- Update the flag if needed (in case this event fires first)
    if not self.inArena then
        self.inArena = true
        self.enemyClasses = {}
    end
    
    self:DetectArenaOpponents()
    self:UpdateAllBars()
end

function HB:OnArenaOpponentUpdate(event, unitID, updateType)
    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" then return end
    
    if self.db.profile.debug then
        print("|cFF00FF00[HandyBar]|r ARENA_OPPONENT_UPDATE: unitID=", unitID, "updateType=", tostring(updateType))
    end
    
    self:DetectArenaOpponents()
    self:UpdateAllBars()
end

------------------------------------------------------------------------
-- Opponent Detection
-- Uses Blizzard Arena Prep API (Retail) for robust spec detection
------------------------------------------------------------------------

function HB:DetectArenaOpponents()
    self.enemyClasses = {}

    -- Method 1: Arena Prep API (preferred, works even before UnitExists)
    -- This is the robust way on Retail - provides specs during prep phase
    local numSpecs = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0
    
    if self.db.profile.debug then
        print("|cFF00FF00[HandyBar]|r DetectArenaOpponents: numSpecs =", numSpecs)
    end
    
    if numSpecs > 0 then
        for i = 1, numSpecs do
            local specID = GetArenaOpponentSpec(i) or 0
            if specID > 0 then
                -- GetSpecializationInfoByID returns: id, name, description, icon, role, classFile, className
                local specIDRet, specName, _, specIcon, _, classFile, className = GetSpecializationInfoByID(specID)
                if classFile then
                    self.enemyClasses[classFile] = true
                    -- Avoid per-opponent spam; summary printed below.
                end
            end
        end
    end

    -- Method 2: UnitClass fallback (works when units are visible)
    -- Covers edge cases and ensures we catch all opponents
    for i = 1, 5 do
        local unitID = "arena" .. i
        if UnitExists(unitID) then
            local _, classFile = UnitClass(unitID)
            if classFile then
                local wasNew = not self.enemyClasses[classFile]
                self.enemyClasses[classFile] = true
                -- Avoid per-unit spam; summary printed below.
            end
        end
    end
    
    if self.db.profile.debug then
        local classes = {}
        for class in pairs(self.enemyClasses) do
            table.insert(classes, class)
        end
        table.sort(classes)
        if #classes > 0 then
            print("|cFF00FF00[HandyBar]|r   Enemy classes: " .. table.concat(classes, ", "))
        else
            print("|cFF00FF00[HandyBar]|r   Enemy classes: (none yet)")
        end
    end
end

------------------------------------------------------------------------
-- Query Functions
------------------------------------------------------------------------

function HB:IsInArena()
    return self.inArena
end

function HB:GetEnemyClasses()
    return self.enemyClasses
end
