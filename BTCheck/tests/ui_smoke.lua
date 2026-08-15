local addonPath = (... or "outputs/BTCheck")

local Object = {}
Object.__index = Object

function Object:SetScript(script, handler)
    self.scripts = self.scripts or {}
    self.scripts[script] = handler
end
function Object:GetScript(script)
    return self.scripts and self.scripts[script]
end
function Object:RegisterEvent(event)
    self.events = self.events or {}
    self.events[event] = true
end
function Object:UnregisterEvent(event)
    if self.events then
        self.events[event] = nil
    end
end
function Object:CreateTexture()
    return setmetatable({ shown = true }, Object)
end
function Object:CreateFontString()
    return setmetatable({ shown = true }, Object)
end
function Object:SetPoint(point, _, relativePoint, x, y)
    self.point = { point or "CENTER", relativePoint or point or "CENTER", x or 0, y or 0 }
end
function Object:GetPoint()
    local point = self.point or { "CENTER", "CENTER", 0, 0 }
    return point[1], UIParent, point[2], point[3], point[4]
end
function Object:ClearAllPoints()
    self.point = nil
end
function Object:SetSize(width, height)
    self.width = width
    self.height = height
end
function Object:SetWidth(width)
    self.width = width
end
function Object:SetHeight(height)
    self.height = height
end
function Object:GetFrameLevel()
    return self.frameLevel or 1
end
function Object:SetFrameLevel(level)
    self.frameLevel = level
end
function Object:GetEffectiveScale()
    return 1
end
function Object:GetCenter()
    return 500, 500
end
function Object:SetValue(value)
    self.value = value
    local handler = self.scripts and self.scripts.OnValueChanged
    if handler then
        handler(self, value)
    end
end
function Object:SetMinMaxValues(minimum, maximum)
    self.minimum = minimum
    self.maximum = maximum
end
function Object:SetText(text)
    self.text = text
    if self.frameType == "EditBox" then
        local handler = self.scripts and self.scripts.OnTextChanged
        if handler then
            handler(self, false)
        end
    end
end
function Object:GetText()
    return self.text or ""
end
function Object:SetTexture(texture)
    self.texture = texture
end
function Object:SetWordWrap(value)
    self.wordWrap = value
end
function Object:GetThumbTexture()
    self.thumb = self.thumb or setmetatable({ shown = true }, Object)
    return self.thumb
end
function Object:Show()
    self.shown = true
    local handler = self.scripts and self.scripts.OnShow
    if handler then
        handler(self)
    end
end
function Object:Hide()
    self.shown = false
    local handler = self.scripts and self.scripts.OnHide
    if handler then
        handler(self)
    end
end
function Object:IsShown()
    return self.shown == true
end
function Object:SetShown(shown)
    if shown then
        self:Show()
    else
        self:Hide()
    end
end
function Object:StartMoving()
end
function Object:StopMovingOrSizing()
end

local noOpMethods = {
    "SetAllPoints", "SetColorTexture", "SetTexCoord", "SetJustifyH", "SetJustifyV",
    "SetTextColor", "SetFrameStrata", "SetMovable", "SetClampedToScreen", "EnableMouse", "EnableMouseWheel",
    "RegisterForDrag", "RegisterForClicks", "SetHighlightTexture", "SetOrientation", "SetValueStep",
    "SetThumbTexture", "SetVertexColor", "SetOwner", "AddLine", "AddDoubleLine", "SetAutoFocus",
    "SetTextInsets", "SetFontObject", "ClearFocus",
}
for index = 1, #noOpMethods do
    Object[noOpMethods[index]] = function()
    end
end

function CreateFrame(frameType)
    return setmetatable({ shown = true, scripts = {}, events = {}, frameType = frameType }, Object)
end

UIParent = setmetatable({ shown = true }, Object)
Minimap = setmetatable({ shown = true, frameLevel = 2 }, Object)
GameTooltip = setmetatable({ shown = false }, Object)
SlashCmdList = {}

local runtime = {
    completed = { [10568] = true, [10571] = true },
    active = { [10574] = true },
}

function GetBuildInfo()
    return "2.5.6", "69110", "Aug 5 2026", 20506
end
function UnitGUID()
    return "Player-1-UI"
end
function UnitName()
    return "界面测试", "周年测试服"
end
function UnitClass()
    return "牧师", "PRIEST", 5
end
function UnitFactionGroup()
    return "Alliance", "联盟"
end
function GetRealmName()
    return "周年测试服"
end
function GetCursorPosition()
    return 580, 500
end
function date(_, timestamp)
    return "T" .. tostring(timestamp)
end

C_DateAndTime = { GetServerTimeLocal = function() return 2000 end }
C_QuestLog = {
    IsQuestFlaggedCompleted = function(questID) return runtime.completed[questID] == true end,
    IsOnQuest = function(questID) return runtime.active[questID] == true end,
}

