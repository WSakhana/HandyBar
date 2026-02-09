------------------------------------------------------------------------
-- HandyBar - Bar Module
-- Creates and manages cooldown bar frames and spell buttons
------------------------------------------------------------------------
local addonName, ns = ...
local HB = ns.HB

-- Local references for performance
local CreateFrame = CreateFrame
local GetTime = GetTime
local pairs = pairs
local ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove
local floor = math.floor
local format = string.format
local max = math.max
local tostring = tostring

-- Preferred class ordering (used for sorting visible spells)
local CLASS_ORDER = {
    "WARRIOR", "PALADIN", "DEATHKNIGHT", "HUNTER", "ROGUE",
    "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "MONK",
    "DRUID", "DEMONHUNTER", "EVOKER",
}

local CLASS_INDEX = {}
for i, classID in ipairs(CLASS_ORDER) do
    CLASS_INDEX[classID] = i
end

------------------------------------------------------------------------
-- Bar Lifecycle
------------------------------------------------------------------------

function HB:CreateAllBars()
    if self.db.profile.debug then
        local count = 0
        for barName, barDB in pairs(self.db.profile.bars) do
            if barDB.enabled then count = count + 1 end
        end
        print("|cFF00FF00[HandyBar]|r CreateAllBars: Creating " .. count .. " enabled bars")
    end
    
    for barName, barDB in pairs(self.db.profile.bars) do
        if barDB.enabled then
            self:CreateBar(barName)
        end
    end
end

function HB:DestroyAllBars()
    for barName in pairs(self.barFrames) do
        self:DestroyBar(barName)
    end
    self.barFrames = {}
end

function HB:HideAllBars()
    for _, frame in pairs(self.barFrames) do
        frame:Hide()
    end
end

function HB:ShowAllBars()
    for _, frame in pairs(self.barFrames) do
        frame:Show()
    end
end

------------------------------------------------------------------------
-- Bar Frame Creation
------------------------------------------------------------------------

function HB:CreateBar(barName)
    if self.barFrames[barName] then return self.barFrames[barName] end

    local barDB = self.db.profile.bars[barName]
    if not barDB then return nil end

    -- Sanitize frame name (remove spaces/special chars)
    local safeName = barName:gsub("[^%w]", "_")
    local frame = CreateFrame("Frame", "HandyBar_" .. safeName, UIParent, "BackdropTemplate")
    frame:SetSize(barDB.iconSize + 4, barDB.iconSize + 4)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("MEDIUM")
    frame.barName = barName
    frame.allButtons = {}
    frame.activeButtons = {}
    frame.buttonPool = {}

    local isLocked = self.db.profile.locked

    -- Drag handling
    frame:SetMovable(true)
    frame:EnableMouse(not isLocked)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(f)
        if not HB.db.profile.locked then
            f:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local point, _, relativePoint, x, y = f:GetPoint()
        local db = HB.db.profile.bars[f.barName]
        if db then
            db.position = {
                point = point,
                relativePoint = relativePoint,
                x = x,
                y = y,
            }
        end
    end)

    -- Title label (visible when unlocked)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.title:SetPoint("BOTTOM", frame, "TOP", 0, 2)
    frame.title:SetText(barName)
    frame.title:SetTextColor(1, 0.82, 0, 1)
    frame.title:SetShown(not isLocked)
    
    -- Create invisible frame for title to make it draggable
    frame.titleFrame = CreateFrame("Frame", nil, frame)
    frame.titleFrame:SetPoint("BOTTOM", frame, "TOP", 0, 0)
    frame.titleFrame:SetSize(100, 20)
    frame.titleFrame:SetMovable(true)
    frame.titleFrame:EnableMouse(true)
    frame.titleFrame:RegisterForDrag("LeftButton")
    
    frame.titleFrame:SetScript("OnDragStart", function()
        if not HB.db.profile.locked then
            frame:StartMoving()
        end
    end)
    
    frame.titleFrame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, relativePoint, x, y = frame:GetPoint()
        local db = HB.db.profile.bars[frame.barName]
        if db then
            db.position = {
                point = point,
                relativePoint = relativePoint,
                x = x,
                y = y,
            }
        end
    end)
    
    frame.titleFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Click and drag to move", 1, 1, 1)
        GameTooltip:Show()
        frame.title:SetTextColor(1, 1, 0, 1)  -- Brighten on hover
    end)
    
    frame.titleFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
        frame.title:SetTextColor(1, 0.82, 0, 1)  -- Restore normal color
    end)
    
    frame.titleFrame:SetShown(not isLocked)

    -- Restore saved position
    if barDB.position then
        frame:SetPoint(
            barDB.position.point,
            UIParent,
            barDB.position.relativePoint,
            barDB.position.x,
            barDB.position.y
        )
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    self.barFrames[barName] = frame

    -- Populate and layout
    self:UpdateBarSpells(barName)
    self:UpdateBarVisibility(barName)

    return frame
