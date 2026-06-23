# -*- coding: utf-8 -*-
"""
gen_site.py —— 把项目里零散的 MD 文档 + HTML 看板，汇总成一个本地静态门户网站。

用法（在仓库根目录）:
    python tools/gen_site.py

产物:
    docs/site/index.html      —— 门户首页（项目快照 + 当前焦点 + 分区入口）
    docs/site/<doc>.html      —— 每篇 MD 渲染成统一模板的页面
    docs/site/dash_<x>.html   —— 每个已有 HTML 看板的包裹页（iframe 内嵌，保持同一套导航）

设计要点:
  * 运行时真实扫描文件系统枚举文档（清单自保鲜、不依赖手抄）。
  * MD 单一可信源；本站点是"人读视图"，永远重新生成、勿手改。
  * 零第三方依赖（自带极简 Markdown 转换器）。

约定: 改完任意 MD 后重跑本脚本即可刷新整站。
"""
import os
import re
import html
import json
import shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "docs", "site")

# 扫描时跳过的目录 / 文件
SKIP_DIRS = {".git", ".godot", "node_modules", "dev_capture", "site", "__pycache__",
             "addons", "assets", "fish_photos"}
SKIP_HTML_BASENAMES = set()  # 如需排除某些 html，加在这里

# ---- 分区与人类可读标题（仅对存在的文件生效；其余文档自动归入「更多文档」）----
# (相对仓库根的路径, 显示标题)
#       （以下路径均经文件系统真值核对存在；早期被注入污染的 9 个假路径已剔除）
SECTIONS = [
    ("概览 · 进展", [
        ("VISION.md", "愿景 VISION"),
        ("ROADMAP.md", "路线图 ROADMAP"),
        ("BACKLOG.md", "想法冰箱 BACKLOG"),
        ("README.md", "玩法总览 README"),
    ]),
    ("玩法与数据", [
        ("docs/fish-expansion-plan.md", "鱼扩展方案"),
        ("docs/fish_icon_art_standard.md", "鱼图标美术标准"),
        ("docs/fish_icon_manifest.md", "鱼图标清单"),
    ]),
    ("可视看板", [
        ("docs/fish_gallery.html", "鱼图鉴看板"),
        ("docs/world_wonder_fishing_spots_scene_board.html", "世界奇观钓点展板"),
        ("docs/world_wonder_scene_workbench.html", "奇观场景工作台"),
        ("docs/community_photo_wall_design.html", "社区照片墙设计"),
        ("design-ref/playable/Corner Fishing.html", "可玩设计稿"),
    ]),
    ("设计与规范", [
        ("design-ref/_HANDOFF_INDEX.md", "设计交接索引"),
        ("design-ref/handoff/2026-06-16_corner-entry-consolidation.md", "交接 · 入口收敛(06-16)"),
        ("design-ref/handoff/2026-06-18_nav-dissolve-into-scene.md", "交接 · 导航融入场景(06-18)"),
        ("design-ref/handoff/游戏仓库-CLAUDE.md", "交接 · 游戏仓库说明"),
        ("design-ref/handoff/给ClaudeCode的话-复制粘贴.md", "交接 · 给 Claude 的话"),
        ("docs/audio_asset_rules.md", "音频资源规则"),
        ("docs/parallel-dev-contract.md", "多车道并行约定"),
        ("CLAUDE.md", "项目总纲 CLAUDE"),
    ]),
]

# =====================================================================
# 极简 Markdown -> HTML（零依赖）。覆盖本项目文档用到的语法：
# 标题 / 段落 / 列表(含任务清单复选框) / 有序列表 / 引用 / 代码块 /
# 行内代码 / 粗体 / 斜体 / 链接 / 图片 / 分隔线 / GFM 表格 / 硬换行。
# =====================================================================

_CODE_TOKEN = "\x00CODE%d\x00"


