local addonName, ns = ...

local type = type
local pairs = pairs
local tostring = tostring
local tonumber = tonumber
local table_sort = table.sort

local eventFrame = CreateFrame("Frame")
local deletedThisSession = {}

ns.eventFrame = eventFrame
ns.deletedThisSession = deletedThisSession
ns.compatible = false
ns.ready = false
ns.currentGUID = nil
ns.disabledReason = nil
ns.buildInfo = nil

local function NewDatabase()
    return {
        version = ns.DB_VERSION,
        characters = {},
        ui = {
            minimapAngle = 220,
            window = {
                point = "CENTER",
                relativePoint = "CENTER",
                x = 0,
                y = 20,
            },
        },
    }
end

function ns:Print(message)
    print("|cff9ddcffBTCheck:|r " .. tostring(message))
end

function ns:InitializeDatabase()
    if type(BTCheckDB) ~= "table" then
        BTCheckDB = NewDatabase()
    end

    if BTCheckDB.version == nil then
        BTCheckDB.version = ns.DB_VERSION
    elseif tonumber(BTCheckDB.version) > ns.DB_VERSION then
        ns.disabledReason = "数据库版本高于当前插件版本；为保护数据，插件已停止运行。"
        return false
    else
        BTCheckDB.version = ns.DB_VERSION
    end

    if type(BTCheckDB.characters) ~= "table" then
        BTCheckDB.characters = {}
    end
    if type(BTCheckDB.ui) ~= "table" then
        BTCheckDB.ui = {}
    end
    if type(BTCheckDB.ui.minimapAngle) ~= "number" then
        BTCheckDB.ui.minimapAngle = 220
    end
    if type(BTCheckDB.ui.window) ~= "table" then
        BTCheckDB.ui.window = NewDatabase().ui.window
    end

    ns.db = BTCheckDB
    return true
end

local function MissingFunction(path, value)
    if type(value) ~= "function" then
        return path
    end
    return nil
end

function ns:ValidateCompatibility()
    ns.compatible = false
    local missing = nil

    missing = missing or MissingFunction("CreateFrame", CreateFrame)
    missing = missing or MissingFunction("GetBuildInfo", GetBuildInfo)
    missing = missing or MissingFunction("UnitGUID", UnitGUID)
    missing = missing or MissingFunction("UnitName", UnitName)
    missing = missing or MissingFunction("UnitClass", UnitClass)
    missing = missing or MissingFunction("UnitFactionGroup", UnitFactionGroup)
    missing = missing or MissingFunction("GetRealmName", GetRealmName)
    missing = missing or MissingFunction("GetCursorPosition", GetCursorPosition)
    missing = missing or MissingFunction("date", date)
    missing = missing or MissingFunction("math.atan2", math.atan2)

    if not UIParent then
        missing = missing or "UIParent"
    end
    if not Minimap then
        missing = missing or "Minimap"
    end
    if not GameTooltip then
        missing = missing or "GameTooltip"
    end
    if type(SlashCmdList) ~= "table" then
        missing = missing or "SlashCmdList"
    end

    if type(C_DateAndTime) ~= "table" then
        missing = missing or "C_DateAndTime"
    else
        missing = missing or MissingFunction("C_DateAndTime.GetServerTimeLocal", C_DateAndTime.GetServerTimeLocal)
    end

    if type(C_QuestLog) ~= "table" then
        missing = missing or "C_QuestLog"
    else
        missing = missing or MissingFunction("C_QuestLog.IsQuestFlaggedCompleted", C_QuestLog.IsQuestFlaggedCompleted)
        missing = missing or MissingFunction("C_QuestLog.IsOnQuest", C_QuestLog.IsOnQuest)
    end

    if missing then
        ns.disabledReason = ns.STRINGS.API_ERROR .. missing
        return false
    end

    local version, build, buildDate, interface = GetBuildInfo()
    ns.buildInfo = {
        version = version,
        build = build,
        buildDate = buildDate,
        interface = interface,
    }

    if version ~= ns.TARGET_VERSION or tonumber(interface) ~= ns.TARGET_INTERFACE then
        ns.disabledReason = ns.STRINGS.VERSION_ERROR .. " 当前：" .. tostring(version) .. " / " .. tostring(interface)
        return false
    end

    ns.api = {
        IsQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted,
        IsOnQuest = C_QuestLog.IsOnQuest,
        GetServerTime = C_DateAndTime.GetServerTimeLocal,
    }
    ns.compatible = true
    return true
