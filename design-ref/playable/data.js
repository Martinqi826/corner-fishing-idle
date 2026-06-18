// AUTO-DERIVED from source/fish_data.gd — do not hand-edit fish stats.
// 角落垂钓 game data (1:1 with the Godot source).
window.GAMEDATA = (function(){
const TIER_NAMES = ["普通","优良","稀有","史诗","传说","神话"];
const TIER_COLORS = ["#C7C7CC","#59C74D","#4D9EF2","#B86BF2","#FF8C1F","#FF6152"];
const QUALITY_NAMES = ["","上品","极品","完美"];
const QUALITY_MULTS = [1.0,1.8,4.0,8.0];
const VARIANT_NAMES = ["","斑斓","鎏金","七彩"];
const VARIANT_MULTS = [1.0,2.0,5.0,12.0];
const VARIANT_COLORS = ["#ffffff","#8CD9F2","#FFD659","#F28CF2"];
const VARIANT_PROBS = [0.0,0.06,0.012,0.002];
const BASE_WEIGHTS = {0:58.0,1:25.0,2:11.0,3:4.5,4:1.3,5:0.2};
const BAITS = [
  {name:"蚯蚓",cost:0,probs:[1.0,0.08,0.02,0.05],desc:"河边随手挖的"},
  {name:"红虫",cost:800,probs:[1.0,0.22,0.10,0.08],desc:"冬钓利器，上品率明显提升"},
  {name:"活虾",cost:5000,probs:[1.0,0.45,0.18,0.12],desc:"大鱼爱追活食"},
  {name:"秘制饵",cost:24000,probs:[1.0,0.70,0.35,0.18],desc:"老钓翁的祖传配方"},
];
const HOOKS = [
  {name:"基础鱼钩",cost:0,double:0.0,desc:"普普通通的单钩"},
  {name:"宽门钩",cost:2000,double:0.10,desc:"钩门更宽，偶尔双钩"},
  {name:"倒刺钩",cost:12000,double:0.20,desc:"倒刺挂得牢，双钩更常见"},
  {name:"双叉钩",cost:60000,double:0.32,desc:"一线两钩，常常成对上鱼"},
];
const BAG_CAPS = [20,25,30,35,40,45,50,55];
const BAG_COSTS = [100,250,600,1500,4000,10000,25000];
const SPOTS = {
  river_bend:{name:"新手河湾",desc:"最初的那方静水，缓流绕过雪岸。从白条到国宝鲟，什么都可能上钩——新手友好的全能钓点。",unlock:null,habitat_tags:["river"],bg:"spot_river_bend",surface:"glass",wait_mult:1.0,value_mult:1.0,luck_bonus:0,bite:[300,322]},
  still_lake:{name:"静水湖泊",desc:"水草丰茂的冬日湖湾，掠食者潜伏在乱石与树根间。鲈、鳜、黑鱼、狗鱼当家，偶有巨鲟与欧鲶。",unlock:{kind:"catches",n:80},habitat_tags:["lake"],bg:"spot_still_lake",surface:"paper",wait_mult:1.08,value_mult:1.06,luck_bonus:0,bite:[262,346]},
  coast_pier:{name:"海岸码头",desc:"海风咸涩，浪拍木桩，小灯在栈桥尽头摇。海鲈、鲷、带鱼、石斑、马鲛轮番登场，深处藏着金枪与旗鱼。",unlock:{kind:"catches",n:300},habitat_tags:["coast"],bg:"spot_coast_pier",surface:"paper",wait_mult:0.96,value_mult:1.12,luck_bonus:0,bite:[315,330]},
};
const SPOT_ORDER = ["river_bend","still_lake","coast_pier"];
const FISH = {"whitebait":{"name":"白条","tier":0,"wmin":0.01,"wmax":0.02,"vmin":1,"vmax":3,"tags":["river","lake"]},"topmouth":{"name":"麦穗鱼","tier":0,"wmin":0.01,"wmax":0.03,"vmin":1,"vmax":3,"tags":["river","lake"]},"loach":{"name":"泥鳅","tier":0,"wmin":0.03,"wmax":0.15,"vmin":2,"vmax":5,"tags":["river","lake","night"]},"crucian":{"name":"鲫鱼","tier":0,"wmin":0.1,"wmax":0.6,"vmin":3,"vmax":9,"tags":["river","lake"]},"bighead":{"name":"鲢鳙","tier":0,"wmin":1.5,"wmax":3,"vmin":6,"vmax":14,"tags":["river","lake"]},"yellowhead":{"name":"黄颡鱼","tier":0,"wmin":0.1,"wmax":0.3,"vmin":8,"vmax":18,"tags":["river","lake","night"]},"bluegill":{"name":"蓝鳃太阳鱼","tier":0,"wmin":0.05,"wmax":0.4,"vmin":2,"vmax":6,"tags":["lake"]},"icefish":{"name":"银鱼","tier":0,"wmin":0.005,"wmax":0.02,"vmin":3,"vmax":8,"tags":["lake","cold"]},"bitterling":{"name":"鳑鲏","tier":0,"wmin":0.005,"wmax":0.02,"vmin":1,"vmax":3,"tags":["lake"]},"sardine":{"name":"沙丁鱼","tier":0,"wmin":0.02,"wmax":0.1,"vmin":2,"vmax":5,"tags":["coast"]},"filefish":{"name":"马面鲀","tier":0,"wmin":0.1,"wmax":0.5,"vmin":4,"vmax":10,"tags":["coast"]},"goby":{"name":"虾虎鱼","tier":0,"wmin":0.01,"wmax":0.08,"vmin":1,"vmax":4,"tags":["coast"]},"minnow":{"name":"马口鱼","tier":0,"wmin":0.03,"wmax":0.15,"vmin":3,"vmax":8,"tags":["river","stream"]},"zacco":{"name":"宽鳍鱲","tier":0,"wmin":0.02,"wmax":0.1,"vmin":2,"vmax":6,"tags":["river","stream"]},"gudgeon":{"name":"棒花鱼","tier":0,"wmin":0.01,"wmax":0.08,"vmin":1,"vmax":4,"tags":["river","lake"]},"spined_loach":{"name":"中华花鳅","tier":0,"wmin":0.02,"wmax":0.1,"vmin":2,"vmax":5,"tags":["river","lake","night"]},"ricefish":{"name":"青鳉","tier":0,"wmin":0.002,"wmax":0.01,"vmin":2,"vmax":6,"tags":["lake"]},"paradisefish":{"name":"斗鱼","tier":0,"wmin":0.01,"wmax":0.05,"vmin":3,"vmax":8,"tags":["lake"]},"anchovy":{"name":"鳀鱼","tier":0,"wmin":0.005,"wmax":0.02,"vmin":2,"vmax":5,"tags":["coast"]},"halfbeak":{"name":"鱵鱼","tier":0,"wmin":0.02,"wmax":0.12,"vmin":3,"vmax":8,"tags":["coast"]},"sandlance":{"name":"玉筋鱼","tier":0,"wmin":0.005,"wmax":0.03,"vmin":2,"vmax":6,"tags":["coast"]},"dace":{"name":"雅罗鱼","tier":1,"wmin":0.3,"wmax":1,"vmin":14,"vmax":26,"tags":["river","cold"]},"carp":{"name":"鲤鱼","tier":1,"wmin":1,"wmax":8,"vmin":16,"vmax":40,"tags":["river","lake"]},"grass":{"name":"草鱼","tier":1,"wmin":2,"wmax":12,"vmin":16,"vmax":42,"tags":["river","lake"]},"bream":{"name":"鳊鱼","tier":1,"wmin":0.5,"wmax":2,"vmin":18,"vmax":36,"tags":["river","lake"]},"blackcarp":{"name":"青鱼","tier":1,"wmin":4,"wmax":15,"vmin":24,"vmax":55,"tags":["river","lake"]},"perch":{"name":"河鲈","tier":1,"wmin":0.2,"wmax":1.2,"vmin":18,"vmax":38,"tags":["lake"]},"catfish":{"name":"鲇鱼","tier":1,"wmin":0.5,"wmax":4,"vmin":16,"vmax":44,"tags":["lake","night"]},"swampeel":{"name":"黄鳝","tier":1,"wmin":0.1,"wmax":0.7,"vmin":20,"vmax":45,"tags":["lake","night"]},"tilapia":{"name":"罗非鱼","tier":1,"wmin":0.2,"wmax":1.5,"vmin":14,"vmax":30,"tags":["lake"]},"mackerel":{"name":"鲐鱼","tier":1,"wmin":0.2,"wmax":1,"vmin":14,"vmax":30,"tags":["coast"]},"small_croaker":{"name":"小黄鱼","tier":1,"wmin":0.1,"wmax":0.4,"vmin":20,"vmax":44,"tags":["coast"]},"mullet":{"name":"鲻鱼","tier":1,"wmin":0.3,"wmax":2,"vmin":16,"vmax":36,"tags":["coast"]},"rockfish":{"name":"许氏平鲉","tier":1,"wmin":0.2,"wmax":1.5,"vmin":22,"vmax":48,"tags":["coast"]},"redeye":{"name":"赤眼鳟","tier":1,"wmin":0.3,"wmax":2,"vmin":16,"vmax":36,"tags":["river","lake"]},"wuchang":{"name":"武昌鱼","tier":1,"wmin":0.5,"wmax":2.5,"vmin":18,"vmax":40,"tags":["river","lake"]},"spotted_steed":{"name":"唇䱻","tier":1,"wmin":0.3,"wmax":1.5,"vmin":18,"vmax":38,"tags":["river","stream"]},"bigscale_loach":{"name":"大鳞副泥鳅","tier":1,"wmin":0.05,"wmax":0.3,"vmin":16,"vmax":34,"tags":["lake","night"]},"yellowtail_fish":{"name":"黄尾鲴","tier":1,"wmin":0.2,"wmax":1,"vmin":16,"vmax":32,"tags":["river","lake"]},"yellow_drum":{"name":"黄姑鱼","tier":1,"wmin":0.3,"wmax":2,"vmin":20,"vmax":44,"tags":["coast"]},"greenling":{"name":"六线鱼","tier":1,"wmin":0.2,"wmax":1.5,"vmin":22,"vmax":46,"tags":["coast"]},"haarder":{"name":"梭鱼","tier":1,"wmin":0.3,"wmax":2.5,"vmin":18,"vmax":40,"tags":["coast"]},"flathead_fish":{"name":"鲬","tier":1,"wmin":0.3,"wmax":1.5,"vmin":20,"vmax":42,"tags":["coast"]},"bass":{"name":"鲈鱼","tier":2,"wmin":0.5,"wmax":3,"vmin":55,"vmax":120,"tags":["river","lake"]},"fangbream":{"name":"三角鲂","tier":2,"wmin":0.5,"wmax":5,"vmin":60,"vmax":130,"tags":["river","lake"]},"barbel":{"name":"花䱻","tier":2,"wmin":0.3,"wmax":1.5,"vmin":70,"vmax":140,"tags":["river","stream"]},"culter":{"name":"翘嘴鲌","tier":2,"wmin":1,"wmax":5,"vmin":80,"vmax":170,"tags":["river","lake"]},"mandarin":{"name":"鳜鱼","tier":2,"wmin":0.5,"wmax":3,"vmin":90,"vmax":190,"tags":["river","lake","night"]},"largemouth":{"name":"大口黑鲈","tier":2,"wmin":0.5,"wmax":4,"vmin":70,"vmax":160,"tags":["lake"]},"seabass":{"name":"海鲈","tier":2,"wmin":0.5,"wmax":5,"vmin":70,"vmax":160,"tags":["coast"]},"blackbream":{"name":"黑鲷","tier":2,"wmin":0.3,"wmax":2.5,"vmin":65,"vmax":150,"tags":["coast"]},"hairtail":{"name":"带鱼","tier":2,"wmin":0.2,"wmax":1.5,"vmin":60,"vmax":140,"tags":["coast","deep","night"]},"flounder":{"name":"牙鲆","tier":2,"wmin":0.5,"wmax":4,"vmin":80,"vmax":180,"tags":["coast"]},"conger":{"name":"海鳗","tier":2,"wmin":0.5,"wmax":5,"vmin":60,"vmax":140,"tags":["coast","night"]},"pufferfish":{"name":"红鳍东方鲀","tier":2,"wmin":0.3,"wmax":2,"vmin":90,"vmax":190,"tags":["coast"]},"spinibarbus":{"name":"光倒刺鲃","tier":2,"wmin":0.5,"wmax":3,"vmin":60,"vmax":130,"tags":["river","stream"]},"mongolian_redfin":{"name":"蒙古鲌","tier":2,"wmin":0.5,"wmax":3,"vmin":60,"vmax":130,"tags":["river","lake"]},"small_snakehead":{"name":"月鳢","tier":2,"wmin":0.3,"wmax":1.5,"vmin":60,"vmax":130,"tags":["lake","night"]},"yellowfin_seabream":{"name":"黄鳍鲷","tier":2,"wmin":0.3,"wmax":2,"vmin":65,"vmax":150,"tags":["coast"]},"crimson_snapper":{"name":"红笛鲷","tier":2,"wmin":0.5,"wmax":3,"vmin":70,"vmax":160,"tags":["coast"]},"spotted_scat":{"name":"金钱鱼","tier":2,"wmin":0.2,"wmax":1,"vmin":60,"vmax":130,"tags":["coast"]},"octopus":{"name":"章鱼","tier":2,"wmin":0.5,"wmax":4,"vmin":70,"vmax":160,"tags":["coast","night"]},"squid":{"name":"鱿鱼","tier":2,"wmin":0.2,"wmax":2,"vmin":60,"vmax":140,"tags":["coast","night"]},"cuttlefish":{"name":"墨鱼","tier":2,"wmin":0.3,"wmax":2.5,"vmin":65,"vmax":150,"tags":["coast"]},"snakehead":{"name":"黑鱼","tier":3,"wmin":1,"wmax":6,"vmin":200,"vmax":420,"tags":["river","lake","night"]},"trout":{"name":"虹鳟","tier":3,"wmin":0.8,"wmax":4,"vmin":210,"vmax":430,"tags":["river","stream","cold"]},"pike":{"name":"白斑狗鱼","tier":3,"wmin":1,"wmax":8,"vmin":220,"vmax":450,"tags":["river","lake","cold"]},"zander":{"name":"梭鲈","tier":3,"wmin":1,"wmax":14,"vmin":240,"vmax":500,"tags":["river","lake"]},"longsnout":{"name":"江团","tier":3,"wmin":1,"wmax":5,"vmin":260,"vmax":520,"tags":["river","night"]},"lenok":{"name":"细鳞鱼","tier":3,"wmin":0.5,"wmax":3,"vmin":280,"vmax":560,"tags":["river","stream","cold"]},"yellowcheek":{"name":"鳡鱼","tier":3,"wmin":2,"wmax":30,"vmin":240,"vmax":560,"tags":["lake"]},"eel":{"name":"鳗鲡","tier":3,"wmin":0.3,"wmax":3,"vmin":220,"vmax":460,"tags":["lake","night"]},"seabream":{"name":"真鲷","tier":3,"wmin":0.5,"wmax":4,"vmin":240,"vmax":500,"tags":["coast"]},"spanish_mackerel":{"name":"马鲛鱼","tier":3,"wmin":1,"wmax":8,"vmin":220,"vmax":470,"tags":["coast"]},"pomfret":{"name":"银鲳","tier":3,"wmin":0.2,"wmax":1.5,"vmin":230,"vmax":480,"tags":["coast"]},"grouper":{"name":"石斑鱼","tier":3,"wmin":0.8,"wmax":8,"vmin":260,"vmax":560,"tags":["coast","deep"]},"yellowcroaker":{"name":"大黄鱼","tier":3,"wmin":0.3,"wmax":3,"vmin":300,"vmax":580,"tags":["coast"]},"chinese_sucker":{"name":"胭脂鱼","tier":3,"wmin":1,"wmax":6,"vmin":260,"vmax":540,"tags":["river"]},"burbot":{"name":"江鳕","tier":3,"wmin":1,"wmax":8,"vmin":240,"vmax":500,"tags":["river","lake","cold","night"]},"manchurian_trout":{"name":"花羔红点鲑","tier":3,"wmin":0.5,"wmax":3,"vmin":260,"vmax":540,"tags":["river","stream","cold"]},"amur_catfish":{"name":"怀头鲇","tier":3,"wmin":2,"wmax":20,"vmin":240,"vmax":520,"tags":["lake","deep","night"]},"amberjack":{"name":"高体鰤","tier":3,"wmin":2,"wmax":15,"vmin":260,"vmax":560,"tags":["coast","deep"]},"cobia":{"name":"军曹鱼","tier":3,"wmin":3,"wmax":20,"vmin":260,"vmax":560,"tags":["coast","deep"]},"barramundi":{"name":"尖吻鲈","tier":3,"wmin":1,"wmax":8,"vmin":240,"vmax":500,"tags":["coast"]},"miiuy_croaker":{"name":"鮸鱼","tier":3,"wmin":1,"wmax":8,"vmin":240,"vmax":500,"tags":["coast"]},"koi":{"name":"锦鲤","tier":4,"wmin":1,"wmax":8,"vmin":750,"vmax":1600,"tags":["river","lake"]},"salmon":{"name":"大马哈鱼","tier":4,"wmin":3,"wmax":14,"vmin":800,"vmax":1700,"tags":["river","coast","cold"]},"sturgeon":{"name":"施氏鲟","tier":4,"wmin":5,"wmax":30,"vmin":900,"vmax":1900,"tags":["river","lake","deep"]},"taimen":{"name":"哲罗鲑","tier":4,"wmin":3,"wmax":50,"vmin":1000,"vmax":2200,"tags":["river","stream","cold"]},"wels_catfish":{"name":"六须鲇","tier":4,"wmin":5,"wmax":100,"vmin":850,"vmax":2000,"tags":["lake","deep","night"]},"tuna":{"name":"金枪鱼","tier":4,"wmin":5,"wmax":200,"vmin":900,"vmax":2000,"tags":["coast","deep"]},"giant_grouper":{"name":"龙趸石斑","tier":4,"wmin":10,"wmax":300,"vmin":1000,"vmax":2200,"tags":["coast","deep"]},"mahseer":{"name":"结鱼","tier":4,"wmin":3,"wmax":30,"vmin":800,"vmax":1800,"tags":["river","stream","cold"]},"marbled_eel":{"name":"花鳗鲡","tier":4,"wmin":2,"wmax":20,"vmin":800,"vmax":1800,"tags":["river","lake","night"]},"marlin":{"name":"马林鱼","tier":4,"wmin":30,"wmax":300,"vmin":1000,"vmax":2200,"tags":["coast","deep"]},"giant_trevally":{"name":"浪人鲹","tier":4,"wmin":5,"wmax":50,"vmin":900,"vmax":2000,"tags":["coast","deep"]},"mahimahi":{"name":"鲯鳅","tier":4,"wmin":3,"wmax":30,"vmin":800,"vmax":1800,"tags":["coast","deep"]},"swordfish":{"name":"剑鱼","tier":4,"wmin":30,"wmax":200,"vmin":950,"vmax":2100,"tags":["coast","deep"]},"wahoo":{"name":"刺鲅","tier":4,"wmin":2,"wmax":40,"vmin":800,"vmax":1800,"tags":["coast","deep"]},"chinese_sturgeon":{"name":"中华鲟","tier":5,"wmin":20,"wmax":300,"vmin":4500,"vmax":9500,"tags":["river","coast","protected"]},"kaluga":{"name":"达氏鳇","tier":5,"wmin":50,"wmax":1000,"vmin":5000,"vmax":11000,"tags":["river","deep","protected"]},"sailfish":{"name":"旗鱼","tier":5,"wmin":20,"wmax":90,"vmin":5000,"vmax":10000,"tags":["coast","deep"]},"paddlefish":{"name":"白鲟","tier":5,"wmin":50,"wmax":300,"vmin":5000,"vmax":11000,"tags":["river","protected"]},"coelacanth":{"name":"矛尾鱼","tier":5,"wmin":30,"wmax":90,"vmin":6000,"vmax":12000,"tags":["coast","deep"]},"oarfish":{"name":"皇带鱼","tier":5,"wmin":50,"wmax":200,"vmin":5500,"vmax":11000,"tags":["coast","deep","night"]},"whale_shark":{"name":"鲸鲨","tier":5,"wmin":200,"wmax":1000,"vmin":6000,"vmax":13000,"tags":["coast","deep","protected"]}};
const HAS_ART = {"whitebait":true,"topmouth":true,"loach":true,"crucian":true,"bighead":false,"yellowhead":false,"bluegill":false,"icefish":false,"bitterling":false,"sardine":false,"filefish":false,"goby":false,"minnow":false,"zacco":false,"gudgeon":true,"spined_loach":false,"ricefish":false,"paradisefish":false,"anchovy":false,"halfbeak":false,"sandlance":false,"dace":true,"carp":true,"grass":true,"bream":true,"blackcarp":true,"perch":false,"catfish":false,"swampeel":false,"tilapia":false,"mackerel":false,"small_croaker":false,"mullet":false,"rockfish":false,"redeye":true,"wuchang":false,"spotted_steed":false,"bigscale_loach":false,"yellowtail_fish":false,"yellow_drum":false,"greenling":false,"haarder":false,"flathead_fish":false,"bass":true,"fangbream":true,"barbel":false,"culter":false,"mandarin":true,"largemouth":false,"seabass":false,"blackbream":false,"hairtail":false,"flounder":false,"conger":false,"pufferfish":false,"spinibarbus":false,"mongolian_redfin":false,"small_snakehead":false,"yellowfin_seabream":false,"crimson_snapper":false,"spotted_scat":false,"octopus":false,"squid":false,"cuttlefish":false,"snakehead":true,"trout":true,"pike":true,"zander":false,"longsnout":true,"lenok":true,"yellowcheek":false,"eel":false,"seabream":false,"spanish_mackerel":false,"pomfret":false,"grouper":false,"yellowcroaker":false,"chinese_sucker":false,"burbot":false,"manchurian_trout":false,"amur_catfish":false,"amberjack":false,"cobia":false,"barramundi":false,"miiuy_croaker":false,"koi":true,"salmon":true,"sturgeon":true,"taimen":true,"wels_catfish":false,"tuna":false,"giant_grouper":false,"mahseer":false,"marbled_eel":false,"marlin":true,"giant_trevally":false,"mahimahi":false,"swordfish":false,"wahoo":false,"chinese_sturgeon":true,"kaluga":true,"sailfish":false,"paddlefish":false,"coelacanth":true,"oarfish":true,"whale_shark":false};
const GENERIC_BY_TIER = ["generic_tier0","generic_tier1","generic_tier2","generic_tier3","generic_tier4","generic_tier5"];

function artFor(id){ return HAS_ART[id] ? id : GENERIC_BY_TIER[FISH[id].tier]; }
function tierOf(id){ return FISH[id].tier; }
function poolFor(spotId){
  const want = SPOTS[spotId].habitat_tags;
  const out = [];
  for (const fid in FISH){ const tags = FISH[fid].tags||["river"]; if (want.some(t=>tags.includes(t))) out.push(fid); }
  out.sort((a,b)=> tierOf(a)!==tierOf(b) ? tierOf(a)-tierOf(b) : (a<b?-1:1));
  return out;
}
function weightsForRod(rodLevel){
  const lv = rodLevel-1;
  return {0:Math.max(16.0,BASE_WEIGHTS[0]-lv*2.4),1:BASE_WEIGHTS[1]+lv*0.7,2:BASE_WEIGHTS[2]+lv*0.85,3:BASE_WEIGHTS[3]+lv*0.50,4:BASE_WEIGHTS[4]+lv*0.22,5:BASE_WEIGHTS[5]+lv*0.05};
}
function idsOfTier(ids,tier){ if(tier<0||tier>5)return[]; return ids.filter(id=>FISH[id].tier===tier); }
function rollFish(weights,pool){
  let total=0; for(const r in weights) total+=weights[r];
  let pick=Math.random()*total, tier=0;
  for(const r in weights){ pick-=weights[r]; if(pick<=0){tier=+r;break;} }
  const ids = (pool&&pool.length)?pool:Object.keys(FISH);
  let cands = idsOfTier(ids,tier);
  if(!cands.length){ for(let d=1;d<6;d++){ cands=idsOfTier(ids,tier-d); if(!cands.length)cands=idsOfTier(ids,tier+d); if(cands.length)break; } }
  if(!cands.length)cands=ids;
  return cands[Math.floor(Math.random()*cands.length)];
}
function rollQuality(baitIdx){
  const probs = BAITS[Math.max(0,Math.min(BAITS.length-1,baitIdx))].probs;
  let q=0; for(let lvl=1;lvl<probs.length;lvl++){ if(Math.random()<probs[lvl]) q=lvl; else break; } return q;
}
function rollVariant(){
  const r=Math.random(); let acc=0;
  for(let vi=VARIANT_PROBS.length-1;vi>0;vi--){ acc+=VARIANT_PROBS[vi]; if(r<acc) return vi; } return 0;
}
function lerp(a,b,t){ return a+(b-a)*t; }
function rollCatch(rodLevel,baitIdx,luck,pool){
  baitIdx=baitIdx||0; luck=luck||0;
  const id=rollFish(weightsForRod(rodLevel+luck),pool);
  const f=FISH[id];
  let k=Math.random(); k=k*k;
  const w=lerp(f.wmin,f.wmax,k);
  let sr=0; if(f.wmax>f.wmin) sr=(w-f.wmin)/(f.wmax-f.wmin);
  const base=lerp(f.vmin,f.vmax,sr);
  const rodMult=1.0+(rodLevel-1)*0.08;
  const jitter=0.92+Math.random()*0.16;
  const q=rollQuality(baitIdx);
  const vr=rollVariant();
  return {id,w:Math.round(w*100)/100,v:Math.max(1,Math.round(base*rodMult*jitter*QUALITY_MULTS[q]*VARIANT_MULTS[vr])),q,var:vr};
}
function qualityLabel(q){ if(q<=0)return""; return QUALITY_NAMES[q]+"★".repeat(q)+"·"; }
function variantLabel(v){ if(v<=0)return""; return VARIANT_NAMES[v]+"·"; }
function sizeTag(id,w){ const f=FISH[id]; if(f.wmax<=f.wmin)return""; const r=(w-f.wmin)/(f.wmax-f.wmin); if(r>=0.95)return"巨物·"; if(r>=0.75)return"大·"; return""; }
function displayName(id){ return FISH[id].name; }
function fullName(c){ return variantLabel(c.var)+qualityLabel(c.q)+sizeTag(c.id,c.w)+displayName(c.id); }
function rodCost(rodLevel){ return Math.round(200.0*Math.pow(2.0,rodLevel-1)); }

return {TIER_NAMES,TIER_COLORS,QUALITY_NAMES,QUALITY_MULTS,VARIANT_NAMES,VARIANT_MULTS,VARIANT_COLORS,VARIANT_PROBS,
  BAITS,HOOKS,BAG_CAPS,BAG_COSTS,SPOTS,SPOT_ORDER,FISH,HAS_ART,GENERIC_BY_TIER,
  artFor,tierOf,poolFor,weightsForRod,rollCatch,qualityLabel,variantLabel,sizeTag,displayName,fullName,rodCost,rollVariant,rollQuality};
})();
