extends SceneTree
## 鱼图鉴看板生成器：从 FishData 直接生成 docs/fish_gallery.html。
## 用途：核对每条鱼的「名字 ↔ 真实世界图 ↔ 游戏图」是否匹配。
## 真实图取 assets/art/fish_photos/<id>.jpg，游戏图取 assets/art/fish/<id>.png；
## 缺图自动显示「待补」占位（接受分批补图：先有名字，再补真实图/游戏图）。
##
## 跑法（新增/修改鱼后必须重跑，保持看板与数据一致）：
##   godot --headless --path . -s tools/gen_fish_gallery.gd

const HEAD := """<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>角落垂钓 · 全部鱼图鉴看板</title>
<style>
:root{--ink:#2f3432;--muted:#686d67;--paper:#eee8dc;--paper2:#f7f3eb;--line:#c9c2b5;--water:#476f78;--pine:#3f4d45;--gold:#d6a85d;--shadow:rgba(43,48,44,.16);}
*{box-sizing:border-box;}
body{margin:0;font-family:"Microsoft YaHei","Segoe UI",Arial,sans-serif;background:#d8d2c4;color:var(--ink);}
header{position:sticky;top:0;z-index:5;background:rgba(238,232,220,.96);backdrop-filter:blur(10px);border-bottom:1px solid var(--line);padding:14px min(4vw,40px) 12px;}
h1{margin:0 0 4px;font-size:22px;}
.sub{margin:0 0 10px;color:var(--muted);font-size:13px;line-height:1.5;}
.sub b{color:var(--pine);}
.bar{display:flex;flex-wrap:wrap;gap:8px;align-items:center;}
#q{flex:0 0 auto;width:min(260px,60vw);padding:7px 12px;border:1px solid var(--line);border-radius:999px;background:rgba(255,255,255,.6);font-size:13px;color:var(--ink);}
.fbtns{display:flex;flex-wrap:wrap;gap:6px;}
.fbtn{cursor:pointer;border:1px solid var(--line);border-radius:999px;padding:6px 11px;background:rgba(255,255,255,.4);font-size:12.5px;color:var(--ink);}
.fbtn.on{background:var(--water);color:#fff;border-color:var(--water);}
.grid{display:grid;gap:12px;grid-template-columns:repeat(auto-fill,minmax(184px,1fr));padding:16px min(4vw,40px) 60px;}
.card{background:rgba(247,243,235,.78);border:1px solid var(--line);border-radius:10px;box-shadow:0 8px 22px var(--shadow);padding:10px;}
.imgs{display:grid;grid-template-columns:1fr 1fr;gap:6px;margin-bottom:8px;}
.slot{position:relative;aspect-ratio:1/1;border:1px solid var(--line);border-radius:8px;overflow:hidden;background:repeating-conic-gradient(#e7e0d2 0% 25%,#efe9dc 0% 50%) 50%/14px 14px;}
.slot .lab{position:absolute;top:3px;left:3px;z-index:3;font-size:9px;line-height:1;padding:2px 5px;border-radius:999px;background:rgba(47,52,50,.55);color:#fff;}
.slot .ph{position:absolute;inset:0;display:grid;place-items:center;color:var(--muted);font-size:11px;text-align:center;padding:6px;}
.slot img{position:absolute;inset:0;width:100%;height:100%;object-fit:contain;z-index:2;}
.nm{display:flex;align-items:center;gap:6px;font-size:15px;font-weight:700;color:var(--ink);}
.dot{width:9px;height:9px;border-radius:50%;flex:0 0 auto;box-shadow:0 0 0 1px rgba(0,0,0,.12);}
.id{font-family:Consolas,monospace;font-size:11px;color:var(--water);margin:1px 0 5px;word-break:break-all;}
.meta{font-size:12px;color:var(--muted);margin-bottom:6px;}
.pills{display:flex;flex-wrap:wrap;gap:4px;}
.pill{font-size:10.5px;padding:2px 7px;border-radius:999px;border:1px solid var(--line);background:rgba(255,255,255,.5);color:#55605a;}
.pill.tag{background:rgba(71,111,120,.1);border-color:rgba(71,111,120,.3);color:var(--water);}
footer{padding:0 min(4vw,40px) 40px;color:var(--muted);font-size:12px;}
footer code{color:var(--water);font-family:Consolas,monospace;}
</style>
</head>
<body>
<header>
<h1>🐟 全部鱼图鉴看板</h1>
<p class="sub">核对每条鱼：<b>名字 ↔ 真实世界图 ↔ 游戏图</b> 是否匹配。缺图自动显示「待补」（接受分批补图）。共 <b id="count"></b> 条。</p>
<div class="bar">
<input id="q" placeholder="搜 名字 / id …" />
<span class="fbtns">
<button class="fbtn on" data-t="-1">全部</button>
<button class="fbtn" data-t="0">普通</button>
<button class="fbtn" data-t="1">优良</button>
<button class="fbtn" data-t="2">稀有</button>
<button class="fbtn" data-t="3">史诗</button>
<button class="fbtn" data-t="4">传说</button>
<button class="fbtn" data-t="5">神话</button>
</span>
</div>
</header>
<div id="grid" class="grid"></div>
<footer>本页由 <code>tools/gen_fish_gallery.gd</code> 从 <code>fish_data.gd</code> 生成 —— 改鱼后重跑即可同步。真实图：<code>assets/art/fish_photos/&lt;id&gt;.jpg</code>　游戏图：<code>assets/art/fish/&lt;id&gt;.png</code></footer>
<script>
const FISH = """

