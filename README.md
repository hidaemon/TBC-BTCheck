# BTCheck · TBC 团本开门进度

BTCheck 是面向《魔兽世界》TBC 周年服 `2.5.6 / Interface 20506` 的简体中文团本开门任务插件。

当前版本：`2.0.1`

作者：达蒙

项目地址：[https://github.com/hidaemon/TBC-BTCheck](https://github.com/hidaemon/TBC-BTCheck)

## 主要功能

- 总览全部9个TBC 70级团本。
- 完整追踪卡拉赞、毒蛇神殿、风暴要塞、海加尔山之战和黑暗神殿5条任务线。
- 明确标注格鲁尔的巢穴、玛瑟里顿的巢穴、祖阿曼和太阳之井高地无需个人开门任务。
- 角色进度与当前版本进入要求分开显示。
- 使用账号级SavedVariables保存跨服务器、跨阵营角色快照。
- 当前角色固定第一列，其他角色按当前所选团本完成度排序。
- 支持模糊搜索、职业染色、横向/纵向滚动和角色管理。
- 1.x黑暗神殿数据自动无损迁移到2.0数据库。
- 无第三方运行库，严格校验 `2.5.6 / 20506` 与必需API。

## 安装

将仓库中的 `BTCheck` 文件夹复制到：

```text
World of Warcraft/_anniversary_/Interface/AddOns/
```

确认存在 `.../Interface/AddOns/BTCheck/BTCheck.toc`，进入游戏后输入 `/btcheck`。

## 文档

- [插件详细说明](BTCheck/README.md)
- [Quest ID与任务链审计](BTCheck/QUEST_DATA.md)
- [20506 API审计](BTCheck/API_AUDIT.md)
- [测试与验收](BTCheck/TESTING.md)

## 隐私

仓库不包含玩家SavedVariables。插件只在本机保存角色GUID、角色名、服务器、职业、阵营、任务状态、隐藏设置和最后同步时间；不提供跨电脑或战网云端同步。分享游戏目录或SavedVariables前，请自行检查角色信息。
