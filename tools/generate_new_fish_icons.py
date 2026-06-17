from __future__ import annotations

import json
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
FISH_DIR = ROOT / "assets" / "art" / "fish"
SOURCE_DIR = FISH_DIR / "source"
MANIFEST_PATH = FISH_DIR / "fish_art_manifest.json"


FISH = [
    ("minnow", "slender", (142, 132, 96), (204, 190, 138), {"stripe": (78, 92, 70), "bars": 3}),
    ("zacco", "slender", (126, 136, 100), (214, 196, 148), {"stripe": (70, 88, 80), "orange_fin": True}),
    ("gudgeon", "loach", (138, 123, 93), (196, 180, 134), {"spots": (78, 68, 55), "barbels": True}),
    ("spined_loach", "eel", (150, 132, 92), (218, 196, 140), {"mottled": (86, 75, 60), "barbels": True}),
    ("ricefish", "tiny", (154, 164, 144), (224, 220, 190), {"clear": True}),
    ("paradisefish", "deep", (104, 126, 112), (184, 144, 120), {"bands": (128, 78, 68), "long_fins": True}),
    ("anchovy", "slender", (132, 150, 152), (220, 224, 206), {"silver": True}),
    ("halfbeak", "needle", (120, 146, 136), (218, 214, 188), {"beak": True}),
    ("sandlance", "needle", (116, 136, 118), (210, 206, 172), {"sand": True}),
    ("redeye", "standard", (124, 132, 96), (210, 190, 140), {"red_eye": True, "stripe": (80, 84, 58)}),
    ("wuchang", "deep", (132, 138, 116), (210, 202, 166), {"tall": True}),
    ("spotted_steed", "barbel", (142, 126, 88), (214, 190, 132), {"spots": (78, 66, 48), "barbels": True}),
    ("bigscale_loach", "loach", (130, 112, 76), (204, 178, 124), {"mottled": (72, 60, 42), "barbels": True}),
    ("yellowtail_fish", "standard", (128, 138, 108), (224, 198, 96), {"yellow_tail": True, "stripe": (88, 98, 72)}),
    ("yellow_drum", "croaker", (150, 132, 88), (226, 202, 126), {"gold": True}),
    ("greenling", "standard", (96, 124, 100), (180, 168, 122), {"mottled": (62, 88, 72), "bars": 5}),
    ("haarder", "mullet", (124, 138, 126), (214, 204, 172), {"stripe": (82, 98, 88)}),
    ("flathead_fish", "flathead", (118, 106, 82), (194, 170, 122), {"mottled": (66, 58, 44), "flat": True}),
    ("spinibarbus", "barbel", (118, 116, 82), (216, 190, 126), {"orange_fin": True, "barbels": True}),
    ("mongolian_redfin", "culter", (122, 138, 138), (220, 214, 184), {"red_fin": True}),
    ("small_snakehead", "snakehead", (86, 104, 72), (166, 150, 96), {"mottled": (50, 62, 42), "bars": 6}),
    ("yellowfin_seabream", "deep", (138, 142, 126), (224, 202, 118), {"yellow_fin": True, "bars": 4}),
    ("crimson_snapper", "deep", (166, 92, 78), (226, 156, 130), {"red": True}),
    ("spotted_scat", "disc", (128, 126, 90), (212, 188, 116), {"spots": (45, 55, 48), "yellow_fin": True}),
    ("octopus", "octopus", (126, 86, 72), (198, 144, 126), {}),
    ("squid", "squid", (128, 118, 112), (218, 204, 190), {}),
    ("cuttlefish", "cuttlefish", (124, 112, 96), (210, 190, 162), {"mottled": (82, 70, 58)}),
    ("chinese_sucker", "sucker", (150, 104, 86), (216, 168, 134), {"black_fins": True}),
    ("burbot", "eel", (92, 96, 72), (164, 150, 112), {"mottled": (48, 54, 42), "barbels": True}),
    ("manchurian_trout", "trout", (94, 116, 98), (194, 168, 124), {"spots": (48, 64, 54), "orange_spots": True}),
    ("amur_catfish", "catfish", (82, 86, 72), (158, 146, 112), {"barbels": True}),
    ("amberjack", "jack", (100, 126, 132), (214, 196, 112), {"yellow_tail": True, "stripe": (72, 86, 82)}),
    ("cobia", "cobia", (82, 98, 94), (184, 178, 148), {"stripe": (42, 54, 52)}),
    ("barramundi", "standard", (122, 138, 126), (218, 208, 166), {"silver": True}),
    ("miiuy_croaker", "croaker", (142, 122, 86), (218, 190, 122), {"gold": True}),
    ("mahseer", "barbel", (118, 108, 76), (216, 180, 106), {"gold": True, "barbels": True}),
    ("marbled_eel", "eel", (84, 96, 74), (168, 152, 110), {"mottled": (42, 50, 38)}),
    ("marlin", "billfish", (86, 112, 132), (196, 194, 170), {"bill": True, "sail": False}),
    ("giant_trevally", "jack", (92, 112, 118), (194, 188, 154), {"deep_head": True}),
    ("mahimahi", "mahimahi", (72, 142, 138), (218, 190, 86), {"yellow_tail": True}),
    ("swordfish", "billfish", (92, 118, 138), (206, 202, 178), {"bill": True, "sword": True}),
    ("wahoo", "needle", (78, 126, 142), (208, 204, 166), {"bars": 7}),
    ("paddlefish", "paddle", (118, 128, 126), (204, 198, 174), {}),
    ("coelacanth", "coelacanth", (68, 96, 112), (148, 154, 150), {"spots": (190, 188, 160)}),
    ("oarfish", "ribbon", (190, 182, 168), (228, 222, 204), {"red_fin": True}),
    ("whale_shark", "shark", (82, 108, 126), (184, 192, 188), {"spots": (214, 220, 206)}),
]

