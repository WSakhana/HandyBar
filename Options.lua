------------------------------------------------------------------------
-- HandyBar - Options
-- AceConfig-3.0 configuration interface
------------------------------------------------------------------------
local addonName, ns = ...
local HB = ns.HB

-- Local references
local format = string.format
local pairs = pairs
local ipairs = ipairs
local tostring = tostring

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
            general = self:GetGeneralOptions(),
            bars = self:GetBarsContainerOptions(),
        },
    }
end

------------------------------------------------------------------------
-- General Tab
------------------------------------------------------------------------

function HB:GetGeneralOptions()
    return {
        type = "group",
        name = "General",
        order = 1,
        args = {
            header = {
                type = "description",
                name = "|cff00ccffHandyBar|r is a manual cooldown tracking addon for PvP Arenas.\n"
                    .. "Click enemy spell icons when you see them used to start tracking their cooldowns.\n"
                    .. "Right-click to reset a cooldown.\n",
                order = 1,
                fontSize = "medium",
            },
            spacer0 = { type = "description", name = " ", order = 5 },
            testMode = {
                type = "toggle",
                name = "Test Mode",
                desc = "Show all bars and spells for layout testing. Arena filtering is ignored.\n\n|cFFFF8800Note:|r Test Mode is not persisted and is automatically disabled on reloads and zone changes.",
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
                name = "Lock Bars",
                desc = "Prevent bars from being moved. Hides bar titles and background.",
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
                name = "Debug Mode",
                desc = "Print debug messages to chat for arena enemy detection (helps troubleshoot issues).",
                order = 22,
                width = "full",
                get = function() return HB.db.profile.debug end,
                set = function(_, val)
                    HB.db.profile.debug = val
                    if val then
                        print("|cFF00FF00[HandyBar]|r Debug mode enabled. You'll see detection messages in arena.")
                    else
                        print("|cFF00FF00[HandyBar]|r Debug mode disabled.")
                    end
                end,
            },
            spacer1 = { type = "description", name = "\n", order = 25 },
            resetAll = {
                type = "execute",
                name = "Reset All Cooldowns",
                desc = "Reset all active cooldowns on every bar.",
                order = 30,
                func = function()
                    HB:ResetAllCooldowns()
                    HB:Print("All cooldowns reset.")
                end,
                confirm = true,
                confirmText = "Reset all active cooldowns?",
            },
            resetConfig = {
                type = "execute",
                name = "|cffff0000Reset Configuration|r",
                desc = "Reset all HandyBar settings (including bars and spell selections) back to defaults.",
                order = 32,
                func = function()
                    HB:ResetConfiguration()
                end,
                confirm = true,
                confirmText = "Reset ALL HandyBar configuration to defaults?",
            },
            spacer2 = { type = "description", name = "\n", order = 35 },
            commands = {
                type = "description",
                name = "|cff888888Slash Commands:|r\n"
                    .. "  |cff00ff00/hb|r          - Open this configuration\n"
                    .. "  |cff00ff00/hb test|r      - Toggle Test Mode\n"
                    .. "  |cff00ff00/hb lock|r      - Toggle bar locking\n"
                    .. "  |cff00ff00/hb reset|r     - Reset all cooldowns\n",
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
            name = "Create New Bar",
            order = 1,
        },
        newBarName = {
            type = "input",
            name = "Bar Name",
            desc = "Enter a unique name for the new bar.",
            order = 2,
            width = "double",
            get = function() return newBarName end,
            set = function(_, val) newBarName = val end,
        },
        createBar = {
            type = "execute",
            name = "Create Bar",
            order = 3,
            func = function()
                local name = (newBarName or ""):trim()
                if name == "" then
                    HB:Print("Please enter a bar name.")
                    return
                end
                if HB.db.profile.bars[name] then
                    HB:Print("A bar named '" .. name .. "' already exists!")
                    return
                end
                HB.db.profile.bars[name] = HB:GetBarDefaults(name)
                HB:CreateBar(name)
                HB:UpdateBarSpells(name)
                newBarName = ""
                HB:RefreshOptions()
                HB:Print("Bar '|cff00ff00" .. name .. "|r' created.")
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
        name = "Bars",
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
            name = "Settings",
            order = 1,
            args = self:BuildBarSettingsArgs(barName, barDB),
        },
        spells = {
            type = "group",
            name = "Spells",
            order = 2,
            childGroups = "tree",
            args = self:BuildSpellArgs(barName, barDB),
        },
    }
end

------------------------------------------------------------------------
-- Bar Settings Arguments
------------------------------------------------------------------------

function HB:BuildBarSettingsArgs(barName, barDB)
    return {
        enabled = {
            type = "toggle",
            name = "Enabled",
            desc = "Enable or disable this bar.",
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
            name = "Icon Size",
            desc = "Size of spell icons in pixels.",
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
            name = "Spacing",
            desc = "Space between icons in pixels.",
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
            name = "Max Icons Per Row",
            desc = "Maximum number of icons per row. Bar will wrap to multiple rows if needed.",
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
            name = "Icon Display Limit",
            desc = "Limit how many spell icons can be displayed on this bar. Set to 0 for unlimited.",
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
            name = "Grow Direction",
            desc = "Direction icons are added. Rows grow horizontally, and stack vertically.",
            order = 30,
            values = {
                RIGHT = "Right (rows stack down)",
                LEFT = "Left (rows stack down)",
                DOWN = "Down (columns stack right)",
                UP = "Up (columns stack right)",
            },
            get = function() return barDB.growDirection end,
            set = function(_, val)
                barDB.growDirection = val
                HB:LayoutBar(barName)
            end,
        },
        showCooldownText = {
            type = "toggle",
            name = "Show Cooldown Text",
            desc = "Display remaining time text on icons during cooldown.",
            order = 40,
            get = function() return barDB.showCooldownText end,
            set = function(_, val)
                barDB.showCooldownText = val
                HB:UpdateBarSpells(barName)
            end,
        },
        showIconBorder = {
            type = "toggle",
            name = "Show Icon Border",
            desc = "Display class-colored borders around icons.",
            order = 50,
            get = function() return barDB.showIconBorder ~= false end,
            set = function(_, val)
                barDB.showIconBorder = val
                HB:UpdateBarSpells(barName)
            end,
        },
        duplicateSameSpecClass = {
            type = "toggle",
            name = "Duplicate Same Spec/Class",
            desc = "Show a second icon when multiple opponents share the same spec or class.",
            order = 55,
            width = "full",
            get = function() return barDB.duplicateSameSpecClass end,
            set = function(_, val)
                barDB.duplicateSameSpecClass = val
                HB:UpdateBarSpells(barName)
            end,
        },
        spacer2 = { type = "description", name = "\n", order = 85 },
        actionsHeader = {
            type = "header",
            name = "Actions",
            order = 86,
        },
        resetCooldowns = {
            type = "execute",
            name = "Reset Bar Cooldowns",
            desc = "Reset all active cooldowns on this bar.",
            order = 90,
            func = function()
                HB:ResetBarCooldowns(barName)
                HB:Print("Cooldowns reset for bar: " .. barName)
            end,
        },
        resetPosition = {
            type = "execute",
            name = "Reset Position",
            desc = "Move this bar back to the center of the screen.",
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
            name = "|cffff0000Delete This Bar|r",
            desc = "Permanently remove this bar and all its settings.",
            order = 100,
            confirm = true,
            confirmText = format(
                "Are you sure you want to delete the bar '%s'?\nThis cannot be undone.",
                barName
            ),
            func = function()
                HB:DestroyBar(barName)
                HB.db.profile.bars[barName] = nil
                HB:Print("Bar '|cffff0000" .. barName .. "|r' deleted.")
                HB:RefreshOptions()
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

    -- Ensure spells table exists
    if not barDB.spells then
        barDB.spells = {}
    end

    for i, classID in ipairs(CLASS_ORDER) do
        local classInfo = MC.Classes[classID]
        if classInfo then
            local classSpells = MC:GetByClass(classID)
            if #classSpells > 0 then
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

                for _, spell in ipairs(classSpells) do
                    local specs = spell.specs or {}
                    local bucketName

                    if #specs == 0 then
                        bucketName = "All Specs"
                    elseif #specs == 1 then
                        local specInfo = MC.SpecByID[specs[1]]
                        bucketName = (specInfo and specInfo.name) or "Unknown Spec"
                    else
                        bucketName = "Multiple Specs"
                    end

                    if not specBuckets[bucketName] then
                        specBuckets[bucketName] = {}
                    end
                    specBuckets[bucketName][#specBuckets[bucketName] + 1] = spell
                end

                -- Enable Default / Disable All buttons
                classArgs.enableDefault = {
                    type = "execute",
                    name = "Enable default",
                    order = 1,
                    width = "full",
                    func = function()
                        for _, spell in ipairs(classSpells) do
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
                    name = "Disable All",
                    order = 2,
                    width = "full",
                    func = function()
                        for _, spell in ipairs(classSpells) do
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
                local specOrder = { "All Specs" }
                for _, spec in ipairs(classSpecs) do
                    specOrder[#specOrder + 1] = spec.name
                end
                if specBuckets["Unknown Spec"] then
                    specOrder[#specOrder + 1] = "Unknown Spec"
                end
                specOrder[#specOrder + 1] = "Multiple Specs"

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
                            local displayName = format(
                                "|T%s:18:18|t %s  |cff888888(%ds)|r",
                                tostring(spellInfo.icon),
                                spellInfo.name,
                                spell.duration
                            )

                            local desc = format(
                                "Category: %s\nSpell ID: %d\nCharges: %d",
                                spell.category or "Unknown",
                                spell.spellID,
                                spell.stack or 1
                            )

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