def _inline(text):
    """行内元素渲染。先转义 HTML，再处理行内代码(占位保护)、图片、链接、粗斜体。"""
    # 1. 抽出行内代码，先占位，避免其中内容被二次格式化
    codes = []

    def _stash(m):
        codes.append(m.group(1))
        return _CODE_TOKEN % (len(codes) - 1)

    text = re.sub(r"`([^`]+)`", _stash, text)

    # 2. 转义
    text = html.escape(text, quote=False)

    # 3. 图片 ![alt](src)
    text = re.sub(r"!\[([^\]]*)\]\(([^)\s]+)[^)]*\)",
                  lambda m: '<img src="%s" alt="%s">' % (m.group(2), m.group(1)),
                  text)
    # 4. 链接 [text](url)
    text = re.sub(r"\[([^\]]+)\]\(([^)\s]+)[^)]*\)",
                  lambda m: '<a href="%s">%s</a>' % (m.group(2), m.group(1)),
                  text)
    # 5. 粗体 **x** / __x__
    text = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"__([^_]+)__", r"<strong>\1</strong>", text)
    # 6. 斜体 *x* / _x_
    text = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<em>\1</em>", text)
    text = re.sub(r"(?<!_)_([^_]+)_(?!_)", r"<em>\1</em>", text)

    # 7. 还原行内代码
    def _restore(m):
        return "<code>%s</code>" % html.escape(codes[int(m.group(1))], quote=False)

    text = re.sub(r"\x00CODE(\d+)\x00", _restore, text)
    return text


def _render_table(rows):
    """rows: 原始行(含表头与分隔行)。返回 HTML <table>。"""
    cells = [[c.strip() for c in re.split(r"(?<!\\)\|", r.strip().strip("|"))] for r in rows]
    head = cells[0]
    body = cells[2:]  # cells[1] 是 |---| 分隔行
    out = ['<table><thead><tr>']
    out += ['<th>%s</th>' % _inline(c) for c in head]
    out.append('</tr></thead><tbody>')
    for row in body:
        out.append('<tr>')
        out += ['<td>%s</td>' % _inline(c) for c in row]
        out.append('</tr>')
    out.append('</tbody></table>')
    return "".join(out)


def _is_table_sep(line):
    return bool(re.match(r"^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)+\|?\s*$", line))


def md_to_html(md):
    lines = md.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    out = []
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        stripped = line.strip()

        # 围栏代码块
        if stripped.startswith("```"):
            i += 1
            buf = []
            while i < n and not lines[i].strip().startswith("```"):
                buf.append(lines[i])
                i += 1
            i += 1  # 跳过结束围栏
            out.append("<pre><code>%s</code></pre>" % html.escape("\n".join(buf), quote=False))
            continue

        # 空行
        if stripped == "":
            i += 1
            continue

        # 分隔线
        if re.match(r"^(\*\s*){3,}$", stripped) or re.match(r"^(-\s*){3,}$", stripped) or re.match(r"^(_\s*){3,}$", stripped):
            out.append("<hr>")
            i += 1
            continue

        # 标题
        m = re.match(r"^(#{1,6})\s+(.*)$", stripped)
        if m:
            lvl = len(m.group(1))
            text = m.group(2).strip().rstrip("#").strip()
            out.append("<h%d>%s</h%d>" % (lvl, _inline(text), lvl))
            i += 1
            continue

        # 表格（当前行有 | 且下一行是分隔行）
        if "|" in line and i + 1 < n and _is_table_sep(lines[i + 1]):
            tbl = [line, lines[i + 1]]
            i += 2
            while i < n and "|" in lines[i] and lines[i].strip() != "":
                tbl.append(lines[i])
                i += 1
            out.append(_render_table(tbl))
            continue

        # 引用块
        if stripped.startswith(">"):
            buf = []
            while i < n and lines[i].strip().startswith(">"):
                buf.append(re.sub(r"^\s*>\s?", "", lines[i]))
                i += 1
            inner = md_to_html("\n".join(buf))
            out.append("<blockquote>%s</blockquote>" % inner)
            continue

        # 列表（无序 / 有序 / 任务清单），按缩进支持一层嵌套
        if re.match(r"^\s*([-*+]|\d+\.)\s+", line):
            items = []
            ordered = bool(re.match(r"^\s*\d+\.\s+", line))
            while i < n and re.match(r"^\s*([-*+]|\d+\.)\s+", lines[i]):
                raw = lines[i]
                indent = len(raw) - len(raw.lstrip(" "))
                content = re.sub(r"^\s*([-*+]|\d+\.)\s+", "", raw)
                # 任务清单复选框
                task = re.match(r"^\[([ xX])\]\s+(.*)$", content)
                if task:
                    checked = "checked" if task.group(1).lower() == "x" else ""
                    cls = "done" if checked else ""
                    body = '<label class="task %s"><input type="checkbox" disabled %s>%s</label>' % (
                        cls, checked, _inline(task.group(2)))
                else:
                    body = _inline(content)
                items.append((indent, body))
                i += 1
            out.append(_render_list(items, ordered))
            continue

        # 段落（合并连续普通行，遇到块级起始/空行停止）
        buf = [stripped]
        i += 1
        while i < n:
            nxt = lines[i]
            ns = nxt.strip()
            if ns == "" or ns.startswith("```") or ns.startswith("#") or ns.startswith(">") \
               or re.match(r"^\s*([-*+]|\d+\.)\s+", nxt) \
               or re.match(r"^(\*\s*){3,}$", ns) or re.match(r"^(-\s*){3,}$", ns):
                break
            if "|" in nxt and i + 1 < n and _is_table_sep(lines[i + 1]):
                break
            buf.append(ns)
            i += 1
        out.append("<p>%s</p>" % "<br>".join(_inline(b) for b in buf))
    return "\n".join(out)