end

function HB:DestroyBar(barName)
    local frame = self.barFrames[barName]
    if not frame then return end

    -- Clean up all buttons
    for _, button in ipairs(frame.allButtons) do
        self:CleanupButton(button)
        button:Hide()
        button:SetParent(nil)
    end

    frame:Hide()
    frame:SetParent(nil)
    self.barFrames[barName] = nil
end

------------------------------------------------------------------------
-- Spell Filtering
------------------------------------------------------------------------

function HB:GetVisibleSpells(barName)
    local barDB = self.db.profile.bars[barName]
    if not barDB then return {} end

    local MC = self.MC
    local visibleSpells = {}
    local debugEnabled = self.db.profile.debug
    local isTestMode = self:IsTestMode()
    
    if debugEnabled then
        local spellCount = 0
        for _ in pairs(barDB.spells) do spellCount = spellCount + 1 end
        print("|cFF00FF00[HandyBar]|r GetVisibleSpells:", barName,
              "assigned=" .. tostring(spellCount),
              "testMode=" .. tostring(isTestMode),
              "inArena=" .. tostring(self.inArena))
    end

    local enemySpecCountsByClass = self.enemySpecCountsByClass or {}
    local enemyClassCounts = self.enemyClassCounts or {}
    local duplicateEnabled = barDB.duplicateSameSpecClass

    local function getMatchCount(spellData)
        local classFile = spellData.class
        if not self.enemyClasses[classFile] then
            return 0
        end

        local specs = spellData.specs or {}
        local specCounts = enemySpecCountsByClass[classFile]
        if specCounts and next(specCounts) then
            if #specs == 0 then
                local total = 0
                for _, count in pairs(specCounts) do
                    total = total + count
                end
                return total
            end

            local total = 0
            for i = 1, #specs do
                total = total + (specCounts[specs[i]] or 0)
            end
            return total
        end

        return enemyClassCounts[classFile] or 1
    end

    for spellKey, enabled in pairs(barDB.spells) do
        if enabled then
            local spellData = MC:GetByKey(spellKey)
            if spellData then
                if isTestMode then
                    -- Test mode: show ALL assigned spells
                    tinsert(visibleSpells, spellData)
                elseif self.inArena then
                    -- Arena: only show spells matching enemy classes/specs
                    local matchCount = getMatchCount(spellData)
                    if matchCount > 0 then
                        if duplicateEnabled then
                            for i = 1, matchCount do
                                tinsert(visibleSpells, spellData)
                            end
                        else
                            tinsert(visibleSpells, spellData)
                        end
                    end
                end
                -- Outside arena + no test mode: show nothing
            end
        end
    end
    
    if debugEnabled then
        print("|cFF00FF00[HandyBar]|r   Visible spells:", #visibleSpells)
    end

    -- Sort: class (preferred order) -> priority (desc) -> localized spell name -> key
    table.sort(visibleSpells, function(a, b)
        if a.class ~= b.class then
            local ai = CLASS_INDEX[a.class] or 999
            local bi = CLASS_INDEX[b.class] or 999
            return ai < bi
        end

        local ap = a.priority or 0
        local bp = b.priority or 0
        if ap ~= bp then return ap > bp end

        local an = (HB:GetSpellData(a.spellID).name or "")
        local bn = (HB:GetSpellData(b.spellID).name or "")
        if an ~= bn then return an < bn end

        return a.key < b.key
    end)

    -- Apply per-bar icon limit (0 = unlimited)
    local maxIcons = barDB.maxIcons or 0
    if maxIcons > 0 and #visibleSpells > maxIcons then
        local limited = {}
        for i = 1, maxIcons do
            limited[i] = visibleSpells[i]
        end
        visibleSpells = limited
        if debugEnabled then
            print("|cFF00FF00[HandyBar]|r   Limited to maxIcons=", maxIcons)
        end
    end

    return visibleSpells
end

------------------------------------------------------------------------
-- Spell Button Pool & Creation
------------------------------------------------------------------------

--- Format remaining cooldown time for display
local function FormatCooldownText(remaining)
    if remaining > 60 then
        return format("%dm", floor(remaining / 60) + 1)
    elseif remaining > 5 then
        return format("%d", floor(remaining) + 1)
    else
        return format("%.1f", remaining)
    end
end

--- OnUpdate handler for timer text (only active during cooldowns)
local function CooldownTimerOnUpdate(button, elapsed)
    if not button.cooldownEndTime then
        button.timerText:SetText("")
        button:SetScript("OnUpdate", nil)
        return
    end

    local remaining = button.cooldownEndTime - GetTime()
    if remaining <= 0 then
        button.timerText:SetText("")
        button.cooldownEndTime = nil
        button:SetScript("OnUpdate", nil)
        return
    end

    -- Throttle text updates to every 0.1s for performance
    button.timerElapsed = (button.timerElapsed or 0) + elapsed
    if button.timerElapsed >= 0.1 then
        button.timerElapsed = 0
        button.timerText:SetText(FormatCooldownText(remaining))

        -- Color by urgency
        if remaining <= 5 then
            button.timerText:SetTextColor(1, 0, 0, 1)
        elseif remaining <= 15 then
            button.timerText:SetTextColor(1, 1, 0, 1)
        else
            button.timerText:SetTextColor(1, 1, 1, 1)
        end
    end
end


function HB:GetOrCreateButton(barFrame)
    -- Try reusing from pool
    local button = tremove(barFrame.buttonPool)
    if button then return button end

    local barDB = self.db.profile.bars[barFrame.barName]
    local iconSize = barDB and barDB.iconSize or 36

    -- Create button
    button = CreateFrame("Button", nil, barFrame)
    button:SetSize(iconSize, iconSize)
    button.barName = barFrame.barName

    -- Icon texture
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 1, -1)
    button.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Class-colored border (4 edge textures)
    button.borderTextures = {}
    local function CreateEdge(point1, p1Rel, p1x, p1y, point2, p2Rel, p2x, p2y, w, h)
        local tex = button:CreateTexture(nil, "OVERLAY")
        tex:SetPoint(point1, button, p1Rel, p1x, p1y)
        tex:SetPoint(point2, button, p2Rel, p2x, p2y)
        if w then tex:SetWidth(w) end
        if h then tex:SetHeight(h) end
        tex:SetColorTexture(0, 0, 0, 1)
        return tex
    end
    button.borderTextures.top    = CreateEdge("TOPLEFT","TOPLEFT",0,0, "TOPRIGHT","TOPRIGHT",0,0, nil, 1)
    button.borderTextures.bottom = CreateEdge("BOTTOMLEFT","BOTTOMLEFT",0,0, "BOTTOMRIGHT","BOTTOMRIGHT",0,0, nil, 1)
    button.borderTextures.left   = CreateEdge("TOPLEFT","TOPLEFT",0,0, "BOTTOMLEFT","BOTTOMLEFT",0,0, 1, nil)
    button.borderTextures.right  = CreateEdge("TOPRIGHT","TOPRIGHT",0,0, "BOTTOMRIGHT","BOTTOMRIGHT",0,0, 1, nil)

    -- Cooldown frame (spiral overlay)
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetPoint("TOPLEFT", button.icon, "TOPLEFT", 0, 0)
    button.cooldown:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", 0, 0)
    button.cooldown:SetDrawBling(false)
    button.cooldown:SetDrawEdge(true)
    button.cooldown:SetHideCountdownNumbers(true) -- We use custom text

    -- Timer text
    button.timerText = button:CreateFontString(nil, "OVERLAY")
    button.timerText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    button.timerText:SetPoint("CENTER", 0, 0)
    button.timerText:SetTextColor(1, 1, 1, 1)

    -- Charge count text (bottom-right)
    button.chargeText = button:CreateFontString(nil, "OVERLAY")
    button.chargeText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    button.chargeText:SetPoint("BOTTOMRIGHT", -2, 2)
    button.chargeText:SetTextColor(1, 1, 1, 1)

    -- Highlight on hover
    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints(button.icon)
    button.highlight:SetColorTexture(1, 1, 1, 0.15)

    -- Click handling
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            HB:ResetSpellCooldown(self)
        else
            HB:StartSpellCooldown(self)
        end
    end)

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        if not self.spellData then return end

        local spellInfo = HB:GetSpellData(self.spellData.spellID)
        local MC = HB.MC
        local classInfo = MC.Classes[self.spellData.class]

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(spellInfo.name, 1, 1, 1)

        if classInfo then
            local r = tonumber(classInfo.color:sub(1,2), 16) / 255
            local g = tonumber(classInfo.color:sub(3,4), 16) / 255
            local b = tonumber(classInfo.color:sub(5,6), 16) / 255
            GameTooltip:AddLine(classInfo.name, r, g, b)
        end

        GameTooltip:AddLine(format("Cooldown: %ds", self.spellData.duration), 0.8, 0.8, 0.8)

        if self.spellData.category then
            GameTooltip:AddLine("Category: " .. self.spellData.category, 0.6, 0.6, 0.6)
        end

        if self.maxCharges and self.maxCharges > 1 then
            GameTooltip:AddLine(format("Charges: %d / %d", self.currentCharges, self.maxCharges), 0.8, 0.8, 0.8)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff00ff00Left-click:|r Start cooldown", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("|cffff0000Right-click:|r Reset cooldown", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    tinsert(barFrame.allButtons, button)
    return button
