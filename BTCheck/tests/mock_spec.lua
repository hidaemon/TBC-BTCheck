local addonPath = (... or "outputs/BTCheck")

local registeredEvents = {}
local eventHandler = nil

local frame = {}
function frame:RegisterEvent(event)
    registeredEvents[event] = true
end
function frame:UnregisterEvent(event)
    registeredEvents[event] = nil
end
function frame:SetScript(script, handler)
    if script == "OnEvent" then
        eventHandler = handler
    end
end
function frame:GetText()
    return self.text or ""
end
function frame:SetText(text)
    self.text = text
end
function frame:SetAutoFocus()
end
function frame:SetTextInsets()
end
function frame:SetFontObject()
end
function frame:SetTextColor()
end
function frame:ClearFocus()
end
function frame:Hide()
end

function CreateFrame()
    return frame
end

UIParent = {}
Minimap = {}
GameTooltip = {}
SlashCmdList = {}

local runtime = {
    guid = "Player-1-A",
    name = "奥尔多角色",
    realm = "测试服一",
    className = "战士",
    classToken = "WARRIOR",
    factionToken = "Alliance",
    factionName = "联盟",
    now = 1000,
    completed = {},
    active = {},
}

function GetBuildInfo()
    return "2.5.6", "69110", "Aug 5 2026", 20506
end
function UnitGUID()
    return runtime.guid
end
function UnitName()
    return runtime.name, runtime.realm
end
function UnitClass()
    return runtime.className, runtime.classToken, 1
end
function UnitFactionGroup()
    return runtime.factionToken, runtime.factionName
end
function GetRealmName()
    return runtime.realm
end
function GetCursorPosition()
    return 0, 0
end
function date(_, timestamp)
    return "T" .. tostring(timestamp)
end

C_DateAndTime = {
    GetServerTimeLocal = function()
        return runtime.now
    end,
}

C_QuestLog = {
    IsQuestFlaggedCompleted = function(questID)
        return runtime.completed[questID] == true
    end,
    IsOnQuest = function(questID)
        return runtime.active[questID] == true
    end,
}

local ns = {}
assert(loadfile(addonPath .. "/Data.lua"))("BTCheck", ns)
assert(loadfile(addonPath .. "/Core.lua"))("BTCheck", ns)

assert(eventHandler, "Core.lua did not install its event handler")
eventHandler(frame, "ADDON_LOADED", "BTCheck")
assert(ns.compatible, ns.disabledReason or "compatibility validation failed")
assert(registeredEvents.QUEST_LOG_UPDATE, "QUEST_LOG_UPDATE was not registered")
assert(registeredEvents.QUEST_TURNED_IN, "QUEST_TURNED_IN was not registered")

runtime.completed = {
    [10568] = true,
    [10571] = true,
    [10574] = true,
    [10575] = true,
    [10622] = true,
}
runtime.active = { [10628] = true }
eventHandler(frame, "PLAYER_LOGIN")

local first = BTCheckDB.characters[runtime.guid]
assert(first, "current character was not created")
local completed, total, active = ns:GetProgress(first)
assert(completed == 5, "expected 5 completed stages, got " .. tostring(completed))
assert(total == 16, "expected denominator 16, got " .. tostring(total))
assert(active == 1, "expected 1 active stage, got " .. tostring(active))

-- Completing both faction variants must not double-count the first four stages.
runtime.completed = {
    [10568] = true, [10683] = true,
    [10571] = true, [10684] = true,
    [10574] = true, [10685] = true,
    [10575] = true, [10686] = true,
}
runtime.active = {}
runtime.now = 1100
ns:ScanCurrentCharacter()
completed, total = ns:GetProgress(first)
assert(completed == 4, "faction branches double-counted; expected 4, got " .. tostring(completed))
assert(total == 16, "branch test changed denominator")

-- Add a second, cross-realm Scryer character and complete the final attunement quest.
runtime.guid = "Player-1-B"
runtime.name = "占星角色"
runtime.realm = "测试服二"
runtime.className = "法师"
runtime.classToken = "MAGE"
runtime.factionToken = "Horde"
runtime.factionName = "部落"
runtime.now = 1200
runtime.completed = {
    [10683] = true,
    [10684] = true,
    [10685] = true,
    [10686] = true,
    [10985] = true,
}
runtime.active = {}
ns:ScanCurrentCharacter()