def _render_list(items, ordered):
    """items: [(indent, html_body)]，按最小缩进为外层，更深缩进并入上一项的子列表。"""
    tag = "ol" if ordered else "ul"
    base = min(ind for ind, _ in items)
    html_out = ["<%s>" % tag]
    pending_children = []

    def flush_children():
        if pending_children:
            html_out.append("<ul>")
            for c in pending_children:
                html_out.append("<li>%s</li>" % c)
            html_out.append("</ul>")
            pending_children.clear()

    for idx, (ind, body) in enumerate(items):
        if ind > base:
            pending_children.append(body)
            continue
        # 新的顶层项：先把上一项的子项收尾
        if html_out[-1] != "<%s>" % tag:
            flush_children()
            html_out.append("</li>")
        html_out.append("<li>%s" % body)
    flush_children()
    if html_out[-1] != "<%s>" % tag:
        html_out.append("</li>")
    html_out.append("</%s>" % tag)
    return "".join(html_out)


# =====================================================================
# 站点模板
# =====================================================================

CSS = """
:root{
  --paper:#f3efe6; --paper2:#ece6d8; --ink:#2c2b28; --muted:#6f6a5f;
  --line:#d8d0bf; --blue:#5b6f7a; --blue-d:#3f5159; --gold:#c39a3e; --gold-d:#a87f24;
  --card:#fbf8f1; --shadow:0 1px 3px rgba(60,50,30,.12);
}
*{box-sizing:border-box}
body{margin:0;font-family:-apple-system,"Segoe UI","Microsoft YaHei",sans-serif;
  color:var(--ink);background:
    radial-gradient(140% 120% at 0% 0%, #f7f3ea 0%, var(--paper) 45%, var(--paper2) 100%);
  min-height:100vh;line-height:1.7;font-size:15px}
.layout{display:flex;min-height:100vh}
/* 侧边栏 */
.side{width:262px;flex:0 0 262px;position:sticky;top:0;height:100vh;overflow:auto;
  background:linear-gradient(180deg,#33414a,var(--blue-d));color:#e8e2d4;padding:22px 0 40px}
.side .brand{padding:0 22px 14px;border-bottom:1px solid rgba(255,255,255,.12);margin-bottom:10px}
.side .brand h1{font-family:"Noto Serif SC",Georgia,serif;font-size:19px;margin:0;color:#fff;letter-spacing:.5px}
.side .brand .sub{font-size:12px;color:#b9c4ca;margin-top:4px}
.side .grp{font-size:11px;letter-spacing:1px;color:#8fa0a8;text-transform:uppercase;
  padding:16px 22px 6px;margin-top:6px}
.side a{display:block;padding:7px 22px;color:#dcd6c8;text-decoration:none;font-size:14px;
  border-left:3px solid transparent}
.side a:hover{background:rgba(255,255,255,.06);color:#fff}
.side a.active{background:rgba(195,154,62,.18);border-left-color:var(--gold);color:#fff}
.side a .ico{opacity:.8;margin-right:7px}
/* 内容区 */
.main{flex:1;min-width:0;padding:38px 52px 80px;max-width:980px}
.content h1,.content h2,.content h3,.content h4{font-family:"Noto Serif SC",Georgia,serif;
  color:var(--blue-d);line-height:1.35}
.content h1{font-size:30px;border-bottom:2px solid var(--gold);padding-bottom:10px;display:inline-block}
.content h2{font-size:22px;margin-top:34px;border-bottom:1px solid var(--line);padding-bottom:6px}
.content h3{font-size:18px;margin-top:24px}
.content a{color:var(--gold-d)}
.content code{background:#efe9da;padding:1px 6px;border-radius:4px;font-size:13px;
  font-family:"Cascadia Code",Consolas,monospace}
.content pre{background:#2c3138;color:#e6e1d4;padding:14px 16px;border-radius:8px;overflow:auto}
.content pre code{background:none;color:inherit;padding:0}
.content blockquote{border-left:4px solid var(--gold);background:var(--card);margin:14px 0;
  padding:10px 18px;color:var(--muted);border-radius:0 6px 6px 0}
.content table{border-collapse:collapse;width:100%;margin:16px 0;background:var(--card);
  box-shadow:var(--shadow);border-radius:8px;overflow:hidden}
.content th,.content td{border:1px solid var(--line);padding:8px 12px;text-align:left}
.content th{background:#e7e0d0;font-weight:600}
.content hr{border:none;border-top:1px dashed var(--line);margin:26px 0}
.content ul,.content ol{padding-left:24px}
.content li{margin:4px 0}
.task{display:inline-flex;align-items:center;gap:8px}
.task input{width:15px;height:15px}
.task.done{color:var(--muted);text-decoration:line-through;text-decoration-color:var(--gold)}
/* 首页卡片 */
.hero{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:26px 30px;
  box-shadow:var(--shadow);margin-bottom:26px}
.hero h1{font-family:"Noto Serif SC",Georgia,serif;color:var(--blue-d);margin:.1em 0 .3em;font-size:28px}
.focus{background:linear-gradient(180deg,#fff8e8,#fdf1d4);border:1px solid #e7cf94;
  border-left:5px solid var(--gold);border-radius:8px;padding:14px 18px;margin:14px 0}
.focus .k{font-size:12px;letter-spacing:1px;color:var(--gold-d);text-transform:uppercase}
.snapshot{font-size:13px;color:var(--muted);margin-top:10px}
.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:16px;margin-top:8px}
.card{display:block;background:var(--card);border:1px solid var(--line);border-radius:12px;
  padding:16px 18px;text-decoration:none;color:var(--ink);box-shadow:var(--shadow);transition:.15s}
.card:hover{transform:translateY(-2px);border-color:var(--gold)}
.card .t{font-family:"Noto Serif SC",Georgia,serif;font-size:16px;color:var(--blue-d);margin-bottom:4px}
.card .d{font-size:12px;color:var(--muted)}
/* iframe 看板包裹 */
.dashwrap{position:fixed;inset:0 0 0 262px}
.dashbar{height:42px;display:flex;align-items:center;gap:14px;padding:0 18px;
  background:#e7e0d0;border-bottom:1px solid var(--line);font-size:13px}
.dashbar a{color:var(--gold-d);text-decoration:none}
.dashframe{width:100%;height:calc(100% - 42px);border:0;background:#fff}
.foot{margin-top:50px;padding-top:18px;border-top:1px solid var(--line);color:var(--muted);font-size:12px}
.en{display:inline-block;margin-left:6px;font-size:10px;line-height:1;padding:2px 5px;border-radius:4px;
  border:1px solid var(--gold);color:var(--gold-d);background:rgba(195,154,62,.12);vertical-align:middle}
.side a .en{border-color:rgba(255,255,255,.4);color:#e9d9a8;background:rgba(255,255,255,.08)}
"""