end

------------------------------------------------------------------------
-- Button Configuration
------------------------------------------------------------------------

function HB:ConfigureButton(button, spellData, barDB)
    button.spellData = spellData
    button.maxCharges = spellData.stack or 1
    button.currentCharges = button.maxCharges
    button.cooldownEndTime = nil
    button.rechargeTimers = {}
    button.timerElapsed = 0

    -- Set spell icon
    local spellInfo = self:GetSpellData(spellData.spellID)
    button.icon:SetTexture(spellInfo.icon)
    button.icon:SetDesaturated(false)

    -- Apply icon size
    local iconSize = barDB.iconSize or 36
    button:SetSize(iconSize, iconSize)

    -- Scale font size to icon
    local fontSize = max(10, floor(iconSize * 0.38))
    button.timerText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    button.timerText:SetText("")
    button.timerText:SetShown(barDB.showCooldownText)

    local chargeFontSize = max(8, floor(iconSize * 0.3))
    button.chargeText:SetFont("Fonts\\FRIZQT__.TTF", chargeFontSize, "OUTLINE")

    -- Charge display
    if button.maxCharges > 1 then
        button.chargeText:SetText(tostring(button.currentCharges))
        button.chargeText:Show()
    else
        button.chargeText:SetText("")
        button.chargeText:Hide()
    end

    -- Class-colored border
    local MC = self.MC
    local classInfo = MC.Classes[spellData.class]
    local barDB = self.db.profile.bars[button.barName]
    local showBorder = barDB and (barDB.showIconBorder ~= false)
    
    if classInfo and showBorder then
        local r = tonumber(classInfo.color:sub(1,2), 16) / 255
        local g = tonumber(classInfo.color:sub(3,4), 16) / 255
        local b = tonumber(classInfo.color:sub(5,6), 16) / 255
        for _, tex in pairs(button.borderTextures) do
            tex:SetColorTexture(r, g, b, 0.9)
            tex:Show()
        end
    else
        for _, tex in pairs(button.borderTextures) do
            tex:Hide()
        end
    end

    -- Clear any previous cooldown state
    button.cooldown:Clear()
    button:SetScript("OnUpdate", nil)

    button:Show()
