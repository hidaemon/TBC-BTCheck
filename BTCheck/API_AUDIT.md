# BTCheck 2.5.6 / 20506 API 审计

## 审计基线

- 目标客户端：TBC Anniversary 2.5.6
- TOC Interface：20506
- 客户端界面源码快照：`Gethe/wow-ui-source` 的 `classic_anniversary` 分支
- 审计提交：`e9bbe81652a6a3fddc6fb547c379218341899792`
- 该提交标记的客户端构建：`2.5.6 (69110)`，提交时间 `2026-08-05T00:46:05Z`
- 核心依据：客户端导出的 `Interface/AddOns/Blizzard_APIDocumentationGenerated` 与暴雪 FrameXML。

该镜像保存客户端实际附带的暴雪界面文件；代码只采用在上述目标快照中出现的接口。运行时还会校验版本、Interface 和必需函数，校验失败即停止扫描。

## 任务接口

| 接口/事件 | 用途 | 20506 依据 |
|---|---|---|
| `C_QuestLog.IsQuestFlaggedCompleted(questID)` | 判断历史完成 | `QuestLogDocumentation.lua` 的正式函数定义 |
| `C_QuestLog.IsOnQuest(questID)` | 判断当前进行中 | `QuestLogDocumentation.lua` 的正式函数定义 |
| `QUEST_LOG_UPDATE` | 任务日志变化后刷新 | `QuestLogDocumentation.lua` 的正式事件定义 |
| `QUEST_TURNED_IN` | 交任务后立即刷新 | `QuestLogDocumentation.lua` 的正式事件定义 |

计划草案中的 `C_QuestLog.GetLogIndexForQuestID` **不在 20506 TBC QuestLog 自动生成文档中**，因此实现没有使用它。20506 官方定义的 `C_QuestLog.IsOnQuest` 直接返回任务是否在日志中，无需依赖旧版 `GetQuestLogIndexByID`。

## 角色、时间与版本接口

| 接口 | 用途 | 20506 依据 |
|---|---|---|
| `UnitGUID("player")` | 稳定角色主键 | `UnitDocumentation.lua` |
| `UnitName("player")` | 角色名与服务器 | `UnitDocumentation.lua` |
| `UnitClass("player")` | 职业信息 | `UnitDocumentation.lua` |
| `UnitFactionGroup("player")` | 阵营信息 | `UnitDocumentation.lua` |
| `GetRealmName()` | 同服角色服务器名补全 | `ConnectionDocumentation.lua` |
| `C_DateAndTime.GetServerTimeLocal()` | 快照时间 | `DateAndTimeDocumentation.lua` |
| `GetCursorPosition()` | 小地图按钮拖动 | `InputDocumentation.lua` |
| `GetBuildInfo()` | 校验 2.5.6 / 20506 | 暴雪 `GlueXML` 与 `Settings_Shared` FrameXML 实际调用 |
| `date()` | 格式化快照时间 | 暴雪 `CombatLog`、`Minimap`、`UIParent` FrameXML 实际调用 |

## 界面接口

界面只使用 `CreateFrame`、`UIParent`、`Minimap`、`GameTooltip` 和自动生成 ScriptObject 文档中存在的基础 Frame/Button/Slider/Texture/FontString 方法。关键方法包括：

- Frame：`SetPoint`、`SetSize`、`SetFrameStrata`、`SetFrameLevel`、`SetMovable`、`SetClampedToScreen`、`StartMoving`、`StopMovingOrSizing`、`RegisterEvent`、`SetScript`。
- Button：`RegisterForClicks`、`RegisterForDrag`、`SetHighlightTexture`。
- Slider：`SetOrientation`、`SetMinMaxValues`、`SetValueStep`、`SetValue`、`SetThumbTexture`、`GetThumbTexture`。
- Texture/FontString：`SetColorTexture`、`SetTexture`、`SetTexCoord`、`SetVertexColor`、`SetText`、`SetTextColor`、`SetJustifyH`、`SetJustifyV`、`SetWordWrap`。
- EditBox：`GetText`、`SetText`、`SetAutoFocus`、`SetTextInsets`、`SetFontObject`、`SetTextColor`、`ClearFocus`。

搜索框仅使用 EditBox 的 `OnTextChanged`、`OnEditFocusGained`、`OnEditFocusLost`、`OnEscapePressed` 和 `OnEnterPressed` 脚本处理器；这些处理器由目标客户端 EditBox/FrameXML 提供。

插件自行绘制背景、边框、表格与滚动条，不依赖 `BackdropTemplate`、`ScrollBox`、`UIDropDownMenu`、`EasyMenu`、Settings API 或第三方 UI 库。

小地图按钮图标使用 `Interface\\Icons\\Spell_Shadow_Metamorphosis`。该路径在目标 2.5.6/20506 客户端源码 `Blizzard_SettingsDefinitions_Frame/Classic/Colorblind.xml` 中被实际引用；未使用此前未经目标客户端源码核对的 `Spell_Shadow_Shadowform`。

## 明确未使用

- `C_QuestLog.GetLogIndexForQuestID`
- `GetQuestLogIndexByID`、`GetQuestLogTitle` 等旧版任务日志兼容函数
- `C_AddOns`、`C_Timer`、`ScrollBox`、现代 Menu/Settings API
- `UIDropDownMenu`、`EasyMenu`
- Ace3、LibStub 或任何嵌入库
- 受保护动作、SecureHandler、战斗内属性修改

## 运行时失败关闭

加载时依次检查目标版本、Interface、任务接口、角色接口、时间接口、光标接口、基础 UI 全局对象及小地图拖动所需数学函数。任何检查失败都会设置明确的 `disabledReason`，停止注册任务刷新事件和角色扫描；不会改用未经审计的替代函数。
