-- Mouse Target Configuration
-- Author: fae (and gemini)

local addonName, addonTable = ...

-- LibSharedMedia setup
local LSM = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)
local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"

local function RegisterSettings()
    -- Ensure DB exists
    if not MouseTargetDB then MouseTargetDB = {} end
    if not MouseTargetDB.customColor then MouseTargetDB.customColor = {r = 1, g = 1, b = 1} end

    local category = Settings.RegisterVerticalLayoutCategory("Mouse Target")
    addonTable.category = category

    local function OnSettingChanged()
        if addonTable.ApplySettings then addonTable.ApplySettings() end
    end

    local function CreateHeading(category, name)
        local layout = SettingsPanel:GetLayout(category)
        layout:AddInitializer(Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", {name = name}))
    end

    -- 1. VISUAL SETTINGS
    CreateHeading(category, "Visual Appearance")
    if LSM then
        local fontSetting = Settings.RegisterAddOnSetting(category, "MouseTargetFont", "fontPath", MouseTargetDB, Settings.VarType.String, "Font", DEFAULT_FONT)
        Settings.CreateDropdown(category, fontSetting, function()
            local container = Settings.CreateControlTextContainer()
            local fonts = LSM:List("font")
            for _, fontName in ipairs(fonts) do
                container:Add(LSM:Fetch("font", fontName), fontName)
            end
            return container:GetData()
        end, "Choose your font.")
        fontSetting:SetValueChangedCallback(OnSettingChanged)
    end

    local sizeSetting = Settings.RegisterAddOnSetting(category, "MouseTargetSize", "fontSize", MouseTargetDB, Settings.VarType.Number, "Font Size", 14)
    Settings.CreateSlider(category, sizeSetting, Settings.CreateSliderOptions(8, 32, 1), "Adjust font size.")
    sizeSetting:SetValueChangedCallback(OnSettingChanged)

    local offsetSetting = Settings.RegisterAddOnSetting(category, "MouseTargetOffset", "offset", MouseTargetDB, Settings.VarType.Number, "Distance from Mouse", 15)
    Settings.CreateSlider(category, offsetSetting, Settings.CreateSliderOptions(0, 100, 1), "Adjust distance from mouse.")
    offsetSetting:SetValueChangedCallback(OnSettingChanged)

    -- 2. TEXT STYLE
    local outlineOptions = {
        { label = "None", value = "" }, { label = "Outline", value = "OUTLINE" },
        { label = "Thick Outline", value = "THICKOUTLINE" }, { label = "Monochrome", value = "MONOCHROME" },
    }
    local outlineSetting = Settings.RegisterAddOnSetting(category, "MouseTargetOutline", "outline", MouseTargetDB, Settings.VarType.String, "Outline", "OUTLINE")
    Settings.CreateDropdown(category, outlineSetting, function()
        local container = Settings.CreateControlTextContainer()
        for _, opt in ipairs(outlineOptions) do container:Add(opt.value, opt.label) end
        return container:GetData()
    end, "Text outline style.")
    outlineSetting:SetValueChangedCallback(OnSettingChanged)

    local shadowSetting = Settings.RegisterAddOnSetting(category, "MouseTargetShadow", "shadow", MouseTargetDB, Settings.VarType.Boolean, "Shadow", true)
    Settings.CreateCheckbox(category, shadowSetting, "Enable text shadow.")
    shadowSetting:SetValueChangedCallback(OnSettingChanged)

    -- 3. POSITION & ALIGNMENT
    CreateHeading(category, "Position & Alignment")
    local anchorOptions = {
        { label = "Right", value = "RIGHT" }, { label = "Left", value = "LEFT" },
        { label = "Top", value = "TOP" }, { label = "Bottom", value = "BOTTOM" },
    }
    local anchorSetting = Settings.RegisterAddOnSetting(category, "MouseTargetAnchor", "anchor", MouseTargetDB, Settings.VarType.String, "Anchor Point", "RIGHT")
    Settings.CreateDropdown(category, anchorSetting, function()
        local container = Settings.CreateControlTextContainer()
        for _, opt in ipairs(anchorOptions) do container:Add(opt.value, opt.label) end
        return container:GetData()
    end, "Anchor relative to mouse.")
    anchorSetting:SetValueChangedCallback(OnSettingChanged)

    local growthOptions = {
        { label = "Left", value = "LEFT" }, { label = "Center", value = "CENTER" }, { label = "Right", value = "RIGHT" },
    }
    local growthSetting = Settings.RegisterAddOnSetting(category, "MouseTargetGrowth", "growth", MouseTargetDB, Settings.VarType.String, "Text Alignment", "LEFT")
    Settings.CreateDropdown(category, growthSetting, function()
        local container = Settings.CreateControlTextContainer()
        for _, opt in ipairs(growthOptions) do container:Add(opt.value, opt.label) end
        return container:GetData()
    end, "How the text grows.")
    growthSetting:SetValueChangedCallback(OnSettingChanged)

    -- 4. FILTERS
    CreateHeading(category, "Visibility Filters")
    local showAllies = Settings.RegisterAddOnSetting(category, "MouseTargetShowAllies", "showAllies", MouseTargetDB, Settings.VarType.Boolean, "Show Allied Players", true)
    Settings.CreateCheckbox(category, showAllies, "Show names for allied players.")

    local showEnemies = Settings.RegisterAddOnSetting(category, "MouseTargetShowEnemies", "showEnemies", MouseTargetDB, Settings.VarType.Boolean, "Show Enemies", true)
    Settings.CreateCheckbox(category, showEnemies, "Show names for enemies.")

    local showNPCs = Settings.RegisterAddOnSetting(category, "MouseTargetShowNPCs", "showNPCs", MouseTargetDB, Settings.VarType.Boolean, "Show NPCs", true)
    Settings.CreateCheckbox(category, showNPCs, "Show names for NPCs.")

    local colorQuestSet = Settings.RegisterAddOnSetting(category, "MouseTargetColorQuest", "colorQuest", MouseTargetDB, Settings.VarType.Boolean, "Highlight Quest Targets", true)
    Settings.CreateCheckbox(category, colorQuestSet, "Change name color to orange if the unit is a quest objective.")

    -- Combat Filters
    CreateHeading(category, "Combat & Behavior")
    local hideAllies = Settings.RegisterAddOnSetting(category, "MouseTargetHideAlliesCombat", "hideAlliesCombat", MouseTargetDB, Settings.VarType.Boolean, "Hide Allies in Combat", false)
    Settings.CreateCheckbox(category, hideAllies, "Hide allied names when you are in combat.")

    local hideEnemies = Settings.RegisterAddOnSetting(category, "MouseTargetHideEnemiesCombat", "hideEnemiesCombat", MouseTargetDB, Settings.VarType.Boolean, "Hide Enemies in Combat", false)
    Settings.CreateCheckbox(category, hideEnemies, "Hide enemy names when you are in combat.")

    local hideNPCs = Settings.RegisterAddOnSetting(category, "MouseTargetHideNPCsCombat", "hideNPCsCombat", MouseTargetDB, Settings.VarType.Boolean, "Hide NPCs in Combat", false)
    Settings.CreateCheckbox(category, hideNPCs, "Hide NPC names when you are in combat.")

    -- Unit Frame Exclusion
    local excludeSet = Settings.RegisterAddOnSetting(category, "MouseTargetExcludeUnitFrames", "excludeUnitFrames", MouseTargetDB, Settings.VarType.Boolean, "Exclude Unit Frames", false)
    Settings.CreateCheckbox(category, excludeSet, "Only show the text when hovering over bodies or nameplates (ignores UI frames).")

    -- Abbreviate Names
    local abbreviateSet = Settings.RegisterAddOnSetting(category, "MouseTargetAbbreviateNames", "abbreviateNames", MouseTargetDB, Settings.VarType.Boolean, "Abbreviate NPC Names", false)
    Settings.CreateCheckbox(category, abbreviateSet, "Omit the first word of NPC names. Note: May not work on some enemies if their names are protected ('secret') by Blizzard.")

    -- 5. COLOR MODE & SELECTION
    CreateHeading(category, "Color Customization")
    local colorModeSetting = Settings.RegisterAddOnSetting(category, "MouseTargetColorMode", "colorMode", MouseTargetDB, Settings.VarType.String, "Color Mode", "STANDARD")
    Settings.CreateDropdown(category, colorModeSetting, function()
        local container = Settings.CreateControlTextContainer()
        container:Add("STANDARD", "Standard (Class/Reaction/Red)")
        container:Add("CUSTOM", "Custom Color")
        return container:GetData()
    end, "Choose color mode.")
    colorModeSetting:SetValueChangedCallback(OnSettingChanged)

    local colorPresets = {
        { name = "White", r = 1, g = 1, b = 1 },
        { name = "Yellow", r = 1, g = 1, b = 0 },
        { name = "Green", r = 0, g = 1, b = 0 },
        { name = "Blue", r = 0, g = 0.5, b = 1 },
        { name = "Red", r = 1, g = 0, b = 0 },
        { name = "Purple", r = 0.6, g = 0.2, b = 1 },
        { name = "Orange", r = 1, g = 0.5, b = 0 },
        { name = "Pink", r = 1, g = 0.4, b = 0.7 },
        { name = "Cyan", r = 0, g = 1, b = 1 },
    }

    local colorSelectSetting = Settings.RegisterAddOnSetting(category, "MouseTargetCustomColorName", "customColorName", MouseTargetDB, Settings.VarType.String, "Select Color", "White")
    Settings.CreateDropdown(category, colorSelectSetting, function()
        local container = Settings.CreateControlTextContainer()
        for _, color in ipairs(colorPresets) do container:Add(color.name, color.name) end
        return container:GetData()
    end, "Choose a custom color.")

    colorSelectSetting:SetValueChangedCallback(function(setting, value)
        for _, color in ipairs(colorPresets) do
            if color.name == value then
                MouseTargetDB.customColor = {r = color.r, g = color.g, b = color.b}
                break
            end
        end
        OnSettingChanged()
    end)

    -- 6. GENERAL SETTINGS
    CreateHeading(category, "General Settings")
    local loginMessageSet = Settings.RegisterAddOnSetting(category, "MouseTargetShowLoginMessage", "showLoginMessage", MouseTargetDB, Settings.VarType.Boolean, "Show Welcome Message", true)
    Settings.CreateCheckbox(category, loginMessageSet, "Show the welcome message in the chat when the addon loads.")

    Settings.RegisterAddOnCategory(category)
end

-- Initialization
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
    if name == addonName then
        RegisterSettings()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Slash commands
SLASH_MOUSETARGET1 = "/mousetarget"
SLASH_MOUSETARGET2 = "/motar"
SlashCmdList["MOUSETARGET"] = function()
    if addonTable.category then Settings.OpenToCategory(addonTable.category:GetID()) else Settings.OpenToCategory() end
end
