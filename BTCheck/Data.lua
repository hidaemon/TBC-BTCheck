local addonName, ns = ...

ns.ADDON_NAME = addonName
ns.DB_VERSION = 1
ns.TARGET_VERSION = "2.5.6"
ns.TARGET_INTERFACE = 20506

ns.STATUS_TODO = 0
ns.STATUS_ACTIVE = 1
ns.STATUS_DONE = 2

-- The first four stages have mutually exclusive Aldor/Scryer quest IDs.
-- Either quest ID completes the logical stage, so the denominator remains 16.
ns.STEPS = {
    { key = "baari_tablets", title = "巴尔里石板", ids = { 10568, 10683 }, branches = { [10568] = "奥尔多", [10683] = "占星者" } },
    { key = "oronu", title = "长者奥洛努", ids = { 10571, 10684 }, branches = { [10571] = "奥尔多", [10684] = "占星者" } },
    { key = "corruptors", title = "灰舌腐蚀者", ids = { 10574, 10685 }, branches = { [10574] = "奥尔多", [10685] = "占星者" } },
    { key = "wardens_cage", title = "守望者的牢笼", ids = { 10575, 10686 }, branches = { [10575] = "奥尔多", [10686] = "占星者" } },
    { key = "allegiance", title = "忠诚的证明", ids = { 10622 } },
    { key = "akama", title = "阿卡玛", ids = { 10628 } },
    { key = "udalo", title = "先知乌达鲁", ids = { 10705 } },
    { key = "portent", title = "神秘的征兆", ids = { 10706 } },
    { key = "atamal", title = "阿塔玛平台", ids = { 10707 } },
    { key = "promise", title = "阿卡玛的保证", ids = { 10708 } },
    { key = "secret", title = "危险的秘密", ids = { 10944 } },
    { key = "ruse", title = "灰舌的计谋", ids = { 10946 } },
    { key = "artifact", title = "往日的神器", ids = { 10947 } },
    { key = "hostage", title = "灵魂之囚", ids = { 10948 } },
    { key = "entry", title = "进入黑暗神殿", ids = { 10949 } },
    { key = "distraction", title = "帮助阿卡玛", ids = { 10985 } },
}

ns.ALL_QUEST_IDS = {}
do
    local index = 1
    for stepIndex = 1, #ns.STEPS do
        local step = ns.STEPS[stepIndex]
        for questIndex = 1, #step.ids do
            ns.ALL_QUEST_IDS[index] = step.ids[questIndex]
            index = index + 1
        end
    end
end

ns.STRINGS = {
    ADDON_TITLE = "黑暗神殿开门进度",
    VERSION_ERROR = "只支持 TBC 周年服 2.5.6（Interface 20506）。",
    API_ERROR = "缺少 20506 必需接口：",
    ACCOUNT_PENDING = "账号开门状态：|cffffcc00未解锁|r（仅根据已记录角色）",
    ACCOUNT_UNLOCKED = "账号开门状态：|cff33ff66已解锁|r｜完成角色：",
    NO_CHARACTERS = "尚无角色记录。请登录角色后等待任务日志刷新。",
    LIVE = "当前角色／实时",
    SNAPSHOT = "离线快照",
    DONE = "已完成",
    ACTIVE = "进行中",
    TODO = "未开始",
}
