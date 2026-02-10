------------------------------------------------------------------------
-- HandyBar - Locale: English (Default)
------------------------------------------------------------------------
local addonName, ns = ...

local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)
if not L then return end

------------------------------------------------------------------------
-- General
------------------------------------------------------------------------
L["HandyBar"] = "HandyBar"
L["ADDON_DESC"] = "|cff00ccffHandyBar|r is a manual cooldown tracking addon for PvP Arenas.\nClick enemy spell icons when you see them used to start tracking their cooldowns.\nRight-click to reset a cooldown.\n"
L["General"] = "General"
L["Bars"] = "Bars"
L["Customize"] = "Customize"

------------------------------------------------------------------------
-- General Tab
------------------------------------------------------------------------
L["Test Mode"] = "Test Mode"
L["TEST_MODE_DESC"] = "Show all bars and spells for layout testing. Arena filtering is ignored.\n\n|cFFFF8800Note:|r Test Mode is not persisted and is automatically disabled on reloads and zone changes."
L["Test Mode enabled."] = "|cff00ff00Test Mode enabled.|r All bars and spells are now visible."
L["Test Mode disabled."] = "|cffff0000Test Mode disabled.|r"
L["Lock Bars"] = "Lock Bars"
L["LOCK_BARS_DESC"] = "Prevent bars from being moved. Hides bar titles and background."
L["Icon Tooltips"] = "Icon Tooltips"
L["ICON_TOOLTIPS_DESC"] = "Show a tooltip when hovering spell icons."
L["Debug Mode"] = "Debug Mode"
L["DEBUG_MODE_DESC"] = "Print debug messages to chat for arena enemy detection (helps troubleshoot issues)."
L["Debug mode enabled."] = "|cFF00FF00[HandyBar]|r Debug mode enabled. You'll see detection messages in arena."
L["Debug mode disabled."] = "|cFF00FF00[HandyBar]|r Debug mode disabled."
L["Reset All Cooldowns"] = "Reset All Cooldowns"
L["RESET_ALL_CD_DESC"] = "Reset all active cooldowns on every bar."
L["Reset all active cooldowns?"] = "Reset all active cooldowns?"
L["All cooldowns reset."] = "All cooldowns reset."
L["Reset Configuration"] = "Reset Configuration"
L["RESET_CONFIG_DESC"] = "Reset all HandyBar settings (including bars and spell selections) back to defaults."
L["RESET_CONFIG_CONFIRM"] = "Reset ALL HandyBar configuration to defaults?"
L["Configuration reset to defaults."] = "Configuration reset to defaults."

------------------------------------------------------------------------
-- Slash Commands
------------------------------------------------------------------------
L["SLASH_COMMANDS_DESC"] = "|cff888888Slash Commands:|r\n  |cff00ff00/hb|r          - Open this configuration\n  |cff00ff00/hb test|r      - Toggle Test Mode\n  |cff00ff00/hb lock|r      - Toggle bar locking\n  |cff00ff00/hb reset|r     - Reset all cooldowns\n"
L["HandyBar Commands:"] = "|cff00ff00HandyBar Commands:|r"
L["CMD_CONFIG"] = "  /hb          - Open configuration"
L["CMD_TEST"] = "  /hb test     - Toggle Test Mode"
L["CMD_LOCK"] = "  /hb lock     - Toggle bar locking"
L["CMD_RESET"] = "  /hb reset    - Reset all cooldowns"

------------------------------------------------------------------------
-- Bars
------------------------------------------------------------------------
L["Create New Bar"] = "Create New Bar"
L["Bar Name"] = "Bar Name"
L["BAR_NAME_DESC"] = "Enter a unique name for the new bar."
L["Create Bar"] = "Create Bar"
L["Please enter a bar name."] = "Please enter a bar name."
L["BAR_EXISTS"] = "A bar named '%s' already exists!"
L["BAR_CREATED"] = "Bar '|cff00ff00%s|r' created."
L["BAR_DELETED"] = "Bar '|cffff0000%s|r' deleted."

------------------------------------------------------------------------
-- Bar Settings
------------------------------------------------------------------------
L["Settings"] = "Settings"
L["Appearance"] = "Appearance"
L["Enabled"] = "Enabled"
L["ENABLED_DESC"] = "Enable or disable this bar."
L["Icon Size"] = "Icon Size"
L["ICON_SIZE_DESC"] = "Size of spell icons in pixels."
L["Spacing"] = "Spacing"
L["SPACING_DESC"] = "Space between icons in pixels."
L["Max Icons Per Row"] = "Max Icons Per Row"
L["MAX_PER_ROW_DESC"] = "Maximum number of icons per row. Bar will wrap to multiple rows if needed."
L["Icon Display Limit"] = "Icon Display Limit"
L["MAX_ICONS_DESC"] = "Limit how many spell icons can be displayed on this bar. Set to 0 for unlimited."
L["Grow Direction"] = "Grow Direction"
L["GROW_DIR_DESC"] = "Direction icons are added. Rows grow horizontally, and stack vertically."
L["Right (rows stack down)"] = "Right (rows stack down)"
L["Left (rows stack down)"] = "Left (rows stack down)"
L["Down (columns stack right)"] = "Down (columns stack right)"
L["Up (columns stack right)"] = "Up (columns stack right)"
L["Show Cooldown Text"] = "Show Cooldown Text"
L["SHOW_CD_TEXT_DESC"] = "Display remaining time text on icons during cooldown."
L["Show Icon Border"] = "Show Icon Border"
L["SHOW_BORDER_DESC"] = "Display class-colored borders around icons."