end

function ns:GetQuestStatus(character, questID)
    if not character or type(character.quests) ~= "table" then
        return ns.STATUS_TODO
    end
    return character.quests[questID] or ns.STATUS_TODO
end

function ns:GetStepStatus(character, step)
    local active = false
    for index = 1, #step.ids do
        local status = self:GetQuestStatus(character, step.ids[index])
        if status == ns.STATUS_DONE then
            return ns.STATUS_DONE
        elseif status == ns.STATUS_ACTIVE then
            active = true
        end
    end
    if active then
        return ns.STATUS_ACTIVE
    end
    return ns.STATUS_TODO
end

function ns:GetProgress(character)
    local completed = 0
    local active = 0
    for index = 1, #ns.STEPS do
        local status = self:GetStepStatus(character, ns.STEPS[index])
        if status == ns.STATUS_DONE then
            completed = completed + 1
        elseif status == ns.STATUS_ACTIVE then
            active = active + 1
        end
    end
    return completed, #ns.STEPS, active
end

function ns:IsFirstStepNotStarted(character)
    return ns.STEPS[1] and self:GetStepStatus(character, ns.STEPS[1]) == ns.STATUS_TODO
end

function ns:ApplyAutomaticVisibility()
    if not ns.db or not ns.currentGUID then
        return
    end

    for guid, character in pairs(ns.db.characters) do
        if type(character) == "table" then
            if type(character.manualHidden) ~= "boolean" then
                character.manualHidden = character.hidden == true and character.autoHidden ~= true
            end
            if type(character.autoHiddenDismissed) ~= "boolean" then
                character.autoHiddenDismissed = false
            end

            local firstStepNotStarted = self:IsFirstStepNotStarted(character)
            if not firstStepNotStarted then
                character.autoHiddenDismissed = false
            end

            if guid == ns.currentGUID then
                -- 当前登录角色不因“未开始第一步”自动隐藏。
                character.autoHidden = false
                character.autoHiddenReason = nil
            elseif firstStepNotStarted and not character.manualHidden and not character.autoHiddenDismissed then
                character.autoHidden = true
                character.autoHiddenReason = "FIRST_STEP_NOT_STARTED"
            else
                character.autoHidden = false
                character.autoHiddenReason = nil
            end

            character.hidden = character.manualHidden or character.autoHidden
        end
    end
end

function ns:GetStepCharacterCounts(step, characters)
    local completed = 0
    local active = 0
    characters = characters or self:GetCharacters(false)

    for index = 1, #characters do
        local status = self:GetStepStatus(characters[index], step)
        if status == ns.STATUS_DONE then
            completed = completed + 1
        elseif status == ns.STATUS_ACTIVE then
            active = active + 1
        end
    end

    return completed, active
end

