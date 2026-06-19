from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

import generate_new_fish_icons as base


ROOT = Path(__file__).resolve().parents[1]
FISH_DIR = ROOT / "assets" / "art" / "fish"
SOURCE_DIR = FISH_DIR / "source"
OUT_DIR = FISH_DIR / "wip" / "v3_template_v1"
OUT_SOURCE_DIR = OUT_DIR / "source"
DOC_IMG_DIR = ROOT / "docs" / "img"
CONTACT_SHEET = DOC_IMG_DIR / "fish_v3_template_v1_contact_sheet.png"
GAME_PREVIEW = DOC_IMG_DIR / "fish_v3_template_v1_game_preview.png"
MANIFEST = OUT_DIR / "manifest.json"

REF_IDS = ["carp", "koi", "bass", "mandarin"]


def spec(fish_id: str, group: str, template: str, dark, light, flags=None):
    return {
        "id": fish_id,
        "group": group,
        "template": template,
        "dark": tuple(dark),
        "light": tuple(light),
        "flags": dict(flags or {}),
    }


FISH = [
    # Mountain stream.
    spec("amur_minnow", "stream", "minnow", (116, 122, 88), (216, 206, 166), {"silver": True, "stripe": (70, 78, 58), "red_fin": True, "tiny": True}),
    spec("hillstream_loach", "stream", "flathead_fish", (92, 86, 64), (180, 158, 112), {"wide_pectoral": True, "mottled": (58, 52, 40), "flat": True}),
    spec("plateau_loach", "stream", "loach", (110, 96, 76), (198, 180, 136), {"mottled": (66, 58, 46), "barbels": True, "slender": True}),
    spec("largescale_shoveljaw", "stream", "chinese_sucker", (116, 128, 112), (224, 222, 196), {"silver": True, "large_scales": True, "shovel_jaw": True}),
    spec("taiwan_shoveljaw", "stream", "chinese_sucker", (114, 116, 78), (216, 202, 138), {"stripe": (68, 82, 66), "green_sheen": True, "shovel_jaw": True}),
    spec("rock_carp", "stream", "carp", (66, 64, 56), (154, 130, 88), {"large_scales": True, "dark_edges": True}),
    spec("schizothorax", "stream", "barbel", (116, 124, 106), (218, 204, 164), {"silver": True, "barbels": True, "belly_scales": True}),
    spec("torrent_catfish", "stream", "amur_catfish", (78, 74, 60), (158, 140, 100), {"barbels": True, "wide_pectoral": True, "mottled": (48, 44, 36), "flat": True}),
    spec("grayling", "stream", "trout", (102, 112, 118), (212, 204, 180), {"silver": True, "fan_dorsal": True, "violet_spots": True}),
    spec("sichuan_taimen", "stream", "taimen", (86, 102, 74), (198, 172, 122), {"spots": (42, 48, 36), "red_tail": True, "big_mouth": True}),

    # Deep sea.
    spec("lanternfish", "deep_sea", "anchovy", (42, 64, 82), (156, 174, 174), {"silver": True, "glow_row": True, "big_eye": True, "tiny": True}),
    spec("bristlemouth", "deep_sea", "anchovy", (42, 40, 38), (126, 104, 76), {"glow_dots": True, "teeth": True, "big_mouth": True, "slender": True}),
    spec("hatchetfish", "deep_sea", "bream", (92, 102, 108), (226, 224, 204), {"hatchet": True, "glow_row": True, "big_eye": True, "silver": True}),
    spec("rattail", "deep_sea", "burbot", (80, 72, 60), (166, 148, 112), {"rattail": True, "big_eye": True, "large_head": True}),
    spec("dragonfish", "deep_sea", "marbled_eel", (28, 32, 36), (84, 84, 80), {"glow_dots": True, "lure": True, "teeth": True, "big_mouth": True, "eel": True}),
    spec("lancetfish", "deep_sea", "wahoo", (88, 108, 122), (214, 210, 184), {"silver": True, "long_sail": True, "teeth": True, "slender": True}),
    spec("anglerfish", "deep_sea", "blackcarp", (54, 48, 42), (136, 108, 78), {"angler": True, "lure": True, "teeth": True, "big_mouth": True}),
    spec("escolar", "deep_sea", "cobia", (44, 46, 44), (156, 146, 122), {"fork_tail": True, "dark_edges": True}),
    spec("opah", "deep_sea", "spotted_scat", (126, 70, 68), (218, 176, 152), {"white_spots": True, "red_fin": True, "round_body": True}),
    spec("giant_squid", "deep_sea", "squid", (126, 76, 70), (220, 156, 140), {"giant_squid": True, "mottled": (92, 54, 52), "big_eye": True}),

    # Reef.
    spec("clownfish", "reef", "koi", (156, 82, 42), (230, 176, 110), {"white_bands": True, "dark_band_edges": True, "round_body": True}),
    spec("damselfish", "reef", "bream", (54, 100, 138), (142, 184, 180), {"blue_body": True, "round_body": True}),
    spec("cardinalfish", "reef", "minnow", (126, 84, 78), (218, 190, 172), {"red_stripes": True, "big_eye": True, "tiny": True}),
    spec("chromis", "reef", "ricefish", (52, 126, 132), (154, 204, 178), {"green_sheen": True, "tiny": True, "fork_tail": True}),
    spec("blenny", "reef", "loach", (94, 84, 66), (184, 160, 112), {"crest": True, "mottled": (58, 52, 42), "slender": True}),
    spec("firefish", "reef", "halfbeak", (150, 76, 68), (232, 218, 198), {"red_tail": True, "dorsal_filament": True, "slender": True}),
    spec("butterflyfish", "reef", "fangbream", (150, 132, 58), (230, 218, 154), {"black_bar": True, "eye_spot": True, "round_body": True}),
    spec("surgeonfish", "reef", "bream", (48, 82, 142), (144, 172, 206), {"yellow_tail": True, "tail_spine": True, "round_body": True}),
    spec("anthias", "reef", "paradisefish", (156, 88, 80), (228, 154, 132), {"fork_tail": True, "pink": True, "tiny": True}),
    spec("wrasse", "reef", "paradisefish", (56, 120, 100), (166, 196, 154), {"blue_lines": True, "slender": True}),
    spec("foxface", "reef", "bream", (154, 134, 48), (224, 206, 104), {"face_mask": True, "point_snout": True}),
    spec("hawkfish", "reef", "mandarin", (138, 78, 62), (214, 160, 126), {"grid_marks": True, "fin_tufts": True}),
    spec("angelfish", "reef", "spotted_scat", (46, 80, 128), (212, 184, 80), {"blue_yellow_rings": True, "long_fins": True, "round_body": True}),
    spec("parrotfish", "reef", "bass", (54, 132, 116), (196, 166, 150), {"pink_marks": True, "beak": True}),
    spec("triggerfish", "reef", "spotted_scat", (76, 98, 108), (210, 174, 126), {"patchwork": True, "dorsal_spine": True, "round_body": True}),
    spec("lionfish", "reef", "mandarin", (126, 66, 58), (226, 202, 176), {"lionfish": True, "white_bands": True}),
    spec("moray", "reef", "marbled_eel", (78, 94, 54), (174, 166, 92), {"mottled": (52, 62, 36), "teeth": True, "big_mouth": True, "eel": True}),
    spec("boxfish", "reef", "fangbream", (148, 126, 48), (228, 206, 94), {"boxfish": True, "spots": (52, 50, 38)}),
    spec("spotted_puffer", "reef", "bream", (92, 92, 82), (216, 202, 178), {"puffer": True, "spots": (42, 44, 40)}),
    spec("coral_grouper", "reef", "crimson_snapper", (162, 76, 68), (222, 138, 122), {"blue_spots": True, "big_mouth": True}),
    spec("bohar_snapper", "reef", "crimson_snapper", (136, 70, 58), (214, 128, 102), {"snapper_head": True}),
    spec("emperor_fish", "reef", "yellowfin_seabream", (136, 126, 104), (222, 196, 164), {"blue_eye_lines": True}),
    spec("unicornfish", "reef", "spotted_scat", (82, 98, 112), (174, 186, 188), {"horn": True, "tail_spine": True}),
    spec("bumphead_parrot", "reef", "mahseer", (70, 118, 112), (168, 188, 158), {"head_hump": True, "beak": True}),
    spec("dogtooth_tuna", "reef", "wahoo", (56, 86, 110), (180, 188, 172), {"teeth": True, "fork_tail": True}),
    spec("napoleon_wrasse", "reef", "mahseer", (56, 122, 102), (170, 190, 154), {"head_hump": True, "worm_lines": True, "thick_lips": True}),
    spec("manta_ray", "reef", "spotted_scat", (42, 52, 60), (172, 182, 174), {"manta": True}),

    # Brackish.
    spec("mudskipper", "brackish", "flathead_fish", (92, 80, 58), (180, 152, 102), {"mudskipper": True, "mottled": (58, 50, 38), "top_eyes": True}),
    spec("glassfish", "brackish", "whitebait", (136, 146, 136), (226, 218, 184), {"clear": True, "bone_line": True, "tiny": True}),
    spec("silverside", "brackish", "anchovy", (110, 132, 136), (226, 226, 204), {"silver": True, "stripe": (210, 212, 196), "slender": True}),
    spec("archerfish", "brackish", "bream", (110, 112, 98), (222, 212, 180), {"bars": 4, "point_snout": True}),
    spec("threadfin", "brackish", "haarder", (120, 124, 108), (222, 206, 164), {"silver": True, "threadfins": True}),
    spec("marble_sleeper", "brackish", "flathead_fish", (94, 76, 58), (176, 144, 98), {"mottled": (58, 48, 38), "big_mouth": True}),
    spec("silverbiddy", "brackish", "bream", (124, 132, 126), (226, 222, 196), {"silver": True, "small_mouth": True}),
    spec("mangrove_snapper", "brackish", "crimson_snapper", (112, 64, 58), (196, 128, 100), {"snapper_head": True, "dark_edges": True}),
    spec("fingermark", "brackish", "yellowfin_seabream", (120, 104, 70), (220, 196, 132), {"fingermark": True, "spots": (70, 64, 48)}),
    spec("milkfish", "brackish", "haarder", (114, 130, 126), (228, 224, 196), {"silver": True, "fork_tail": True}),
    spec("tigerperch", "brackish", "bass", (116, 112, 94), (218, 202, 164), {"curved_bars": True}),
    spec("king_threadfin", "brackish", "amberjack", (122, 120, 96), (226, 204, 148), {"threadfins": True, "gold": True}),
    spec("tarpon", "brackish", "salmon", (112, 128, 134), (228, 224, 202), {"large_scales": True, "upturned_jaw": True, "big_eye": True}),
    spec("estuary_stingray", "brackish", "spotted_scat", (86, 68, 54), (172, 142, 100), {"ray": True, "long_tail": True, "sting": True}),
    spec("bull_shark", "brackish", "whale_shark", (74, 84, 88), (188, 188, 170), {"shark": True, "blunt_snout": True}),
    spec("giant_threadfin", "brackish", "amberjack", (116, 118, 98), (226, 202, 138), {"threadfins": True, "gold": True, "large": True}),
    spec("bahaba", "brackish", "yellow_drum", (136, 116, 72), (226, 196, 118), {"gold_lips": True, "large_scales": True}),
    spec("sawfish", "brackish", "paddlefish", (80, 94, 98), (186, 188, 166), {"sawfish": True}),

    # Polar.
    spec("polar_smelt", "polar", "whitebait", (116, 142, 134), (228, 232, 214), {"silver": True, "clear": True, "tiny": True}),
    spec("ninespine_stickleback", "polar", "minnow", (92, 104, 82), (198, 192, 146), {"back_spines": 9, "tiny": True}),
    spec("capelin", "polar", "whitebait", (94, 130, 110), (222, 226, 198), {"silver": True}),
    spec("pond_smelt", "polar", "whitebait", (124, 144, 138), (230, 228, 206), {"silver": True, "clear": True, "tiny": True}),
    spec("arctic_cisco", "polar", "grass", (106, 126, 132), (226, 226, 204), {"silver": True, "fork_tail": True}),
    spec("whitefish", "polar", "grass", (108, 126, 132), (224, 222, 198), {"silver": True, "blue_back": True}),
    spec("sculpin", "polar", "flathead_fish", (82, 72, 56), (174, 148, 104), {"mottled": (50, 44, 34), "wide_pectoral": True}),
    spec("ruffe", "polar", "bass", (112, 94, 72), (198, 174, 126), {"spots": (52, 48, 40), "dorsal_spine": True}),
    spec("arctic_char", "polar", "trout", (72, 104, 96), (208, 164, 116), {"pale_spots": True, "orange_belly": True}),
    spec("inconnu", "polar", "salmon", (102, 124, 132), (226, 224, 202), {"silver": True, "point_snout": True}),
    spec("round_whitefish", "polar", "bream", (114, 128, 128), (226, 222, 198), {"silver": True, "round_body": True}),
    spec("fourhorn_sculpin", "polar", "flathead_fish", (82, 72, 56), (174, 146, 104), {"mottled": (50, 44, 34), "head_horns": 4}),
    spec("lake_trout", "polar", "trout", (68, 94, 72), (174, 174, 132), {"pale_spots": True, "worm_lines": True}),
    spec("arctic_cod", "polar", "burbot", (92, 106, 108), (210, 204, 184), {"silver": True, "chin_barbel": True}),
    spec("broad_whitefish", "polar", "bighead", (110, 128, 132), (226, 222, 198), {"silver": True, "blunt_snout": True}),
    spec("greenland_halibut", "polar", "flathead_fish", (54, 62, 68), (134, 140, 132), {"flatfish": True, "same_side_eyes": True}),
    spec("arctic_skate", "polar", "spotted_scat", (76, 68, 58), (168, 150, 118), {"ray": True, "long_tail": True}),
    spec("greenland_shark", "polar", "whale_shark", (52, 60, 64), (148, 152, 142), {"shark": True, "small_eye": True}),
    spec("beluga_sturgeon", "polar", "sturgeon", (82, 94, 98), (190, 188, 168), {"bone_plates": True, "long_snout": True}),

    # Cavern.
    spec("cave_loach", "cavern", "loach", (128, 112, 110), (228, 204, 194), {"blind": True, "barbels": True, "clear": True, "slender": True}),
    spec("blind_cavefish", "cavern", "whitebait", (140, 116, 112), (232, 206, 194), {"blind": True, "clear": True}),
    spec("cave_minnow", "cavern", "minnow", (142, 122, 80), (230, 210, 164), {"weak_eye": True, "gold": True, "clear": True, "tiny": True}),
    spec("cave_catfish", "cavern", "amur_catfish", (130, 110, 108), (228, 202, 192), {"blind": True, "barbels": True, "clear": True}),
    spec("olm", "cavern", "marbled_eel", (150, 118, 112), (232, 210, 198), {"salamander": True, "external_gills": True, "tiny_legs": True}),
    spec("cave_eel", "cavern", "marbled_eel", (126, 108, 104), (226, 200, 188), {"weak_eye": True, "clear": True, "eel": True}),
    spec("golden_barb", "cavern", "barbel", (138, 116, 66), (226, 198, 120), {"gold": True, "weak_eye": True, "barbels": True}),
    spec("blind_eel", "cavern", "marbled_eel", (114, 112, 108), (220, 210, 196), {"blind": True, "barbels": True, "eel": True}),
    spec("cave_sleeper", "cavern", "flathead_fish", (82, 70, 56), (166, 138, 98), {"weak_eye": True, "big_mouth": True, "mottled": (52, 44, 36)}),
    spec("cavern_catfish", "cavern", "amur_catfish", (126, 106, 104), (226, 200, 190), {"blind": True, "barbels": True, "large": True}),
    spec("ancient_loach", "cavern", "loach", (100, 80, 62), (188, 154, 108), {"mottled": (58, 48, 38), "barbels": True}),
    spec("bichir", "cavern", "coelacanth", (78, 88, 66), (166, 152, 104), {"many_dorsallets": True, "snake_head": True, "eel": True}),
    spec("lungfish", "cavern", "marbled_eel", (90, 80, 62), (178, 150, 104), {"leg_fins": True, "mottled": (56, 48, 38), "eel": True}),
    spec("giant_salamander", "cavern", "marbled_eel", (76, 62, 48), (158, 126, 86), {"salamander": True, "tiny_legs": True, "mottled": (50, 42, 32), "flat_head": True}),
    spec("alligator_gar", "cavern", "longsnout", (76, 86, 70), (166, 154, 112), {"long_jaws": True, "teeth": True, "large_scales": True}),

    # Urban.
    spec("mosquitofish", "urban", "ricefish", (94, 96, 82), (192, 184, 146), {"round_belly": True, "tiny": True}),
    spec("feral_goldfish", "urban", "crucian", (112, 96, 58), (214, 158, 86), {"mottled": (70, 76, 46), "round_body": True}),
    spec("feral_guppy", "urban", "ricefish", (86, 96, 82), (198, 172, 130), {"tail_marks": True, "tiny": True}),
    spec("plecostomus", "urban", "sturgeon", (60, 52, 44), (136, 116, 84), {"armor_plates": True, "sucker_mouth": True, "large_dorsal": True}),
    spec("crayfish", "urban", "cuttlefish", (116, 50, 42), (196, 108, 82), {"crayfish": True}),
    spec("bullfrog", "urban", "spotted_scat", (72, 102, 58), (164, 158, 100), {"frog": True, "big_eye": True}),
    spec("walking_catfish", "urban", "amur_catfish", (52, 56, 52), (130, 122, 94), {"barbels": True, "long_body": True}),
    spec("red_eared_slider", "urban", "spotted_scat", (66, 90, 54), (164, 152, 96), {"turtle": True, "red_ear": True}),
    spec("channel_catfish", "urban", "amur_catfish", (88, 100, 100), (190, 182, 154), {"barbels": True, "spots": (48, 52, 50), "fork_tail": True}),
    spec("giant_gourami", "urban", "bighead", (112, 120, 112), (212, 202, 176), {"threadfins": True, "blunt_snout": True}),
    spec("snapping_turtle", "urban", "spotted_scat", (76, 64, 50), (158, 132, 92), {"turtle": True, "hooked_beak": True, "spiky_shell": True}),
    spec("flathead_catfish", "urban", "flathead_fish", (92, 80, 54), (176, 144, 88), {"barbels": True, "big_mouth": True}),
    spec("arapaima", "urban", "oarfish", (68, 80, 72), (184, 136, 112), {"red_tail_scales": True, "large_scales": True, "large": True}),
    spec("yangtze_softshell", "urban", "spotted_scat", (90, 78, 62), (182, 154, 112), {"softshell": True, "tube_snout": True, "spots": (58, 50, 40)}),
]