end

--- Clean up button timers before recycling
function HB:CleanupButton(button)
    if button.cooldownTimer then
        self:CancelTimer(button.cooldownTimer)
        button.cooldownTimer = nil
    end
    if button.rechargeTimers then
        for _, ti in ipairs(button.rechargeTimers) do
            if ti.handle then
                self:CancelTimer(ti.handle)
            end
        end
        button.rechargeTimers = {}
    end
    button.cooldownEndTime = nil
    button:SetScript("OnUpdate", nil)
end

------------------------------------------------------------------------
-- Update Bar Spells
------------------------------------------------------------------------

function HB:UpdateBarSpells(barName)
    local frame = self.barFrames[barName]
    if not frame then 
        if self.db.profile.debug then
            print("|cFF00FF00[HandyBar]|r UpdateBarSpells: No frame found for bar:", barName)
        end
        return 
    end

    local barDB = self.db.profile.bars[barName]
    if not barDB then 
        if self.db.profile.debug then
            print("|cFF00FF00[HandyBar]|r UpdateBarSpells: No barDB found for:", barName)
        end
        return 
    end

    -- Return current buttons to pool
    for _, button in ipairs(frame.activeButtons) do
        self:CleanupButton(button)
        button:Hide()
        tinsert(frame.buttonPool, button)
    end
    frame.activeButtons = {}

    -- Get spells that should be visible
    local visibleSpells = self:GetVisibleSpells(barName)
    
    -- (debug) intentionally quiet here

    -- Create/configure buttons
    for _, spellData in ipairs(visibleSpells) do
        local button = self:GetOrCreateButton(frame)
        self:ConfigureButton(button, spellData, barDB)
        tinsert(frame.activeButtons, button)
    end

    -- Re-layout
    self:LayoutBar(barName)

    -- Update visibility
    self:UpdateBarVisibility(barName)
