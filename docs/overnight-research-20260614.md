# 通宵调研与需求（2026-06-14）

调研同类产品，转成本项目（桌面透明挂机钓鱼《角落垂钓》）的可落地需求。
定位锚点：**安静的桌面陪伴 + 手动卖鱼 + 长期收集目标 + 低干扰回访**。

## 1. Rusty's Retirement — 桌面陪伴 / 低干扰

- 来源：[Steam](https://store.steampowered.com/app/2666510/Rustys_Retirement/) ·
  [Wikipedia](https://en.wikipedia.org/wiki/Rusty's_Retirement) ·
  [GameDiscover 复盘](https://newsletter.gamediscover.co/p/how-rustys-retirement-idle-farmed)
- 借鉴点：贴屏底/侧边只占 25~33% 桌面；**Focus Mode**（放慢产出、降干扰）；可缩放；可长开不惩罚。97% 好评，核心是"不打扰的陪伴"。
- 适合本项目：✅ 高度契合（我们已是角落透明窗）。可补**专注/省心模式**与**不透明度/缩放**已具备。
- 决定实现：**专注模式开关**（暂缓——已有不透明度；优先做信息可见性，见下）。

## 2. Chillquarium — 收集 / 出售 / 稀有变体 / 展示

- 来源：[Steam](https://store.steampowered.com/app/2276930/Chillquarium/) ·
  [Wiki Gameplay](https://chillquarium.fandom.com/wiki/Gameplay) ·
  [TheGamer 上手](https://www.thegamer.com/chillquarium-beginner-tips-tricks/)
- 借鉴点：156 种鱼，每种有 普通/彩绘/黄金/彩虹 4 级变体（越来越稀有）——**收集深度护城河**；养大再卖的节奏；纯装饰品自定义。
- 适合本项目：✅ 收集深度。变体=我们的**星级品质**已有雏形。**图鉴长期徽章**（集齐 N 条/巨物/完美）是低成本收集目标。
- 决定实现：**图鉴长期目标徽章**（每种鱼：钓满 10 条 / 巨物 / 完美★★★ / 最大体重纪录）。

## 3. WEBFISHING / Fisch — 鱼种 / 稀有度 / 体重 / 品质 / 装备

- 来源：[Quality Wiki](https://webfishing.wiki.gg/wiki/Quality) ·
  [Fishing Wiki](https://webfishing.wiki.gg/wiki/Fishing) ·
  [Drop tables](https://webfishing.net/blogs/webfishing-fish-drop-tables)
- 借鉴点：tier=稀有度；价值 = tier×均重×loot weight，再 ×品质×（相对均重的体型）；品质 6 级倍率 1/1.8/4/6/10/15；**鱼饵决定品质权重**，鱼竿 Luck 决定 tier。
- 适合本项目：✅ 我们已照搬（6 阶 + 体重定价 + 4 档星级 + 鱼饵/鱼竿成长）。可借鉴的是**更丰富的订单条件**（按体重/品质/类别）。
- 决定实现：**更多订单类型**（指定品阶 / 完美品质 / 指定重量级）。

## 4. Stardew / Animal Crossing — 每日目标 / 订单 / 捆绑

- 来源：[SDV Bundles Wiki](https://stardewvalleywiki.com/Bundles) ·
  [SDV Fish Pond Wiki](https://stardewvalleywiki.com/Fish_Pond) ·
  [Fish Tank Bundle 指南](https://gamerant.com/stardew-valley-fish-tank-bundle-lake-ocean-night-crab-pot-speciality-guide/)
- 借鉴点：捆绑=按类别集齐多项一次性大奖（River/Lake/Ocean/Night/CrabPot/Specialty）；鱼塘任务=投喂指定物升容量；AC 的 CJ 限时高价收购。
- 适合本项目：✅ 我们已有**每日订单（指定鱼种×2.5）+ 流动鱼贩（限时×1.5）**。缺**HUD 上的订单进度可见性**与**订单多样性**。
- 决定实现：**HUD 每日订单进度**（"订单 鲤鱼 1/3"）+ **鱼贩×订单联动提示**。

## 5. Melvor Idle — 离线 / 背包 / 回收

- 来源：[Offline Progression](https://wiki.melvoridle.com/w/Offline_Progression) ·
  [Bank](https://wiki.melvoridle.com/w/Bank) ·
  [背包管理](https://tap-guides.com/2025/10/24/melvor-idle-inventory-bank-management-tips/)
- 借鉴点：离线上限 24h 模拟；起始 20 格、购买扩容价格递增（上限百万级）；背包满是核心约束，需要**整理/排序/批量处理**手段。
- 适合本项目：✅ 我们离线上限 8h、起始 20 格、阶梯扩容已有。背包大了之后**排序/筛选**缺失，是体验痛点。
- 决定实现：**鱼篓排序/筛选**（按价值/品阶/重量/最新；筛"订单鱼"）。

## 6. 综合 — 桌面挂机回访机制

- 借鉴点：回访要"一眼看到收获"（离线小结）+ "有明确下一步"（订单/徽章）+ "低操作变现"（批量卖、未来自动化付费）。
- 适合本项目：离线小结已做（特性 6）。下一步是**让目标常驻可见**（HUD 订单进度）+ **给长期目标**（图鉴徽章）。

---

## 今夜实现优先级（自主排定）

1. **HUD 每日订单进度** —— 订单常驻角落可见（"订单 鲤鱼 1/3"），点击开订单页。来源：Stardew/AC 每日目标可见性。
2. **鱼篓排序/筛选** —— 价值/品阶/重量/最新 + 只看订单鱼。来源：Melvor 背包管理。
3. **图鉴长期目标徽章** —— 每种鱼 集齐10条/巨物/完美/最大体重纪录，图鉴卡片显示徽章。来源：Chillquarium 收集 + Fisch 奖杯。
4. **更多订单类型** —— 指定品阶 / 完美品质 / 指定重量级（不只指定鱼种）。来源：Stardew 捆绑多样性 + WEBFISHING 品质。
5. **数值平衡复查** —— 鱼竿/鱼饵/扩容/订单/鱼贩 组合后的产出曲线与通胀。
6.（备选）**专注模式** —— Rusty's 式放慢+降干扰开关。

每项：实现 → 无头回归 0 失败 → 截图验证 → 文档 → 独立 commit。存档结构变更必须带迁移与测试。
