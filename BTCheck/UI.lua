local addonName, ns = ...

local type = type
local tostring = tostring
local tonumber = tonumber
local table_concat = table.concat
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_cos = math.cos
local math_sin = math.sin
local math_rad = math.rad
local math_deg = math.deg
local math_atan2 = math.atan2
local string_lower = string.lower
local string_find = string.find

local MAIN_WIDTH = 940
local MAIN_HEIGHT = 640
local LABEL_X = 18
local LABEL_WIDTH = 195
local TABLE_X = 223
local COLUMN_WIDTH = 130
local VISIBLE_COLUMNS = 5
local ROW_HEIGHT = 25
local VISIBLE_ROWS = 16
local BODY_TOP = -171
local CHARACTER_ROWS_PER_PAGE = 10
local CHARACTER_ROW_STEP = 46

local STATUS_TEXT = {
    [ns.STATUS_TODO] = "|cff777777—|r",
    [ns.STATUS_ACTIVE] = "|cffffcc00进行中|r",
    [ns.STATUS_DONE] = "|cff33ff66已完成|r",
}

local STATUS_PLAIN = {
    [ns.STATUS_TODO] = ns.STRINGS.TODO,
    [ns.STATUS_ACTIVE] = ns.STRINGS.ACTIVE,
    [ns.STATUS_DONE] = ns.STRINGS.DONE,
}

-- TBC 2.5.6 的职业颜色固定表；未知或历史快照缺少职业信息时使用白色。
local CLASS_COLOR_HEX = {
    WARRIOR = "ffc79c6e",
    PALADIN = "fff58cba",
    HUNTER = "ffabd473",
    ROGUE = "fffff569",
    PRIEST = "ffffffff",
    SHAMAN = "ff0070de",
    MAGE = "ff69ccf0",
    WARLOCK = "ff9482c9",
    DRUID = "ffff7d0a",
}

local function ColorizeCharacterName(character)
    local color = CLASS_COLOR_HEX[character and character.classToken] or "ffffffff"
    return "|c" .. color .. tostring(character and character.name or "未知角色") .. "|r"
end

local function UpdateSearchHint(searchBox)
    if not searchBox or not searchBox.searchHint then
        return
    end
    local text = searchBox:GetText() or ""
    if text == "" and not searchBox.searchHasFocus then
        searchBox.searchHint:Show()
    else
        searchBox.searchHint:Hide()
    end
end

local function AddBackground(frame, red, green, blue, alpha)
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(frame)
    texture:SetColorTexture(red, green, blue, alpha)
    frame.background = texture
    return texture
end

local function AddBorder(frame, red, green, blue, alpha)
    local top = frame:CreateTexture(nil, "BORDER")
    top:SetColorTexture(red, green, blue, alpha)
    top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    top:SetHeight(1)

    local bottom = frame:CreateTexture(nil, "BORDER")
    bottom:SetColorTexture(red, green, blue, alpha)
    bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)

    local left = frame:CreateTexture(nil, "BORDER")
    left:SetColorTexture(red, green, blue, alpha)
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    left:SetWidth(1)

    local right = frame:CreateTexture(nil, "BORDER")
    right:SetColorTexture(red, green, blue, alpha)
    right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(1)
end

local function MakeButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    AddBackground(button, 0.12, 0.12, 0.14, 0.96)
    AddBorder(button, 0.42, 0.42, 0.46, 1)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetColorTexture(0.95, 0.78, 0.18, 0.16)
    button:SetHighlightTexture(highlight)

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", button, "LEFT", 6, 0)
    label:SetPoint("RIGHT", button, "RIGHT", -6, 0)
    label:SetJustifyH("CENTER")
    label:SetText(text or "")
    button.label = label
    return button
end