const TAIL := """;
const TC=["#c7c7cc","#5ac74d","#4d9ef2","#b86bf2","#ff8c1f","#ff6152"];
let curTier=-1, q="";
const grid=document.getElementById('grid');
const countEl=document.getElementById('count');
function slot(lab,src){
  return `<div class="slot"><span class="lab">${lab}</span><div class="ph">待补</div><img loading="lazy" src="${src}" onerror="this.style.display='none'"></div>`;
}
function card(f){
  const real=`../assets/art/fish_photos/${f.id}.jpg`;
  const game=`../assets/art/fish/${f.id}.png`;
  const spots=(f.spots||[]).map(s=>`<span class="pill">${s}</span>`).join('');
  const tags=(f.tags||[]).map(t=>`<span class="pill tag">${t}</span>`).join('');
  return `<div class="card">
    <div class="imgs">${slot('真实',real)}${slot('游戏',game)}</div>
    <div class="nm"><span class="dot" style="background:${TC[f.tier]}"></span>${f.name}</div>
    <div class="id">${f.id}</div>
    <div class="meta">${f.wmin}–${f.wmax} kg　·　¥${f.vmin}–${f.vmax}</div>
    <div class="pills">${spots}${tags}</div>
  </div>`;
}
function render(){
  const list=FISH.filter(f=>(curTier<0||f.tier===curTier)&&(!q||f.name.includes(q)||f.id.includes(q)));
  grid.innerHTML=list.map(card).join('');
  countEl.textContent=list.length+(list.length===FISH.length?'':' / '+FISH.length);
}
document.querySelectorAll('.fbtn').forEach(b=>{
  const t=parseInt(b.dataset.t);
  const n=t<0?FISH.length:FISH.filter(f=>f.tier===t).length;
  b.textContent=b.textContent+' '+n;
  b.onclick=()=>{curTier=t;document.querySelectorAll('.fbtn').forEach(x=>x.classList.remove('on'));b.classList.add('on');render();};
});
document.getElementById('q').oninput=e=>{q=e.target.value.trim();render();};
render();
</script>
</body>
</html>
"""


func _init() -> void:
	var spot_ids: Array = SpotData.SPOT_ORDER
	var data: Array = []
	for fid in FishData.FISH:
		var f: Dictionary = FishData.FISH[fid]
		var tags: Array = f.get("tags", [])
		var spots: Array = []
		for sid in spot_ids:
			var hab: Array = SpotData.get_spot(str(sid)).get("habitat_tags", [])
			for t in hab:
				if t in tags:
					spots.append(SpotData.display_name(str(sid)))
					break
		data.append({
			"id": fid,
			"name": f["name"],
			"tier": int(f["tier"]),
			"wmin": f["wmin"], "wmax": f["wmax"],
			"vmin": f["vmin"], "vmax": f["vmax"],
			"tags": tags,
			"spots": spots,
		})
	data.sort_custom(func(a, b):
		if int(a["tier"]) != int(b["tier"]):
			return int(a["tier"]) < int(b["tier"])
		return str(a["id"]) < str(b["id"]))
	var json := JSON.stringify(data)
	var html := HEAD + json + TAIL
	var fa := FileAccess.open("res://docs/fish_gallery.html", FileAccess.WRITE)
	if fa == null:
		push_error("无法写入 docs/fish_gallery.html")
		quit(1)
		return
	fa.store_string(html)
	fa.close()
	print("已生成 docs/fish_gallery.html，共 ", data.size(), " 条鱼")
	quit()