def page_shell(title, nav_html, body_html, active_rel, full_bleed=False):
    main_cls = "main" if not full_bleed else "main dashhost"
    return """<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title} · 角落垂钓</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Noto+Serif+SC:wght@500;700&display=swap" rel="stylesheet">
<style>{css}</style></head>
<body><div class="layout">
<nav class="side">{nav}</nav>
{body}
</div></body></html>""".format(title=html.escape(title), css=CSS, nav=nav_html, body=body_html)


def build_nav(sections, active_rel):
    parts = ['<div class="brand"><h1>🎣 角落垂钓</h1><div class="sub">项目信息门户 · 本地</div></div>']
    parts.append('<a class="%s" href="index.html"><span class="ico">🏠</span>首页 / 进展</a>' %
                 ("active" if active_rel == "__home__" else ""))
    parts.append('<a class="%s" href="audio.html"><span class="ico">🔊</span>音频试听</a>' %
                 ("active" if active_rel == "__audio__" else ""))
    for grp, entries in sections:
        if not entries:
            continue
        parts.append('<div class="grp">%s</div>' % html.escape(grp))
        for rel, title, out_name, is_dash, is_en in entries:
            ico = "📊" if is_dash else "📄"
            cls = "active" if rel == active_rel else ""
            badge = '<span class="en">EN</span>' if is_en else ""
            parts.append('<a class="%s" href="%s"><span class="ico">%s</span>%s%s</a>' %
                         (cls, out_name, ico, html.escape(title), badge))
    return "\n".join(parts)


