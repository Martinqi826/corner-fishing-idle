#!/usr/bin/env python3
# 从 Wikimedia 抓鱼的代表照片 —— 仅收可商用授权（PD/CC0/CC-BY/CC-BY-SA），排除 NC/ND。
# 输出：assets/art/fish_photos/<id>.jpg + CREDITS.json（署名/授权清单，CC-BY 合规必备）。
import urllib.request, urllib.parse, json, os, re, sys

UA = "CornerFishingGame/1.0 (game dex; martinqi826@gmail.com)"
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "art", "fish_photos")
os.makedirs(OUT, exist_ok=True)

# id -> (中文名, 学名/英文维基条目)
BATCH = {
    "carp":             ("鲤鱼",   "Cyprinus carpio"),
    "grass":            ("草鱼",   "Ctenopharyngodon idella"),
    "crucian":          ("鲫鱼",   "Carassius carassius"),
    "blackcarp":        ("青鱼",   "Mylopharyngodon piceus"),
    "catfish":          ("鲇鱼",   "Silurus asotus"),
    "snakehead":        ("乌鳢",   "Channa argus"),
    "chinese_sturgeon": ("中华鲟", "Acipenser sinensis"),
    "koi":              ("锦鲤",   "Koi"),
    "perch":            ("河鲈",   "Perca fluviatilis"),
    "tuna":             ("金枪鱼", "Thunnus"),
}

def api(host, params):
    params["format"] = "json"
    url = "https://%s/w/api.php?%s" % (host, urllib.parse.urlencode(params))
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)

def rest_lead_url(host, title):
    url = "https://%s/api/rest_v1/page/summary/%s" % (host, urllib.parse.quote(title.replace(" ", "_")))
    try:
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=30) as r:
            d = json.load(r)
    except Exception:
        return None
    img = d.get("originalimage") or d.get("thumbnail")
    return img.get("source") if img else None

def commons_filename(u):
    parts = urllib.parse.urlparse(u).path.split("/")
    name = parts[-2] if "thumb" in parts else parts[-1]
    return urllib.parse.unquote(name)

def lead_file(title, cn):
    # 先英文维基(学名)，再中文维基(中文名)兜底
    for host, t in (("en.wikipedia.org", title), ("zh.wikipedia.org", cn)):
        u = rest_lead_url(host, t)
        if u:
            return commons_filename(u)
    return None

def strip(html):
    return re.sub(r"<[^>]+>", "", html or "").strip()

def fileinfo(fname):
    d = api("commons.wikimedia.org", {"action": "query", "prop": "imageinfo",
            "titles": "File:" + fname, "iiprop": "extmetadata|url", "iiurlwidth": "560"})
    pages = d.get("query", {}).get("pages", {})
    for _, p in pages.items():
        ii = p.get("imageinfo")
        if ii:
            return ii[0]
    return None

def lic_ok(lic):
    l = (lic or "").lower()
    if not l: return False
    if "nc" in l or "nd" in l or "non-free" in l or "fair" in l: return False
    return ("cc-by" in l) or ("cc0" in l) or l == "pd" or "public" in l

credits = {}
report = []
for fid, (cn, title) in BATCH.items():
    try:
        fn = lead_file(title, cn)
        if not fn:
            report.append((fid, cn, "无维基代表图", "")); continue
        info = fileinfo(fn)
        em = info.get("extmetadata", {})
        lic = em.get("LicenseShortName", {}).get("value", "") or em.get("License", {}).get("value", "")
        artist = strip(em.get("Artist", {}).get("value", "")) or "（未署名）"
        licurl = em.get("LicenseUrl", {}).get("value", "")
        if not lic_ok(em.get("License", {}).get("value", "") or lic):
            report.append((fid, cn, "授权不可商用：" + lic, fn)); continue
        thumb = info.get("thumburl") or info.get("url")
        dst = os.path.join(OUT, fid + ".jpg")
        req = urllib.request.Request(thumb, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=40) as r, open(dst, "wb") as f:
            f.write(r.read())
        sz = os.path.getsize(dst)
        credits[fid] = {"cn": cn, "file": fn, "license": lic, "author": artist,
                        "license_url": licurl, "source": "Wikimedia Commons"}
        report.append((fid, cn, "OK %s (%d KB)" % (lic, sz // 1024), fn))
    except Exception as e:
        report.append((fid, cn, "错误：" + str(e)[:60], ""))

with open(os.path.join(OUT, "CREDITS.json"), "w", encoding="utf-8") as f:
    json.dump(credits, f, ensure_ascii=False, indent=2)

print("=== 采集结果 ===")
for fid, cn, status, fn in report:
    print("  %-18s %-6s %s" % (fid, cn, status))
print("成功 %d / %d 条；CREDITS.json 已写。" % (len(credits), len(BATCH)))