TIER_SHEETS = {
    "common": "assets/art/source/fish_sheets/tier0_common_sheet.png",
    "good": "assets/art/source/fish_sheets/tier1_good_sheet.png",
    "rare": "assets/art/source/fish_sheets/tier2_rare_sheet.png",
    "epic": "assets/art/source/fish_sheets/tier3_epic_sheet.png",
    "legend": "assets/art/source/fish_sheets/tier4_5_legend_myth_sheet.png",
    "myth": "assets/art/source/fish_sheets/tier4_5_legend_myth_sheet.png",
}

TEMPLATE_BY_ID = {
    "minnow": "whitebait",
    "zacco": "dace",
    "gudgeon": "loach",
    "spined_loach": "loach",
    "ricefish": "whitebait",
    "paradisefish": "bream",
    "anchovy": "whitebait",
    "halfbeak": "whitebait",
    "sandlance": "whitebait",
    "redeye": "grass",
    "wuchang": "bream",
    "spotted_steed": "barbel",
    "bigscale_loach": "loach",
    "yellowtail_fish": "grass",
    "yellow_drum": "bream",
    "greenling": "bass",
    "haarder": "grass",
    "flathead_fish": "snakehead",
    "spinibarbus": "barbel",
    "mongolian_redfin": "culter",
    "small_snakehead": "snakehead",
    "yellowfin_seabream": "bream",
    "crimson_snapper": "bream",
    "spotted_scat": "fangbream",
    "chinese_sucker": "longsnout",
    "burbot": "loach",
    "manchurian_trout": "trout",
    "amur_catfish": "longsnout",
    "amberjack": "salmon",
    "cobia": "pike",
    "barramundi": "bass",
    "miiuy_croaker": "bream",
    "mahseer": "barbel",
    "marbled_eel": "loach",
    "marlin": "pike",
    "giant_trevally": "bass",
    "mahimahi": "taimen",
    "swordfish": "pike",
    "wahoo": "pike",
    "paddlefish": "sturgeon",
    "coelacanth": "mandarin",
    "oarfish": "loach",
    "whale_shark": "kaluga",
}


def tier_for(index: int) -> str:
    if index < 9:
        return "common"
    if index < 18:
        return "good"
    if index < 27:
        return "rare"
    if index < 35:
        return "epic"
    if index < 42:
        return "legend"
    return "myth"


def rgba(c, a):
    return (*c, a)


def mix(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))