def safe_name(rel):
    base = re.sub(r"[^0-9A-Za-z一-鿿]+", "_", rel).strip("_")
    return base.lower() if re.match(r"^[0-9A-Za-z]", base) else base


def discover(known_paths):
    """扫描仓库，返回未被 SECTIONS 收录的额外 .md/.html（归入「更多文档」）。"""
    extras = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".")]
        for fn in filenames:
            if not (fn.endswith(".md") or fn.endswith(".html")):
                continue
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, ROOT).replace("\\", "/")
            if rel in known_paths or rel.startswith("docs/site/"):
                continue
            extras.append(rel)
    extras.sort()
    return extras


def first_h1(md, fallback):
    for ln in md.split("\n"):
        m = re.match(r"^#\s+(.*)$", ln.strip())
        if m:
            return re.sub(r"[#*`]", "", m.group(1)).strip()
    return fallback


def extract_focus(roadmap_md):
    """从 ROADMAP.md 抽出『当前焦点』段与『数据快照』行，供首页 callout。"""
    focus_lines, snap = [], ""
    lines = roadmap_md.split("\n")
    grab = False
    for ln in lines:
        if "当前焦点" in ln and ln.strip().startswith("#"):
            grab = True
            continue
        if grab:
            if ln.strip().startswith("#") or ln.strip() == "---":
                grab = False
                continue
            if "数据快照" in ln:
                snap = re.sub(r"[*_`]", "", ln).strip()
            t = re.sub(r"^[>\-\s]+", "", ln).strip()
            if t and "数据快照" not in t:
                focus_lines.append(t)
    return focus_lines[:6], snap


# 中文占比阈值：低于此值视为「英文原稿」，分流到独立次级分区（不改源文件）。
# 取 0.15 可精准命中纯英文 design-ref 稿（实测 0~8%），而不误伤中英混排的
# README（~31%）、奇观工作台（~17%）等中文文档。
EN_THRESHOLD = 0.15


def zh_ratio(full_path):
    """估算文件中文占比（HTML 先粗略去标签）。读不到则当作中文(1.0)不分流。"""
    try:
        with open(full_path, encoding="utf-8", errors="ignore") as f:
            t = f.read()
    except Exception:
        return 1.0
    if full_path.lower().endswith(".html"):
        t = re.sub(r"(?is)<(script|style)\b.*?</\1>", " ", t)
        t = re.sub(r"<[^>]+>", " ", t)
    zh = len(re.findall(r"[一-鿿]", t))
    en = len(re.findall(r"[A-Za-z]", t))
    tot = zh + en
    return 1.0 if tot < 30 else zh / tot


# =====================================================================
# 音频试听页：读 audio_manifest.json，逐条带 <audio> 播放器；
# 另有「情景叠播」按钮，按 audio_manager.gd 的配方相对音量同时循环播放
# 对应层，让人在浏览器里听到游戏内实际的叠加混音。
# =====================================================================

ASSET_CN = {
    "ui_click": "界面点击", "ui_error": "无效操作", "cast": "抛竿", "bobber_splash": "浮漂入水",
    "bite": "咬钩", "catch_common": "普通上鱼", "catch_rare": "稀有上鱼", "coin": "金币入袋", "upgrade": "升级",
    "ambience_water_loop": "静水底噪", "amb_stream_loop": "溪流", "amb_birds_day": "林鸟·昼",
    "amb_wind_loop": "旷野风", "amb_night_insects": "夜虫", "amb_waves_loop": "海浪",
    "amb_gulls_day": "海鸥·昼", "amb_cave_drip": "洞穴滴水",
}
CAT_CN = [("ambience", "环境音床 Ambience"), ("fishing", "钓鱼 Fishing"),
          ("economy", "经济 Economy"), ("ui", "界面 UI")]

