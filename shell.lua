local _, DelCraft = ...

-- Create the shell frame
local shellFrame = CreateFrame("Frame", "DelCraftShellFrame", UIParent, "BackdropTemplate")
shellFrame:SetSize(460, 320)           -- taller to fit the list
shellFrame:SetPoint("CENTER", 0, 80)
shellFrame:SetMovable(true)
shellFrame:EnableMouse(true)
shellFrame:RegisterForDrag("LeftButton")
shellFrame:SetScript("OnDragStart", shellFrame.StartMoving)
shellFrame:SetScript("OnDragStop", shellFrame.StopMovingOrSizing)
shellFrame:Hide()

-- Backdrop
shellFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

-- Title
local title = shellFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", 0, -18)
title:SetText("|cffffd700DelCraft - Multiple Matches|r")

-- Scrollable list area
local scrollFrame = CreateFrame("ScrollFrame", nil, shellFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(420, 160)
scrollFrame:SetPoint("TOP", 0, -55)

local listFrame = CreateFrame("Frame", nil, scrollFrame)
listFrame:SetSize(420, 160)
scrollFrame:SetScrollChild(listFrame)

local listText = listFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
listText:SetPoint("TOPLEFT", 10, -5)
listText:SetJustifyH("LEFT")
listText:SetWidth(400)

-- Input box
local editBox = CreateFrame("EditBox", nil, shellFrame, "InputBoxTemplate")
editBox:SetSize(380, 32)
editBox:SetPoint("BOTTOM", 0, 45)
editBox:SetFontObject("ChatFontNormal")
editBox:SetAutoFocus(true)

local instruction = shellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
instruction:SetPoint("BOTTOM", editBox, "TOP", 0, 12)
instruction:SetText("Type the number and press |cffffd700Enter|r   •   Type |cffffd700exit|r or press |cffffd700Escape|r to cancel")

-- Close button
local closeBtn = CreateFrame("Button", nil, shellFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -8, -8)
closeBtn:SetScript("OnClick", function()
    shellFrame:Hide()
    print("|cffffd700[DelCraft Shell]|r Selection cancelled.")
end)

-- Main handler
local function OnEnterPressed(self)
    local text = strtrim(self:GetText() or "")
    if text == "" then return end

    local lower = text:lower()
    if lower == "exit" or lower == "quit" then
        shellFrame:Hide()
        print("|cffffd700[DelCraft Shell]|r Session ended.")
        return
    end

    local num = tonumber(text)
    if num and DelCraft.currentMatches and num >= 1 and num <= #DelCraft.currentMatches then
        local selected = DelCraft.currentMatches[num]
        local qty = DelCraft.currentQty or 1

        local newMsg = '"' .. selected .. '"'
        if qty > 1 then
            newMsg = newMsg .. " " .. qty
        end

        shellFrame:Hide()
        editBox:SetText("")

        DelCraft.MyAddonCommands(newMsg)
        return
    end

    print("|cffffd700[DelCraft Shell]|r Invalid number. Please type a valid option.")
    self:SetText("")
end

editBox:SetScript("OnEnterPressed", OnEnterPressed)
editBox:SetScript("OnEscapePressed", function()
    shellFrame:Hide()
    print("|cffffd700[DelCraft Shell]|r Selection cancelled.")
end)

-- Activation function
function DelCraft.ActivateShell(ambiguousTerm, qty, matchNames)
    DelCraft.currentMatches = matchNames
    DelCraft.currentQty = qty or 1

    -- Build the list text
    local listStr = "|cffffffffAvailable options:|r\n\n"
    for i, name in ipairs(matchNames) do
        listStr = listStr .. "|cffffd700" .. i .. ".|r " .. name .. "\n"
    end

    listText:SetText(listStr)

    -- Show the frame
    shellFrame:Show()
    editBox:SetText("")
    editBox:SetFocus()
end