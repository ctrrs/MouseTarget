-- Mouse Target logic
-- Author: fae (and gemini)

local addonName, addonTable = ...
local frame = CreateFrame("Frame", "MouseTargetFrame", UIParent)
frame:SetSize(1, 1)
frame:SetFrameStrata("TOOLTIP")
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER", frame, "CENTER")

-- Initialize database globally
MouseTargetDB = MouseTargetDB or {}

-- Default configuration
local defaults = {
    fontSize = 14,
    fontPath = "Fonts\\FRIZQT__.TTF",
    outline = "OUTLINE",
    shadow = true,
    anchor = "RIGHT",
    growth = "LEFT",
    offset = 15,
    colorMode = "STANDARD",
    customColor = {r = 1, g = 1, b = 1},
    customColorName = "White",
    showEnemies = true,
    showAllies = true,
    showNPCs = true,
    hideEnemiesCombat = false,
    hideAlliesCombat = false,
    hideNPCsCombat = false,
    excludeUnitFrames = false,
    abbreviateNames = false,
    showLoginMessage = true,
    colorQuest = true,
}

local function GetProcessedName(name, unit)
    -- If no name, return empty
    if not name then return "" end
    
    -- If abbreviation is off or it's a player, return name as is
    if not MouseTargetDB or not MouseTargetDB.abbreviateNames or UnitIsPlayer(unit) then
        return name
    end

    -- Use a protected call (pcall) to handle "secret" or "protected" strings
    local success, result = pcall(function()
        -- Attempt to find a space and return everything after it
        local firstSpace = string.find(name, " ")
        if firstSpace then
            return string.sub(name, firstSpace + 1)
        end
        return name
    end)

    -- If the processing was successful and we got a string back, return it
    if success and result then
        return result
    end

    -- Fallback: return the original name if processing failed or was blocked
    return name
end
local function GetUnitColor(unit, isQuest)
    if MouseTargetDB.colorMode == "CUSTOM" then
        local c = MouseTargetDB.customColor or {r = 1, g = 1, b = 1}
        return c.r, c.g, c.b
    end

    -- Priority: Quest Target Color (Golden Yellow)
    if isQuest == nil then isQuest = MouseTargetDB.colorQuest and UnitIsQuestBoss(unit) end
    if isQuest then
        return 1.0, 0.82, 0 -- Golden Yellow
    end

    if UnitIsPlayer(unit) then
        -- Players (Allies and Enemies): Always Class Color
        local _, classTag = UnitClass(unit)
        local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[classTag]
        if color then
            return color.r, color.g, color.b
        end
        return 1, 1, 1 -- Fallback to white if class not found
    else
        -- NPCs: Selection/Reaction Color
        local r, g, b = UnitSelectionColor(unit)

        -- Fix for units with Cyan/Blue color (Quest/Special units):
        -- Change it to a Light Purple (Lavender)
        if b > 0.5 and r < 0.3 then
            return 0.8, 0.6, 1.0 -- Light Purple / Lavender
        end

        return r, g, b
    end
end


-- Robust focus detection
local function GetCurrentMouseFocus()
    if GetMouseFoci then
        local foci = GetMouseFoci()
        return foci and foci[1]
    end
    return GetMouseFocus and GetMouseFocus()
end

local function ShouldShowUnit(unit)
    local isPlayer = UnitIsPlayer(unit)
    local isEnemy = UnitCanAttack("player", unit)
    local inCombat = InCombatLockdown()

    -- 1. Exclude Unit Frames logic (Attribute based)
    if MouseTargetDB.excludeUnitFrames then
        local focus = GetCurrentMouseFocus()
        if focus and focus.GetAttribute then
            local unitAttr = focus:GetAttribute("unit")
            if unitAttr then
                -- It has a unit attribute. Check if it's a nameplate.
                if not unitAttr:find("nameplate") then
                    -- It's a standard unit frame (player, target, party, raid, etc.)
                    return false
                end
            end
        end
    end

    -- 2. Combat Filters
    if isEnemy then
        if not MouseTargetDB.showEnemies then return false end
        if inCombat and MouseTargetDB.hideEnemiesCombat then return false end
        return true
    elseif isPlayer then
        if not MouseTargetDB.showAllies then return false end
        if inCombat and MouseTargetDB.hideAlliesCombat then return false end
        return true
    else
        if not MouseTargetDB.showNPCs then return false end
        if inCombat and MouseTargetDB.hideNPCsCombat then return false end
        return true
    end
end

local function UpdatePosition()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local uiX, uiY = x / scale, y / scale

    local offset = MouseTargetDB.offset or 15
    local offsetX, offsetY = offset, offset
    local point = "BOTTOMLEFT"

    if MouseTargetDB.anchor == "TOP" then
        point = "BOTTOM"
        offsetY = offset + 10
        offsetX = 0
    elseif MouseTargetDB.anchor == "BOTTOM" then
        point = "TOP"
        offsetY = -(offset + 10)
        offsetX = 0
    elseif MouseTargetDB.anchor == "LEFT" then
        point = "RIGHT"
        offsetX = -offset
        offsetY = 0
    elseif MouseTargetDB.anchor == "RIGHT" then
        point = "LEFT"
        offsetX = offset
        offsetY = 0
    end

    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, "BOTTOMLEFT", uiX + offsetX, uiY + offsetY)
end

frame:SetScript("OnUpdate", function(self)
    if not UnitExists("mouseover") or not ShouldShowUnit("mouseover") then
        self:Hide()
        return
    end
    UpdatePosition()
end)

local function ApplySettings()
    if not MouseTargetDB then return end
    
    text:ClearAllPoints()
    if MouseTargetDB.growth == "LEFT" then
        text:SetPoint("RIGHT", frame, "CENTER")
        text:SetJustifyH("RIGHT")
    elseif MouseTargetDB.growth == "RIGHT" then
        text:SetPoint("LEFT", frame, "CENTER")
        text:SetJustifyH("LEFT")
    else
        text:SetPoint("CENTER", frame, "CENTER")
        text:SetJustifyH("CENTER")
    end
    
    local fontPath = MouseTargetDB.fontPath or "Fonts\\FRIZQT__.TTF"
    text:SetFont(fontPath, MouseTargetDB.fontSize, MouseTargetDB.outline)
    if MouseTargetDB.shadow then
        text:SetShadowOffset(1, -1)
    else
        text:SetShadowOffset(0, 0)
    end
end

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        MouseTargetDB = MouseTargetDB or {}
        for k, v in pairs(defaults) do
            if MouseTargetDB[k] == nil then MouseTargetDB[k] = v end
        end
        ApplySettings()
        
        if MouseTargetDB.showLoginMessage then
            print("|cFF8000FFMouse Target:|r loaded. Henlo.")
        end
        
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        if UnitExists("mouseover") and ShouldShowUnit("mouseover") then
            local rawName = UnitName("mouseover")
            local processedName = GetProcessedName(rawName, "mouseover")
            
            local isQuest = MouseTargetDB.colorQuest and UnitIsQuestBoss("mouseover")
            local r, g, b = GetUnitColor("mouseover", isQuest)
            local prefix = isQuest and "|cFFFFD100(!)|r " or ""
            
            text:SetText(prefix .. processedName)
            text:SetTextColor(r, g, b)
            self:Show()
        else
            self:Hide()
        end
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
frame:SetScript("OnEvent", OnEvent)
frame:Hide()

addonTable.ApplySettings = ApplySettings