# (key, 显示名, {层id: 相对音量}) —— 镜像 audio_manager.gd 的 _ambience_recipe（含时段全局增益）
AUDIO_SCENES = [
    ("fresh_day", "河湾·白昼", {"ambience_water_loop": 0.8, "amb_birds_day": 0.55}),
    ("fresh_night", "河湾·夜晚", {"ambience_water_loop": 0.56, "amb_night_insects": 0.28}),
    ("stream_day", "山溪·白昼", {"amb_stream_loop": 0.9, "ambience_water_loop": 0.4, "amb_birds_day": 0.5}),
    ("lake_night", "湖泊·夜晚", {"ambience_water_loop": 0.49, "amb_wind_loop": 0.315, "amb_night_insects": 0.245}),
    ("polar_day", "极地·白昼", {"ambience_water_loop": 0.5, "amb_wind_loop": 0.7}),
    ("sea_day", "海岸·白昼", {"amb_waves_loop": 1.0, "ambience_water_loop": 0.25, "amb_gulls_day": 0.6}),
    ("sea_night", "深海·夜晚", {"amb_waves_loop": 0.7, "ambience_water_loop": 0.175}),
    ("cavern_day", "洞穴·白昼", {"amb_cave_drip": 0.9, "ambience_water_loop": 0.3}),
]

AUDIO_CSS = """
.agrid{display:grid;gap:12px;margin:14px 0 28px}
.arow{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:12px 14px;box-shadow:var(--shadow)}
.arow .aname{font-family:"Noto Serif SC",serif;font-size:15px;display:flex;align-items:center;gap:8px;flex-wrap:wrap}
.arow .cn{color:var(--blue-d);font-weight:700}
.arow .id{color:var(--muted);font-size:12px;font-family:Consolas,monospace}
.badge{font-size:10px;letter-spacing:.5px;padding:1px 7px;border-radius:20px}
.badge.loop{background:#e7f0e7;color:#3f6b3f;border:1px solid #bcd6bc}
.badge.dur{background:#efe9da;color:var(--muted)}
.arow .adesc{font-size:12px;color:var(--muted);margin:5px 0 9px;line-height:1.5}
.arow audio{width:100%;height:34px}
.scenebar{display:flex;flex-wrap:wrap;gap:10px;margin:14px 0 28px}
.scenebtn{background:var(--card);border:1px solid var(--line);border-radius:22px;padding:8px 16px;cursor:pointer;
  font-size:14px;color:var(--blue-d);font-family:"Noto Serif SC",serif;transition:.15s}
.scenebtn:hover{border-color:var(--gold)}
.scenebtn.on{background:linear-gradient(180deg,#fff8e8,#fdf1d4);border-color:var(--gold);color:var(--gold-d)}
.stopbtn{background:#f3e3e0;border:1px solid #dcb8b0;border-radius:22px;padding:8px 16px;cursor:pointer;font-size:14px;color:#a05040}
.stopbtn:hover{border-color:#a05040}
"""