local function CreateSearchBox(parent)
    local searchBox = CreateFrame("EditBox", nil, parent)
    searchBox:SetSize(190, 25)
    searchBox:SetAutoFocus(false)
    searchBox:SetTextInsets(6, 6, 0, 0)
    searchBox:SetFontObject(GameFontHighlightSmall)
    searchBox:SetTextColor(1, 1, 1)
    searchBox:EnableMouse(true)
    AddBackground(searchBox, 0.08, 0.08, 0.10, 0.98)
    AddBorder(searchBox, 0.42, 0.42, 0.46, 1)

    local hint = searchBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("LEFT", searchBox, "LEFT", 7, 0)
    hint:SetText(ns.STRINGS.SEARCH_PLACEHOLDER)
    hint:SetTextColor(0.55, 0.58, 0.64)
    searchBox.searchHint = hint
    searchBox.searchHasFocus = false

    searchBox:SetScript("OnTextChanged", function(self)
        ns.searchText = self:GetText() or ""
        ns.columnOffset = 0
        UpdateSearchHint(self)
        if ns.mainFrame then
            ns:RenderMainTable()
        end
    end)
    searchBox:SetScript("OnEditFocusGained", function(self)
        self.searchHasFocus = true
        UpdateSearchHint(self)
    end)
    searchBox:SetScript("OnEditFocusLost", function(self)
        self.searchHasFocus = false
        UpdateSearchHint(self)
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    UpdateSearchHint(searchBox)
    return searchBox
end

local function MakeSlider(parent, orientation, width, height)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetOrientation(orientation)
    slider:SetSize(width, height)
    slider:SetMinMaxValues(0, 0)
    slider:SetValueStep(1)

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints(slider)
    track:SetColorTexture(0.08, 0.08, 0.09, 0.95)
    AddBorder(slider, 0.32, 0.32, 0.35, 1)

    if orientation == "VERTICAL" then
        slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")
        local thumb = slider:GetThumbTexture()
        thumb:SetSize(width - 2, 32)
        thumb:SetVertexColor(0.9, 0.72, 0.22)
    else
        slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        local thumb = slider:GetThumbTexture()
        thumb:SetSize(42, height - 2)
        thumb:SetVertexColor(0.9, 0.72, 0.22)
    end
    slider:SetValue(0)
    return slider
end

local function SetButtonText(button, text)
    button.label:SetText(text or "")
end

local function Clamp(value, minimum, maximum)
    return math_min(math_max(value, minimum), maximum)
end

function ns:ApplyWindowPosition()
    if not ns.mainFrame or not ns.db then
        return
    end
    local saved = ns.db.ui.window or {}
    local point = saved.point or "CENTER"
    local relativePoint = saved.relativePoint or point
    local x = tonumber(saved.x) or 0
    local y = tonumber(saved.y) or 20
    ns.mainFrame:ClearAllPoints()
    ns.mainFrame:SetPoint(point, UIParent, relativePoint, x, y)
end

local function SaveWindowPosition(frame)
    if not ns.db then
        return
    end
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    ns.db.ui.window = {
        point = point or "CENTER",
        relativePoint = relativePoint or point or "CENTER",
        x = x or 0,
        y = y or 0,
    }
end

local function ScrollRows(delta)
    if not ns.mainFrame then
        return
    end
    local maximum = math_max(0, #ns.STEPS - VISIBLE_ROWS)
    ns.rowOffset = Clamp((ns.rowOffset or 0) - delta, 0, maximum)
    ns.mainFrame.verticalSlider:SetValue(ns.rowOffset)
    ns:RenderMainTable()
end

local function ScrollColumns(delta)
    if not ns.mainFrame then
        return
    end
    local characters = ns.visibleCharacters or ns:GetCharacters(false)
    local maximum = math_max(0, #characters - VISIBLE_COLUMNS)
    ns.columnOffset = Clamp((ns.columnOffset or 0) - delta, 0, maximum)
    ns.mainFrame.horizontalSlider:SetValue(ns.columnOffset)
    ns:RenderMainTable()
end

function ns:FilterCharacters(characters)
    local query = string_lower(tostring(self.searchText or ""))
    if query == "" then
        return characters
    end

    local filtered = {}
    for index = 1, #characters do
        local character = characters[index]
        local name = string_lower(tostring(character.name or ""))
        if string_find(name, query, 1, true) then
            filtered[#filtered + 1] = character
        end
    end
    return filtered
end

local function AddStepTooltip(step)
    GameTooltip:SetText(step.title, 1, 0.82, 0)
    for index = 1, #step.ids do
        local questID = step.ids[index]
        local branch = step.branches and step.branches[questID]
        if branch then
            GameTooltip:AddLine(branch .. "分支｜Quest ID " .. tostring(questID), 0.85, 0.85, 0.85)
        else
            GameTooltip:AddLine("Quest ID " .. tostring(questID), 0.85, 0.85, 0.85)
        end
    end
    if step.branches then
        GameTooltip:AddLine("两个阵营任务二选一，只计一个逻辑步骤。", 0.55, 0.75, 1, true)
    end
end

function ns:ShowCellTooltip(cell)
    local step = cell.step
    local character = cell.character
    if not step or not character then
        return
    end

    GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
    AddStepTooltip(step)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(tostring(character.name) .. "-" .. tostring(character.realm), 1, 1, 1)

    for index = 1, #step.ids do
        local questID = step.ids[index]
        local status = self:GetQuestStatus(character, questID)
        local branch = step.branches and step.branches[questID]
        local label = branch and (branch .. "｜" .. tostring(questID)) or tostring(questID)
        local statusText = STATUS_PLAIN[status] or ns.STRINGS.TODO
        if status == ns.STATUS_DONE then
            GameTooltip:AddDoubleLine(label, statusText, 0.8, 0.8, 0.8, 0.2, 1, 0.35)
        elseif status == ns.STATUS_ACTIVE then
            GameTooltip:AddDoubleLine(label, statusText, 0.8, 0.8, 0.8, 1, 0.82, 0)
        else
            GameTooltip:AddDoubleLine(label, statusText, 0.8, 0.8, 0.8, 0.5, 0.5, 0.5)
        end
    end

    GameTooltip:AddLine(" ")
    if character.guid == ns.currentGUID and not ns.deletedThisSession[character.guid] then
        GameTooltip:AddLine(ns.STRINGS.LIVE, 0.25, 1, 0.5)
    else
        GameTooltip:AddLine(ns.STRINGS.SNAPSHOT .. "｜" .. self:FormatTimestamp(character.lastSeen), 0.65, 0.75, 0.9)
    end
    GameTooltip:Show()
end

local function CreateMainFrame()
    local frame = CreateFrame("Frame", "BTCheckMainFrame", UIParent)
    frame:SetSize(MAIN_WIDTH, MAIN_HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    AddBackground(frame, 0.035, 0.035, 0.045, 0.97)
    AddBorder(frame, 0.72, 0.55, 0.12, 1)

    local titleBar = CreateFrame("Button", nil, frame)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -44, -2)
    titleBar:SetHeight(34)
    titleBar:EnableMouse(true)
    titleBar:SetFrameLevel(frame:GetFrameLevel() + 1)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        SaveWindowPosition(frame)
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -12)
    title:SetText(ns.STRINGS.ADDON_TITLE)

    local versionText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionText:SetPoint("LEFT", title, "RIGHT", 10, 0)
    versionText:SetText("|cff888888v1.1.5｜作者：达蒙|r")

    local close = MakeButton(frame, "×", 28, 24)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -7)
    close:SetFrameLevel(frame:GetFrameLevel() + 2)
    close:SetScript("OnClick", function()
        frame:Hide()
    end)
    frame.closeButton = close

    local accountText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    accountText:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -48)
    accountText:SetWidth(515)
    accountText:SetJustifyH("LEFT")
    frame.accountText = accountText

    local refresh = MakeButton(frame, "刷新", 104, 25)
    refresh:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -216, -43)
    refresh:SetScript("OnClick", function()
        if not ns:ScanCurrentCharacter() then
            ns:Print("当前无法刷新角色数据。")
        end
    end)

    local manage = MakeButton(frame, "角色管理", 88, 25)
    manage:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -120, -43)
    manage:SetScript("OnClick", function()
        ns:OpenCharacterManager()
    end)

    local legend = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    legend:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -82)
    legend:SetText("|cff33ff66已完成|r　|cffffcc00进行中|r　|cff777777未开始|r　｜　前四步按奥尔多/占星者二选一计数")

    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 500, -82)
    searchLabel:SetText("搜索角色")
    searchLabel:SetTextColor(0.85, 0.82, 0.62)

    local searchBox = CreateSearchBox(frame)
    searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 568, -78)
    frame.searchBox = searchBox

    local clearSearch = MakeButton(frame, "清除", 50, 25)
    clearSearch:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)
    clearSearch:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
    end)
    frame.clearSearchButton = clearSearch

    local stepHeader = CreateFrame("Frame", nil, frame)
    stepHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", LABEL_X, -108)
    stepHeader:SetSize(LABEL_WIDTH, 58)
    AddBackground(stepHeader, 0.11, 0.10, 0.07, 1)
    AddBorder(stepHeader, 0.42, 0.36, 0.17, 1)
    local stepHeaderText = stepHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stepHeaderText:SetPoint("CENTER", stepHeader, "CENTER", 0, 0)
    stepHeaderText:SetText("任务步骤")

    frame.characterHeaders = {}
    for column = 1, VISIBLE_COLUMNS do
        local header = CreateFrame("Button", nil, frame)
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", TABLE_X + ((column - 1) * COLUMN_WIDTH), -108)
        header:SetSize(COLUMN_WIDTH, 58)
        AddBackground(header, 0.09, 0.10, 0.12, 1)
        AddBorder(header, 0.30, 0.34, 0.42, 1)
        local text = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("TOPLEFT", header, "TOPLEFT", 5, -7)
        text:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -5, 5)
        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")
        header.text = text
        header:EnableMouseWheel(true)
        header:SetScript("OnMouseWheel", function(_, delta)
            ScrollColumns(delta)
        end)
        header:SetScript("OnEnter", function(self)
            local character = self.character
            if not character then
                return
            end
            local done, total, active = ns:GetProgress(character)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(ColorizeCharacterName(character) .. "-" .. tostring(character.realm), 1, 0.82, 0)
            GameTooltip:AddLine(tostring(character.className or "") .. "｜" .. tostring(character.factionName or ""), 0.8, 0.8, 0.8)
            GameTooltip:AddLine("进度 " .. tostring(done) .. "/" .. tostring(total) .. "｜进行中 " .. tostring(active), 1, 1, 1)
            if character.guid == ns.currentGUID and not ns.deletedThisSession[character.guid] then
                GameTooltip:AddLine(ns.STRINGS.LIVE, 0.25, 1, 0.5)
            else
                GameTooltip:AddLine(ns.STRINGS.SNAPSHOT .. "｜" .. ns:FormatTimestamp(character.lastSeen), 0.65, 0.75, 0.9)
            end
            GameTooltip:Show()
        end)
        header:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        frame.characterHeaders[column] = header
    end

    frame.rowLabels = {}
    frame.cells = {}
    for row = 1, VISIBLE_ROWS do
        local y = BODY_TOP - ((row - 1) * ROW_HEIGHT)
        local rowLabel = CreateFrame("Button", nil, frame)
        rowLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", LABEL_X, y)
        rowLabel:SetSize(LABEL_WIDTH, ROW_HEIGHT)
        AddBackground(rowLabel, row % 2 == 0 and 0.065 or 0.08, row % 2 == 0 and 0.065 or 0.08, row % 2 == 0 and 0.075 or 0.09, 1)
        AddBorder(rowLabel, 0.20, 0.20, 0.22, 1)
        local rowText = rowLabel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rowText:SetPoint("LEFT", rowLabel, "LEFT", 7, 0)
        rowText:SetPoint("RIGHT", rowLabel, "RIGHT", -43, 0)
    rowText:SetJustifyH("LEFT")
    rowText:SetWordWrap(false)
        rowLabel.text = rowText
        local countText = rowLabel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        countText:SetPoint("RIGHT", rowLabel, "RIGHT", -5, 0)
        countText:SetWidth(35)
        countText:SetJustifyH("RIGHT")
        countText:SetTextColor(0.58, 0.65, 0.72)
        rowLabel.countText = countText
        rowLabel:EnableMouseWheel(true)
        rowLabel:SetScript("OnMouseWheel", function(_, delta)
            ScrollRows(delta)
        end)
        rowLabel:SetScript("OnEnter", function(self)
            if not self.step then
                return
            end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            AddStepTooltip(self.step)
            local doneCount, activeCount = ns:GetStepCharacterCounts(self.step, ns.visibleCharacters or ns:GetCharacters(false))
            local recordedCount = doneCount + activeCount
            GameTooltip:AddLine("已完成 " .. tostring(doneCount) .. " 人｜进行中 " .. tostring(activeCount) .. " 人｜共 " .. tostring(recordedCount) .. " 人", 0.75, 0.85, 0.95)
            GameTooltip:Show()
        end)
        rowLabel:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        frame.rowLabels[row] = rowLabel

        frame.cells[row] = {}
        for column = 1, VISIBLE_COLUMNS do
            local cell = CreateFrame("Button", nil, frame)
            cell:SetPoint("TOPLEFT", frame, "TOPLEFT", TABLE_X + ((column - 1) * COLUMN_WIDTH), y)
            cell:SetSize(COLUMN_WIDTH, ROW_HEIGHT)
            AddBackground(cell, row % 2 == 0 and 0.05 or 0.065, row % 2 == 0 and 0.055 or 0.07, row % 2 == 0 and 0.065 or 0.085, 1)
            AddBorder(cell, 0.18, 0.20, 0.24, 1)
            local cellText = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            cellText:SetPoint("CENTER", cell, "CENTER", 0, 0)
            cell.text = cellText
            cell:EnableMouseWheel(true)
            cell:SetScript("OnMouseWheel", function(_, delta)
                ScrollRows(delta)
            end)
            cell:SetScript("OnEnter", function(self)
                ns:ShowCellTooltip(self)
            end)
            cell:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            frame.cells[row][column] = cell
        end
    end

    local verticalSlider = MakeSlider(frame, "VERTICAL", 14, VISIBLE_ROWS * ROW_HEIGHT)
    verticalSlider:SetPoint("TOPLEFT", frame, "TOPLEFT", TABLE_X + (VISIBLE_COLUMNS * COLUMN_WIDTH) + 7, BODY_TOP)
    verticalSlider:EnableMouseWheel(true)
    verticalSlider:SetScript("OnMouseWheel", function(_, delta)
        ScrollRows(delta)
    end)
    verticalSlider:SetScript("OnValueChanged", function(_, value)
        local rounded = math_floor(value + 0.5)
        if rounded ~= (ns.rowOffset or 0) then
            ns.rowOffset = rounded
            ns:RenderMainTable()
        end
    end)
    frame.verticalSlider = verticalSlider

    local horizontalSlider = MakeSlider(frame, "HORIZONTAL", VISIBLE_COLUMNS * COLUMN_WIDTH, 14)
    horizontalSlider:SetPoint("TOPLEFT", frame, "TOPLEFT", TABLE_X, BODY_TOP - (VISIBLE_ROWS * ROW_HEIGHT) - 8)
    horizontalSlider:EnableMouseWheel(true)
    horizontalSlider:SetScript("OnMouseWheel", function(_, delta)
        -- 在底部滚动条上滚动时，移动角色列的左右位置。
        ScrollColumns(delta)
    end)
    horizontalSlider:SetScript("OnValueChanged", function(_, value)
        local rounded = math_floor(value + 0.5)
        if rounded ~= (ns.columnOffset or 0) then
            ns.columnOffset = rounded
            ns:RenderMainTable()
        end
    end)
    frame.horizontalSlider = horizontalSlider

    local noCharacters = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noCharacters:SetPoint("CENTER", frame, "CENTER", 85, -15)
    noCharacters:SetWidth(500)
    noCharacters:SetText(ns.STRINGS.NO_CHARACTERS)
    noCharacters:Hide()
    frame.noCharacters = noCharacters

    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 13)
    footer:SetText("/btcheck　打开/关闭｜/btcheck chars　角色管理｜/btcheck reset　重置位置")
    footer:SetTextColor(0.58, 0.58, 0.62)

    frame:SetScript("OnShow", function()
        ns:RefreshUI()
    end)
    frame:Hide()
    return frame
