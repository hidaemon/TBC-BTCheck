local addonPath = (... or "BTCheck")

math.atan2 = math.atan2 or function(y, x)
    return math.atan(y, x)
end

local registeredEvents = {}
local eventHandler = nil

local frame = {}
function frame:RegisterEvent(event) registeredEvents[event] = true end
function frame:UnregisterEvent(event) registeredEvents[event] = nil end
function frame:SetScript(script, handler)
    if script == "OnEvent" then eventHandler = handler end
end
function frame:GetText() return self.text or "" end
function frame:SetText(text) self.text = text end
function frame:SetAutoFocus() end
function frame:SetTextInsets() end
function frame:SetFontObject() end
function frame:SetTextColor() end
function frame:ClearFocus() end
function frame:Hide() end

function CreateFrame() return frame end
UIParent, Minimap, GameTooltip, SlashCmdList = {}, {}, {}, {}

local runtime = {
    guid = "Player-1-A", name = "综合角色", realm = "测试服一",
    className = "战士", classToken = "WARRIOR",
    factionToken = "Alliance", factionName = "联盟",
    now = 1000, completed = {}, active = {},
}

function GetBuildInfo() return "2.5.6", "69110", "Aug 5 2026", 20506 end
function UnitGUID() return runtime.guid end
function UnitName() return runtime.name, runtime.realm end
function UnitClass() return runtime.className, runtime.classToken, 1 end
function UnitFactionGroup() return runtime.factionToken, runtime.factionName end
function GetRealmName() return runtime.realm end
function GetCursorPosition() return 0, 0 end
function date(_, timestamp) return "T" .. tostring(timestamp) end

C_DateAndTime = { GetServerTimeLocal = function() return runtime.now end }
C_QuestLog = {
    IsQuestFlaggedCompleted = function(questID) return runtime.completed[questID] == true end,
    IsOnQuest = function(questID) return runtime.active[questID] == true end,
}

-- 模拟 1.x 数据，验证 2.0.0 无损迁移。
BTCheckDB = {
    version = 1,
    characters = {
        ["Player-Legacy"] = {
            name = "旧版角色", realm = "旧服", classToken = "PRIEST",
            lastSeen = 500, hidden = false,
            quests = { [10568] = 2, [10571] = 2, [10622] = 1 },
        },
    },
    ui = {},
}

local ns = {}
assert(loadfile(addonPath .. "/Data.lua"))("BTCheck", ns)
assert(loadfile(addonPath .. "/Core.lua"))("BTCheck", ns)