end

------------------------------------------------------------------------
-- Bar Layout
------------------------------------------------------------------------

function HB:LayoutBar(barName)
    local frame = self.barFrames[barName]
    if not frame then return end

    local barDB = self.db.profile.bars[barName]
    if not barDB then return end

    local buttons = frame.activeButtons
    local numButtons = #buttons

    if numButtons == 0 then
        frame:SetSize(1, 1)
        return
    end

    local iconSize = barDB.iconSize or 36
    local spacing = barDB.spacing or 2
    local maxPerRow = barDB.maxPerRow or 12
    local growDir = barDB.growDirection or "RIGHT"

    -- Calculate number of rows/columns needed
    local numRows = math.ceil(numButtons / maxPerRow)

    -- Calculate total bar size
    local totalWidth, totalHeight
    local maxIconsInAnyRow = math.min(numButtons, maxPerRow)
    
    if growDir == "RIGHT" or growDir == "LEFT" then
        -- Horizontal layout: rows grow horizontally, stack vertically
        totalWidth = (iconSize * maxIconsInAnyRow) + (spacing * (maxIconsInAnyRow - 1)) + 4
        totalHeight = (iconSize * numRows) + (spacing * (numRows - 1)) + 4
    else
        -- Vertical layout: columns grow vertically, stack horizontally
        totalWidth = (iconSize * numRows) + (spacing * (numRows - 1)) + 4
        totalHeight = (iconSize * maxIconsInAnyRow) + (spacing * (maxIconsInAnyRow - 1)) + 4
    end
    frame:SetSize(totalWidth, totalHeight)

    -- Position each button
    for i, button in ipairs(buttons) do
        button:ClearAllPoints()
        button:SetSize(iconSize, iconSize)

        local row = math.floor((i - 1) / maxPerRow)
        local col = (i - 1) % maxPerRow
        local xOffset, yOffset

        if growDir == "RIGHT" then
            -- Rows grow right, stack down
            xOffset = col * (iconSize + spacing) + 2
            yOffset = -(row * (iconSize + spacing) + 2)
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, yOffset)
        elseif growDir == "LEFT" then
            -- Rows grow left, stack down
            xOffset = -(col * (iconSize + spacing) + 2)
            yOffset = -(row * (iconSize + spacing) + 2)
            button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", xOffset, yOffset)
        elseif growDir == "DOWN" then
            -- Columns grow down, stack right
            xOffset = row * (iconSize + spacing) + 2
            yOffset = -(col * (iconSize + spacing) + 2)
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, yOffset)
        else -- UP
            -- Columns grow up, stack right
            xOffset = row * (iconSize + spacing) + 2
            yOffset = col * (iconSize + spacing) + 2
            button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", xOffset, yOffset)
        end
    end