def build_audio_page(nav):
    mpath = os.path.join(ROOT, "assets", "audio", "audio_manifest.json")
    manifest = {}
    if os.path.exists(mpath):
        with open(mpath, encoding="utf-8") as f:
            manifest = json.load(f)

    groups = {}
    for aid, e in manifest.items():
        rel = str(e.get("path", "")).replace("res://assets/audio/", "")
        cat = rel.split("/")[0] if "/" in rel else "other"
        groups.setdefault(cat, []).append((aid, e, "../../assets/audio/" + rel))

    btns = []
    for key, label, _layers in AUDIO_SCENES:
        btns.append('<button class="scenebtn" id="btn_%s" onclick="playScene(\'%s\')">%s</button>'
                    % (key, key, html.escape(label)))
    btns.append('<button class="stopbtn" onclick="stopScene()">⏹ 停止叠播</button>')
    scenebar = '<div class="scenebar">%s</div>' % "".join(btns)

    sections_html = []
    for cat, cat_label in CAT_CN:
        items = groups.get(cat, [])
        if not items:
            continue
        rows = []
        for aid, e, src in items:
            loop = bool(e.get("loop"))
            badges = '<span class="badge dur">%.1fs</span>' % float(e.get("duration_seconds", 0))
            if loop:
                badges += ' <span class="badge loop">LOOP</span>'
            rows.append(
                '<div class="arow"><div class="aname"><span class="cn">%s</span>'
                '<span class="id">%s</span>%s</div><div class="adesc">%s</div>'
                '<audio class="%s" id="a_%s" controls preload="none"%s src="%s"></audio></div>'
                % (html.escape(ASSET_CN.get(aid, "")), html.escape(aid), badges,
                   html.escape(str(e.get("description", ""))),
                   "amb" if cat == "ambience" else "sfx", html.escape(aid),
                   " loop" if loop else "", html.escape(src)))
        sections_html.append('<h2>%s</h2><div class="agrid">%s</div>' % (html.escape(cat_label), "".join(rows)))

    scenes_js = json.dumps({k: lay for k, _l, lay in AUDIO_SCENES}, ensure_ascii=False)
    script = ("<script>\nconst SCENES=" + scenes_js + ";\n"
              "function stopScene(){document.querySelectorAll('audio.amb').forEach(function(a){a.pause();a.currentTime=0;a.loop=false;});"
              "document.querySelectorAll('.scenebtn').forEach(function(b){b.classList.remove('on');});}\n"
              "function playScene(k){stopScene();var s=SCENES[k];for(var id in s){var a=document.getElementById('a_'+id);"
              "if(!a)continue;a.loop=true;a.volume=Math.min(1,s[id]);a.currentTime=0;a.play();}"
              "var b=document.getElementById('btn_'+k);if(b)b.classList.add('on');}\n</script>")

    intro = ('<p>点任意条目的 ▶ 播放，即可直接听到游戏里实际用的音频文件（与游戏内同一份无损 PCM）。'
             '环境音床均为无缝循环。</p>')
    scene_note = ('<p>游戏里按「钓点生态 × 时段」<strong>同时叠播多层</strong>，所以单听某个文件 ≠ 在场听感。'
                  '下面的情景按钮会按游戏配方的相对音量同时循环播放对应层——这就是你在游戏里实际听到的混音。</p>')
    main_html = ('<main class="main"><article class="content"><h1>🔊 音频试听</h1>' + intro
                 + '<style>' + AUDIO_CSS + '</style>'
                 + '<h2>情景叠播 · 还原在场混音</h2>' + scene_note + scenebar
                 + "".join(sections_html)
                 + '<div class="foot">数据源：assets/audio/audio_manifest.json · 本页由 tools/gen_site.py 生成，请勿手改</div>'
                 + '</article>' + script + '</main>')
    return page_shell("音频试听", nav, main_html, "__audio__")


