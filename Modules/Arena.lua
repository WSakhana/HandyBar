------------------------------------------------------------------------
-- HandyBar - Arena Module
-- Detects arena opponents and filters spells by enemy class
------------------------------------------------------------------------
local addonName, ns = ...
local HB = ns.HB

local function ResetArenaEnemyState(self)
    self.enemyClasses = {}
    self.enemySpecsByClass = {}
    self.enemyClassCounts = {}
    self.enemySpecCountsByClass = {}
    self.arenaSlotClasses = {}
    self.arenaSlotSpecs = {}
end

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
        self:Print("|cFF00FF00[HandyBar]|r PLAYER_ENTERING_WORLD: instanceType=", instanceType, "inArena=", tostring(self.inArena))
    end

    if self.inArena then
        -- Entering arena: reset state for fresh match
        ResetArenaEnemyState(self)
        self:ResetAllCooldowns()
        if self.ResetEnemyCooldownTracking then
            self:ResetEnemyCooldownTracking()
        end
        self:DetectArenaOpponents()
    elseif wasInArena then
        -- Leaving arena: clear enemy data
        ResetArenaEnemyState(self)
        if self.ResetEnemyCooldownTracking then
            self:ResetEnemyCooldownTracking()
        end
    end

    if self.RefreshEnemyCooldownTracking then
        self:RefreshEnemyCooldownTracking()
    end

    self:UpdateAllBars()
end

function HB:OnArenaPrepOpponentSpecs()
    -- CRITICAL: This event can fire BEFORE PLAYER_ENTERING_WORLD
    -- So we check instance type directly instead of relying on self.inArena
    local _, instanceType = IsInInstance()
    local isInArena = (instanceType == "arena")
    
    if self.db.profile.debug then
        self:Print("|cFF00FF00[HandyBar]|r ARENA_PREP_OPPONENT_SPECIALIZATIONS: instanceType=", instanceType)
    end
    
    if not isInArena then return end
    
    -- Auto-disable test mode when entering real arena
    self:DisableTestMode(true, true)
    
    -- Update the flag if needed (in case this event fires first)
    if not self.inArena then
        self.inArena = true
        ResetArenaEnemyState(self)
        if self.ResetEnemyCooldownTracking then
            self:ResetEnemyCooldownTracking()
        end
    end
    
    self:DetectArenaOpponents()
    if self.RefreshEnemyCooldownTracking then
        self:RefreshEnemyCooldownTracking()
    end
    self:UpdateAllBars()
end

function HB:OnArenaOpponentUpdate(event, unitID, updateType)
    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" then return end
    
    if self.db.profile.debug then
        self:Print("|cFF00FF00[HandyBar]|r ARENA_OPPONENT_UPDATE: unitID=", unitID, "updateType=", tostring(updateType))
    end
    
    self:DetectArenaOpponents()
    if self.RefreshEnemyCooldownTracking then
        self:RefreshEnemyCooldownTracking()
    end
    self:UpdateAllBars()
end

------------------------------------------------------------------------
-- Opponent Detection
-- Uses Blizzard Arena Prep API (Retail) for robust spec detection
------------------------------------------------------------------------

