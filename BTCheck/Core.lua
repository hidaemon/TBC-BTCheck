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
            selectedRaidKey = "overview",
            window = {
                point = "CENTER",
                relativePoint = "CENTER",
                x = 0,
                y = 20,
            },
        },
    }
end

local function MergeQuestTables(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return
    end
    for questID, status in pairs(source) do
        local numericID = tonumber(questID) or questID
        local numericStatus = tonumber(status) or ns.STATUS_TODO
        if numericStatus > (tonumber(target[numericID]) or ns.STATUS_TODO) then
            target[numericID] = numericStatus
        end
    end
end

local function EnsureCharacterRaid(character, raidKey)
    if type(character.raids) ~= "table" then
        character.raids = {}
    end
    if type(character.raids[raidKey]) ~= "table" then
        character.raids[raidKey] = { quests = {} }
    end
    local snapshot = character.raids[raidKey]
    if type(snapshot.quests) ~= "table" then
        snapshot.quests = {}
    end
    return snapshot
end

local function MigrateCharacter(character)
    if type(character) ~= "table" then
        return
    end

    local blackTemple = EnsureCharacterRaid(character, "black_temple")
    if type(character.quests) == "table" then
        MergeQuestTables(blackTemple.quests, character.quests)
        character.quests = nil
    end

    for raidIndex = 1, #ns.ATTUNEMENT_RAID_KEYS do
        EnsureCharacterRaid(character, ns.ATTUNEMENT_RAID_KEYS[raidIndex])
    end

    if type(character.manualHidden) ~= "boolean" then
        character.manualHidden = character.hidden == true and character.autoHidden ~= true
    end
    if type(character.autoHiddenDismissed) ~= "boolean" then
        character.autoHiddenDismissed = false
    end
    character.hidden = character.manualHidden or character.autoHidden == true
end

function ns:Print(message)
    print("|cff9ddcffBTCheck:|r " .. tostring(message))
end

function ns:InitializeDatabase()
    if type(BTCheckDB) ~= "table" then
        BTCheckDB = NewDatabase()
    end

    local oldVersion = tonumber(BTCheckDB.version) or 1
    if oldVersion > ns.DB_VERSION then
        ns.disabledReason = "数据库版本高于当前插件版本；为保护数据，插件已停止运行。"
        return false
    end

    if type(BTCheckDB.characters) ~= "table" then
        BTCheckDB.characters = {}
    end
    for _, character in pairs(BTCheckDB.characters) do
        MigrateCharacter(character)
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
    if oldVersion < 2 and BTCheckDB.ui.selectedRaidKey == nil then
        -- 老用户升级后先看到原来的黑暗神殿页面。
        BTCheckDB.ui.selectedRaidKey = ns.DEFAULT_RAID_KEY
    end
    if BTCheckDB.ui.selectedRaidKey ~= "overview" and not ns.RAIDS[BTCheckDB.ui.selectedRaidKey] then
        BTCheckDB.ui.selectedRaidKey = "overview"
    end

    BTCheckDB.version = ns.DB_VERSION
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

    if not UIParent then missing = missing or "UIParent" end
    if not Minimap then missing = missing or "Minimap" end
    if not GameTooltip then missing = missing or "GameTooltip" end
    if type(SlashCmdList) ~= "table" then missing = missing or "SlashCmdList" end

    if not missing then
        local searchBox = CreateFrame("EditBox", nil, UIParent)
        if not searchBox then
            missing = "CreateFrame(EditBox)"
        else
            local searchMethods = {
                "GetText", "SetText", "SetAutoFocus", "SetTextInsets",
                "SetFontObject", "SetTextColor", "ClearFocus",
            }
            for index = 1, #searchMethods do
                local method = searchMethods[index]
                missing = missing or MissingFunction("EditBox:" .. method, searchBox[method])
            end
            searchBox:Hide()
        end
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
    ns.buildInfo = { version = version, build = build, buildDate = buildDate, interface = interface }
    if version ~= ns.TARGET_VERSION or tonumber(interface) ~= ns.TARGET_INTERFACE then
        ns.disabledReason = ns.STRINGS.VERSION_ERROR .. " 当前：" .. tostring(version) .. " / " .. tostring(interface)
        return false
    end

    ns.api = {
        IsQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted,
        IsOnQuest = C_QuestLog.IsOnQuest,
        GetServerTime = C_DateAndTime.GetServerTimeLocal,
    }
    ns.disabledReason = nil
    ns.compatible = true
    return true
end

function ns:GetRaid(raidOrKey)
    if type(raidOrKey) == "table" then
        return raidOrKey
    end
    local raidKey = raidOrKey
    if not raidKey or raidKey == "overview" then
        raidKey = ns.DEFAULT_RAID_KEY
    end
    return ns.RAIDS[raidKey]
end

function ns:GetSelectedRaidKey()
    if ns.db and ns.db.ui then
        return ns.db.ui.selectedRaidKey or "overview"
    end
    return "overview"
end

function ns:SetSelectedRaidKey(raidKey)
    if raidKey ~= "overview" and not ns.RAIDS[raidKey] then
        return false
    end
    if ns.db and ns.db.ui then
        ns.db.ui.selectedRaidKey = raidKey
    end
    return true
end

function ns:GetRaidSnapshot(character, raidOrKey, create)
    if type(character) ~= "table" then
        return nil
    end
    local raid = self:GetRaid(raidOrKey)
    if not raid then
        return nil
    end
    if create then
        return EnsureCharacterRaid(character, raid.key)
    end
    return type(character.raids) == "table" and character.raids[raid.key] or nil
end

function ns:GetQuestStatus(character, questID, raidOrKey)
    local snapshot = self:GetRaidSnapshot(character, raidOrKey, false)
    if not snapshot or type(snapshot.quests) ~= "table" then
        return ns.STATUS_TODO
    end
    return tonumber(snapshot.quests[questID]) or ns.STATUS_TODO
end

function ns:GetStepStatus(character, step, raidOrKey)
    local active = false
    for index = 1, #step.ids do
        local status = self:GetQuestStatus(character, step.ids[index], raidOrKey)
        if status == ns.STATUS_DONE then
            return ns.STATUS_DONE
        elseif status == ns.STATUS_ACTIVE then
            active = true
        end
    end
    return active and ns.STATUS_ACTIVE or ns.STATUS_TODO
end

function ns:GetProgress(character, raidOrKey)
    local raid = self:GetRaid(raidOrKey)
    if not raid or not raid.hasAttunement then
        return 0, 0, 0
    end
    local completed, active = 0, 0
    for index = 1, #raid.steps do
        local status = self:GetStepStatus(character, raid.steps[index], raid)
        if status == ns.STATUS_DONE then
            completed = completed + 1
        elseif status == ns.STATUS_ACTIVE then
            active = active + 1
        end
    end
    return completed, #raid.steps, active
end

function ns:GetOverallProgress(character)
    local completed, total, active = 0, 0, 0
    for index = 1, #ns.ATTUNEMENT_RAID_KEYS do
        local raidCompleted, raidTotal, raidActive = self:GetProgress(character, ns.ATTUNEMENT_RAID_KEYS[index])
        completed = completed + raidCompleted
        total = total + raidTotal
        active = active + raidActive
    end
    return completed, total, active
end

function ns:HasAnyTrackedProgress(character)
    if type(character) ~= "table" or type(character.raids) ~= "table" then
        return false
    end
    for raidIndex = 1, #ns.ATTUNEMENT_RAID_KEYS do
        local raidKey = ns.ATTUNEMENT_RAID_KEYS[raidIndex]
        local snapshot = character.raids[raidKey]
        if snapshot and type(snapshot.quests) == "table" then
            for _, status in pairs(snapshot.quests) do
                if tonumber(status) == ns.STATUS_ACTIVE or tonumber(status) == ns.STATUS_DONE then
                    return true
                end
            end
        end
    end
    return false
end

function ns:IsFirstStepNotStarted(character, raidOrKey)
    local raid = self:GetRaid(raidOrKey)
    return raid and raid.steps[1] and self:GetStepStatus(character, raid.steps[1], raid) == ns.STATUS_TODO
end

function ns:ApplyAutomaticVisibility()
    if not ns.db or not ns.currentGUID then return end

    for guid, character in pairs(ns.db.characters) do
        if type(character) == "table" then
            MigrateCharacter(character)
            local hasProgress = self:HasAnyTrackedProgress(character)
            if hasProgress then
                character.autoHiddenDismissed = false
            end

            if guid == ns.currentGUID then
                character.autoHidden = false
                character.autoHiddenReason = nil
            elseif not hasProgress and not character.manualHidden and not character.autoHiddenDismissed then
                character.autoHidden = true
                character.autoHiddenReason = "NO_TRACKED_ATTUNEMENT_PROGRESS"
            else
                character.autoHidden = false
                character.autoHiddenReason = nil
            end
            character.hidden = character.manualHidden or character.autoHidden
        end
    end
end

function ns:GetStepCharacterCounts(step, characters, raidOrKey)
    local completed, active = 0, 0
    characters = characters or self:GetCharacters(false)
    for index = 1, #characters do
        local status = self:GetStepStatus(characters[index], step, raidOrKey)
        if status == ns.STATUS_DONE then completed = completed + 1
        elseif status == ns.STATUS_ACTIVE then active = active + 1 end
    end
    return completed, active
end

function ns:GetCharacters(includeHidden)
    local characters = {}
    if not ns.db or type(ns.db.characters) ~= "table" then return characters end

    for guid, character in pairs(ns.db.characters) do
        if type(character) == "table" and (includeHidden or not character.hidden) then
            character.guid = guid
            characters[#characters + 1] = character
        end
    end
    table_sort(characters, function(left, right)
        if left.guid == ns.currentGUID and right.guid ~= ns.currentGUID then return true end
        if right.guid == ns.currentGUID and left.guid ~= ns.currentGUID then return false end
        local leftSeen, rightSeen = tonumber(left.lastSeen) or 0, tonumber(right.lastSeen) or 0
        if leftSeen ~= rightSeen then return leftSeen > rightSeen end
        return tostring(left.name or "") .. "-" .. tostring(left.realm or "") < tostring(right.name or "") .. "-" .. tostring(right.realm or "")
    end)
    return characters
end

function ns:GetAccountUnlockSummary(raidOrKey)
    local raid = self:GetRaid(raidOrKey)
    local names = {}
    if not raid or not raid.hasAttunement then return false, names end

    local characters = self:GetCharacters(true)
    for index = 1, #characters do
        local character = characters[index]
        local completed = false
        for finalIndex = 1, #raid.finalQuestIDs do
            if self:GetQuestStatus(character, raid.finalQuestIDs[finalIndex], raid) == ns.STATUS_DONE then
                completed = true
                break
            end
        end
        if completed then
            names[#names + 1] = tostring(character.name or "未知") .. "-" .. tostring(character.realm or "未知服务器")
        end
    end
    return #names > 0, names
end

function ns:FormatTimestamp(timestamp)
    if type(timestamp) ~= "number" or timestamp <= 0 then return "未知" end
    return date("%Y-%m-%d %H:%M", timestamp)
end

function ns:ScanCurrentCharacter()
    if not ns.compatible or not ns.ready or not ns.db then return false end

    local guid = UnitGUID("player")
    if not guid then
        self:Print("无法取得当前角色 GUID，已跳过本次扫描。")
        return false
    end
    if deletedThisSession[guid] then return false end

    local name, realm = UnitName("player")
    if not realm or realm == "" then realm = GetRealmName() end
    local className, classToken = UnitClass("player")
    local factionToken, factionName = UnitFactionGroup("player")

    local character = ns.db.characters[guid]
    if type(character) ~= "table" then
        character = { raids = {}, hidden = false, manualHidden = false }
        ns.db.characters[guid] = character
    end
    MigrateCharacter(character)

    character.name = name or "未知角色"
    character.realm = realm or "未知服务器"
    character.className = className or ""
    character.classToken = classToken or ""
    character.factionName = factionName or ""
    character.factionToken = factionToken or ""
    character.lastSeen = ns.api.GetServerTime()

    for raidIndex = 1, #ns.ATTUNEMENT_RAID_KEYS do
        local raidKey = ns.ATTUNEMENT_RAID_KEYS[raidIndex]
        local snapshot = EnsureCharacterRaid(character, raidKey)
        local questIDs = ns.ALL_QUEST_IDS_BY_RAID[raidKey]
        snapshot.lastScan = character.lastSeen
        for questIndex = 1, #questIDs do
            local questID = questIDs[questIndex]
            if ns.api.IsQuestCompleted(questID) then
                snapshot.quests[questID] = ns.STATUS_DONE
            elseif ns.api.IsOnQuest(questID) then
                snapshot.quests[questID] = ns.STATUS_ACTIVE
            else
                snapshot.quests[questID] = ns.STATUS_TODO
            end
        end
    end

    ns.currentGUID = guid
    self:ApplyAutomaticVisibility()
    if ns.RefreshUI then ns:RefreshUI() end
    return true
end

function ns:SetCharacterHidden(guid, hidden)
    local character = ns.db and ns.db.characters and ns.db.characters[guid]
    if not character then return end
    local wasAutoHidden = character.autoHidden == true
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
    if ns.RefreshUI then ns:RefreshUI() end
end

function ns:DeleteCharacter(guid)
    if not ns.db or not ns.db.characters or not ns.db.characters[guid] then return end
    ns.db.characters[guid] = nil
    if guid == ns.currentGUID then deletedThisSession[guid] = true end
    if ns.RefreshUI then ns:RefreshUI() end
end

function ns:ResetPositions()
    if not ns.db then return end
    ns.db.ui.minimapAngle = 220
    ns.db.ui.window = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 20 }
    if ns.ApplyWindowPosition then ns:ApplyWindowPosition() end
    if ns.UpdateMinimapPosition then ns:UpdateMinimapPosition() end
end

local function HandleAddonLoaded(loadedAddon)
    if loadedAddon ~= addonName then return end
    eventFrame:UnregisterEvent("ADDON_LOADED")
    if not ns:InitializeDatabase() then return end
    ns:ValidateCompatibility()
    if ns.RegisterSlashCommands then ns:RegisterSlashCommands() end
    if ns.compatible then
        if ns.InitializeUI then ns:InitializeUI() end
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
        if ns.disabledReason then ns:Print(ns.disabledReason); return end
        if ns.compatible then ns.ready = true; ns:ScanCurrentCharacter() end
    elseif event == "QUEST_LOG_UPDATE" or event == "QUEST_TURNED_IN" then
        ns:ScanCurrentCharacter()
    end
end)