def main():
    if os.path.isdir(OUT_DIR):
        shutil.rmtree(OUT_DIR)
    os.makedirs(OUT_DIR, exist_ok=True)

    # 1. 解析 SECTIONS -> 仅保留存在的文件，附带输出名/类型
    resolved = []
    known = set()
    for grp, entries in SECTIONS:
        items = []
        for rel, title in entries:
            full = os.path.join(ROOT, rel.replace("/", os.sep))
            if not os.path.exists(full):
                continue
            known.add(rel)
            is_dash = rel.endswith(".html")
            out_name = "dash_" + safe_name(rel) + ".html" if is_dash else safe_name(rel) + ".html"
            is_en = zh_ratio(full) < EN_THRESHOLD
            items.append((rel, title, out_name, is_dash, is_en))
        resolved.append((grp, items))

    # 2. 发现额外文档 -> 「更多文档」
    extras = discover(known)
    extra_items = []
    for rel in extras:
        full = os.path.join(ROOT, rel.replace("/", os.sep))
        is_dash = rel.endswith(".html")
        title = rel.split("/")[-1]
        if not is_dash:
            try:
                with open(full, encoding="utf-8") as f:
                    title = first_h1(f.read(), rel.split("/")[-1])
            except Exception:
                pass
        out_name = ("dash_" if is_dash else "") + safe_name(rel) + ".html"
        is_en = zh_ratio(full) < EN_THRESHOLD
        extra_items.append((rel, title, out_name, is_dash, is_en))
    if extra_items:
        resolved.append(("更多文档", extra_items))

    # 2.5 语言分流：把英文为主的条目从各分区抽出，集中到底部独立次级分区。
    #     —— 不改源文件，只调整门户的呈现归类，主区保持全中文。
    en_bucket = []
    zh_sections = []
    for grp, items in resolved:
        zh_items = [it for it in items if not it[4]]
        en_bucket += [it for it in items if it[4]]
        if zh_items:
            zh_sections.append((grp, zh_items))
    if en_bucket:
        en_bucket.sort(key=lambda it: it[0])
        zh_sections.append(("🌐 设计参考 · 英文原稿（移植用 · 未翻译）", en_bucket))
    resolved = zh_sections

    # 3. 逐篇生成
    count_md = count_dash = 0
    for grp, items in resolved:
        for rel, title, out_name, is_dash, is_en in items:
            full = os.path.join(ROOT, rel.replace("/", os.sep))
            nav = build_nav(resolved, rel)
            if is_dash:
                # iframe 包裹：把已有 HTML 看板收进同一套导航
                rel_to_src = os.path.relpath(full, OUT_DIR).replace("\\", "/")
                body = ('<div class="dashwrap">'
                        '<div class="dashbar"><strong>%s</strong>'
                        '<a href="%s" target="_blank">↗ 新标签打开原页</a></div>'
                        '<iframe class="dashframe" src="%s"></iframe></div>'
                        % (html.escape(title), html.escape(rel_to_src), html.escape(rel_to_src)))
                # 看板页用全屏布局（侧栏 + iframe）
                shell = """<!DOCTYPE html><html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>{t} · 角落垂钓</title>
<style>{css}</style></head><body><div class="layout"><nav class="side">{nav}</nav>{body}</div></body></html>""".format(
                    t=html.escape(title), css=CSS, nav=nav, body=body)
                with open(os.path.join(OUT_DIR, out_name), "w", encoding="utf-8") as f:
                    f.write(shell)
                count_dash += 1
            else:
                with open(full, encoding="utf-8") as f:
                    md = f.read()
                page_title = first_h1(md, title)
                content = '<article class="content">%s<div class="foot">源文件：%s · 本页由 tools/gen_site.py 生成，请勿手改</div></article>' % (
                    md_to_html(md), html.escape(rel))
                main_html = '<main class="main">%s</main>' % content
                with open(os.path.join(OUT_DIR, out_name), "w", encoding="utf-8") as f:
                    f.write(page_shell(page_title, nav, main_html, rel))
                count_md += 1

    # 4. 首页
    nav = build_nav(resolved, "__home__")
    focus_html = ""
    rm = os.path.join(ROOT, "ROADMAP.md")
    if os.path.exists(rm):
        with open(rm, encoding="utf-8") as f:
            fl, snap = extract_focus(f.read())
        if fl:
            focus_html = '<div class="focus"><div class="k">▶ 当前焦点</div>%s</div>' % \
                         "".join("<div>%s</div>" % _inline(x) for x in fl)
        if snap:
            focus_html += '<div class="snapshot">%s</div>' % _inline(snap)
    cards = []
    cards.append('<a class="card" href="audio.html"><div class="t">🔊 音频试听</div>'
                 '<div class="d">点播放听全部音效 / 环境音，并按游戏配方叠播还原在场混音</div></a>')
    for grp, items in resolved:
        for rel, title, out_name, is_dash, is_en in items:
            badge = '<span class="en">EN</span>' if is_en else ""
            cards.append('<a class="card" href="%s"><div class="t">%s %s%s</div><div class="d">%s</div></a>' %
                         (out_name, "📊" if is_dash else "📄", html.escape(title), badge, html.escape(rel)))
    hero = ('<div class="hero"><h1>🎣 角落垂钓 · 项目信息门户</h1>'
            '<p>把项目里零散的文档与看板汇总到一处。改完任意 MD 后重跑 '
            '<code>python tools/gen_site.py</code> 即可刷新本站。'
            '<br><span style="color:var(--muted);font-size:13px">'
            '中文产品/进展文档在上方核心分区；英文的 design-ref 设计原稿（移植用）统一收在底部 '
            '<strong>「🌐 设计参考」</strong> 分区，并标 <span class="en">EN</span> 角标。</span></p>%s</div>' % focus_html)
    body = '<main class="main">%s<h2 style="font-family:\'Noto Serif SC\',serif;color:var(--blue-d)">全部条目</h2><div class="cards">%s</div></main>' % (
        hero, "".join(cards))
    with open(os.path.join(OUT_DIR, "index.html"), "w", encoding="utf-8") as f:
        f.write(page_shell("首页", nav, body, "__home__"))

    # 5. 音频试听页（读 manifest，自带 <audio> 播放器 + 情景叠播）
    with open(os.path.join(OUT_DIR, "audio.html"), "w", encoding="utf-8") as f:
        f.write(build_audio_page(build_nav(resolved, "__audio__")))

    print("[gen_site] 完成：%d 篇文档页 + %d 个看板页 -> %s" %
          (count_md, count_dash, os.path.relpath(OUT_DIR, ROOT)))
    print("[gen_site] 打开 docs/site/index.html 即可浏览")


if __name__ == "__main__":
    main()