local second = BTCheckDB.characters[runtime.guid]
assert(second and second.realm == "测试服二", "cross-realm character was not stored")
local characters = ns:GetCharacters(false)
assert(#characters == 2, "expected two visible characters")
assert(characters[1].guid == runtime.guid, "current character was not sorted first")

local unlocked, names = ns:GetAccountUnlockSummary()
assert(unlocked, "account unlock summary did not detect quest 10985")
assert(#names == 1 and names[1] == "占星角色-测试服二", "unexpected unlock character list")

first.quests[10622] = ns.STATUS_DONE
local doneCount, activeCount = ns:GetStepCharacterCounts(ns.STEPS[5], ns:GetCharacters(false))
assert(doneCount == 1 and activeCount == 0, "visible task character count was incorrect")
ns:SetCharacterHidden("Player-1-A", true)
doneCount, activeCount = ns:GetStepCharacterCounts(ns.STEPS[5], ns:GetCharacters(false))
assert(doneCount == 0 and activeCount == 0, "hidden character was included in task count")
assert(#ns:GetCharacters(false) == 1, "hidden character remained in the main list")
assert(#ns:GetCharacters(true) == 2, "hidden character disappeared from management list")
ns:SetCharacterHidden("Player-1-A", false)
assert(#ns:GetCharacters(false) == 2, "restored character did not return")

-- A character with no first-step progress stays visible while logged in,
-- then becomes automatically hidden after switching to another character.
runtime.guid = "Player-1-C"
runtime.name = "未开始角色"
runtime.realm = "测试服三"
runtime.className = "盗贼"
runtime.classToken = "ROGUE"
runtime.factionToken = "Alliance"
runtime.factionName = "联盟"
runtime.now = 1300
runtime.completed = {}
runtime.active = {}
ns:ScanCurrentCharacter()

local third = BTCheckDB.characters[runtime.guid]
assert(third and ns:IsFirstStepNotStarted(third), "unstarted character was not detected")
assert(not third.hidden and not third.autoHidden, "current unstarted character was hidden")
assert(#ns:GetCharacters(false) == 3, "current unstarted character was removed from the main list")

runtime.guid = "Player-1-B"
runtime.name = "占星角色"
runtime.realm = "测试服二"
runtime.className = "法师"
runtime.classToken = "MAGE"
runtime.factionToken = "Horde"
runtime.factionName = "部落"
runtime.now = 1400
runtime.completed = {
    [10683] = true, [10684] = true, [10685] = true, [10686] = true, [10985] = true,
}
runtime.active = {}
ns:ScanCurrentCharacter()
assert(third.hidden and third.autoHidden, "other unstarted character was not auto-hidden")
assert(third.autoHiddenReason == "FIRST_STEP_NOT_STARTED", "auto-hidden reason was not recorded")
assert(#ns:GetCharacters(false) == 2, "auto-hidden character remained in the main list")

ns:SetCharacterHidden("Player-1-C", false)
assert(not third.hidden and third.autoHiddenDismissed, "manual restore did not override auto-hide")
ns:ApplyAutomaticVisibility()
assert(not third.hidden, "manually restored character was hidden again without a status change")

ns:DeleteCharacter(runtime.guid)
assert(BTCheckDB.characters[runtime.guid] == nil, "character deletion failed")
ns:ScanCurrentCharacter()
assert(BTCheckDB.characters[runtime.guid] == nil, "deleted current character was recreated in the same session")

local validGetBuildInfo = GetBuildInfo
GetBuildInfo = function()
    return "2.5.5", "68000", "Jul 1 2026", 20505
end
assert(not ns:ValidateCompatibility(), "version mismatch did not fail closed")
assert(not ns.compatible, "version mismatch left the addon compatible")
assert(ns.disabledReason and ns.disabledReason:find("20506", 1, true), "version mismatch reason was not specific")
GetBuildInfo = validGetBuildInfo

print("BTCheck mock tests: PASS")