end

------------------------------------------------------------------------
-- Bar Visibility
------------------------------------------------------------------------

function HB:UpdateBarVisibility(barName)
    local frame = self.barFrames[barName]
    if not frame then return end

    local barDB = self.db.profile.bars[barName]
    if not barDB or not barDB.enabled then
        frame:Hide()
        if self.db.profile.debug then
            print("|cFF00FF00[HandyBar]|r UpdateBarVisibility:", barName, "HIDDEN (not enabled)")
        end
        return
    end

    local hasButtons = #frame.activeButtons > 0
    local shouldShow = hasButtons and (self:IsTestMode() or self.inArena)
    
    if self.db.profile.debug then
        print("|cFF00FF00[HandyBar]|r UpdateBarVisibility:", barName, 
              "hasButtons=" .. tostring(hasButtons) .. " (#" .. #frame.activeButtons .. ")",
              "testMode=" .. tostring(self:IsTestMode()),
              "inArena=" .. tostring(self.inArena),
              "shouldShow=" .. tostring(shouldShow))
    end

    if shouldShow then
        frame:Show()
    else
        frame:Hide()
    end
end

function HB:UpdateAllBars()
    if self.db.profile.debug then
        local count = 0
        for _ in pairs(self.barFrames) do count = count + 1 end
        print("|cFF00FF00[HandyBar]|r UpdateAllBars: Found " .. count .. " bar frames")
    end
    
    for barName in pairs(self.barFrames) do
        self:UpdateBarSpells(barName)
    end
end

------------------------------------------------------------------------
-- Cooldown Start (Left-Click)
------------------------------------------------------------------------

function HB:StartSpellCooldown(button)
    if not button.spellData then return end

    local duration = button.spellData.duration
    if not duration or duration <= 0 then return end

    local barDB = self.db.profile.bars[button:GetParent().barName]

    if button.maxCharges > 1 then
        -- ---- Charge-based cooldown ----
        if button.currentCharges <= 0 then return end

        button.currentCharges = button.currentCharges - 1

        local startTime = GetTime()
        local endTime = startTime + duration

        local timerInfo = {
            startTime = startTime,
            endTime = endTime,
            duration = duration,
        }

        -- Schedule recharge
        timerInfo.handle = self:ScheduleTimer(function()
            button.currentCharges = button.currentCharges + 1

            -- Remove completed timer
            for i, ti in ipairs(button.rechargeTimers) do
                if ti == timerInfo then
                    tremove(button.rechargeTimers, i)
                    break
                end
            end

            self:UpdateButtonVisual(button)
        end, duration)

        tinsert(button.rechargeTimers, timerInfo)
        self:UpdateButtonVisual(button)
    else
        -- ---- Single-charge cooldown ----
        -- Cancel existing cooldown if re-clicking
        if button.cooldownTimer then
            self:CancelTimer(button.cooldownTimer)
            button.cooldownTimer = nil
        end

        local startTime = GetTime()
        button.cooldownEndTime = startTime + duration

        -- Start spiral animation
        button.cooldown:SetCooldown(startTime, duration)
        button.icon:SetDesaturated(true)

        -- Start timer text if enabled
        if barDB and barDB.showCooldownText then
            button.timerElapsed = 0
            button:SetScript("OnUpdate", CooldownTimerOnUpdate)
        end

        -- Schedule cooldown end
        button.cooldownTimer = self:ScheduleTimer(function()
            button.cooldownEndTime = nil
            button.cooldown:Clear()
            button.icon:SetDesaturated(false)
            button.timerText:SetText("")
            button:SetScript("OnUpdate", nil)
            button.cooldownTimer = nil
        end, duration)
    end