end

function ns:RenderMainTable()
    local frame = ns.mainFrame
    if not frame then
        return
    end

    local characters = self:FilterCharacters(self:GetCharacters(false))
    ns.visibleCharacters = characters
    local maxRows = math_max(0, #ns.STEPS - VISIBLE_ROWS)
    local maxColumns = math_max(0, #characters - VISIBLE_COLUMNS)
    ns.rowOffset = Clamp(ns.rowOffset or 0, 0, maxRows)
    ns.columnOffset = Clamp(ns.columnOffset or 0, 0, maxColumns)

    frame.verticalSlider:SetMinMaxValues(0, maxRows)
    frame.verticalSlider:SetValue(ns.rowOffset)
    if maxRows > 0 then
        frame.verticalSlider:Show()
    else
        frame.verticalSlider:Hide()
    end
    frame.horizontalSlider:SetMinMaxValues(0, maxColumns)
    frame.horizontalSlider:SetValue(ns.columnOffset)

    for column = 1, VISIBLE_COLUMNS do
        local character = characters[ns.columnOffset + column]
        local header = frame.characterHeaders[column]
        header.character = character
        if character then
            local completed, total, active = self:GetProgress(character)
            local liveMarker = character.guid == ns.currentGUID and not ns.deletedThisSession[character.guid] and "|cff33ff66●|r " or ""
            header.text:SetText(liveMarker .. ColorizeCharacterName(character) .. "\n|cff9aa5b1" .. tostring(character.realm) .. "|r\n" .. tostring(completed) .. "/" .. tostring(total) .. (active > 0 and ("　|cffffcc00进行 " .. tostring(active) .. "|r") or ""))
            header:Show()
        else
            header:Hide()
        end
    end

    for row = 1, VISIBLE_ROWS do
        local stepIndex = ns.rowOffset + row
        local step = ns.STEPS[stepIndex]
        local rowLabel = frame.rowLabels[row]
        rowLabel.step = step
        if step then
            local branchMarker = step.branches and " |cff73bfff[阵营]|r" or ""
            rowLabel.text:SetText(string.format("%02d　%s%s", stepIndex, step.title, branchMarker))
            local doneCount, activeCount = self:GetStepCharacterCounts(step, characters)
            rowLabel.countText:SetText(tostring(doneCount + activeCount) .. "人")
            rowLabel:Show()
        else
            rowLabel.countText:SetText("")
            rowLabel:Hide()
        end

        for column = 1, VISIBLE_COLUMNS do
            local cell = frame.cells[row][column]
            local character = characters[ns.columnOffset + column]
            cell.step = step
            cell.character = character
            if step and character then
                local status = self:GetStepStatus(character, step)
                cell.text:SetText(STATUS_TEXT[status] or STATUS_TEXT[ns.STATUS_TODO])
                cell:Show()
            else
                cell:Hide()
            end
        end
    end

    if #characters == 0 and tostring(self.searchText or "") ~= "" then
        frame.noCharacters:SetText(ns.STRINGS.NO_SEARCH_RESULTS)
    else
        frame.noCharacters:SetText(ns.STRINGS.NO_CHARACTERS)
    end
    frame.noCharacters:SetShown(#characters == 0)
end

local function CreateCharacterManager(mainFrame)
    local panel = CreateFrame("Frame", nil, mainFrame)
    panel:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -38)
    panel:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, 10)
    panel:SetFrameLevel(mainFrame:GetFrameLevel() + 20)
    AddBackground(panel, 0.025, 0.025, 0.032, 0.995)
    AddBorder(panel, 0.72, 0.55, 0.12, 1)
    panel.page = 1
    panel.rowsPerPage = CHARACTER_ROWS_PER_PAGE

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -18)
    title:SetText("角色管理")

    local description = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    description:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -43)
    description:SetText("未开始第一步的非当前角色会自动隐藏；隐藏只影响主表，删除会移除快照。")
    description:SetTextColor(0.7, 0.72, 0.76)

    local close = MakeButton(panel, "返回进度表", 100, 26)
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -14)
    close:SetScript("OnClick", function()
        panel:Hide()
    end)

    panel.rows = {}
    for index = 1, panel.rowsPerPage do
        local row = CreateFrame("Frame", nil, panel)
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -75 - ((index - 1) * CHARACTER_ROW_STEP))
        row:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -18, -75 - ((index - 1) * CHARACTER_ROW_STEP))
        row:SetHeight(42)
        AddBackground(row, index % 2 == 0 and 0.055 or 0.07, index % 2 == 0 and 0.055 or 0.07, index % 2 == 0 and 0.065 or 0.085, 1)
        AddBorder(row, 0.18, 0.19, 0.22, 1)

        local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        name:SetPoint("LEFT", row, "LEFT", 10, 0)
        name:SetWidth(470)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        row.name = name

        local hideButton = MakeButton(row, "隐藏", 78, 25)
        hideButton:SetPoint("RIGHT", row, "RIGHT", -98, 0)
        hideButton:SetScript("OnClick", function()
            local character = row.character
            if character then
                ns:SetCharacterHidden(character.guid, not character.hidden)
            end
        end)
        row.hideButton = hideButton

        local deleteButton = MakeButton(row, "删除", 78, 25)
        deleteButton:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        deleteButton:SetScript("OnClick", function()
            local character = row.character
            if character then
                panel.confirmTarget = character.guid
                panel.confirmText:SetText("确定删除 " .. tostring(character.name) .. "-" .. tostring(character.realm) .. " 的进度快照？")
                panel.confirm:Show()
            end
        end)
        row.deleteButton = deleteButton
        panel.rows[index] = row
    end

    local empty = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    empty:SetPoint("CENTER", panel, "CENTER", 0, 10)
    empty:SetText("没有可管理的角色记录。")
    empty:Hide()
    panel.empty = empty

    local previous = MakeButton(panel, "上一页", 78, 25)
    previous:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 18, 16)
    previous:SetScript("OnClick", function()
        panel.page = math_max(1, panel.page - 1)
        ns:RefreshCharacterManager()
    end)
    panel.previous = previous

    local pageText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pageText:SetPoint("LEFT", previous, "RIGHT", 14, 0)
    panel.pageText = pageText

    local nextButton = MakeButton(panel, "下一页", 78, 25)
    nextButton:SetPoint("LEFT", pageText, "RIGHT", 14, 0)
    nextButton:SetScript("OnClick", function()
        panel.page = panel.page + 1
        ns:RefreshCharacterManager()
    end)
    panel.next = nextButton

    local confirm = CreateFrame("Frame", nil, panel)
    confirm:SetSize(520, 150)
    confirm:SetPoint("CENTER", panel, "CENTER", 0, 0)
    confirm:SetFrameLevel(panel:GetFrameLevel() + 10)
    AddBackground(confirm, 0.05, 0.035, 0.035, 1)
    AddBorder(confirm, 0.8, 0.2, 0.2, 1)
    local confirmText = confirm:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    confirmText:SetPoint("TOPLEFT", confirm, "TOPLEFT", 22, -28)
    confirmText:SetPoint("TOPRIGHT", confirm, "TOPRIGHT", -22, -28)
    confirmText:SetJustifyH("CENTER")
    panel.confirmText = confirmText

    local confirmDelete = MakeButton(confirm, "确认删除", 100, 28)
    confirmDelete:SetPoint("BOTTOM", confirm, "BOTTOM", -60, 20)
    confirmDelete:SetScript("OnClick", function()
        if panel.confirmTarget then
            ns:DeleteCharacter(panel.confirmTarget)
        end
        panel.confirmTarget = nil
        confirm:Hide()
        ns:RefreshCharacterManager()
    end)

    local cancelDelete = MakeButton(confirm, "取消", 100, 28)
    cancelDelete:SetPoint("BOTTOM", confirm, "BOTTOM", 60, 20)
    cancelDelete:SetScript("OnClick", function()
        panel.confirmTarget = nil
        confirm:Hide()
    end)
    panel.confirm = confirm
    confirm:Hide()

    panel:SetScript("OnShow", function()
        panel.page = 1
        ns:RefreshCharacterManager()
    end)
    panel:Hide()
    return panel
