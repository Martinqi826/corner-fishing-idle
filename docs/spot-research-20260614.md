# 多钓点生态调研（2026-06-14）

把"单钓点挂机"升级为"多钓点生态挂机"前的资料调研。目标：用真实鱼类生态/分类/运动钓鱼数据，
为 3 个首发钓点（新手河湾 / 静水湖泊 / 海岸码头）选鱼、定品阶、配生态标签与随机事件。
定位锚点不变：**安静的桌面陪伴 + 手动卖鱼 + 长期收集 + 低干扰回访**。

每条：来源链接 · 可借鉴点 · 是否适合本项目 · 采用方案。

---

## 1. FishBase / GBIF — 鱼种数据库与生态资料

- 来源：
  - FishBase 官网 <https://www.fishbase.se/> · Wikipedia <https://en.wikipedia.org/wiki/FishBase>
  - GBIF 上的 FishBase 数据集 <https://www.gbif.org/dataset/197908d0-5565-11d8-b290-b8a03c50a862>
  - 大口黑鲈生境（USFWS）<https://www.fws.gov/sites/default/files/documents/largemouth-bass.pdf>
- 可借鉴点：
  - FishBase 收录 >35,000 种鱼，含**栖息地类型（淡水/咸淡水/海水）、营养级、体长体重、生活史**等结构化字段——正好对应我们要给每条鱼打的 `habitat/tags` 与体重区间。
  - 关键生境结论：**大口黑鲈栖息于清澈多水草的湖、塘、沼泽与河流回水**，确认它是典型"静水湖泊"鱼，而非急流鱼。GBIF 提供出现点分布，可佐证某鱼属于河/湖/海哪类水体。
- 是否适合：✅ 直接适合。我们不需要实时 API，只需要"按水体分类给鱼打标签"这一层结论。
- 采用方案：
  - 为**全部 60 种鱼**新增 `tags` 数组（river/lake/stream/coast/deep/cold/night/protected）。
  - 钓点用 `habitat_tags` 圈定鱼池；按 FishBase 生境把静水掠食者（鲈/鳜/黑鱼/狗鱼/大口黑鲈）归 lake，急流冷水种（虹鳟/细鳞/哲罗）归 stream/cold，海水种归 coast。

## 2. Eschmeyer's Catalog of Fishes — 分类学权威

- 来源：
  - 项目页（加州科学院）<https://www.calacademy.org/scientists/projects/eschmeyers-catalog-of-fishes>
  - Wikipedia <https://en.wikipedia.org/wiki/Eschmeyer's_Catalog_of_Fishes>
- 可借鉴点：
  - 收录 37,586 个有效种，其中 **19,250 个标注"Habitat: freshwater"**；是 FishBase 等数据库的分类学基线（学名、属、科的权威裁定）。
  - 用于核对我们新增鱼的**学名/科归属是否真实**，避免出现"民间叫法对不上真实物种"的硬伤（如带鱼属 Trichiuridae、石斑属 Epinephelus、马鲛属 Scomberomorus）。
- 是否适合：✅ 作为校对层适合；游戏只显示中文名，但底层物种要立得住。
- 采用方案：
  - 新鱼命名以真实物种为准并在 `fish_data.gd` 注释谱系来源；海水层确认 带鱼/大黄鱼/小黄鱼/银鲳/石斑/马鲛/真鲷/黑鲷 等均为有效物种再入表。
  - 沿用现有"养殖放流个体"设定解释神话档国宝鱼（中华鲟）可被钓起又不违和。

## 3. IGFA World Records — 运动钓鱼目标鱼

- 来源：
  - IGFA 世界纪录按种检索 <https://igfa.org/member-services/world-record/>
  - 大口黑鲈全装备纪录（22 lb 4 oz，Perry 1932 / Kurita 2009 并列）<https://thebigbasspodcast.com/black-bass-world-records/>
  - 按种参考整理 <https://www.oneoutdoors.org/guides/igfa-records-by-species>
- 可借鉴点：
  - IGFA 把**大口黑鲈、北方狗鱼、条纹鲈、金枪鱼、旗鱼/马林、石斑**列为标志性运动钓目标鱼——这些正是"玩家梦想中的大物"，适合做各钓点的**传说/神话档**与"巨物"体型上限。
  - 纪录体重给我们**体重区间的现实锚点**（如狗鱼/鲟/旗鱼可达数十~数百 kg），让"大·/巨物·"体型标签有据。
- 是否适合：✅ 适合做高品阶选种与体重上限定标。
- 采用方案：
  - 静水湖泊传说层：施氏鲟、欧鲶（六须鲇，可达 100kg+）；湖泊掠食目标鱼大口黑鲈、鳡鱼。
  - 海岸码头传说/神话层：金枪鱼、龙趸石斑（鞍带石斑，最大石斑）、**旗鱼**（海洋顶级运动钓，定为海岸 t5 神话）。
  - 体重 wmax 参考 IGFA 量级缩放（保留游戏化压缩，避免单条价值破坏经济）。

## 4. Fishbrain / 钓鱼社区 — 玩家实际常钓鱼种与钓点偏好

- 来源：
  - Fishbrain 热门水域 <https://fishbrain.com/fishing-waters/popular> · App 介绍 <https://apps.apple.com/us/app/fishbrain-fishing-app/id477967747>
  - 美国 Pier Fishing 社区指南 <https://www.pierfishing.com/> · Take Me Fishing 常见海水鱼 <https://www.takemefishing.org/saltwater-fishing/saltwater-fish-species/common-saltwater-fish/>