def colorize_template(template_id, dark, light, kind):
    src = Image.open(SOURCE_DIR / f"{template_id}.png").convert("RGBA")
    pix = src.load()
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    dst = out.load()
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = pix[x, y]
            if a == 0:
                continue
            lum = (r * 0.299 + g * 0.587 + b * 0.114) / 255.0
            shade = max(0.0, min(1.0, 1.0 - lum))
            base = mix(light, dark, 0.18 + shade * 0.78)
            # Keep a whisper of the source hue so the original watercolor
            # granulation and edge warmth survive the recolor.
            base = mix(base, (r, g, b), 0.16)
            dst[x, y] = (*base, a)

    if kind == "ribbon":
        bbox = out.getbbox()
        crop = out.crop(bbox)
        crop = crop.resize((112, 18), Image.Resampling.LANCZOS)
        ribbon = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        ribbon.alpha_composite(crop, (8, 55))
        out = ribbon
    elif kind in {"needle", "billfish"}:
        bbox = out.getbbox()
        crop = out.crop(bbox)
        crop = crop.resize((104, 35), Image.Resampling.LANCZOS)
        slim = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        slim.alpha_composite(crop, (8, 46))
        out = slim
    elif kind == "eel":
        bbox = out.getbbox()
        crop = out.crop(bbox)
        crop = crop.resize((112, 29), Image.Resampling.LANCZOS)
        eel = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        eel.alpha_composite(crop, (7, 49))
        out = eel
    return out


def draw_template_details(img, fish_id, kind, dark, light, flags):
    rng = random.Random(f"{fish_id}-details")
    bbox = img.getbbox() or (6, 34, 122, 94)
    x0, top, x1, bottom = bbox
    cy = (top + bottom) / 2
    d = ImageDraw.Draw(img, "RGBA")
    add_marks(img, kind, x0, top, x1, bottom, dark, light, rng, flags)
    if flags.get("yellow_tail"):
        draw_soft_poly(img, [(x0, cy), (x0 + 22, top + 4), (x0 + 23, bottom - 5)], rgba((218, 178, 68), 75), 0.45)
    if flags.get("yellow_fin"):
        draw_soft_poly(img, [(x0 + 58, bottom - 5), (x0 + 75, bottom + 12), (x0 + 86, bottom - 7)], rgba((218, 178, 68), 70), 0.45)
    if flags.get("orange_fin") or flags.get("red_fin"):
        draw_soft_poly(img, [(x0 + 58, bottom - 5), (x0 + 75, bottom + 10), (x0 + 86, bottom - 7)], rgba((166, 88, 58), 72), 0.45)
    if flags.get("red_eye"):
        draw_soft_ellipse(img, (x1 - 28, cy - 10, x1 - 24, cy - 6), rgba((134, 54, 44), 155), 0.1)
    if flags.get("barbels"):
        d.line([(x1 - 8, cy + 7), (x1 + 5, cy + 11)], fill=rgba(dark, 78), width=1)
        d.line([(x1 - 10, cy + 9), (x1 + 2, cy + 15)], fill=rgba(dark, 58), width=1)
    if flags.get("bill"):
        length = 29 if flags.get("sword") else 23
        d.line([(x1 - 12, cy - 2), (min(126, x1 + length), cy - 6)], fill=rgba(dark, 130), width=3)
    if flags.get("beak"):
        d.line([(x1 - 8, cy), (min(126, x1 + 18), cy - 1)], fill=rgba(dark, 105), width=2)
    if fish_id == "paddlefish":
        draw_soft_poly(img, [(x1 - 7, cy - 5), (126, cy - 12), (127, cy - 4), (x1 - 3, cy + 5)], rgba(mix(dark, light, .35), 110), 0.35)
    if fish_id == "oarfish":
        d.line([(x0 + 10, cy - 1), (x1 - 6, cy - 2)], fill=rgba((126, 118, 112), 70), width=1)
        draw_soft_poly(img, [(24, top + 3), (70, top - 8), (108, top + 2), (92, top + 7), (48, top + 7)], rgba((174, 78, 66), 100), 0.55)
    if fish_id == "coelacanth":
        for px, py in [(x0 + 36, bottom - 4), (x0 + 66, bottom - 5), (x0 + 75, top + 5)]:
            draw_soft_ellipse(img, (px - 8, py - 5, px + 8, py + 6), rgba(mix(dark, light, .35), 80), 0.55)
    if fish_id == "whale_shark":
        for _ in range(32):
            x = rng.uniform(x0 + 25, x1 - 20)
            y = rng.uniform(top + 8, cy + 3)
            draw_soft_ellipse(img, (x - 1.4, y - 1.4, x + 1.4, y + 1.4), rgba((214, 220, 206), 95), 0.2)
    return img