assert(#ns.RAID_ORDER == 9, "raid registry must contain all nine level-70 raids")
assert(#ns.ATTUNEMENT_RAID_KEYS == 5, "expected five formal attunement lines")
assert(#ns.RAIDS.karazhan.steps == 8, "Karazhan denominator changed")
assert(#ns.RAIDS.tempest_keep.steps == 30, "Tempest Keep denominator changed")
assert(#ns.RAIDS.black_temple.steps == 16, "Black Temple denominator changed")
assert(not ns.RAIDS.gruuls_lair.hasAttunement, "Gruul was incorrectly given an attunement")
assert(not ns.RAIDS.sunwell_plateau.hasAttunement, "Sunwell was incorrectly given a personal attunement")

local allQuestIDs = {}
for raidIndex = 1, #ns.RAID_ORDER do
    local raid = ns.RAIDS[ns.RAID_ORDER[raidIndex]]
    local raidQuestIDs = {}
    local stepKeys = {}
    for stepIndex = 1, #raid.steps do
        local step = raid.steps[stepIndex]
        assert(not stepKeys[step.key], "duplicate logical step key in " .. raid.key)
        stepKeys[step.key] = true
        for questIndex = 1, #step.ids do
            local questID = step.ids[questIndex]
            raidQuestIDs[questID] = true
            allQuestIDs[questID] = true
        end
    end
    for finalIndex = 1, #raid.finalQuestIDs do
        assert(raidQuestIDs[raid.finalQuestIDs[finalIndex]], "final quest is outside the tracked line: " .. raid.key)
    end
end
local uniqueQuestCount = 0
for _ in pairs(allQuestIDs) do uniqueQuestCount = uniqueQuestCount + 1 end
assert(uniqueQuestCount == #ns.ALL_QUEST_IDS, "global quest scanner contains duplicate IDs")

assert(eventHandler, "Core.lua did not install its event handler")
eventHandler(frame, "ADDON_LOADED", "BTCheck")
assert(ns.compatible, ns.disabledReason or "compatibility validation failed")
assert(BTCheckDB.version == 2, "database schema was not upgraded")
local legacy = BTCheckDB.characters["Player-Legacy"]
assert(legacy.quests == nil, "legacy top-level quest table was not retired")
assert(legacy.raids.black_temple.quests[10568] == ns.STATUS_DONE, "legacy BT completion was not migrated")
assert(legacy.raids.black_temple.quests[10622] == ns.STATUS_ACTIVE, "legacy active state was not migrated")
assert(BTCheckDB.ui.selectedRaidKey == "black_temple", "upgraded users should remain on the BT page")
assert(registeredEvents.QUEST_LOG_UPDATE and registeredEvents.QUEST_TURNED_IN, "quest events were not registered")

runtime.completed = {
    [9824] = true, [9825] = true, [9826] = true,
    [10568] = true, [10571] = true, [10574] = true, [10575] = true, [10622] = true,
    [10680] = true, [10458] = true,
}
runtime.active = { [9829] = true, [10628] = true, [10480] = true, [10901] = true }
eventHandler(frame, "PLAYER_LOGIN")

local first = BTCheckDB.characters[runtime.guid]
assert(first and first.raids and not first.quests, "current character did not use v2 raid snapshots")
local completed, total, active = ns:GetProgress(first, "black_temple")
assert(completed == 5 and total == 16 and active == 1, "Black Temple progress aggregation failed")
completed, total, active = ns:GetProgress(first, "karazhan")
assert(completed == 3 and total == 8 and active == 1, "Karazhan progress aggregation failed")
completed, total, active = ns:GetProgress(first, "tempest_keep")
assert(completed == 2 and total == 30 and active == 1, "Tempest Keep progress aggregation failed")
completed, total, active = ns:GetProgress(first, "serpentshrine_cavern")
assert(completed == 0 and total == 1 and active == 1, "SSC active state failed")
assert(ns:GetProgress(first, "gruuls_lair") == 0, "no-attunement raid returned fake progress")

-- 两个任务 ID 同时完成也只能算一个分支步骤。
runtime.completed[10683] = true
runtime.completed[10681] = true
ns:ScanCurrentCharacter()
completed = ns:GetProgress(first, "black_temple")
assert(completed == 5, "BT Aldor/Scryer alternatives double-counted")
completed = ns:GetProgress(first, "tempest_keep")
assert(completed == 2, "Tempest Keep faction alternatives double-counted")

-- 第二个跨服角色完成 SSC 与 BT，账号汇总必须按所选团本独立计算。
runtime.guid = "Player-1-B"
runtime.name = "完成角色"
runtime.realm = "测试服二"
runtime.className, runtime.classToken = "法师", "MAGE"
runtime.factionToken, runtime.factionName = "Horde", "部落"
runtime.now = 1200
runtime.completed = { [10901] = true, [10985] = true }
runtime.active = {}
ns:ScanCurrentCharacter()

local unlocked, names = ns:GetAccountUnlockSummary("serpentshrine_cavern")
assert(unlocked and #names == 1 and names[1] == "完成角色-测试服二", "SSC account summary failed")
unlocked, names = ns:GetAccountUnlockSummary("black_temple")
assert(unlocked and #names == 1, "BT account summary failed")
unlocked = ns:GetAccountUnlockSummary("hyjal_summit")
assert(not unlocked, "Hyjal account summary leaked another raid's completion")

local doneCount, activeCount = ns:GetStepCharacterCounts(ns.RAIDS.serpentshrine_cavern.steps[1], ns:GetCharacters(false), "serpentshrine_cavern")
assert(doneCount == 1 and activeCount == 1, "raid-specific visible character count failed")

-- 当前无进度角色保留；切换角色后自动隐藏。手动恢复后保持显示。
runtime.guid = "Player-1-C"
runtime.name = "未开始角色"
runtime.realm = "测试服三"
runtime.className, runtime.classToken = "盗贼", "ROGUE"
runtime.now = 1300
runtime.completed, runtime.active = {}, {}
ns:ScanCurrentCharacter()
local third = BTCheckDB.characters[runtime.guid]
assert(not third.hidden and not ns:HasAnyTrackedProgress(third), "current unstarted character was hidden")

runtime.guid = "Player-1-B"
runtime.name = "完成角色"
runtime.realm = "测试服二"
runtime.className, runtime.classToken = "法师", "MAGE"
runtime.now = 1400
runtime.completed = { [10901] = true, [10985] = true }
ns:ScanCurrentCharacter()
assert(third.hidden and third.autoHiddenReason == "NO_TRACKED_ATTUNEMENT_PROGRESS", "unstarted offline character was not auto-hidden")
ns:SetCharacterHidden("Player-1-C", false)
ns:ApplyAutomaticVisibility()
assert(not third.hidden and third.autoHiddenDismissed, "manual restore did not override global auto-hide")

ns:DeleteCharacter(runtime.guid)
assert(BTCheckDB.characters[runtime.guid] == nil, "character deletion failed")
ns:ScanCurrentCharacter()
assert(BTCheckDB.characters[runtime.guid] == nil, "deleted current character was recreated in the same session")

local validGetBuildInfo = GetBuildInfo
GetBuildInfo = function() return "2.5.5", "68000", "Jul 1 2026", 20505 end
assert(not ns:ValidateCompatibility(), "version mismatch did not fail closed")
assert(ns.disabledReason and ns.disabledReason:find("20506", 1, true), "version mismatch reason was not specific")
GetBuildInfo = validGetBuildInfo

print("BTCheck v2 mock tests: PASS")