------------------------------------------------------------------------
-- Arena Visibility
------------------------------------------------------------------------
L["Arena Visibility"] = "Arena Visibility"
L["Visibility Mode"] = "Visibility Mode"
L["VISIBILITY_MODE_DESC"] = "Choose which arena opponents this bar tracks spells for."
L["All Enemies"] = "All Enemies"
L["Arena 1 Only"] = "Arena 1 Only"
L["Arena 2 Only"] = "Arena 2 Only"
L["Arena 3 Only"] = "Arena 3 Only"
L["Duplicate Same Spec/Class"] = "Duplicate Same Spec/Class"
L["DUPLICATE_DESC"] = "Show a second icon when multiple opponents share the same spec or class."
L["ARENA_VIS_NOTE"] = "|cff888888Note:|r When 'All Enemies' is selected, spells from all detected opponents are shown. Selecting a specific arena slot filters to that opponent only."

------------------------------------------------------------------------
-- Bar Actions
------------------------------------------------------------------------
L["Actions"] = "Actions"
L["Reset Bar Cooldowns"] = "Reset Bar Cooldowns"
L["RESET_BAR_CD_DESC"] = "Reset all active cooldowns on this bar."
L["COOLDOWNS_RESET_BAR"] = "Cooldowns reset for bar: %s"
L["Reset Position"] = "Reset Position"
L["RESET_POS_DESC"] = "Move this bar back to the center of the screen."
L["Delete This Bar"] = "Delete This Bar"
L["DELETE_BAR_DESC"] = "Permanently remove this bar and all its settings."
L["DELETE_BAR_CONFIRM"] = "Are you sure you want to delete the bar '%s'?\nThis cannot be undone."

------------------------------------------------------------------------
-- Spells
------------------------------------------------------------------------
L["Spells"] = "Spells"
L["Enable Default"] = "Enable Default"
L["Disable All"] = "Disable All"
L["All Specs"] = "All Specs"
L["Multiple Specs"] = "Multiple Specs"
L["Unknown Spec"] = "Unknown Spec"

------------------------------------------------------------------------
-- Customize Tab
------------------------------------------------------------------------
L["Cooldown Overrides"] = "Cooldown Overrides"
L["CD_OVERRIDE_DESC"] = "Override the default cooldown duration for any spell from MajorCooldowns.\nChanges apply to all bars."
L["Custom Spells"] = "Custom Spells"
L["CUSTOM_SPELLS_DESC"] = "Add your own custom spells that are not included in MajorCooldowns.\nCustom spells can be assigned to any bar."
L["Spell ID"] = "Spell ID"
L["SPELL_ID_DESC"] = "The numeric Spell ID from Wowhead or the in-game tooltip."
L["Cooldown (seconds)"] = "Cooldown (seconds)"
L["CD_SECONDS_DESC"] = "Cooldown duration in seconds."
L["Class"] = "Class"
L["CLASS_DESC"] = "The class this spell belongs to."
L["Specialization"] = "Specialization"
L["SPEC_DESC"] = "The specialization this spell belongs to, or All Specs for class-wide abilities."
L["Class Ability"] = "Class Ability"
L["Category"] = "Category"
L["CATEGORY_DESC"] = "The category of this spell."
L["Add Custom Spell"] = "Add Custom Spell"
L["Edit Custom Spell"] = "Edit Custom Spell"
L["Edit"] = "Edit"
L["Editing"] = "Editing"
L["Save Changes"] = "Save Changes"
L["Cancel"] = "Cancel"
L["Remove"] = "Remove"
L["REMOVE_CUSTOM_CONFIRM"] = "Remove custom spell '%s'?"
L["CUSTOM_ADDED"] = "Custom spell '|cff00ff00%s|r' (ID: %d) added."
L["CUSTOM_UPDATED"] = "Custom spell '|cff00ccff%s|r' (ID: %d) updated."
L["CUSTOM_REMOVED"] = "Custom spell '|cffff0000%s|r' removed."
L["CUSTOM_INVALID_ID"] = "Invalid Spell ID. Please enter a valid number."
L["CUSTOM_ALREADY_EXISTS"] = "A custom spell with that Spell ID already exists."
L["No custom spells added yet."] = "No custom spells added yet."
L["Default Duration"] = "Default Duration"
L["Override Duration"] = "Override Duration"
L["OVERRIDE_DURATION_DESC"] = "Override cooldown duration in seconds. Set to 0 to use default."
L["Reset Override"] = "Reset Override"
L["Select a class..."] = "Select a class..."

------------------------------------------------------------------------
-- Tooltips
------------------------------------------------------------------------
L["Cooldown: %ds"] = "Cooldown: %ds"
L["Category: %s"] = "Category: %s"
L["TOOLTIP_CD_OVERRIDE"] = "|cffFFAA00Cooldown: %ds|r |cff888888(default: %ds)|r"
L["TOOLTIP_SPEC_FORMAT"] = "%s - %s"
L["TOOLTIP_OVERRIDE_ACTIVE"] = "|cffFFAA00Override active|r"
L["TOOLTIP_REMAINING"] = "Remaining: %s"
L["Left-click: Start cooldown"] = "|cff00ff00Left-click:|r Start cooldown"
L["Right-click: Reset cooldown"] = "|cffff0000Right-click:|r Reset cooldown"
L["Click and drag to move"] = "Click and drag to move"

------------------------------------------------------------------------
-- Lock Messages
------------------------------------------------------------------------
L["Bars locked."] = "Bars |cffff0000locked|r."
L["Bars unlocked."] = "Bars |cff00ff00unlocked|r."