end

function ns:RefreshCharacterManager()
    local panel = ns.characterManager
    if not panel then
        return
    end
    local characters = self:GetCharacters(true)
    local pageCount = math_max(1, math_floor((#characters + panel.rowsPerPage - 1) / panel.rowsPerPage))
    panel.page = Clamp(panel.page or 1, 1, pageCount)
    local startIndex = ((panel.page - 1) * panel.rowsPerPage) + 1

    for rowIndex = 1, panel.rowsPerPage do
        local character = characters[startIndex + rowIndex - 1]
        local row = panel.rows[rowIndex]
        row.character = character
        if character then
            local completed, total, active = self:GetProgress(character)
            local state = character.hidden and "|cffffcc00已隐藏|r" or "|cff33ff66显示中|r"
            local autoNote = character.autoHidden and "　|cffffcc00自动隐藏|r" or ""
            local firstStepNote = self:IsFirstStepNotStarted(character) and "　|cffffcc00未开始开门任务|r" or ""
            local sync = character.guid == ns.currentGUID and not ns.deletedThisSession[character.guid] and ns.STRINGS.LIVE or self:FormatTimestamp(character.lastSeen)
            row.name:SetText(ColorizeCharacterName(character) .. "-" .. tostring(character.realm) .. "　" .. state .. autoNote .. firstStepNote .. "　进度 " .. tostring(completed) .. "/" .. tostring(total) .. (active > 0 and ("｜进行中 " .. tostring(active)) or "") .. "\n|cff888f9c同步：" .. sync .. "|r")
            SetButtonText(row.hideButton, character.hidden and "恢复" or "隐藏")
            row:Show()
        else
            row:Hide()
        end
    end

    panel.empty:SetShown(#characters == 0)
    panel.pageText:SetText("第 " .. tostring(panel.page) .. " / " .. tostring(pageCount) .. " 页")
    panel.previous:SetShown(panel.page > 1)
    panel.next:SetShown(panel.page < pageCount)
end

function ns:OpenCharacterManager()
    if not ns.characterManager then
        return
    end
    if not ns.mainFrame:IsShown() then
        ns.mainFrame:Show()
    end
    ns.characterManager:Show()
end

function ns:UpdateMinimapPosition()
    if not ns.minimapButton or not ns.db then
        return
    end
    local angle = tonumber(ns.db.ui.minimapAngle) or 220
    local radius = 80
    ns.minimapButton:ClearAllPoints()
    ns.minimapButton:SetPoint("CENTER", Minimap, "CENTER", math_cos(math_rad(angle)) * radius, math_sin(math_rad(angle)) * radius)
end

local function UpdateMinimapDrag(button)
    local scale = Minimap:GetEffectiveScale()
    local centerX, centerY = Minimap:GetCenter()
    local cursorX, cursorY = GetCursorPosition()
    cursorX = cursorX / scale
    cursorY = cursorY / scale
    local angle = math_deg(math_atan2(cursorY - centerY, cursorX - centerX))
    if angle < 0 then
        angle = angle + 360
    end
    ns.db.ui.minimapAngle = angle
    button.wasDragged = true
    ns:UpdateMinimapPosition()
end

local function CreateMinimapButton()
    local button = CreateFrame("Button", "BTCheckMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    local border = button:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints(button)
    border:SetColorTexture(0.05, 0.05, 0.06, 0.95)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
    -- 该图标路径已在 20506 客户端随 Blizzard_SettingsDefinitions_Frame/Classic/Colorblind.xml 使用。
    icon:SetTexture("Interface\\Icons\\Spell_Shadow_Metamorphosis")
    icon:SetTexCoord(0, 1, 0, 1)
    icon:SetVertexColor(1, 1, 1, 1)
    button.icon = icon

    local ringTop = button:CreateTexture(nil, "OVERLAY")
    ringTop:SetColorTexture(0.8, 0.62, 0.16, 1)
    ringTop:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    ringTop:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    ringTop:SetHeight(2)
    local ringBottom = button:CreateTexture(nil, "OVERLAY")
    ringBottom:SetColorTexture(0.8, 0.62, 0.16, 1)
    ringBottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    ringBottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    ringBottom:SetHeight(2)

    button:SetScript("OnClick", function(self)
        if self.wasDragged then
            self.wasDragged = false
            return
        end
        ns:ToggleMainWindow()
    end)
    button:SetScript("OnDragStart", function(self)
        self.wasDragged = false
        self:SetScript("OnUpdate", UpdateMinimapDrag)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(ns.STRINGS.ADDON_TITLE, 1, 0.82, 0)
        GameTooltip:AddLine("左键：打开或关闭进度表", 1, 1, 1)
        GameTooltip:AddLine("拖动：调整按钮位置", 0.75, 0.75, 0.75)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    return button
end

function ns:RefreshUI()
    if not ns.mainFrame then
        return
    end

    local unlocked, names = self:GetAccountUnlockSummary()
    if unlocked then
        ns.mainFrame.accountText:SetText(ns.STRINGS.ACCOUNT_UNLOCKED .. table_concat(names, "、"))
    else
        ns.mainFrame.accountText:SetText(ns.STRINGS.ACCOUNT_PENDING)
    end
    self:RenderMainTable()
    if ns.characterManager and ns.characterManager:IsShown() then
        self:RefreshCharacterManager()
    end
end

function ns:ToggleMainWindow()
    if ns.disabledReason then
        self:Print(ns.disabledReason)
        return
    end
    if not ns.mainFrame then
        self:Print("界面尚未初始化。")
        return
    end
    if ns.mainFrame:IsShown() then
        ns.mainFrame:Hide()
    else
        if ns.ready then
            self:ScanCurrentCharacter()
        end
        ns.mainFrame:Show()
    end
end

function ns:RegisterSlashCommands()
    if ns.slashRegistered then
        return
    end
    ns.slashRegistered = true
    SLASH_BTCHECK1 = "/btcheck"
    SlashCmdList.BTCHECK = function(message)
        local command = tostring(message or ""):match("^%s*(.-)%s*$")
        command = command:lower()

        if command == "chars" then
            if ns.disabledReason then
                ns:Print(ns.disabledReason)
                return
            end
            ns:OpenCharacterManager()
        elseif command == "reset" then
            ns:ResetPositions()
            ns:Print("窗口与小地图按钮位置已重置。")
        elseif command == "refresh" then
            ns:ScanCurrentCharacter()
        elseif command == "help" then
            ns:Print("/btcheck 打开界面；chars 管理角色；refresh 刷新；reset 重置位置。")
        else
            ns:ToggleMainWindow()
        end
    end
end

function ns:InitializeUI()
    if ns.mainFrame then
        return
    end
    ns.rowOffset = 0
    ns.columnOffset = 0
    ns.searchText = ""
    ns.mainFrame = CreateMainFrame()
    ns.characterManager = CreateCharacterManager(ns.mainFrame)
    ns.minimapButton = CreateMinimapButton()
    self:ApplyWindowPosition()
    self:UpdateMinimapPosition()
    self:RefreshUI()
end