def draw_soft_poly(layer, pts, fill, blur=0.45):
    tmp = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(tmp, "RGBA")
    d.polygon(pts, fill=fill)
    if blur:
        tmp = tmp.filter(ImageFilter.GaussianBlur(blur))
    layer.alpha_composite(tmp)


def draw_soft_ellipse(layer, box, fill, blur=0.45):
    tmp = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(tmp, "RGBA")
    d.ellipse(box, fill=fill)
    if blur:
        tmp = tmp.filter(ImageFilter.GaussianBlur(blur))
    layer.alpha_composite(tmp)


def jitter_points(points, rng, amount):
    return [(x + rng.uniform(-amount, amount), y + rng.uniform(-amount, amount)) for x, y in points]


def base_profile(kind):
    profiles = {
        "tiny": (9, 34, 119, 63, 26),
        "slender": (7, 31, 120, 65, 32),
        "needle": (6, 28, 122, 62, 24),
        "standard": (7, 24, 121, 71, 42),
        "deep": (10, 20, 118, 78, 54),
        "disc": (18, 15, 113, 83, 64),
        "mullet": (7, 25, 121, 70, 40),
        "croaker": (9, 23, 119, 74, 44),
        "barbel": (7, 25, 120, 72, 42),
        "culter": (6, 23, 121, 67, 38),
        "loach": (6, 34, 120, 67, 27),
        "eel": (5, 34, 122, 66, 25),
        "snakehead": (6, 28, 121, 70, 34),
        "trout": (6, 24, 121, 70, 40),
        "catfish": (5, 28, 122, 72, 35),
        "jack": (7, 19, 121, 76, 52),
        "cobia": (7, 25, 121, 69, 38),
        "flathead": (5, 30, 122, 74, 32),
        "sucker": (8, 21, 119, 76, 52),
        "billfish": (3, 22, 124, 70, 36),
        "mahimahi": (5, 16, 122, 73, 50),
        "paddle": (3, 25, 122, 69, 38),
        "coelacanth": (6, 19, 121, 78, 52),
        "ribbon": (3, 41, 124, 60, 16),
        "shark": (5, 18, 123, 79, 55),
    }
    return profiles.get(kind, profiles["standard"])


def body_polygon(kind, x0, top, x1, bottom, rng):
    cy = (top + bottom) / 2
    h = bottom - top
    head = x1 - h * (0.34 if kind in {"deep", "disc", "jack", "shark"} else 0.25)
    tail = x0 + h * 0.25
    if kind == "ribbon":
        pts = [(x0 + 8, cy - 6), (x1 - 9, cy - 8), (x1, cy - 2), (x1 - 6, cy + 6), (x0 + 7, cy + 5)]
    elif kind == "flathead":
        pts = [(tail, cy - h * .32), (x1 - 22, top + 3), (x1, cy - 5), (x1 - 2, cy + 10), (x1 - 24, bottom - 4), (tail, cy + h * .28)]
    elif kind in {"eel", "loach"}:
        pts = [(tail, cy - h * .33), (x1 - 18, cy - h * .44), (x1, cy - h * .08), (x1 - 12, cy + h * .36), (tail, cy + h * .30), (x0 + 8, cy + h * .12)]
    elif kind == "paddle":
        pts = [(tail, cy - h * .34), (x1 - 28, top + 5), (x1 - 8, cy - h * .18), (x1 - 2, cy + h * .18), (x1 - 31, bottom - 6), (tail, cy + h * .32)]
    elif kind in {"billfish", "needle"}:
        pts = [(tail, cy - h * .35), (x1 - 20, cy - h * .42), (x1 - 5, cy - h * .12), (x1 - 13, cy + h * .28), (tail, cy + h * .30), (x0 + 13, cy + h * .08)]
    elif kind == "shark":
        pts = [(tail, cy - h * .28), (x1 - 27, top + 5), (x1 - 3, cy - 2), (x1 - 25, bottom - 5), (tail, cy + h * .27), (x0 + 8, cy + 1)]
    else:
        pts = [(tail, cy - h * .40), (head, top + 2), (x1, cy - h * .06), (head, bottom - 3), (tail, cy + h * .36), (x0 + 11, cy)]
    return jitter_points(pts, rng, 1.1)