local ns = {}
assert(loadfile(addonPath .. "/Data.lua"))("BTCheck", ns)
assert(loadfile(addonPath .. "/Core.lua"))("BTCheck", ns)
assert(loadfile(addonPath .. "/UI.lua"))("BTCheck", ns)

local eventHandler = ns.eventFrame:GetScript("OnEvent")
assert(eventHandler, "event handler missing")
eventHandler(ns.eventFrame, "ADDON_LOADED", "BTCheck")
assert(ns.mainFrame and ns.minimapButton and ns.characterManager, "UI initialization failed")
assert(#ns.mainFrame.characterHeaders == 5, "main table did not allocate five visible character columns")
assert(ns.mainFrame.characterHeaders[1].width == 130, "character column width changed unexpectedly")
assert(#ns.mainFrame.rowLabels == 16, "main table did not allocate all sixteen task rows")
assert(not ns.mainFrame.verticalSlider:IsShown(), "vertical slider should be hidden when all task rows fit")
eventHandler(ns.eventFrame, "PLAYER_LOGIN")
assert(ns.mainFrame.rowLabels[1].countText.text == "1人", "task row did not show the visible character count")
assert(ns.mainFrame.rowLabels[1].text.wordWrap == false, "task row text still allows wrapping")
assert(ns.minimapButton.icon.texture == "Interface\\Icons\\Spell_Shadow_Metamorphosis", "minimap icon path was not the verified 20506 asset")
assert(ns.characterManager.rowsPerPage == 10, "character manager did not allocate ten rows per page")
assert(#ns.characterManager.rows == 10, "character manager row pool is not sized for ten characters")
assert(ns.mainFrame.horizontalSlider:GetScript("OnMouseWheel"), "horizontal scrollbar did not bind mouse-wheel scrolling")
assert(ns.mainFrame.verticalSlider:GetScript("OnMouseWheel"), "vertical scrollbar did not bind mouse-wheel scrolling")
assert(ns.mainFrame.characterHeaders[1].text.text:find("|cffffffff界面测试|r", 1, true), "character header did not apply priest class color")
assert(ns.mainFrame.searchBox, "character search box was not created")
ns.mainFrame.searchBox:SetText("面测")
assert(#ns.visibleCharacters == 1 and ns.visibleCharacters[1].name == "界面测试", "fuzzy character search did not filter by substring")
assert(ns.mainFrame.characterHeaders[1]:IsShown(), "matching character header was hidden")
assert(ns.mainFrame.noCharacters.text ~= ns.STRINGS.NO_SEARCH_RESULTS, "matching search incorrectly showed no-results text")
ns.mainFrame.searchBox:SetText("不存在")
assert(#ns.visibleCharacters == 0, "unmatched character search still returned a character")
assert(ns.mainFrame.noCharacters.text == ns.STRINGS.NO_SEARCH_RESULTS, "unmatched search did not show no-results text")
ns.mainFrame.clearSearchButton:GetScript("OnClick")(ns.mainFrame.clearSearchButton)
assert(ns.searchText == "" and #ns.visibleCharacters == 1, "clearing character search did not restore all characters")

ns:ToggleMainWindow()
assert(ns.mainFrame:IsShown(), "main window did not open")
assert(ns.mainFrame.closeButton, "close button was not attached to main frame")
assert(ns.mainFrame.closeButton:GetFrameLevel() > ns.mainFrame:GetFrameLevel(), "close button frame level was not raised")
ns.mainFrame.closeButton:GetScript("OnClick")(ns.mainFrame.closeButton)
assert(not ns.mainFrame:IsShown(), "close button did not hide main window")
ns:ToggleMainWindow()
assert(ns.mainFrame:IsShown(), "main window did not reopen after close")
ns:OpenCharacterManager()
assert(ns.characterManager:IsShown(), "character manager did not open")
assert(ns.characterManager.rows[1].name.text:find("|cffffffff界面测试|r", 1, true), "character manager did not color character name")
ns.characterManager:Hide()

local dragStart = ns.minimapButton:GetScript("OnDragStart")
local dragStop = ns.minimapButton:GetScript("OnDragStop")
dragStart(ns.minimapButton)
local dragUpdate = ns.minimapButton:GetScript("OnUpdate")
assert(dragUpdate, "minimap drag updater missing")
dragUpdate(ns.minimapButton)
dragStop(ns.minimapButton)

SlashCmdList.BTCHECK("reset")
SlashCmdList.BTCHECK("refresh")

assert(ns:GetProgress(BTCheckDB.characters["Player-1-UI"]) == 2, "UI smoke progress changed unexpectedly")
print("BTCheck UI smoke test: PASS")
