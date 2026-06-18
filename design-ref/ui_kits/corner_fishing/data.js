/* 角落垂钓 UI kit — sample game state (fake, for the recreation). */
(function () {
  const A = "../../assets/fish/";
  const fb = (t) => "../../assets/fish/generic_tier" + t + ".png";

  // [id, name, src, tier, variant, quality, weight, sizeTag, value, locked]
  const inventory = [
    { id: "gudgeon", name: "棒花鱼", src: A + "gudgeon.png", tier: 0, variant: 0, quality: 1, weight: 0.04, sizeTag: "", value: 4 },
    { id: "mandarin", name: "鳜鱼", src: A + "mandarin.png", tier: 3, variant: 0, quality: 0, weight: 0.79, sizeTag: "", value: 110 },
    { id: "fangbream", name: "翘嘴鲌", src: A + "fangbream.png", tier: 2, variant: 0, quality: 0, weight: 2.21, sizeTag: "", value: 114 },
    { id: "trout", name: "虹鳟", src: A + "trout.png", tier: 3, variant: 0, quality: 1, weight: 1.28, sizeTag: "", value: 504 },
    { id: "redeye", name: "赤眼鳟", src: A + "redeye.png", tier: 1, variant: 0, quality: 0, weight: 1.12, sizeTag: "", value: 26 },
    { id: "grass", name: "草鱼", src: A + "grass.png", tier: 1, variant: 0, quality: 0, weight: 9.95, sizeTag: "大", value: 39 },
    { id: "koi", name: "锦鲤", src: A + "koi.png", tier: 4, variant: 2, quality: 2, weight: 3.10, sizeTag: "", value: 1820, locked: true },
    { id: "bass", name: "鲈鱼", src: A + "bass.png", tier: 2, variant: 0, quality: 0, weight: 1.84, sizeTag: "", value: 88 },
  ];

  // Codex order roughly by tier
  const dex = [
    { id: "whitebait", name: "白条", src: A + "whitebait.png", tier: 0, known: true, count: 14, maxWeight: 0.12, collected: true },
    { id: "crucian", name: "鲫鱼", src: A + "crucian.png", tier: 0, known: true, count: 8, maxWeight: 0.66 },
    { id: "loach", name: "泥鳅", src: A + "loach.png", tier: 0, known: true, count: 3, maxWeight: 0.09 },
    { id: "gudgeon", name: "棒花鱼", src: A + "gudgeon.png", tier: 0, known: true, count: 1, maxWeight: 0.04 },
    { id: "topmouth", name: "麦穗鱼", src: A + "topmouth.png", tier: 0, known: false },
    { id: "carp", name: "鲤鱼", src: A + "carp.png", tier: 1, known: true, count: 11, maxWeight: 3.4, collected: true, giant: true },
    { id: "grass", name: "草鱼", src: A + "grass.png", tier: 1, known: true, count: 5, maxWeight: 9.95, giant: true },
    { id: "redeye", name: "赤眼鳟", src: A + "redeye.png", tier: 1, known: true, count: 2, maxWeight: 1.12 },
    { id: "dace", name: "雅罗鱼", src: A + "dace.png", tier: 1, known: false },
    { id: "bass", name: "鲈鱼", src: A + "bass.png", tier: 2, known: true, count: 4, maxWeight: 1.84 },
    { id: "bream", name: "鳊鱼", src: A + "bream.png", tier: 2, known: true, count: 1, maxWeight: 0.5, variants: [1] },
    { id: "fangbream", name: "翘嘴鲌", src: A + "fangbream.png", tier: 2, known: true, count: 6, maxWeight: 2.21 },
    { id: "blackcarp", name: "青鱼", src: A + "blackcarp.png", tier: 2, known: false },
    { id: "mandarin", name: "鳜鱼", src: A + "mandarin.png", tier: 3, known: true, count: 2, maxWeight: 0.79 },
    { id: "trout", name: "虹鳟", src: A + "trout.png", tier: 3, known: true, count: 3, maxWeight: 1.28, perfect: true },
    { id: "pike", name: "白斑狗鱼", src: A + "pike.png", tier: 3, known: false },
    { id: "snakehead", name: "黑鱼", src: A + "snakehead.png", tier: 3, known: false },
    { id: "koi", name: "锦鲤", src: A + "koi.png", tier: 4, known: true, count: 2, maxWeight: 3.1, variants: [2] },
    { id: "salmon", name: "大马哈鱼", src: A + "salmon.png", tier: 4, known: false },
    { id: "taimen", name: "哲罗鲑", src: A + "taimen.png", tier: 4, known: false },
    { id: "chinese_sturgeon", name: "中华鲟", src: A + "chinese_sturgeon.png", tier: 5, known: false },
    { id: "kaluga", name: "达氏鳇", src: A + "kaluga.png", tier: 5, known: false },
    { id: "oarfish", name: "皇带鱼", src: A + "oarfish.png", tier: 5, known: false },
    { id: "coelacanth", name: "矛尾鱼", src: A + "coelacanth.png", tier: 5, known: false },
  ];

  const spots = [
    { id: "river", name: "新手河湾", desc: "最初的那方静水，缓流绕过雪岸。从白条到国宝鲟，什么都可能上钩——新手友好的全能钓点。", got: 6, total: 44, unlocked: true, current: true, event: "风平浪静" },
    { id: "lake", name: "静水湖泊", desc: "水草丰茂的冬日湖湾，掠食者潜伏在乱石与树根间。鲈、鳜、黑鱼、狗鱼当家，偶有巨鲟与鳇鲶。", got: 5, total: 43, unlocked: true },
    { id: "coast", name: "海岸码头", desc: "海风咸涩，浪拍木桩，小灯在栈桥尽头摇。海鲈、鲷、带鱼、石斑、马鲛轮番登场，深处藏着金枪与旗鱼。", got: 0, total: 48, unlocked: false, unlockText: "累计渔获 120 条解锁" },
  ];

  window.CF_DATA = { inventory, dex, spots, fb };
})();