def draw_fins(img, kind, x0, top, x1, bottom, dark, accent, rng, flags):
    d = ImageDraw.Draw(img, "RGBA")
    cy = (top + bottom) / 2
    h = bottom - top
    tail_x = x0 + h * 0.22
    # Tail.
    tail = [(x0 + 2, cy), (tail_x + 2, cy - h * .35), (tail_x + 6, cy - h * .05), (tail_x + 2, cy + h * .33)]
    draw_soft_poly(img, jitter_points(tail, rng, 1), rgba(accent, 112), 0.35)
    # Dorsal and pelvic fins.
    dorsal_h = h * (.42 if kind in {"mahimahi", "billfish", "shark"} else .25)
    if kind != "ribbon":
        dorsal = [(x0 + 45, top + 5), (x0 + 62, top - dorsal_h * .35), (x0 + 82, top + 7)]
        draw_soft_poly(img, jitter_points(dorsal, rng, 1), rgba(mix(dark, accent, .25), 80), 0.45)
    pelvic = [(x0 + 61, bottom - 4), (x0 + 76, bottom + h * .23), (x0 + 85, bottom - 7)]
    draw_soft_poly(img, jitter_points(pelvic, rng, 1), rgba(mix(dark, accent, .35), 78), 0.45)
    pectoral = [(x1 - 35, cy + 3), (x1 - 48, cy + h * .30), (x1 - 26, cy + h * .14)]
    draw_soft_poly(img, jitter_points(pectoral, rng, 1), rgba(mix(dark, accent, .45), 78), 0.4)
    if flags.get("long_fins"):
        draw_soft_poly(img, [(64, bottom - 2), (76, bottom + 20), (89, bottom - 4)], rgba(accent, 72), 0.6)
    if flags.get("red_fin"):
        draw_soft_poly(img, [(34, top + 2), (68, top - 8), (104, top + 2), (93, top + 8), (54, top + 7)], rgba((166, 75, 64), 105), 0.5)


def add_marks(img, kind, x0, top, x1, bottom, dark, light, rng, flags):
    d = ImageDraw.Draw(img, "RGBA")
    cy = (top + bottom) / 2
    h = bottom - top
    if flags.get("stripe"):
        y = cy - h * .05
        d.line([(x0 + 20, y), (x1 - 14, y + rng.uniform(-2, 2))], fill=rgba(flags["stripe"], 82), width=3)
    if flags.get("bars"):
        for i in range(flags["bars"]):
            x = x0 + 31 + i * ((x1 - x0 - 48) / max(flags["bars"] - 1, 1))
            d.line([(x, top + 6), (x + rng.uniform(-3, 3), bottom - 6)], fill=rgba(dark, 52), width=3)
    if flags.get("bands"):
        for x in [42, 56, 70, 84]:
            d.line([(x, top + 5), (x + 4, bottom - 5)], fill=rgba(flags["bands"], 70), width=4)
    spot_color = flags.get("spots")
    if spot_color:
        for _ in range(18 if kind in {"coelacanth", "shark"} else 10):
            x = rng.uniform(x0 + 32, x1 - 26)
            y = rng.uniform(top + 8, bottom - 8)
            r = rng.uniform(1.0, 2.3)
            draw_soft_ellipse(img, (x - r, y - r, x + r, y + r), rgba(spot_color, 92), 0.25)
    if flags.get("mottled"):
        c = flags["mottled"]
        for _ in range(22):
            x = rng.uniform(x0 + 20, x1 - 18)
            y = rng.uniform(top + 5, bottom - 5)
            rx = rng.uniform(2, 6)
            ry = rng.uniform(1, 3)
            draw_soft_ellipse(img, (x - rx, y - ry, x + rx, y + ry), rgba(c, 32), 0.7)
    if flags.get("orange_spots"):
        for _ in range(6):
            x = rng.uniform(x0 + 38, x1 - 34)
            y = rng.uniform(cy, bottom - 6)
            draw_soft_ellipse(img, (x - 1.4, y - 1.4, x + 1.4, y + 1.4), rgba((174, 94, 62), 96), 0.2)
    if flags.get("silver"):
        d.line([(x0 + 28, cy + 2), (x1 - 18, cy + 1)], fill=rgba((230, 232, 218), 80), width=2)