function ns:GetCharacters(includeHidden)
    local characters = {}
    if not ns.db or type(ns.db.characters) ~= "table" then
        return characters
    end

    for guid, character in pairs(ns.db.characters) do
        if type(character) == "table" and (includeHidden or not character.hidden) then
            character.guid = guid
            characters[#characters + 1] = character
        end
    end

    table_sort(characters, function(left, right)
        if left.guid == ns.currentGUID and right.guid ~= ns.currentGUID then
            return true
        elseif right.guid == ns.currentGUID and left.guid ~= ns.currentGUID then
            return false
        end

        local leftSeen = tonumber(left.lastSeen) or 0
        local rightSeen = tonumber(right.lastSeen) or 0
        if leftSeen ~= rightSeen then
            return leftSeen > rightSeen
        end

        local leftKey = tostring(left.name or "") .. "-" .. tostring(left.realm or "")
        local rightKey = tostring(right.name or "") .. "-" .. tostring(right.realm or "")
        return leftKey < rightKey
    end)

    return characters
end

function ns:GetAccountUnlockSummary()
    local names = {}
    local characters = self:GetCharacters(true)
    for index = 1, #characters do
        local character = characters[index]
        if self:GetQuestStatus(character, 10985) == ns.STATUS_DONE then
            names[#names + 1] = tostring(character.name or "未知") .. "-" .. tostring(character.realm or "未知服务器")
        end
    end
    return #names > 0, names
end

function ns:FormatTimestamp(timestamp)
    if type(timestamp) ~= "number" or timestamp <= 0 then
        return "未知"
    end
    return date("%Y-%m-%d %H:%M", timestamp)
end

function ns:ScanCurrentCharacter()
    if not ns.compatible or not ns.ready or not ns.db then
        return false
    end

    local guid = UnitGUID("player")
    if not guid then
        self:Print("无法取得当前角色 GUID，已跳过本次扫描。")
        return false
    end
    if deletedThisSession[guid] then
        return false
    end

    local name, realm = UnitName("player")
    if not realm or realm == "" then
        realm = GetRealmName()
    end
    local className, classToken = UnitClass("player")
    local factionToken, factionName = UnitFactionGroup("player")

    local character = ns.db.characters[guid]
    if type(character) ~= "table" then
        character = { quests = {}, hidden = false }
        ns.db.characters[guid] = character
    end
    if type(character.quests) ~= "table" then
        character.quests = {}
    end

    character.name = name or "未知角色"
    character.realm = realm or "未知服务器"
    character.className = className or ""
    character.classToken = classToken or ""
    character.factionName = factionName or ""
    character.factionToken = factionToken or ""
    character.lastSeen = ns.api.GetServerTime()

    for index = 1, #ns.ALL_QUEST_IDS do
        local questID = ns.ALL_QUEST_IDS[index]
        if ns.api.IsQuestCompleted(questID) then
            character.quests[questID] = ns.STATUS_DONE
        elseif ns.api.IsOnQuest(questID) then
            character.quests[questID] = ns.STATUS_ACTIVE
        else
            character.quests[questID] = ns.STATUS_TODO
        end
    end

    ns.currentGUID = guid
    self:ApplyAutomaticVisibility()
    if ns.RefreshUI then
        ns:RefreshUI()
    end
    return true
end

function ns:SetCharacterHidden(guid, hidden)
    local character = ns.db and ns.db.characters and ns.db.characters[guid]
    if not character then
        return
    end
    local wasAutoHidden = character.autoHidden == true
    if type(character.manualHidden) ~= "boolean" then
        character.manualHidden = character.hidden == true and not wasAutoHidden
    end
    if hidden then
        character.manualHidden = true
        character.autoHiddenDismissed = false
    else
        character.manualHidden = false
        character.autoHiddenDismissed = wasAutoHidden
    end
    character.autoHidden = false
    character.autoHiddenReason = nil
    character.hidden = character.manualHidden
    if ns.RefreshUI then
        ns:RefreshUI()
    end
end

function ns:DeleteCharacter(guid)
    if not ns.db or not ns.db.characters or not ns.db.characters[guid] then
        return
    end
    ns.db.characters[guid] = nil
    if guid == ns.currentGUID then
        deletedThisSession[guid] = true
    end
    if ns.RefreshUI then
        ns:RefreshUI()
    end
end

function ns:ResetPositions()
    if not ns.db then
        return
    end
    ns.db.ui.minimapAngle = 220
    ns.db.ui.window = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 20,
    }
    if ns.ApplyWindowPosition then
        ns:ApplyWindowPosition()
    end
    if ns.UpdateMinimapPosition then
        ns:UpdateMinimapPosition()
    end
end

local function HandleAddonLoaded(loadedAddon)
    if loadedAddon ~= addonName then
        return
    end

    eventFrame:UnregisterEvent("ADDON_LOADED")
    if not ns:InitializeDatabase() then
        return
    end
    ns:ValidateCompatibility()

    if ns.RegisterSlashCommands then
        ns:RegisterSlashCommands()
    end
    if ns.compatible then
        if ns.InitializeUI then
            ns:InitializeUI()
        end
        eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
        eventFrame:RegisterEvent("QUEST_TURNED_IN")
    end
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        HandleAddonLoaded(...)
    elseif event == "PLAYER_LOGIN" then
        if ns.disabledReason then
            ns:Print(ns.disabledReason)
            return
        end
        if ns.compatible then
            ns.ready = true
            ns:ScanCurrentCharacter()
        end
    elseif event == "QUEST_LOG_UPDATE" or event == "QUEST_TURNED_IN" then
        ns:ScanCurrentCharacter()
    end
end)