- 可借鉴点：
  - 1500 万钓友的实钓数据显示**大口黑鲈是淡水运动钓"头号鱼"**、分布最广——印证它该是静水湖泊的招牌、好上手的中档鱼。
  - 海岸/码头实钓常见鱼：**各种鲈、鲷、石首鱼（croaker）、鲭、平鲉（rockfish）、鲻鱼、比目鱼**——这些"杂而常见"的鱼适合做海岸钓点的低/中档基本盘，配合带鱼/黄鱼/石斑/马鲛拉高档次。
- 是否适合：✅ 适合校准"哪些鱼该常见、哪些该稀有"的钓点权重感受。
- 采用方案：
  - 海岸码头低档基本盘：沙丁鱼/马面鲀/虾虎鱼（t0）、鲐鱼/小黄鱼/鲻鱼/许氏平鲉（t1）；中档黑鲷/海鲈/牙鲆/海鳗/河豚/带鱼（t2）；高档真鲷/马鲛/银鲳/石斑/大黄鱼（t3）。
  - 静水湖泊把大口黑鲈定为 t2"招牌目标鱼"，河鲈/鲇鱼/罗非/黄鳝（t1）做常见盘。

## 5. 中文垂钓 / 淡水鱼资料 — 补中国本土鱼种与习性

- 来源：
  - 中国钓鱼人网"最常见的淡水鱼" <https://www.cnfisher.com/2025/diaolianyongjiqiao_0423/105592.html>
  - 钓鱼人"水底霸主掠食鱼 10 种" <https://m.diaoyur.com/a/2020/51158.html> · "看图识别淡水鱼" <https://m.diaoyur.com/a/2015/13157.html>
  - 翘嘴（鲌）百科 <https://www.luremaster.cn/article/15269bc290290ca7ccb02a66dfc8acca.html>
- 可借鉴点（习性 → 直接对应生态标签与事件）：
  - **黑鱼**：凶猛肉食、静水塘湖称霸 → lake + 掠食，静水湖泊招牌掠食鱼。
  - **鳜鱼**：栖于水草丰茂、乱石/树根洞穴的洁净水体，**昼伏夜出** → lake/river + night。
  - **翘嘴（鲌）**：广温、爱在**流动水体**捕食 → river/lake，开阔水面掠食。
  - **鲟鳇**：终生底栖淡水、个体可达数百 kg → river/deep，神话档国宝。
  - 静水钓点要点：风线（杂物与明水相交处）是钓翘嘴的点 → 给"顺水鱼群/晨雾"事件的文案与定位提供真实味道。
- 是否适合：✅ 本项目本就以中国北方冬钓鱼种立谱，本土资料是主干。
- 采用方案：
  - 新增本土鱼：鳡鱼（鳡，t3 湖河掠食巨物）、鲇鱼、黄鳝、罗非鱼、河鲈、银鱼、鳑鲏、（海水）带鱼/大小黄鱼/银鲳/石斑/马鲛/真鲷/黑鲷/鲻鱼/牙鲆/海鳗/河豚等。
  - 习性写进 `tags`（night/cold/deep/protected）驱动钓点与事件（如夜行鱼、寒潮、保护鱼放流）。

---

## 钓点设计结论（首发 3 个 + roadmap）

| 钓点 | id | habitat_tags | 招牌鱼 | 专属事件 |
|---|---|---|---|---|
| 新手河湾（保留现有体验） | `river_bend` | river | 现有 28 种全保留 | 顺水鱼群 / 晨雾 / 漂流木箱 |
| 静水湖泊 | `still_lake` | lake | 大口黑鲈·鳜·黑鱼·狗鱼·鲟·欧鲶 | 晨雾 / 寒潮 / 顺水鱼群 |
| 海岸码头 | `coast_pier` | coast | 海鲈·真鲷·带鱼·石斑·马鲛·黄鱼·金枪·旗鱼 | 涨潮 / 漂流木箱 / 保护鱼放流 |
| 山涧溪流（roadmap） | `mountain_stream` | stream/cold | 虹鳟·细鳞·哲罗 | 融雪汛 / 晨雾 |
| 远海深钓（roadmap） | `deep_sea` | deep/coast | 金枪·旗鱼·深海石斑 | 涨潮 / 鱼群追饵 |

随机事件（数据化到 `event_data.gd`，全部低干扰）：
- **fish_run 鱼汛**（全钓点共享）：咬钩更勤 + 高阶鱼大增（沿用现逻辑，迁到数据驱动）。
- **morning_fog 晨雾**：节奏更慢、渔获略值钱（清晨静水）。
- **cold_front 寒潮**：上鱼变慢但个体更大（湖/冷水）。
- **lucky_current 顺水鱼群**：温和提速（河/湖）。
- **drift_crate 漂流木箱**：一次性金币奖励（河/海）。
- **protected_release 保护鱼放流**：放流养殖保护鱼，得保育奖励（河/海）。
- **tide_in 涨潮**：海岸专属上鱼窗口（提速 + 略增值）。

鱼种规模：当前 28 → 扩到 **60**（旧 id 全部不变，旧存档兼容；缺图标按品阶回退通用鱼图标）。
</content>
</invoke>