def draw_head_details(img, kind, x1, top, bottom, dark, rng, flags):
    d = ImageDraw.Draw(img, "RGBA")
    cy = (top + bottom) / 2
    eye = (x1 - (18 if kind not in {"needle", "billfish", "paddle"} else 24), cy - (bottom - top) * .16)
    eye_fill = (134, 62, 48) if flags.get("red_eye") else (46, 43, 36)
    draw_soft_ellipse(img, (eye[0] - 1.7, eye[1] - 1.7, eye[0] + 1.7, eye[1] + 1.7), rgba(eye_fill, 150), 0.15)
    d.arc((x1 - 18, cy - 5, x1 - 4, cy + 8), 205, 295, fill=rgba(dark, 58), width=1)
    if flags.get("barbels"):
        d.line([(x1 - 7, cy + 5), (x1 + 5, cy + 9), (x1 + 12, cy + 8)], fill=rgba(dark, 78), width=1)
        d.line([(x1 - 10, cy + 7), (x1 + 3, cy + 13), (x1 + 8, cy + 15)], fill=rgba(dark, 58), width=1)
    if flags.get("beak"):
        d.line([(x1 - 4, cy + 2), (x1 + 18, cy + 1)], fill=rgba(dark, 96), width=2)
    if flags.get("bill"):
        d.line([(x1 - 7, cy - 1), (x1 + (22 if flags.get("sword") else 18), cy - 4)], fill=rgba(dark, 122), width=3)
    if kind == "paddle":
        draw_soft_poly(img, [(x1 - 5, cy - 4), (x1 + 24, cy - 10), (x1 + 28, cy - 3), (x1 + 3, cy + 5)], rgba(mix(dark, (220, 216, 194), .35), 96), 0.35)


def draw_cephalopod(img, kind, dark, light, rng, flags):
    d = ImageDraw.Draw(img, "RGBA")
    if kind == "octopus":
        draw_soft_ellipse(img, (54, 24, 99, 69), rgba(light, 116), 0.8)
        draw_soft_ellipse(img, (61, 28, 95, 64), rgba(dark, 72), 1.0)
        bases = [58, 64, 70, 76, 82]
        for i, y in enumerate(bases):
            pts = [(72, y), (43 - i * 4, 81 + (i % 2) * 8), (22 + i * 8, 88 + i), (48 + i * 3, 72)]
            d.line(pts, fill=rgba(dark, 95), width=5, joint="curve")
            d.line(pts, fill=rgba(light, 70), width=3, joint="curve")
        draw_soft_ellipse(img, (83, 43, 87, 47), rgba((42, 36, 32), 140), 0.1)
    elif kind == "squid":
        draw_soft_poly(img, [(14, 43), (78, 21), (104, 49), (78, 77)], rgba(light, 112), 0.8)
        draw_soft_poly(img, [(16, 43), (43, 31), (43, 57)], rgba(dark, 72), 0.8)
        draw_soft_poly(img, [(77, 38), (114, 32), (87, 47)], rgba(dark, 80), 0.35)
        draw_soft_poly(img, [(78, 57), (114, 68), (87, 52)], rgba(dark, 72), 0.35)
        for off in [-8, -3, 2, 7]:
            d.line([(98, 48), (121, 48 + off)], fill=rgba(dark, 82), width=2)
        draw_soft_ellipse(img, (88, 42, 92, 46), rgba((42, 36, 34), 130), 0.1)
    else:
        draw_soft_ellipse(img, (18, 29, 90, 70), rgba(light, 112), 0.8)
        draw_soft_ellipse(img, (24, 34, 84, 66), rgba(dark, 54), 1.1)
        draw_soft_poly(img, [(20, 48), (9, 31), (23, 35)], rgba(dark, 58), 0.6)
        draw_soft_poly(img, [(20, 51), (9, 70), (24, 64)], rgba(dark, 58), 0.6)
        for off in [-8, -3, 2, 7]:
            d.line([(89, 50), (119, 50 + off)], fill=rgba(dark, 78), width=2)
        add_marks(img, kind, 18, 29, 92, 70, dark, light, rng, flags)
        draw_soft_ellipse(img, (83, 42, 87, 46), rgba((42, 36, 34), 130), 0.1)