end

------------------------------------------------------------------------
-- Cooldown Reset (Right-Click)
------------------------------------------------------------------------

function HB:ResetSpellCooldown(button)
    if not button.spellData then return end

    -- Cancel all timers
    if button.cooldownTimer then
        self:CancelTimer(button.cooldownTimer)
        button.cooldownTimer = nil
    end

    if button.rechargeTimers then
        for _, ti in ipairs(button.rechargeTimers) do
            if ti.handle then self:CancelTimer(ti.handle) end
        end
        button.rechargeTimers = {}
    end

    -- Reset visual state
    button.cooldownEndTime = nil
    button.currentCharges = button.maxCharges
    button.cooldown:Clear()
    button.icon:SetDesaturated(false)
    button.timerText:SetText("")
    button:SetScript("OnUpdate", nil)

    -- Restore charge display
    if button.maxCharges > 1 then
        button.chargeText:SetText(tostring(button.currentCharges))
    end
end

------------------------------------------------------------------------
-- Charge Visual Update
------------------------------------------------------------------------

function HB:UpdateButtonVisual(button)
    if not button.spellData then return end

    if button.maxCharges <= 1 then return end

    local barDB = self.db.profile.bars[button:GetParent().barName]

    button.chargeText:SetText(tostring(button.currentCharges))

    if button.currentCharges == 0 then
        -- All charges on cooldown
        button.icon:SetDesaturated(true)
        if #button.rechargeTimers > 0 then
            local soonest = button.rechargeTimers[1]
            button.cooldown:SetCooldown(soonest.startTime, button.spellData.duration)
            button.cooldownEndTime = soonest.endTime
            if barDB and barDB.showCooldownText then
                button.timerElapsed = 0
                button:SetScript("OnUpdate", CooldownTimerOnUpdate)
            end
        end

    elseif button.currentCharges < button.maxCharges then
        -- Some charges used but not all
        button.icon:SetDesaturated(false)
        if #button.rechargeTimers > 0 then
            local soonest = button.rechargeTimers[1]
            button.cooldown:SetCooldown(soonest.startTime, button.spellData.duration)
            button.cooldownEndTime = soonest.endTime
            if barDB and barDB.showCooldownText then
                button.timerElapsed = 0
                button:SetScript("OnUpdate", CooldownTimerOnUpdate)
            end
        end

    else
        -- All charges available
        button.icon:SetDesaturated(false)
        button.cooldown:Clear()
        button.cooldownEndTime = nil
        button.timerText:SetText("")
        button:SetScript("OnUpdate", nil)
    end
end

------------------------------------------------------------------------
-- Reset All Cooldowns
------------------------------------------------------------------------

function HB:ResetAllCooldowns()
    for _, frame in pairs(self.barFrames) do
        for _, button in ipairs(frame.activeButtons) do
            self:ResetSpellCooldown(button)
        end
    end
end

function HB:ResetBarCooldowns(barName)
    local frame = self.barFrames[barName]
    if not frame then return end

    for _, button in ipairs(frame.activeButtons) do
        self:ResetSpellCooldown(button)
    end
end

------------------------------------------------------------------------
-- Lock / Unlock Bars
------------------------------------------------------------------------

function HB:LockBars()
    for _, frame in pairs(self.barFrames) do
        frame:EnableMouse(false)
        frame.title:Hide()
        frame.titleFrame:Hide()
    end
end

function HB:UnlockBars()
    for _, frame in pairs(self.barFrames) do
        frame:EnableMouse(true)
        frame.title:Show()
        frame.titleFrame:Show()
    end
end