def rgba(color, alpha):
    return (*color, alpha)


def load_template(template_id: str) -> Image.Image:
    path = SOURCE_DIR / f"{template_id}.png"
    if not path.exists():
        path = FISH_DIR / f"{template_id}.png"
    if not path.exists():
        raise FileNotFoundError(f"Missing template image for {template_id}")
    return Image.open(path).convert("RGBA")


def colorize_from_template(template_id: str, dark, light, preserve=0.38) -> Image.Image:
    src = load_template(template_id)
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
            tinted = base.mix(light, dark, 0.10 + shade * 0.76)
            tinted = base.mix(tinted, (r, g, b), preserve)
            dst[x, y] = (*tinted, a)
    return out


def transform_crop(crop: Image.Image, flags) -> Image.Image:
    w, h = crop.size
    sx = sy = 1.0
    if flags.get("tiny"):
        sx *= 0.84
        sy *= 0.82
    if flags.get("slender"):
        sx *= 1.12
        sy *= 0.78
    if flags.get("eel"):
        sx *= 1.10
        sy *= 0.72
    if flags.get("flat"):
        sx *= 1.05
        sy *= 0.75
    if flags.get("round_body"):
        sx *= 0.92
        sy *= 1.08
    if flags.get("large"):
        sx *= 1.10
        sy *= 1.02
    if flags.get("long_body"):
        sx *= 1.12
        sy *= 0.84
    if flags.get("flatfish"):
        sx *= 1.18
        sy *= 0.58
    if flags.get("shark"):
        sx *= 1.08
        sy *= 0.86
    if flags.get("hatchet"):
        sx *= 0.78
        sy *= 1.28
    return crop.resize((max(1, int(w * sx)), max(1, int(h * sy))), Image.Resampling.LANCZOS)