def draw_icon(fish_id, kind, dark, light, flags):
    rng = random.Random(fish_id)
    scale = 4
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    if kind in {"octopus", "squid", "cuttlefish"}:
        draw_cephalopod(img, kind, dark, light, rng, flags)
        ink = img.filter(ImageFilter.GaussianBlur(0.35))
        img = Image.alpha_composite(ink, img)
        return img
    if fish_id in TEMPLATE_BY_ID:
        template = colorize_template(TEMPLATE_BY_ID[fish_id], dark, light, kind)
        return draw_template_details(template, fish_id, kind, dark, light, flags)

    x0, top, x1, bottom, _ = base_profile(kind)
    cy = (top + bottom) / 2
    accent = light
    if flags.get("yellow_tail") or flags.get("yellow_fin"):
        accent = (214, 180, 80)
    if flags.get("orange_fin") or flags.get("red_fin"):
        accent = (166, 92, 62)
    if flags.get("black_fins"):
        accent = (54, 50, 46)
    body = body_polygon(kind, x0, top, x1, bottom, rng)

    draw_fins(img, kind, x0, top, x1, bottom, dark, accent, rng, flags)

    # A translucent rounded core keeps the silhouettes close to the original
    # hand-painted fish icons while the polygon gives each species its profile.
    core_top = top + (2 if kind not in {"ribbon", "needle", "eel", "loach"} else 4)
    core_bottom = bottom - (2 if kind not in {"ribbon", "needle", "eel", "loach"} else 4)
    if kind == "ribbon":
        draw_soft_ellipse(img, (x0 + 9, cy - 5, x1 - 7, cy + 6), rgba(mix(light, dark, .16), 92), 0.75)
    elif kind in {"eel", "loach", "needle", "billfish"}:
        draw_soft_ellipse(img, (x0 + 15, core_top, x1 - 11, core_bottom), rgba(mix(light, dark, .18), 96), 0.8)
        draw_soft_ellipse(img, (x1 - 32, top + 5, x1 - 4, bottom - 5), rgba(mix(light, dark, .24), 92), 0.65)
    elif kind == "flathead":
        draw_soft_ellipse(img, (x0 + 24, top + 3, x1 - 6, bottom - 2), rgba(mix(light, dark, .20), 98), 0.8)
        draw_soft_ellipse(img, (x1 - 39, top + 1, x1 - 2, bottom + 1), rgba(mix(light, dark, .28), 104), 0.7)
    else:
        draw_soft_ellipse(img, (x0 + 20, core_top, x1 - 8, core_bottom), rgba(mix(light, dark, .18), 104), 0.85)
        draw_soft_ellipse(img, (x1 - 36, top + 4, x1 - 3, bottom - 4), rgba(mix(light, dark, .24), 96), 0.65)

    for i in range(5):
        t = i / 4
        color = mix(light, dark, 0.18 + 0.16 * t)
        pts = jitter_points(body, rng, 1.25 + i * 0.45)
        draw_soft_poly(img, pts, rgba(color, 68), 0.95 + i * 0.08)
    draw_soft_poly(img, body, rgba(mix(light, dark, .22), 124), 0.55)

    # Subtle belly wash.
    belly = [(x0 + 22, cy + 1), (x1 - 25, cy + 2), (x1 - 33, bottom - 6), (x0 + 28, bottom - 5)]
    draw_soft_poly(img, jitter_points(belly, rng, 1), rgba(mix(light, (236, 230, 204), .55), 50), 0.8)

    if kind == "mahimahi":
        draw_soft_poly(img, [(54, top + 5), (88, top - 6), (107, top + 10), (71, top + 11)], rgba((74, 130, 126), 88), 0.55)
    if kind == "coelacanth":
        for px, py in [(43, 79), (72, 80), (81, 27), (34, 29)]:
            draw_soft_ellipse(img, (px - 8, py - 5, px + 8, py + 6), rgba(mix(dark, light, .35), 70), 0.55)
    if kind == "ribbon":
        d = ImageDraw.Draw(img, "RGBA")
        d.line([(x0 + 13, cy), (x1 - 8, cy - 2)], fill=rgba((118, 118, 112), 70), width=1)
        for x in range(30, 108, 13):
            d.line([(x, top + 1), (x + 4, bottom - 1)], fill=rgba((162, 74, 64), 48), width=1)
    if kind == "shark":
        for _ in range(24):
            x = rng.uniform(31, 102)
            y = rng.uniform(top + 8, cy + 2)
            draw_soft_ellipse(img, (x - 1.2, y - 1.2, x + 1.2, y + 1.2), rgba(flags["spots"], 88), 0.2)

    add_marks(img, kind, x0, top, x1, bottom, dark, light, rng, flags)
    draw_head_details(img, kind, x1, top, bottom, dark, rng, flags)

    # A soft ink edge, more wash than outline.
    edge = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw_soft_poly(edge, body, rgba((46, 42, 35), 34), 0.2)
    edge = edge.filter(ImageFilter.FIND_EDGES).filter(ImageFilter.GaussianBlur(0.35))
    img = Image.alpha_composite(edge, img)

    if scale != 1:
        pass
    return img


