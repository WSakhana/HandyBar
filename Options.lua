------------------------------------------------------------------------
-- HandyBar - Options
-- AceConfig-3.0 configuration interface (refactored)
------------------------------------------------------------------------
local addonName, ns = ...
local HB = ns.HB
local L = HB.L

-- Local references
local format = string.format
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber

------------------------------------------------------------------------
-- Class display order for spell lists
------------------------------------------------------------------------
local CLASS_ORDER = {
    "WARRIOR", "PALADIN", "DEATHKNIGHT", "HUNTER", "ROGUE",
    "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "MONK",
    "DRUID", "DEMONHUNTER", "EVOKER",
}

-- State for new bar creation
local newBarName = ""

-- State for custom spell creation form
local customSpellForm = {
    spellID = "",
    duration = 120,
    class = "WARRIOR",
    spec = 0,  -- 0 = All Specs (class ability)
    category = "Utility",
    editing = false,  -- true when editing an existing spell
}

-- Helper: load existing custom spell data into the form
local function LoadCustomSpellIntoForm(spellID)
    local data = HB.db.profile.customSpells[spellID]
    if data then
        customSpellForm.spellID = tostring(spellID)
        customSpellForm.duration = data.duration
        customSpellForm.class = data.class
        customSpellForm.category = data.category or "Utility"
        customSpellForm.editing = true
        local specs = data.specs or {}
        customSpellForm.spec = (#specs == 1) and specs[1] or 0
    end
end

-- Helper: reset the form to defaults
local function ResetCustomSpellForm()
    customSpellForm.spellID = ""
    customSpellForm.duration = 120
    customSpellForm.class = "WARRIOR"
    customSpellForm.spec = 0
    customSpellForm.category = "Utility"
    customSpellForm.editing = false
end

------------------------------------------------------------------------
-- Setup
------------------------------------------------------------------------

function HB:SetupOptions()
    -- Register options table as a function for dynamic updates
    LibStub("AceConfig-3.0"):RegisterOptionsTable("HandyBar", function()
        return HB:GetOptions()
    end)

    -- Add to Blizzard options panel
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(
        "HandyBar", "HandyBar"
    )

    -- Profiles sub-panel
    local profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("HandyBar-Profiles", profileOptions)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(
        "HandyBar-Profiles", "Profiles", "HandyBar"
    )
end

function HB:OpenOptions()
    LibStub("AceConfigDialog-3.0"):Open("HandyBar")
end

function HB:RefreshOptions()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("HandyBar")
end

------------------------------------------------------------------------
-- Root Options Table
------------------------------------------------------------------------

function HB:GetOptions()
    return {
        type = "group",
        name = "|cff00ccffHandyBar|r",
        childGroups = "tab",
        args = {
            general   = self:GetGeneralOptions(),
            bars      = self:GetBarsContainerOptions(),
            customize = self:GetCustomizeOptions(),
        },
    }
end

------------------------------------------------------------------------
-- General Tab
------------------------------------------------------------------------

function HB:GetGeneralOptions()
    return {
        type = "group",
        name = L["General"],
        order = 1,
        args = {
            header = {
                type = "description",
                name = L["ADDON_DESC"],
                order = 1,
                fontSize = "medium",
            },
            spacer0 = { type = "description", name = " ", order = 5 },
            testMode = {
                type = "toggle",
                name = L["Test Mode"],
                desc = L["TEST_MODE_DESC"],
                order = 10,
                width = "full",
                get = function() return HB:IsTestMode() end,
                set = function(_, val)
                    if val then
                        HB:EnableTestMode()
                    else
                        HB:DisableTestMode()
                    end
                end,
            },
            locked = {
                type = "toggle",
                name = L["Lock Bars"],
                desc = L["LOCK_BARS_DESC"],
                order = 20,
                width = "full",
                get = function() return HB.db.profile.locked end,
                set = function(_, val)
                    HB.db.profile.locked = val
                    if val then
                        HB:LockBars()
                    else
                        HB:UnlockBars()
                    end
                end,
            },
            debug = {
                type = "toggle",
                name = L["Debug Mode"],
                desc = L["DEBUG_MODE_DESC"],
                order = 22,
                width = "full",
                get = function() return HB.db.profile.debug end,
                set = function(_, val)
                    HB.db.profile.debug = val
                    if val then
                        print(L["Debug mode enabled."])
                    else
                        print(L["Debug mode disabled."])
                    end
                end,
            },
            spacer1 = { type = "description", name = "\n", order = 25 },
            resetAll = {
                type = "execute",
                name = L["Reset All Cooldowns"],
                desc = L["RESET_ALL_CD_DESC"],
                order = 30,
                func = function()
                    HB:ResetAllCooldowns()
                    HB:Print(L["All cooldowns reset."])
                end,
                confirm = true,
                confirmText = L["Reset all active cooldowns?"],
            },
            resetConfig = {
                type = "execute",
                name = "|cffff0000" .. L["Reset Configuration"] .. "|r",
                desc = L["RESET_CONFIG_DESC"],
                order = 32,
                func = function()
                    HB:ResetConfiguration()
                end,
                confirm = true,
                confirmText = L["RESET_CONFIG_CONFIRM"],
            },
            spacer2 = { type = "description", name = "\n", order = 35 },
            commands = {
                type = "description",
                name = L["SLASH_COMMANDS_DESC"],
                order = 40,
                fontSize = "medium",
            },
        },
    }
end

------------------------------------------------------------------------
-- Bars Container Tab
------------------------------------------------------------------------

function HB:GetBarsContainerOptions()
    local args = {
        newBarHeader = {
            type = "header",
            name = L["Create New Bar"],
            order = 1,
        },
        newBarName = {
            type = "input",
            name = L["Bar Name"],
            desc = L["BAR_NAME_DESC"],
            order = 2,
            width = "double",
            get = function() return newBarName end,
            set = function(_, val) newBarName = val end,
        },
        createBar = {
            type = "execute",
            name = L["Create Bar"],
            order = 3,
            func = function()
                local name = (newBarName or ""):trim()
                if name == "" then
                    HB:Print(L["Please enter a bar name."])
                    return
                end
                if HB.db.profile.bars[name] then
                    HB:Print(format(L["BAR_EXISTS"], name))
                    return
                end
                HB.db.profile.bars[name] = HB:GetBarDefaults(name)
                HB:CreateBar(name)
                HB:UpdateBarSpells(name)
                newBarName = ""
                HB:RefreshOptions()
                HB:Print(format(L["BAR_CREATED"], name))
            end,
        },
        barsSpacer = {
            type = "description",
            name = "\n",
            order = 5,
        },
    }

    -- Add dynamic bar groups
    local order = 10
    for barName, barDB in pairs(self.db.profile.bars) do
        local safeKey = "bar_" .. barName:gsub("[^%w]", "_")
        args[safeKey] = {
            type = "group",
            name = barName,
            order = order,
            childGroups = "tab",
            args = self:BuildSingleBarArgs(barName),
        }
        order = order + 1
    end

    return {
        type = "group",
        name = L["Bars"],
        order = 2,
        childGroups = "tree",
        args = args,
    }
end

------------------------------------------------------------------------
-- Single Bar Options
------------------------------------------------------------------------

function HB:BuildSingleBarArgs(barName)
    local barDB = self.db.profile.bars[barName]
    if not barDB then return {} end

    return {
        settings = {
            type = "group",
            name = L["Appearance"],
            order = 1,
            args = self:BuildBarSettingsArgs(barName, barDB),
        },
        arenaVisibility = {
            type = "group",
            name = L["Arena Visibility"],
            order = 2,
            args = self:BuildArenaVisibilityArgs(barName, barDB),
        },
        spells = {
            type = "group",
            name = L["Spells"],
            order = 3,
            childGroups = "tree",
            args = self:BuildSpellArgs(barName, barDB),
        },
    }
end

------------------------------------------------------------------------
-- Bar Settings (Appearance)
------------------------------------------------------------------------

function HB:BuildBarSettingsArgs(barName, barDB)
    return {
        enabled = {
            type = "toggle",
            name = L["Enabled"],
            desc = L["ENABLED_DESC"],
            order = 1,
            width = "full",
            get = function() return barDB.enabled end,
            set = function(_, val)
                barDB.enabled = val
                if val then
                    HB:CreateBar(barName)
                else
                    HB:DestroyBar(barName)
                end
                HB:UpdateAllBars()
            end,
        },
        spacer1 = { type = "description", name = "", order = 5 },
        iconSize = {
            type = "range",
            name = L["Icon Size"],
            desc = L["ICON_SIZE_DESC"],
            order = 10,
            min = 20, max = 64, step = 1,
            get = function() return barDB.iconSize end,
            set = function(_, val)
                barDB.iconSize = val
                HB:UpdateBarSpells(barName)
            end,
        },
        spacing = {
            type = "range",
            name = L["Spacing"],
            desc = L["SPACING_DESC"],
            order = 20,
            min = 0, max = 20, step = 1,
            get = function() return barDB.spacing end,
            set = function(_, val)
                barDB.spacing = val
                HB:LayoutBar(barName)
            end,
        },
        maxPerRow = {
            type = "range",
            name = L["Max Icons Per Row"],
            desc = L["MAX_PER_ROW_DESC"],
            order = 25,
            min = 1, max = 20, step = 1,
            get = function() return barDB.maxPerRow or 12 end,
            set = function(_, val)
                barDB.maxPerRow = val
                HB:LayoutBar(barName)
            end,
        },
        maxIcons = {
            type = "range",
            name = L["Icon Display Limit"],
            desc = L["MAX_ICONS_DESC"],
            order = 26,
            min = 0, max = 60, step = 1,
            get = function() return barDB.maxIcons or 0 end,
            set = function(_, val)
                barDB.maxIcons = val
                HB:UpdateBarSpells(barName)
            end,
        },
        growDirection = {
            type = "select",
            name = L["Grow Direction"],
            desc = L["GROW_DIR_DESC"],
            order = 30,
            values = {
                RIGHT = L["Right (rows stack down)"],
                LEFT  = L["Left (rows stack down)"],
                DOWN  = L["Down (columns stack right)"],
                UP    = L["Up (columns stack right)"],
            },
            get = function() return barDB.growDirection end,
            set = function(_, val)
                barDB.growDirection = val
                HB:LayoutBar(barName)
            end,
        },
        showCooldownText = {
            type = "toggle",
            name = L["Show Cooldown Text"],
            desc = L["SHOW_CD_TEXT_DESC"],
            order = 40,
            get = function() return barDB.showCooldownText end,
            set = function(_, val)
                barDB.showCooldownText = val
                HB:UpdateBarSpells(barName)
            end,
        },
        showIconBorder = {
            type = "toggle",
            name = L["Show Icon Border"],
            desc = L["SHOW_BORDER_DESC"],
            order = 50,
            get = function() return barDB.showIconBorder ~= false end,
            set = function(_, val)
                barDB.showIconBorder = val
                HB:UpdateBarSpells(barName)
            end,
        },
        spacer2 = { type = "description", name = "\n", order = 85 },
        actionsHeader = {
            type = "header",
            name = L["Actions"],
            order = 86,
        },
        resetCooldowns = {
            type = "execute",
            name = L["Reset Bar Cooldowns"],
            desc = L["RESET_BAR_CD_DESC"],
            order = 90,
            func = function()
                HB:ResetBarCooldowns(barName)
                HB:Print(format(L["COOLDOWNS_RESET_BAR"], barName))
            end,
        },
        resetPosition = {
            type = "execute",
            name = L["Reset Position"],
            desc = L["RESET_POS_DESC"],
            order = 91,
            func = function()
                barDB.position = nil
                local frame = HB.barFrames[barName]
                if frame then
                    frame:ClearAllPoints()
                    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                end
            end,
        },
        spacer3 = { type = "description", name = "\n\n", order = 95 },
        deleteBar = {
            type = "execute",
            name = "|cffff0000" .. L["Delete This Bar"] .. "|r",
            desc = L["DELETE_BAR_DESC"],
            order = 100,
            confirm = true,
            confirmText = format(L["DELETE_BAR_CONFIRM"], barName),
            func = function()
                HB:DestroyBar(barName)
                HB.db.profile.bars[barName] = nil
                HB:Print(format(L["BAR_DELETED"], barName))
                HB:RefreshOptions()
            end,
        },
    }
end

------------------------------------------------------------------------
-- Arena Visibility Arguments
------------------------------------------------------------------------

function HB:BuildArenaVisibilityArgs(barName, barDB)
    -- Migrate old data: ensure arenaVisibility exists
    if not barDB.arenaVisibility then
        barDB.arenaVisibility = "ALL"
    end

    return {
        visDesc = {
            type = "description",
            name = L["ARENA_VIS_NOTE"] .. "\n",
            order = 1,
            fontSize = "medium",
        },
        visibilityMode = {
            type = "select",
            name = L["Visibility Mode"],
            desc = L["VISIBILITY_MODE_DESC"],
            order = 10,
            width = "double",
            values = {
                ALL    = L["All Enemies"],
                ARENA1 = L["Arena 1 Only"],
                ARENA2 = L["Arena 2 Only"],
                ARENA3 = L["Arena 3 Only"],
            },
            get = function() return barDB.arenaVisibility or "ALL" end,
            set = function(_, val)
                barDB.arenaVisibility = val
                HB:UpdateBarSpells(barName)
            end,
        },
        spacer1 = { type = "description", name = "\n", order = 20 },
        duplicateSameSpecClass = {
            type = "toggle",
            name = L["Duplicate Same Spec/Class"],
            desc = L["DUPLICATE_DESC"],
            order = 30,
            width = "full",
            get = function() return barDB.duplicateSameSpecClass end,
            set = function(_, val)
                barDB.duplicateSameSpecClass = val
                HB:UpdateBarSpells(barName)
            end,
        },
    }
end

------------------------------------------------------------------------
-- Spell Selection Arguments (organized by class)
------------------------------------------------------------------------

function HB:BuildSpellArgs(barName, barDB)
    local MC = self.MC
    local args = {}
    local customSpells = self.db.profile.customSpells or {}

    -- Ensure spells table exists
    if not barDB.spells then
        barDB.spells = {}
    end

    for i, classID in ipairs(CLASS_ORDER) do
        local classInfo = MC.Classes[classID]
        if classInfo then
            local classSpells = MC:GetByClass(classID)
            local filteredClassSpells = {}
            for _, spell in ipairs(classSpells) do
                if spell.key and spell.key:sub(1, 7) == "custom_" then
                    if customSpells[spell.spellID] then
                        filteredClassSpells[#filteredClassSpells + 1] = spell
                    end
                else
                    filteredClassSpells[#filteredClassSpells + 1] = spell
                end
            end

            if #filteredClassSpells > 0 then
                local classArgs = {}

                -- Build spec buckets
                local specBuckets = {}
                local classSpecs = {}
                for _, spec in pairs(MC.Specs) do
                    if spec.class == classID then
                        classSpecs[#classSpecs + 1] = spec
                    end
                end
                table.sort(classSpecs, function(a, b)
                    return (a.name or "") < (b.name or "")
                end)

                for _, spell in ipairs(filteredClassSpells) do
                    local specs = spell.specs or {}
                    local bucketName

                    if #specs == 0 then
                        bucketName = L["All Specs"]
                    elseif #specs == 1 then
                        local specInfo = MC.SpecByID[specs[1]]
                        bucketName = (specInfo and specInfo.name) or L["Unknown Spec"]
                    else
                        bucketName = L["Multiple Specs"]
                    end

                    if not specBuckets[bucketName] then
                        specBuckets[bucketName] = {}
                    end
                    specBuckets[bucketName][#specBuckets[bucketName] + 1] = spell
                end

                -- Enable Default / Disable All buttons
                classArgs.enableDefault = {
                    type = "execute",
                    name = L["Enable Default"],
                    order = 1,
                    width = "full",
                    func = function()
                        for _, spell in ipairs(filteredClassSpells) do
                            if spell.defaultEnabled then
                                barDB.spells[spell.key] = true
                            else
                                barDB.spells[spell.key] = nil
                            end
                        end
                        HB:UpdateBarSpells(barName)
                    end,
                }
                classArgs.disableAll = {
                    type = "execute",
                    name = L["Disable All"],
                    order = 2,
                    width = "full",
                    func = function()
                        for _, spell in ipairs(filteredClassSpells) do
                            barDB.spells[spell.key] = nil
                        end
                        HB:UpdateBarSpells(barName)
                    end,
                }
                classArgs.spacer = {
                    type = "description",
                    name = "",
                    order = 3,
                }

                -- Spec groups and spell toggles
                local spellOrder = 10
                local specOrder = { L["All Specs"] }
                for _, spec in ipairs(classSpecs) do
                    specOrder[#specOrder + 1] = spec.name
                end
                if specBuckets[L["Unknown Spec"]] then
                    specOrder[#specOrder + 1] = L["Unknown Spec"]
                end
                specOrder[#specOrder + 1] = L["Multiple Specs"]

                for _, specName in ipairs(specOrder) do
                    local bucket = specBuckets[specName]
                    if bucket and #bucket > 0 then
                        table.sort(bucket, function(a, b)
                            local an = (self:GetSpellData(a.spellID).name or "")
                            local bn = (self:GetSpellData(b.spellID).name or "")
                            if an ~= bn then return an < bn end
                            return a.key < b.key
                        end)

                        classArgs["header_" .. specName:gsub("%s", "_")] = {
                            type = "header",
                            name = specName,
                            order = spellOrder,
                        }
                        spellOrder = spellOrder + 1

                        for _, spell in ipairs(bucket) do
                            local spellInfo = self:GetSpellData(spell.spellID)
                            local effectiveDuration = self:GetEffectiveDuration(spell)
                            local displayName = format(
                                "|T%s:18:18|t %s  |cff888888(%ds)|r",
                                tostring(spellInfo.icon),
                                spellInfo.name,
                                effectiveDuration
                            )

                            local desc = format(
                                "%s: %s\n%s: %d\n",
                                L["Category"],
                                spell.category or "Unknown",
                                L["Spell ID"],
                                spell.spellID
                            )
                            if spell.stack and spell.stack > 1 then
                                desc = desc .. format("Charges: %d\n", spell.stack)
                            end
                            if effectiveDuration ~= spell.duration then
                                desc = desc .. format(
                                    "|cffFFAA00%s: %ds (default: %ds)|r",
                                    L["Override Duration"],
                                    effectiveDuration,
                                    spell.duration
                                )
                            end

                            classArgs["spell_" .. spell.key] = {
                                type = "toggle",
                                name = displayName,
                                desc = desc,
                                order = spellOrder,
                                width = "full",
                                get = function()
                                    return barDB.spells[spell.key] or false
                                end,
                                set = function(_, val)
                                    barDB.spells[spell.key] = val or nil
                                    HB:UpdateBarSpells(barName)
                                end,
                            }
                            spellOrder = spellOrder + 1
                        end
                    end
                end

                -- Class group with colored name
                local colorHex = classInfo.color
                args["class_" .. classID] = {
                    type = "group",
                    name = format("|cff%s%s|r", colorHex, classInfo.name),
                    order = i,
                    args = classArgs,
                }
            end
        end
    end

    return args
end

------------------------------------------------------------------------
-- =====================================================================
-- Customize Tab: Duration Overrides + Custom Spells
-- =====================================================================
------------------------------------------------------------------------

function HB:GetCustomizeOptions()
    return {
        type = "group",
        name = L["Customize"],
        order = 3,
        childGroups = "tab",
        args = {
            overrides = {
                type = "group",
                name = L["Cooldown Overrides"],
                order = 1,
                childGroups = "tree",
                args = self:BuildDurationOverrideArgs(),
            },
            customSpells = {
                type = "group",
                name = L["Custom Spells"],
                order = 2,
                args = self:BuildCustomSpellArgs(),
            },
        },
    }
end

------------------------------------------------------------------------
-- Duration Override Arguments (per class)
------------------------------------------------------------------------

function HB:BuildDurationOverrideArgs()
    local MC = self.MC
    local args = {}

    args.desc = {
        type = "description",
        name = L["CD_OVERRIDE_DESC"] .. "\n",
        order = 1,
        fontSize = "medium",
    }

    for i, classID in ipairs(CLASS_ORDER) do
        local classInfo = MC.Classes[classID]
        if classInfo then
            local classSpells = MC:GetByClass(classID)
            if #classSpells > 0 then
                local classArgs = {}

                -- Build spec buckets (same as spell selection panel)
                local specBuckets = {}
                local classSpecs = {}
                for _, spec in pairs(MC.Specs) do
                    if spec.class == classID then
                        classSpecs[#classSpecs + 1] = spec
                    end
                end
                table.sort(classSpecs, function(a, b)
                    return (a.name or "") < (b.name or "")
                end)

                for _, spell in ipairs(classSpells) do
                    local specs = spell.specs or {}
                    local bucketName
                    if #specs == 0 then
                        bucketName = L["All Specs"]
                    elseif #specs == 1 then
                        local specInfo = MC.SpecByID[specs[1]]
                        bucketName = (specInfo and specInfo.name) or L["Unknown Spec"]
                    else
                        bucketName = L["Multiple Specs"]
                    end
                    if not specBuckets[bucketName] then
                        specBuckets[bucketName] = {}
                    end
                    specBuckets[bucketName][#specBuckets[bucketName] + 1] = spell
                end

                -- Determine spec display order
                local specOrder = { L["All Specs"] }
                for _, spec in ipairs(classSpecs) do
                    specOrder[#specOrder + 1] = spec.name
                end
                if specBuckets[L["Unknown Spec"]] then
                    specOrder[#specOrder + 1] = L["Unknown Spec"]
                end
                specOrder[#specOrder + 1] = L["Multiple Specs"]

                local itemOrder = 1
                for _, specName in ipairs(specOrder) do
                    local bucket = specBuckets[specName]
                    if bucket and #bucket > 0 then
                        table.sort(bucket, function(a, b)
                            local an = (self:GetSpellData(a.spellID).name or "")
                            local bn = (self:GetSpellData(b.spellID).name or "")
                            if an ~= bn then return an < bn end
                            return a.key < b.key
                        end)

                        classArgs["header_" .. specName:gsub("%s", "_")] = {
                            type = "header",
                            name = specName,
                            order = itemOrder,
                        }
                        itemOrder = itemOrder + 1

                        for _, spell in ipairs(bucket) do
                            local spellInfo = self:GetSpellData(spell.spellID)
                            local isOverridden = HB.db.profile.durationOverrides[spell.key] ~= nil
                            local displayName = format(
                                "|T%s:16:16|t %s",
                                tostring(spellInfo.icon),
                                spellInfo.name
                            )

                            -- Checkbox: toggle override on/off
                            classArgs["toggle_" .. spell.key] = {
                                type = "toggle",
                                name = displayName,
                                desc = format(
                                    "%s: %ds  |  %s: %d",
                                    L["Default Duration"], spell.duration,
                                    L["Spell ID"], spell.spellID
                                ),
                                order = itemOrder,
                                width = 1.2,
                                get = function()
                                    return HB.db.profile.durationOverrides[spell.key] ~= nil
                                end,
                                set = function(_, val)
                                    if val then
                                        HB.db.profile.durationOverrides[spell.key] = spell.duration
                                    else
                                        HB.db.profile.durationOverrides[spell.key] = nil
                                    end
                                    HB:UpdateAllBars()
                                    HB:RefreshOptions()
                                end,
                            }

                            -- Slider: only shown when override is active
                            if isOverridden then
                                classArgs["slider_" .. spell.key] = {
                                    type = "range",
                                    name = "",
                                    desc = format("%s: %ds", L["Default Duration"], spell.duration),
                                    order = itemOrder + 0.5,
                                    width = 1.2,
                                    min = 1, max = 600, step = 1, bigStep = 5,
                                    get = function()
                                        return HB.db.profile.durationOverrides[spell.key] or spell.duration
                                    end,
                                    set = function(_, val)
                                        HB.db.profile.durationOverrides[spell.key] = val
                                        HB:UpdateAllBars()
                                    end,
                                }
                            end

                            itemOrder = itemOrder + 1
                        end
                    end
                end

                local colorHex = classInfo.color
                args["class_" .. classID] = {
                    type = "group",
                    name = format("|cff%s%s|r", colorHex, classInfo.name),
                    order = i + 1,
                    args = classArgs,
                }
            end
        end
    end

    return args
end

------------------------------------------------------------------------
-- Custom Spell Arguments
------------------------------------------------------------------------

function HB:BuildCustomSpellArgs()
    local MC = self.MC
    local args = {}

    args.desc = {
        type = "description",
        name = L["CUSTOM_SPELLS_DESC"] .. "\n",
        order = 1,
        fontSize = "medium",
    }

    -- ---- Existing custom spells list (shown LAST) ----
    args.customListHeader = {
        type = "header",
        name = L["Custom Spells"],
        order = 200,
    }

    local customSpells = self.db.profile.customSpells or {}
    local listOrder = 201

    -- Sort by spellID for consistent display
    local sortedIDs = {}
    for spellID in pairs(customSpells) do
        sortedIDs[#sortedIDs + 1] = spellID
    end
    table.sort(sortedIDs)

    if #sortedIDs == 0 then
        args.noCustom = {
            type = "description",
            name = "|cff888888" .. L["No custom spells added yet."] .. "|r\n",
            order = listOrder,
        }
        listOrder = listOrder + 1
    else
        for _, spellID in ipairs(sortedIDs) do
            local data = customSpells[spellID]
            local spellInfo = self:GetSpellData(spellID)
            local classInfo = MC.Classes[data.class]
            local colorHex = classInfo and classInfo.color or "FFFFFF"
            local className = classInfo and classInfo.name or data.class

            -- Resolve spec name
            local specName = L["All Specs"]
            local specs = data.specs or {}
            if #specs == 1 then
                local specInfo = MC.SpecByID[specs[1]]
                specName = specInfo and specInfo.name or L["Unknown Spec"]
            elseif #specs > 1 then
                specName = L["Multiple Specs"]
            end

            local groupArgs = {}

            groupArgs.info = {
                type = "description",
                name = format(
                    "%s: %ds  |  |cff%s%s|r / %s  |  %s: %s",
                    L["Cooldown (seconds)"], data.duration,
                    colorHex, className,
                    specName,
                    L["Category"], data.category or "Utility"
                ),
                order = 1,
            }

            groupArgs.edit = {
                type = "execute",
                name = L["Edit"],
                order = 2,
                func = function()
                    LoadCustomSpellIntoForm(spellID)
                    HB:RefreshOptions()
                end,
            }

            groupArgs.remove = {
                type = "execute",
                name = "|cffff0000" .. L["Remove"] .. "|r",
                order = 3,
                confirm = true,
                confirmText = format(L["REMOVE_CUSTOM_CONFIRM"], spellInfo.name),
                func = function()
                    -- If we're editing this spell, clear the form
                    if tonumber(customSpellForm.spellID) == spellID then
                        ResetCustomSpellForm()
                    end
                    HB:RemoveCustomSpell(spellID)
                    HB:Print(format(L["CUSTOM_REMOVED"], spellInfo.name))
                    HB:UpdateAllBars()
                    HB:RefreshOptions()
                end,
            }

            args["custom_" .. spellID] = {
                type = "group",
                name = format("|T%s:16:16|t %s", tostring(spellInfo.icon), spellInfo.name),
                order = listOrder,
                inline = true,
                args = groupArgs,
            }
            listOrder = listOrder + 1
        end
    end

    -- ---- Add / Edit form ----
    local isEditing = customSpellForm.editing
    local formTitle = isEditing and L["Edit Custom Spell"] or L["Add Custom Spell"]

    args.formHeader = {
        type = "header",
        name = formTitle,
        order = 100,
    }

    -- Build class values for dropdown
    local classValues = {}
    for _, classID in ipairs(CLASS_ORDER) do
        local classInfo = MC.Classes[classID]
        if classInfo then
            classValues[classID] = classInfo.name
        end
    end

    -- Build spec values filtered by the currently selected class
    local specValues = { [0] = L["All Specs"] .. " (" .. L["Class Ability"] .. ")" }
    for _, spec in pairs(MC.Specs) do
        if spec.class == customSpellForm.class then
            specValues[spec.id] = spec.name
        end
    end

    -- Build category values for dropdown
    local categoryValues = {}
    for catKey, catName in pairs(MC.Category) do
        categoryValues[catName] = catName
    end

    args.spellID = {
        type = "input",
        name = L["Spell ID"],
        desc = L["SPELL_ID_DESC"],
        order = 101,
        width = "normal",
        disabled = isEditing,  -- can't change spell ID when editing
        get = function() return customSpellForm.spellID end,
        set = function(_, val)
            customSpellForm.spellID = val
            -- Check if this spell already exists -> auto-switch to edit mode
            local id = tonumber(val)
            if id and id > 0 and HB.db.profile.customSpells[id] then
                LoadCustomSpellIntoForm(id)
            else
                customSpellForm.editing = false
            end
            HB:RefreshOptions()
        end,
    }

    -- Preview: show spell name + icon when a valid spell ID is entered
    local previewID = tonumber(customSpellForm.spellID)
    if previewID and previewID > 0 then
        local previewInfo = self:GetSpellData(previewID)
        local previewText = format(
            "|T%s:20:20|t  |cffffffff%s|r  (ID: %d)",
            tostring(previewInfo.icon),
            previewInfo.name,
            previewID
        )
        if isEditing then
            previewText = previewText .. "  |cff00ccff[" .. L["Editing"] .. "]|r"
        end
        args.preview = {
            type = "description",
            name = previewText,
            order = 102,
            fontSize = "medium",
        }
    end

    args.classSelect = {
        type = "select",
        name = L["Class"],
        desc = L["CLASS_DESC"],
        order = 103,
        values = classValues,
        get = function() return customSpellForm.class end,
        set = function(_, val)
            customSpellForm.class = val
            customSpellForm.spec = 0  -- reset spec when class changes
            HB:RefreshOptions()
        end,
    }
    args.specSelect = {
        type = "select",
        name = L["Specialization"],
        desc = L["SPEC_DESC"],
        order = 104,
        values = specValues,
        get = function() return customSpellForm.spec end,
        set = function(_, val) customSpellForm.spec = val end,
    }
    args.categorySelect = {
        type = "select",
        name = L["Category"],
        desc = L["CATEGORY_DESC"],
        order = 105,
        values = categoryValues,
        get = function() return customSpellForm.category end,
        set = function(_, val) customSpellForm.category = val end,
    }
    args.duration = {
        type = "range",
        name = L["Cooldown (seconds)"],
        desc = L["CD_SECONDS_DESC"],
        order = 106,
        min = 1, max = 600, step = 1, bigStep = 5,
        width = "double",
        get = function() return customSpellForm.duration end,
        set = function(_, val) customSpellForm.duration = val end,
    }

    -- Save / Add button
    args.saveButton = {
        type = "execute",
        name = isEditing and ("|cff00ff00" .. L["Save Changes"] .. "|r") or L["Add Custom Spell"],
        order = 107,
        func = function()
            local spellID = tonumber(customSpellForm.spellID)
            if not spellID or spellID <= 0 then
                HB:Print(L["CUSTOM_INVALID_ID"])
                return
            end
            -- Block adding duplicates (but allow saving edits)
            if not customSpellForm.editing and HB.db.profile.customSpells[spellID] then
                HB:Print(L["CUSTOM_ALREADY_EXISTS"])
                return
            end
            local specs = {}
            if customSpellForm.spec ~= 0 then
                specs = { customSpellForm.spec }
            end
            HB:RegisterCustomSpell(
                spellID,
                customSpellForm.duration,
                customSpellForm.class,
                customSpellForm.category,
                specs
            )
            local spellInfo = HB:GetSpellData(spellID)
            if customSpellForm.editing then
                HB:Print(format(L["CUSTOM_UPDATED"], spellInfo.name, spellID))
            else
                HB:Print(format(L["CUSTOM_ADDED"], spellInfo.name, spellID))
            end
            ResetCustomSpellForm()
            HB:UpdateAllBars()
            HB:RefreshOptions()
        end,
    }

    -- Cancel button (only shown in edit mode)
    if isEditing then
        args.cancelButton = {
            type = "execute",
            name = L["Cancel"],
            order = 108,
            func = function()
                ResetCustomSpellForm()
                HB:RefreshOptions()
            end,
        }
    end

    return args
end