def fit_footprint(img: Image.Image, flags, target=0.86) -> Image.Image:
    bbox = img.getbbox()
    if not bbox:
        return img
    crop = transform_crop(img.crop(bbox), flags)
    max_dim = max(crop.size)
    desired = int(128 * (0.76 if flags.get("tiny") else target))
    if max_dim > 0:
        ratio = desired / max_dim
        crop = crop.resize((max(1, int(crop.size[0] * ratio)), max(1, int(crop.size[1] * ratio))), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    out.alpha_composite(crop, ((128 - crop.size[0]) // 2, (128 - crop.size[1]) // 2))
    return out


def textured_shape(template_id: str, dark, light, mask: Image.Image, preserve=0.42) -> Image.Image:
    tex = colorize_from_template(template_id, dark, light, preserve=preserve)
    bbox = tex.getbbox() or (0, 0, 128, 128)
    tex = tex.crop(bbox).resize((128, 128), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    alpha = mask.filter(ImageFilter.GaussianBlur(0.45))
    tex.putalpha(alpha)
    out.alpha_composite(tex)
    return out


def draw_special(fish) -> Image.Image | None:
    flags = fish["flags"]
    template = fish["template"]
    dark = fish["dark"]
    light = fish["light"]
    mask = Image.new("L", (128, 128), 0)
    d = ImageDraw.Draw(mask)

    if flags.get("ray") or flags.get("manta"):
        if flags.get("manta"):
            pts = [(11, 65), (40, 35), (84, 42), (118, 64), (84, 86), (40, 94)]
        else:
            pts = [(19, 64), (51, 32), (101, 55), (78, 95), (39, 86)]
        d.polygon(pts, fill=210)
        d.ellipse((51, 45, 95, 80), fill=190)
        img = textured_shape(template, dark, light, mask)
        od = ImageDraw.Draw(img, "RGBA")
        od.line([(82, 66), (127, 78)], fill=rgba(dark, 92), width=2)
        if flags.get("manta"):
            base.draw_soft_poly(img, [(88, 54), (119, 43), (101, 60)], rgba(light, 72), 0.4)
            base.draw_soft_poly(img, [(88, 74), (119, 84), (101, 67)], rgba(light, 64), 0.4)
        return img

    if flags.get("turtle") or flags.get("softshell"):
        d.ellipse((24, 39, 91, 83), fill=210)
        d.ellipse((82, 48, 113, 70), fill=178)
        d.polygon([(25, 61), (9, 53), (12, 68)], fill=105)
        d.ellipse((43, 75, 61, 94), fill=120)
        d.ellipse((69, 74, 88, 93), fill=116)
        d.ellipse((43, 32, 60, 48), fill=112)
        img = textured_shape(template, dark, light, mask)
        od = ImageDraw.Draw(img, "RGBA")
        od.arc((29, 42, 88, 82), 190, 352, fill=rgba(base.mix(dark, light, 0.22), 80), width=2)
        od.line([(35, 60), (84, 58)], fill=rgba(base.mix(dark, light, 0.16), 62), width=1)
        if flags.get("red_ear"):
            od.line([(94, 54), (104, 52)], fill=rgba((180, 48, 42), 130), width=2)
        if flags.get("spiky_shell"):
            for x in [43, 57, 71]:
                base.draw_soft_poly(img, [(x - 5, 43), (x, 30), (x + 6, 43)], rgba(dark, 76), 0.3)
        if flags.get("tube_snout"):
            od.line([(106, 60), (125, 59)], fill=rgba(dark, 96), width=3)
        return img

    if flags.get("frog"):
        d.ellipse((27, 45, 87, 82), fill=205)
        d.ellipse((78, 39, 113, 68), fill=175)
        d.ellipse((28, 69, 58, 96), fill=132)
        d.ellipse((66, 69, 88, 91), fill=126)
        d.ellipse((83, 63, 105, 83), fill=118)
        img = textured_shape(template, dark, light, mask)
        base.draw_soft_ellipse(img, (88, 42, 96, 50), rgba((34, 32, 28), 150), 0.1)
        base.draw_soft_ellipse(img, (99, 43, 107, 51), rgba((34, 32, 28), 130), 0.1)
        ImageDraw.Draw(img, "RGBA").arc((87, 53, 109, 69), 15, 110, fill=rgba(dark, 72), width=1)
        return img

    if flags.get("salamander"):
        d.ellipse((16, 50, 100, 73), fill=190)
        d.ellipse((82, 45, 116, 72), fill=172)
        d.line([(22, 61), (5, 66)], fill=110, width=4)
        d.ellipse((35, 67, 54, 83), fill=125)
        d.ellipse((67, 67, 88, 84), fill=120)
        d.ellipse((38, 42, 54, 55), fill=104)
        d.ellipse((68, 41, 84, 55), fill=100)
        img = textured_shape(template, dark, light, mask)
        od = ImageDraw.Draw(img, "RGBA")
        if flags.get("external_gills"):
            for off in [-5, 0, 5]:
                od.line([(91, 57 + off), (108, 48 + off)], fill=rgba((176, 78, 74), 85), width=2)
        return img

    if flags.get("crayfish"):
        d.ellipse((28, 49, 87, 74), fill=190)
        d.polygon([(22, 61), (6, 48), (6, 75)], fill=128)
        d.ellipse((78, 49, 102, 70), fill=168)
        d.line([(96, 55), (116, 38)], fill=140, width=5)
        d.line([(97, 66), (117, 86)], fill=132, width=5)
        d.ellipse((111, 31, 127, 49), fill=135)
        d.ellipse((112, 79, 127, 97), fill=126)
        for i in range(4):
            d.line([(42 + i * 9, 68), (31 + i * 5, 88)], fill=110, width=3)
            d.line([(42 + i * 9, 55), (31 + i * 5, 38)], fill=100, width=2)
        img = textured_shape(template, dark, light, mask)
        od = ImageDraw.Draw(img, "RGBA")
        od.line([(96, 55), (118, 38)], fill=rgba(dark, 72), width=2)
        od.line([(97, 66), (118, 86)], fill=rgba(dark, 68), width=2)
        for i in range(4):
            od.line([(42 + i * 9, 68), (31 + i * 5, 88)], fill=rgba(dark, 62), width=1)
        return img

    if flags.get("boxfish"):
        d.polygon([(28, 42), (83, 35), (109, 60), (84, 85), (29, 78), (16, 60)], fill=205)
        return textured_shape(template, dark, light, mask)

    if flags.get("puffer"):
        d.ellipse((25, 31, 101, 92), fill=210)
        d.ellipse((82, 49, 116, 72), fill=145)
        return textured_shape(template, dark, light, mask)

    if flags.get("giant_squid"):
        d.polygon([(16, 55), (73, 30), (103, 62), (72, 88)], fill=190)
        for off in [-18, -12, -6, 2, 8, 14, 20]:
            d.line([(89, 63), (126, 63 + off)], fill=130, width=3)
        d.line([(82, 58), (127, 28)], fill=112, width=3)
        d.line([(82, 67), (127, 98)], fill=112, width=3)
        img = textured_shape(template, dark, light, mask)
        base.draw_soft_ellipse(img, (80, 54, 90, 64), rgba((34, 28, 26), 150), 0.1)
        return img

    return None


def add_details(img: Image.Image, fish) -> Image.Image:
    flags = fish["flags"]
    dark = fish["dark"]
    light = fish["light"]
    bbox = img.getbbox() or (8, 34, 120, 90)
    x0, y0, x1, y1 = bbox
    cx = (x0 + x1) / 2
    cy = (y0 + y1) / 2
    h = y1 - y0
    d = ImageDraw.Draw(img, "RGBA")

    if flags.get("clear"):
        wash = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(wash, "RGBA").ellipse((x0 + 12, y0 + 6, x1 - 10, y1 - 5), fill=rgba((240, 238, 220), 24))
        img.alpha_composite(wash.filter(ImageFilter.GaussianBlur(1.1)))
    if flags.get("silver"):
        d.line([(x0 + 28, cy + 1), (x1 - 18, cy - 1)], fill=rgba((236, 238, 222), 82), width=2)
    if flags.get("stripe"):
        d.line([(x0 + 27, cy), (x1 - 20, cy - 2)], fill=rgba(flags["stripe"], 80), width=3)
    if flags.get("bars"):
        count = int(flags["bars"])
        for i in range(count):
            x = x0 + 32 + i * (x1 - x0 - 58) / max(1, count - 1)
            d.line([(x, y0 + 6), (x + 4, y1 - 7)], fill=rgba(dark, 58), width=3)
    if flags.get("mottled"):
        color = flags["mottled"]
        for i in range(13):
            x = x0 + 25 + (i * 17) % max(1, int(x1 - x0 - 42))
            y = y0 + 9 + (i * 11) % max(1, int(y1 - y0 - 18))
            base.draw_soft_ellipse(img, (x - 4, y - 2, x + 5, y + 3), rgba(color, 42), 0.65)
    if flags.get("spots"):
        color = flags["spots"]
        for i in range(14):
            x = x0 + 30 + (i * 13) % max(1, int(x1 - x0 - 48))
            y = y0 + 8 + (i * 7) % max(1, int(y1 - y0 - 18))
            base.draw_soft_ellipse(img, (x - 2, y - 2, x + 2, y + 2), rgba(color, 86), 0.22)
    if flags.get("large_scales"):
        for x in range(int(x0 + 34), int(x1 - 28), 10):
            d.arc((x - 4, cy - 10, x + 7, cy + 8), 92, 265, fill=rgba((238, 230, 204), 42), width=1)
    if flags.get("barbels"):
        d.line([(x1 - 12, cy + 6), (min(127, x1 + 6), cy + 11)], fill=rgba(dark, 86), width=1)
        d.line([(x1 - 13, cy + 8), (min(127, x1 + 4), cy + 16)], fill=rgba(dark, 68), width=1)
    if flags.get("teeth"):
        for i in range(4):
            x = x1 - 17 + i * 4
            d.line([(x, cy + 1), (x + 1, cy + 6)], fill=rgba((232, 226, 206), 120), width=1)
    if flags.get("big_eye"):
        base.draw_soft_ellipse(img, (x1 - 29, cy - h * .23, x1 - 23, cy - h * .23 + 6), rgba((36, 34, 30), 150), 0.1)
    if flags.get("small_eye"):
        base.draw_soft_ellipse(img, (x1 - 24, cy - 5, x1 - 20, cy - 1), rgba((32, 30, 28), 118), 0.1)
    if flags.get("blind"):
        base.draw_soft_ellipse(img, (x1 - 25, cy - h * .17, x1 - 21, cy - h * .17 + 3), rgba((160, 128, 126), 54), 0.2)
    if flags.get("weak_eye"):
        base.draw_soft_ellipse(img, (x1 - 24, cy - h * .16, x1 - 21, cy - h * .16 + 3), rgba((64, 50, 45), 70), 0.1)
    if flags.get("glow_row"):
        for i in range(7):
            x = x0 + 27 + i * max(6, (x1 - x0 - 52) / 6)
            base.draw_soft_ellipse(img, (x - 2.2, cy + h * .17 - 2.2, x + 2.2, cy + h * .17 + 2.2), rgba((118, 190, 210), 126), 0.55)
    if flags.get("glow_dots"):
        for i in range(5):
            x = x0 + 34 + i * max(8, (x1 - x0 - 62) / 4)
            base.draw_soft_ellipse(img, (x - 1.7, cy - 1.7, x + 1.7, cy + 1.7), rgba((112, 176, 196), 98), 0.45)
    if flags.get("lure"):
        d.line([(x1 - 18, y0 + h * .18), (x1 - 6, y0 - 12), (min(127, x1 + 8), y0 - 5)], fill=rgba(dark, 88), width=1)
        base.draw_soft_ellipse(img, (min(126, x1 + 5), y0 - 8, min(127, x1 + 13), y0), rgba((130, 200, 210), 120), 0.75)
    if flags.get("fan_dorsal") or flags.get("long_sail"):
        top = y0 - (26 if flags.get("fan_dorsal") else 22)
        base.draw_soft_poly(img, [(x0 + 42, y0 + 4), (x0 + 72, top), (x0 + 104, y0 + 8), (x0 + 86, y0 + 13), (x0 + 58, y0 + 12)], rgba(base.mix(dark, (118, 92, 154), .35), 104), 0.65)
    if flags.get("violet_spots"):
        for x in [x0 + 56, x0 + 70, x0 + 85]:
            base.draw_soft_ellipse(img, (x - 2, y0 - 9, x + 2, y0 - 5), rgba((118, 88, 156), 90), 0.2)
    if flags.get("white_bands"):
        for x in [x0 + 39, x0 + 61, x0 + 82]:
            d.line([(x, y0 + 5), (x + 3, y1 - 5)], fill=rgba((238, 232, 210), 114), width=5)
    if flags.get("dark_band_edges"):
        for x in [x0 + 36, x0 + 58, x0 + 79]:
            d.line([(x, y0 + 5), (x + 3, y1 - 5)], fill=rgba((44, 40, 36), 55), width=1)
    if flags.get("red_stripes"):
        for x in [x0 + 34, x0 + 50, x0 + 66, x0 + 82]:
            d.line([(x, y0 + 7), (x + 7, y1 - 7)], fill=rgba((142, 66, 62), 74), width=2)
    if flags.get("blue_lines"):
        for y in [cy - 5, cy + 1, cy + 7]:
            d.line([(x0 + 26, y), (x1 - 20, y - 2)], fill=rgba((58, 118, 142), 74), width=2)
    if flags.get("blue_spots"):
        for x in range(int(x0 + 35), int(x1 - 22), 13):
            base.draw_soft_ellipse(img, (x - 2, cy - 8, x + 2, cy - 4), rgba((76, 142, 170), 95), 0.2)
    if flags.get("white_spots"):
        for x in range(int(x0 + 32), int(x1 - 24), 12):
            base.draw_soft_ellipse(img, (x - 2, cy - 12, x + 2, cy - 8), rgba((232, 220, 196), 90), 0.2)
            base.draw_soft_ellipse(img, (x + 5, cy + 1, x + 8, cy + 4), rgba((232, 220, 196), 74), 0.2)
    if flags.get("pale_spots"):
        for x in range(int(x0 + 34), int(x1 - 26), 12):
            base.draw_soft_ellipse(img, (x - 2, cy - 12, x + 2, cy - 8), rgba((230, 220, 184), 86), 0.2)
            base.draw_soft_ellipse(img, (x + 4, cy + 1, x + 7, cy + 4), rgba((230, 220, 184), 72), 0.2)
    if flags.get("orange_belly"):
        base.draw_soft_poly(img, [(x0 + 30, cy + 5), (x1 - 32, cy + 4), (x1 - 42, y1 - 5), (x0 + 40, y1 - 4)], rgba((190, 92, 58), 64), 0.7)
    if flags.get("worm_lines"):
        for i in range(6):
            y = y0 + 12 + i * 5
            d.arc((x0 + 34 + i * 2, y - 6, x1 - 25, y + 7), 185, 350, fill=rgba((90, 142, 132), 44), width=1)
    if flags.get("threadfins"):
        for i in range(4):
            x = x1 - 50 + i * 4
            d.line([(x, y1 - 6), (x - 2, min(127, y1 + 23 + i * 2))], fill=rgba(base.mix(dark, light, .35), 92), width=1)
    if flags.get("horn"):
        base.draw_soft_poly(img, [(x1 - 25, y0 + 10), (x1 - 9, y0 - 7), (x1 - 12, y0 + 13)], rgba(base.mix(dark, light, .3), 98), 0.35)
    if flags.get("head_hump"):
        base.draw_soft_ellipse(img, (x1 - 48, y0 - 2, x1 - 15, y0 + 26), rgba(base.mix(dark, light, .35), 88), 0.7)
    if flags.get("head_horns"):
        for off in [-13, -5, 5, 13]:
            d.line([(x1 - 36 + off, y0 + 11), (x1 - 34 + off, y0 - 1)], fill=rgba(dark, 72), width=1)
    if flags.get("many_dorsallets"):
        for x in range(int(x0 + 34), int(x1 - 34), 10):
            base.draw_soft_poly(img, [(x, y0 + 4), (x + 4, y0 - 8), (x + 8, y0 + 5)], rgba(dark, 76), 0.35)
    if flags.get("belly_scales"):
        for x in range(int(x0 + 42), int(x1 - 34), 9):
            base.draw_soft_ellipse(img, (x - 3, y1 - 11, x + 4, y1 - 6), rgba((226, 214, 180), 72), 0.2)
    if flags.get("bone_plates") or flags.get("armor_plates"):
        for x in range(int(x0 + 30), int(x1 - 28), 10):
            base.draw_soft_poly(img, [(x, y0 + 6), (x + 6, y0 + 3), (x + 10, y0 + 8), (x + 4, y0 + 11)], rgba(base.mix(dark, light, .3), 70), 0.25)
    if flags.get("curved_bars"):
        for x in [x0 + 36, x0 + 52, x0 + 68, x0 + 84]:
            d.arc((x - 4, y0 + 5, x + 12, y1 - 6), 110, 250, fill=rgba((52, 48, 40), 70), width=2)
    if flags.get("black_bar"):
        d.line([(x1 - 30, y0 + 8), (x1 - 22, y1 - 8)], fill=rgba((42, 40, 34), 95), width=4)
    if flags.get("eye_spot"):
        base.draw_soft_ellipse(img, (x0 + 30, cy - 6, x0 + 38, cy + 2), rgba((42, 38, 34), 90), 0.25)
    if flags.get("face_mask"):
        base.draw_soft_poly(img, [(x1 - 34, y0 + 6), (x1 - 9, cy - 3), (x1 - 27, y1 - 5)], rgba((44, 42, 38), 82), 0.5)
    if flags.get("fingermark"):
        d.line([(x1 - 34, y0 + 10), (x1 - 18, y1 - 10)], fill=rgba((44, 42, 36), 82), width=3)
        base.draw_soft_ellipse(img, (cx - 5, cy - 1, cx + 3, cy + 7), rgba((60, 54, 40), 70), 0.25)
    if flags.get("blue_eye_lines"):
        d.arc((x1 - 32, cy - 10, x1 - 12, cy + 8), 190, 320, fill=rgba((60, 118, 148), 88), width=2)
    if flags.get("tail_spine"):
        d.line([(x0 + 18, cy), (x0 + 7, cy + 2)], fill=rgba((232, 226, 204), 90), width=2)
    if flags.get("red_tail") or flags.get("red_tail_scales"):
        base.draw_soft_poly(img, [(x0 + 8, cy), (x0 + 25, cy - h * .28), (x0 + 25, cy + h * .26)], rgba((170, 76, 62), 92), 0.45)
    if flags.get("yellow_tail"):
        base.draw_soft_poly(img, [(x0 + 8, cy), (x0 + 25, cy - h * .28), (x0 + 25, cy + h * .26)], rgba((210, 172, 74), 92), 0.45)
    if flags.get("red_fin"):
        base.draw_soft_poly(img, [(x0 + 62, y1 - 5), (x0 + 80, y1 + 12), (x0 + 91, y1 - 7)], rgba((166, 80, 62), 76), 0.45)
    if flags.get("gold_lips"):
        d.line([(x1 - 15, cy + 2), (x1 - 3, cy + 1)], fill=rgba((222, 182, 80), 120), width=2)
    if flags.get("long_snout"):
        d.line([(x1 - 12, cy - 2), (min(127, x1 + 20), cy - 4)], fill=rgba(dark, 92), width=3)
    if flags.get("sawfish"):
        d.line([(x1 - 8, cy - 1), (127, cy - 5)], fill=rgba(dark, 105), width=3)
        for x in range(int(x1), 126, 6):
            d.line([(x, cy - 6), (x + 1, cy - 10)], fill=rgba(dark, 80), width=1)
            d.line([(x, cy - 3), (x + 1, cy + 1)], fill=rgba(dark, 80), width=1)
    if flags.get("long_jaws"):
        d.line([(x1 - 12, cy - 2), (min(127, x1 + 20), cy - 5)], fill=rgba(dark, 118), width=4)
        d.line([(x1 - 12, cy + 3), (min(127, x1 + 19), cy + 4)], fill=rgba(dark, 100), width=3)
    if flags.get("chin_barbel"):
        d.line([(x1 - 14, cy + 7), (x1 - 3, cy + 14)], fill=rgba(dark, 82), width=1)
    if flags.get("same_side_eyes"):
        base.draw_soft_ellipse(img, (x1 - 30, cy - 9, x1 - 25, cy - 4), rgba((36, 34, 30), 130), 0.1)
        base.draw_soft_ellipse(img, (x1 - 23, cy - 5, x1 - 19, cy - 1), rgba((36, 34, 30), 118), 0.1)
    if flags.get("top_eyes"):
        base.draw_soft_ellipse(img, (x1 - 30, y0 + 4, x1 - 24, y0 + 10), rgba((36, 32, 28), 138), 0.1)
        base.draw_soft_ellipse(img, (x1 - 20, y0 + 5, x1 - 14, y0 + 11), rgba((36, 32, 28), 128), 0.1)
    if flags.get("bone_line"):
        d.line([(x0 + 28, cy), (x1 - 20, cy)], fill=rgba((80, 82, 72), 54), width=1)
    if flags.get("tail_marks"):
        base.draw_soft_poly(img, [(x0 + 8, cy), (x0 + 28, cy - h * .33), (x0 + 32, cy + h * .31)], rgba((146, 90, 72), 72), 0.45)
    if flags.get("spiky_shell"):
        for x in [cx - 16, cx, cx + 16]:
            base.draw_soft_poly(img, [(x - 5, y0 + 6), (x, y0 - 7), (x + 5, y0 + 6)], rgba(dark, 74), 0.3)

    return img


def make_icon(fish) -> Image.Image:
    special = draw_special(fish)
    if special is not None:
        img = special
    else:
        img = colorize_from_template(fish["template"], fish["dark"], fish["light"])
        img = fit_footprint(img, fish["flags"])
    img = add_details(img, fish)
    return base.trim_and_center(img, 128, 0.86)


def checker(size=80, cell=10) -> Image.Image:
    img = Image.new("RGBA", (size, size), (236, 233, 224, 255))
    d = ImageDraw.Draw(img)
    for y in range(0, size, cell):
        for x in range(0, size, cell):
            if (x // cell + y // cell) % 2 == 0:
                d.rectangle((x, y, x + cell - 1, y + cell - 1), fill=(250, 248, 242, 255))
    return img


def build_contact_sheet():
    cols = 8
    cell_w = 122
    cell_h = 112
    header_h = 120
    groups: list[tuple[str, list[dict]]] = []
    for fish in FISH:
        if not groups or groups[-1][0] != fish["group"]:
            groups.append((fish["group"], []))
        groups[-1][1].append(fish)

    total_rows = 1 + sum(1 + math.ceil(len(items) / cols) for _, items in groups)
    sheet = Image.new("RGB", (cols * cell_w, header_h + total_rows * cell_h), (232, 226, 214))
    d = ImageDraw.Draw(sheet)
    d.text((12, 8), "v3_template_v1 WIP - references first; candidates are not production-approved until review", fill=(66, 58, 48))
    x = 12
    for ref_id in REF_IDS:
        tile = checker(72)
        icon = Image.open(FISH_DIR / f"{ref_id}.png").convert("RGBA").resize((72, 72), Image.Resampling.LANCZOS)
        tile.alpha_composite(icon, (0, 0))
        sheet.paste(tile.convert("RGB"), (x, 32))
        d.text((x, 106), ref_id, fill=(66, 58, 48))
        x += 100

    y = header_h
    for group, items in groups:
        d.rectangle((0, y, sheet.width, y + 28), fill=(218, 210, 196))
        d.text((12, y + 7), f"{group} ({len(items)})", fill=(58, 68, 64))
        y += 32
        for i, fish in enumerate(items):
            col = i % cols
            row = i // cols
            x = col * cell_w + 12
            yy = y + row * cell_h
            tile = checker(72)
            icon = Image.open(OUT_DIR / f"{fish['id']}.png").convert("RGBA").resize((72, 72), Image.Resampling.LANCZOS)
            tile.alpha_composite(icon, (0, 0))
            sheet.paste(tile.convert("RGB"), (x, yy))
            d.text((x, yy + 76), fish["id"][:18], fill=(60, 56, 50))
        y += math.ceil(len(items) / cols) * cell_h
    sheet.save(CONTACT_SHEET)

    for group, items in groups:
        build_group_contact_sheet(group, items)


def build_group_contact_sheet(group: str, items: list[dict]):
    cols = 7
    cell_w = 126
    cell_h = 114
    header_h = 120
    rows = 1 + math.ceil(len(items) / cols)
    path = DOC_IMG_DIR / f"fish_v3_template_v1_{group}_contact_sheet.png"
    sheet = Image.new("RGB", (cols * cell_w, header_h + rows * cell_h), (232, 226, 214))
    d = ImageDraw.Draw(sheet)
    d.text((12, 8), f"v3_template_v1 {group} WIP - references first; review before production", fill=(66, 58, 48))
    x = 12
    for ref_id in REF_IDS:
        tile = checker(72)
        icon = Image.open(FISH_DIR / f"{ref_id}.png").convert("RGBA").resize((72, 72), Image.Resampling.LANCZOS)
        tile.alpha_composite(icon, (0, 0))
        sheet.paste(tile.convert("RGB"), (x, 32))
        d.text((x, 106), ref_id, fill=(66, 58, 48))
        x += 100

    y = header_h
    for i, fish in enumerate(items):
        x = (i % cols) * cell_w + 12
        yy = y + (i // cols) * cell_h
        tile = checker(72)
        icon = Image.open(OUT_DIR / f"{fish['id']}.png").convert("RGBA").resize((72, 72), Image.Resampling.LANCZOS)
        tile.alpha_composite(icon, (0, 0))
        sheet.paste(tile.convert("RGB"), (x, yy))
        d.text((x, yy + 76), fish["id"][:18], fill=(60, 56, 50))
    sheet.save(path)


def build_game_preview():
    cols = 8
    card_w = 118
    card_h = 142
    pad = 10
    rows = math.ceil(len(FISH) / cols)
    preview = Image.new("RGB", (cols * card_w + pad * 2, rows * card_h + pad * 2), (31, 36, 32))
    d = ImageDraw.Draw(preview)
    for i, fish in enumerate(FISH):
        x = pad + (i % cols) * card_w
        y = pad + (i // cols) * card_h
        d.rounded_rectangle((x, y, x + card_w - 10, y + card_h - 10), radius=8, fill=(36, 42, 37), outline=(68, 150, 76), width=2)
        icon = Image.open(OUT_DIR / f"{fish['id']}.png").convert("RGBA").resize((72, 72), Image.Resampling.LANCZOS)
        preview.paste(icon, (x + (card_w - 10 - 72) // 2, y + 18), icon)
        d.text((x + 8, y + 96), fish["id"][:16], fill=(210, 214, 200))
        d.text((x + 8, y + 113), "WIP", fill=(228, 190, 96))
    preview.save(GAME_PREVIEW)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT_SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    DOC_IMG_DIR.mkdir(parents=True, exist_ok=True)

    manifest = []
    for fish in FISH:
        img = make_icon(fish)
        runtime = img.resize((64, 64), Image.Resampling.LANCZOS)
        img.save(OUT_SOURCE_DIR / f"{fish['id']}.png")
        runtime.save(OUT_DIR / f"{fish['id']}.png")
        manifest.append({
            "id": fish["id"],
            "group": fish["group"],
            "template": fish["template"],
            "runtime_wip": f"assets/art/fish/wip/v3_template_v1/{fish['id']}.png",
            "source_wip": f"assets/art/fish/wip/v3_template_v1/source/{fish['id']}.png",
            "status": "wip_template_repaint_for_art_review",
        })

    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    build_contact_sheet()
    build_game_preview()
    print(f"Generated {len(FISH)} v3 template WIP icons.")
    print(MANIFEST)
    print(CONTACT_SHEET)
    print(GAME_PREVIEW)


if __name__ == "__main__":
    main()