def trim_and_center(im: Image.Image, size: int = 128, target: float = 0.86) -> Image.Image:
    bbox = im.getbbox()
    if not bbox:
        return im
    crop = im.crop(bbox)
    w, h = crop.size
    max_dim = max(w, h)
    desired = int(size * target)
    if max_dim != desired:
        ratio = desired / max_dim
        crop = crop.resize((max(1, int(w * ratio)), max(1, int(h * ratio))), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.alpha_composite(crop, ((size - crop.size[0]) // 2, (size - crop.size[1]) // 2))
    return out


def update_manifest():
    data = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    by_id = {entry["id"]: entry for entry in data}
    for index, (fish_id, *_rest) in enumerate(FISH):
        tier = tier_for(index)
        by_id[fish_id] = {
            "id": fish_id,
            "runtime": f"assets/art/fish/{fish_id}.png",
            "source": f"assets/art/fish/source/{fish_id}.png",
            "sheet": TIER_SHEETS[tier],
        }
    existing_order = [entry["id"] for entry in data]
    new_order = [fish_id for fish_id, *_ in FISH if fish_id not in existing_order]
    ordered = [by_id[fish_id] for fish_id in existing_order if fish_id in by_id]
    ordered.extend(by_id[fish_id] for fish_id in new_order)
    MANIFEST_PATH.write_text(json.dumps(ordered, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main():
    write_production = "--write-production" in sys.argv
    out_fish_dir = FISH_DIR if write_production else FISH_DIR / "wip"
    out_source_dir = SOURCE_DIR if write_production else FISH_DIR / "wip" / "source"
    out_source_dir.mkdir(parents=True, exist_ok=True)
    out_fish_dir.mkdir(parents=True, exist_ok=True)
    for fish_id, kind, dark, light, flags in FISH:
        source = trim_and_center(draw_icon(fish_id, kind, dark, light, flags), 128, 0.86)
        runtime = source.resize((64, 64), Image.Resampling.LANCZOS)
        source.save(out_source_dir / f"{fish_id}.png")
        runtime.save(out_fish_dir / f"{fish_id}.png")
    if write_production:
        update_manifest()
        print(f"Generated {len(FISH)} production fish icons.")
    else:
        print(f"Generated {len(FISH)} WIP fish icons under {out_fish_dir}.")
        print("Review against docs/fish_icon_art_standard.md before copying to production paths.")


if __name__ == "__main__":
    main()
