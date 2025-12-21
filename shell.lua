local _, DelCraft = ...

-- Activate the interactive shell by taking over the chat editbox
-- Optional params for selection mode: ambiguousTerm (string), qty (number), matchNames (table of strings)
function DelCraft.ActivateShell(ambiguousTerm, qty, matchNames)
    local isShellActive = false
    local selectionMode = (matchNames and #matchNames > 0)

    if isShellActive then
        print("|cffffd700[DelCraft Shell]|r Already active. Type 'exit' or 'quit' to close.")
        return
    end

    isShellActive = true

    -- Create a hidden frame if it doesn't exist (for delaying actions)
    DelCraft.shellFrame = DelCraft.shellFrame or CreateFrame("Frame")

    -- Schedule the activation on the next frame to avoid conflict with slash command deactivation
    DelCraft.shellFrame:SetScript("OnUpdate", function(self)
        local editbox = ChatEdit_ChooseBoxForSend()
        ChatEdit_ActivateChat(editbox)
        editbox:SetText("")
        editbox:Show()
        editbox:SetFocus()

        local originalOnEnterPressed = editbox:GetScript("OnEnterPressed")

        local function OnShellEnterPressed(self)
            if not isShellActive then
                if originalOnEnterPressed then
                    originalOnEnterPressed(self)
                end
                return
            end

            local text = self:GetText()
            local lowerText = text:lower()

            if lowerText == "/craft" then
                print("|cffffd700[DelCraft Shell]|r Already active. Type 'exit' or 'quit' to close.")
                self:SetText("")
                return
            end

            if lowerText == "exit" or lowerText == "quit" then
                isShellActive = false
                print("|cffffd700[DelCraft Shell]|r Session ended.")
                self:SetText("")
                self:SetScript("OnEnterPressed", originalOnEnterPressed)
                ChatEdit_DeactivateChat(editbox)  -- Close chat when exiting
                return
            end

            if selectionMode then
                local num = tonumber(text)
                if num and num >= 1 and num <= #matchNames then
                    local selected = matchNames[num]
                    local newMsg = '"' .. selected .. '"'
                    if qty and qty > 1 then
                        newMsg = newMsg .. " " .. qty
                    end
                    DelCraft.MyAddonCommands(newMsg)  -- Process the exact item
                    isShellActive = false
                    self:SetText("")
                    self:SetScript("OnEnterPressed", originalOnEnterPressed)
                    ChatEdit_DeactivateChat(editbox)  -- Close the chat box after selection
                    return
                end
            end

            if text ~= "" then
                print("|cffffd700[DelCraft Shell]|r " .. text)
            end

            self:SetText("")
        end

        editbox:SetScript("OnEnterPressed", OnShellEnterPressed)

        if selectionMode then
            print("|cffffd700[DelCraft Shell]|r Multiple items match '" .. ambiguousTerm .. "'. Please specify one of:")
            for i, name in ipairs(matchNames) do
                print(i .. " " .. name)
            end
            print("Type the number and press Enter to select. Type 'exit' or 'quit' to close.")
        else
            print("|cffffd700[DelCraft Shell]|r Active! Type commands and press Enter. Type 'exit' or 'quit' to close.")
        end

        -- Clear the OnUpdate script after running once
        self:SetScript("OnUpdate", nil)
    end)
end
