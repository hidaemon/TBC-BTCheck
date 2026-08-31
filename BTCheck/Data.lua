local addonName, ns = ...

ns.ADDON_NAME = addonName
ns.DB_VERSION = 2
ns.ADDON_VERSION = "2.0.1"
ns.TARGET_VERSION = "2.5.6"
ns.TARGET_INTERFACE = 20506

ns.STATUS_TODO = 0
ns.STATUS_ACTIVE = 1
ns.STATUS_DONE = 2
ns.DEFAULT_RAID_KEY = "black_temple"

-- 任务名和 Quest ID 已按 TBC 2.5.6 数据核对。steps 中同一项的多个 ID
-- 默认是二选一逻辑；需要全部完成的任务必须拆成多个逻辑步骤。
ns.RAIDS = {
    karazhan = {
        key = "karazhan", title = "卡拉赞", shortTitle = "卡拉赞", size = 10, phase = 1,
        hasAttunement = true, gateStatus = "REMOVED",
        gateText = "任务线保留；当前周年服阶段已取消强制进入要求",
        finalQuestIDs = { 9837 },
        steps = {
            { key = "arcane_disturbances", title = "奥术扰动", ids = { 9824 } },
            { key = "restless_activity", title = "幽灵的活动", ids = { 9825 } },
            { key = "contact_dalaran", title = "联络达拉然", ids = { 9826 } },
            { key = "khadgar", title = "卡德加", ids = { 9829 } },
            { key = "entry_into_karazhan", title = "卡拉赞的钥匙", ids = { 9831 } },
            { key = "second_third_fragments", title = "第二块和第三块", ids = { 9832 } },
            { key = "masters_touch", title = "麦迪文的触摸", ids = { 9836 } },
            { key = "return_to_khadgar", title = "返回卡德加身边", ids = { 9837 } },
        },
    },
    gruuls_lair = {
        key = "gruuls_lair", title = "格鲁尔的巢穴", shortTitle = "格鲁尔", size = 25, phase = 1,
        hasAttunement = false, gateStatus = "NONE",
        gateText = "无需个人开门任务；格鲁尔掉落毒蛇神殿任务所需物品",
        finalQuestIDs = {}, steps = {},
    },
    magtheridons_lair = {
        key = "magtheridons_lair", title = "玛瑟里顿的巢穴", shortTitle = "玛瑟里顿", size = 25, phase = 1,
        hasAttunement = false, gateStatus = "NONE",
        gateText = "无需个人开门任务；玛瑟里顿是风暴要塞试炼目标",
        finalQuestIDs = {}, steps = {},
    },
    serpentshrine_cavern = {
        key = "serpentshrine_cavern", title = "毒蛇神殿", shortTitle = "毒蛇神殿", size = 25, phase = 2,
        hasAttunement = true, gateStatus = "REMOVED",
        gateText = "任务线保留；Phase 3 已取消强制进入要求",
        finalQuestIDs = { 10901 },
        steps = {
            { key = "cudgel_of_kardesh", title = "卡达什圣杖", ids = { 10901 }, note = "任务目标包含格鲁尔与夜之魇掉落物；插件只记录任务进行中/完成。" },
        },
    },
    tempest_keep = {
        key = "tempest_keep", title = "风暴要塞", shortTitle = "风暴要塞", size = 25, phase = 2,
        hasAttunement = true, gateStatus = "REMOVED",
        gateText = "任务线保留；Phase 3 已取消强制进入要求",
        finalQuestIDs = { 10888 },
        steps = {
            { key = "hand_of_guldan", title = "古尔丹之手", ids = { 10680, 10681 }, branches = { [10680] = "联盟", [10681] = "部落" }, branchLabel = "阵营", branchNote = "联盟与部落任务二选一，只计一个逻辑步骤。" },
            { key = "spirits_fire_earth", title = "愤怒的火灵和地灵", ids = { 10458 } },
            { key = "spirits_water", title = "愤怒的水灵", ids = { 10480 } },
            { key = "spirits_air", title = "愤怒的气灵", ids = { 10481 } },
            { key = "oronok", title = "欧鲁诺克-裂心", ids = { 10513 } },
            { key = "many_things", title = "历经沧桑......", ids = { 10514 } },
            { key = "lesson_learned", title = "严厉的教训", ids = { 10515 } },
            { key = "truth_history", title = "诅咒密码 - 真相和历史", ids = { 10519 } },
            { key = "gromtor", title = "格洛姆托，欧鲁诺克之子", ids = { 10521 }, group = "第一块碎片" },
            { key = "gromtor_charge", title = "诅咒密码 - 格洛姆托的命令", ids = { 10522 }, group = "第一块碎片" },
            { key = "first_fragment", title = "诅咒密码 - 第一块碎片", ids = { 10523 }, group = "第一块碎片" },
            { key = "artor", title = "阿托尔，欧鲁诺克之子", ids = { 10527 }, group = "第二块碎片" },
            { key = "demonic_prisons", title = "恶魔的水晶牢笼", ids = { 10528 }, group = "第二块碎片" },
            { key = "lohngoron", title = "洛恩戈鲁，裂心之弓", ids = { 10537 }, group = "第二块碎片" },
            { key = "artor_charge", title = "诅咒密码 - 阿托尔的命令", ids = { 10540 }, group = "第二块碎片" },
            { key = "second_fragment", title = "诅咒密码 - 第二块碎片", ids = { 10541 }, group = "第二块碎片" },
            { key = "borak", title = "伯拉克，欧鲁诺克之子", ids = { 10546 }, group = "第三块碎片" },
            { key = "thistleheads_eggs", title = "血蓟交易......", ids = { 10547 }, group = "第三块碎片" },
            { key = "bundle_bloodthistle", title = "一捆血蓟", ids = { 10550 }, group = "第三块碎片" },
            { key = "catch_thistlehead", title = "血蓟瘾君子", ids = { 10570 }, group = "第三块碎片" },
            { key = "shadowmoon_shuffle", title = "影月谷的乔装者", ids = { 10576 }, group = "第三块碎片" },
            { key = "illidan_wants", title = "伊利丹的信使......", ids = { 10577 }, group = "第三块碎片" },
            { key = "borak_charge", title = "诅咒密码 - 伯拉克的命令", ids = { 10578 }, group = "第三块碎片" },
            { key = "third_fragment", title = "诅咒密码 - 第三块碎片", ids = { 10579 }, group = "第三块碎片" },
            { key = "cipher_of_damnation", title = "诅咒密码", ids = { 10588 } },
            { key = "tempest_key", title = "风暴钥匙", ids = { 10883 } },
            { key = "trial_mercy", title = "纳鲁的试炼：仁慈", ids = { 10884 }, group = "纳鲁的试炼" },
            { key = "trial_strength", title = "纳鲁的试炼：力量", ids = { 10885 }, group = "纳鲁的试炼" },
            { key = "trial_tenacity", title = "纳鲁的试炼：坚韧", ids = { 10886 }, group = "纳鲁的试炼" },
            { key = "trial_magtheridon", title = "纳鲁的试炼：玛瑟里顿", ids = { 10888 }, group = "纳鲁的试炼" },
        },
    },
    hyjal_summit = {
        key = "hyjal_summit", title = "海加尔山之战", shortTitle = "海加尔", size = 25, phase = 3,
        hasAttunement = true, gateStatus = "REQUIRED",
        gateText = "当前阶段开门任务；周年服资格按账号共享",
        finalQuestIDs = { 10445 },
        steps = {
            { key = "vials_of_eternity", title = "永恒水瓶", ids = { 10445 }, note = "任务目标包含瓦丝琪和凯尔萨斯掉落物；插件只记录任务进行中/完成。" },
        },
    },
    black_temple = {
        key = "black_temple", title = "黑暗神殿", shortTitle = "黑暗神殿", size = 25, phase = 3,
        hasAttunement = true, gateStatus = "REQUIRED",
        gateText = "当前阶段开门任务；周年服资格按账号共享",
        finalQuestIDs = { 10985 },
        steps = {
            { key = "baari_tablets", title = "巴尔里石板", ids = { 10568, 10683 }, branches = { [10568] = "奥尔多", [10683] = "占星者" }, branchLabel = "阵营", branchNote = "奥尔多与占星者任务二选一，只计一个逻辑步骤。" },
            { key = "oronu", title = "长者奥洛努", ids = { 10571, 10684 }, branches = { [10571] = "奥尔多", [10684] = "占星者" }, branchLabel = "阵营", branchNote = "奥尔多与占星者任务二选一，只计一个逻辑步骤。" },
            { key = "corruptors", title = "灰舌腐蚀者", ids = { 10574, 10685 }, branches = { [10574] = "奥尔多", [10685] = "占星者" }, branchLabel = "阵营", branchNote = "奥尔多与占星者任务二选一，只计一个逻辑步骤。" },
            { key = "wardens_cage", title = "守望者的牢笼", ids = { 10575, 10686 }, branches = { [10575] = "奥尔多", [10686] = "占星者" }, branchLabel = "阵营", branchNote = "奥尔多与占星者任务二选一，只计一个逻辑步骤。" },
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
        },
    },
    zulaman = {
        key = "zulaman", title = "祖阿曼", shortTitle = "祖阿曼", size = 10, phase = 4,
        hasAttunement = false, gateStatus = "NONE", gateText = "无需个人开门任务",
        finalQuestIDs = {}, steps = {},
    },
    sunwell_plateau = {
        key = "sunwell_plateau", title = "太阳之井高地", shortTitle = "太阳之井", size = 25, phase = 5,
        hasAttunement = false, gateStatus = "SERVER",
        gateText = "无需个人开门任务；开放进度由奎尔丹纳斯岛服务器阶段决定",
        finalQuestIDs = {}, steps = {},
    },
}