function HB:DetectArenaOpponents()
    local previousSlotClasses = self.arenaSlotClasses or {}
    local previousSlotSpecs = self.arenaSlotSpecs or {}
    ResetArenaEnemyState(self)

    local function addEnemy(slotIndex, classFile, specID)
        if not classFile then return end
        self.enemyClasses[classFile] = true
        self.enemyClassCounts[classFile] = (self.enemyClassCounts[classFile] or 0) + 1
        if slotIndex then
            self.arenaSlotClasses[slotIndex] = classFile
            self.arenaSlotSpecs[slotIndex] = (specID and specID > 0) and specID or 0
        end
        if specID and specID > 0 then
            local bucket = self.enemySpecsByClass[classFile]
            if not bucket then
                bucket = {}
                self.enemySpecsByClass[classFile] = bucket
            end
            bucket[specID] = true

            local countBucket = self.enemySpecCountsByClass[classFile]
            if not countBucket then
                countBucket = {}
                self.enemySpecCountsByClass[classFile] = countBucket
            end
            countBucket[specID] = (countBucket[specID] or 0) + 1
        end
    end

    local numSpecs = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0
    
    if self.db.profile.debug then
        self:Print("|cFF00FF00[HandyBar]|r DetectArenaOpponents: numSpecs =", numSpecs)
    end
    
    for i = 1, 5 do
        local specID = GetArenaOpponentSpec and (GetArenaOpponentSpec(i) or 0) or 0
        if specID > 0 then
            -- GetSpecializationInfoByID returns: id, name, description, icon, role, classFile, className
            local _, _, _, _, _, classFile = GetSpecializationInfoByID(specID)
            addEnemy(i, classFile, specID)
        else
            local unitID = "arena" .. i
            if UnitExists(unitID) then
                local _, classFile = UnitClass(unitID)
                local preservedSpec = nil
                if classFile and classFile == previousSlotClasses[i] then
                    preservedSpec = previousSlotSpecs[i]
                end
                addEnemy(i, classFile, preservedSpec)
            elseif previousSlotClasses[i] then
                addEnemy(i, previousSlotClasses[i], previousSlotSpecs[i])
            elseif i <= numSpecs then
                -- During prep, some clients report slot count before all spec details are queryable.
                -- Keep the slot visible with its best-known class once the unit appears.
                addEnemy(i, previousSlotClasses[i], previousSlotSpecs[i])
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
            self:Print("|cFF00FF00[HandyBar]|r   Enemy classes: " .. table.concat(classes, ", "))
        else
            self:Print("|cFF00FF00[HandyBar]|r   Enemy classes: (none yet)")
        end

        local specSummary = {}
        for classFile, specs in pairs(self.enemySpecsByClass) do
            local names = {}
            for specID in pairs(specs) do
                local _, specName = GetSpecializationInfoByID(specID)
                names[#names + 1] = specName or tostring(specID)
            end
            table.sort(names)
            if #names > 0 then
                specSummary[#specSummary + 1] = classFile .. "=" .. table.concat(names, "/")
            end
        end
        table.sort(specSummary)
        if #specSummary > 0 then
            self:Print("|cFF00FF00[HandyBar]|r   Enemy specs: " .. table.concat(specSummary, "; "))
        else
            self:Print("|cFF00FF00[HandyBar]|r   Enemy specs: (none yet)")
        end

        local countSummary = {}
        for classFile, count in pairs(self.enemyClassCounts) do
            countSummary[#countSummary + 1] = classFile .. "=" .. tostring(count)
        end
        table.sort(countSummary)
        if #countSummary > 0 then
            self:Print("|cFF00FF00[HandyBar]|r   Enemy class counts: " .. table.concat(countSummary, ", "))
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

function HB:GetEnemySpecsByClass()
    return self.enemySpecsByClass
end

function HB:GetArenaSlotClass(slotIndex)
    return self.arenaSlotClasses and self.arenaSlotClasses[slotIndex] or nil
end

function HB:GetArenaSlotSpec(slotIndex)
    return self.arenaSlotSpecs and self.arenaSlotSpecs[slotIndex] or nil
end

function HB:GetArenaUnitToken(slotIndex)
    if not slotIndex then
        return nil
    end
    return "arena" .. tostring(slotIndex)
end

function HB:SpellMatchesArenaSlot(spellData, slotIndex)
    if not spellData or not slotIndex then
        return false
    end

    local slotClass = self:GetArenaSlotClass(slotIndex)
    if not slotClass or slotClass ~= spellData.class then
        return false
    end

    local specs = spellData.specs or {}
    if #specs == 0 then
        return true
    end

    local slotSpec = self:GetArenaSlotSpec(slotIndex)
    if not slotSpec or slotSpec <= 0 then
        return true
    end

    for i = 1, #specs do
        if specs[i] == slotSpec then
            return true
        end
    end

    return false
end

function HB:GetMatchingArenaSlotsForSpell(spellData)
    local slots = {}
    if not spellData then
        return slots
    end

    for slotIndex = 1, 5 do
        if self:SpellMatchesArenaSlot(spellData, slotIndex) then
            slots[#slots + 1] = slotIndex
        end
    end

    return slots
end