ns.RAID_ORDER = {
    "karazhan", "gruuls_lair", "magtheridons_lair", "serpentshrine_cavern", "tempest_keep",
    "hyjal_summit", "black_temple", "zulaman", "sunwell_plateau",
}

ns.ATTUNEMENT_RAID_KEYS = {
    "karazhan", "serpentshrine_cavern", "tempest_keep", "hyjal_summit", "black_temple",
}

ns.ALL_QUEST_IDS = {}
ns.ALL_QUEST_IDS_BY_RAID = {}
do
    local seen = {}
    for raidIndex = 1, #ns.RAID_ORDER do
        local raidKey = ns.RAID_ORDER[raidIndex]
        local raid = ns.RAIDS[raidKey]
        local raidIDs = {}
        ns.ALL_QUEST_IDS_BY_RAID[raidKey] = raidIDs
        for stepIndex = 1, #raid.steps do
            local step = raid.steps[stepIndex]
            for questIndex = 1, #step.ids do
                local questID = step.ids[questIndex]
                raidIDs[#raidIDs + 1] = questID
                if not seen[questID] then
                    seen[questID] = true
                    ns.ALL_QUEST_IDS[#ns.ALL_QUEST_IDS + 1] = questID
                end
            end
        end
    end
end

-- 兼容现有扩展代码和旧测试引用；核心逻辑不再依赖这个别名。
ns.STEPS = ns.RAIDS.black_temple.steps

ns.STRINGS = {
    ADDON_TITLE = "TBC 团本开门进度",
    VERSION_ERROR = "只支持 TBC 周年服 2.5.6（Interface 20506）。",
    API_ERROR = "缺少 20506 必需接口：",
    ACCOUNT_PENDING = "账号记录：|cffffcc00尚无角色完成|r（仅根据已记录角色）",
    ACCOUNT_UNLOCKED = "账号记录：|cff33ff66已有角色完成|r｜完成角色：",
    NO_ATTUNEMENT = "该团本无需个人开门任务",
    NO_CHARACTERS = "尚无角色记录。请登录角色后等待任务日志刷新。",
    NO_SEARCH_RESULTS = "没有匹配的角色。",
    SEARCH_PLACEHOLDER = "输入角色名（模糊搜索）",
    LIVE = "当前角色／实时", SNAPSHOT = "离线快照",
    DONE = "已完成", ACTIVE = "进行中", TODO = "未开始",
}
