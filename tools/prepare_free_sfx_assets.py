from __future__ import annotations

import json
import math
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import resample_poly


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio"
FREE_SFX = Path(r"E:\ai-audio\free-sfx\packs")
TARGET_SR = 44_100


SOURCES = {
    "kenney": FREE_SFX / "opengameart_kenney_interface_sounds_cc0" / "Audio",
    "water": FREE_SFX / "opengameart_water_splash_slime_cc0",
    "more": FREE_SFX / "opengameart_202_more_sounds_cc0",
}


ASSETS = {
    "ui_click": {
        "path": "ui/ui_click.wav",
        "loop": False,
        "description": "Soft low-volume UI tap. Source: Kenney Interface Sounds CC0 click_001.",
        "layers": [("kenney/click_001.ogg", 0.0, -11.0)],
        "peak": 0.22,
        "fade_out": 0.035,
    },
    "ui_error": {
        "path": "ui/ui_error.wav",
        "loop": False,
        "description": "Polite invalid-action knock/drop. Source: Kenney Interface Sounds CC0 drop_001.",
        "layers": [("kenney/drop_001.ogg", 0.0, -12.0)],
        "peak": 0.2,
        "fade_out": 0.05,
    },
    "cast": {
        "path": "fishing/cast.wav",
        "loop": False,
        "description": "Soft cast/line rustle. Source: 202 More Sound Effects CC0 Cloth_05.",
        "layers": [("more/Cloth/Cloth_05.wav", 0.0, -5.0)],
        "peak": 0.26,
        "fade_out": 0.08,
    },
    "bobber_splash": {
        "path": "fishing/bobber_splash.wav",
        "loop": False,
        "description": "Small bobber water entry. Source: 40 CC0 water/splash/slime SFX splash_09.",
        "layers": [("water/splash_09.ogg", 0.0, -3.0)],
        "peak": 0.28,
        "fade_out": 0.09,
    },
    "bite": {
        "path": "fishing/bite.wav",
        "loop": False,
        "description": "Small bite/ripple cue. Source: 40 CC0 water/splash/slime SFX bubble_02.",
        "layers": [("water/bubble_02.ogg", 0.0, -8.0)],
        "peak": 0.22,
        "fade_out": 0.08,
    },
    "catch_common": {
        "path": "fishing/catch_common.wav",
        "loop": False,
        "description": "Gentle common catch water lift. Source: 40 CC0 water/splash/slime SFX splash_06.",
        "layers": [("water/splash_06.ogg", 0.0, -4.0)],
        "peak": 0.3,
        "fade_out": 0.12,
    },
    "catch_rare": {
        "path": "fishing/catch_rare.wav",
        "loop": False,
        "description": "Rare catch water lift plus soft confirmation. Sources: water splash_01 and Kenney confirmation_001 CC0.",
        "layers": [
            ("water/splash_01.ogg", 0.0, -6.0),
            ("kenney/confirmation_001.ogg", 0.18, -16.0),
        ],
        "peak": 0.32,
        "fade_out": 0.16,
    },
    "coin": {
        "path": "economy/coin.wav",
        "loop": False,
        "description": "Soft pouch coin Foley. Source: 202 More Sound Effects CC0 Money_07.",
        "layers": [("more/Money/Money_07.wav", 0.0, -4.0)],
        "peak": 0.24,
        "fade_out": 0.06,
    },
    "upgrade": {
        "path": "economy/upgrade.wav",
        "loop": False,
        "description": "Quiet confirmation for upgrades. Source: Kenney Interface Sounds CC0 confirmation_001.",
        "layers": [("kenney/confirmation_001.ogg", 0.0, -11.0)],
        "peak": 0.25,
        "fade_out": 0.12,
    },
    "ambience_water_loop": {
        "path": "ambience/ambience_water_loop.wav",
        "loop": True,
        "description": "Soft looping water ambience. Source: 40 CC0 water/splash/slime SFX loop_water_03.",
        "layers": [("water/loop_water_03.ogg", 0.0, -3.0)],
        "peak": 0.18,
        "fade_out": 0.2,
        "loop_seconds": 28.0,
        "crossfade": 0.5,
    },
}


def db_to_gain(db: float) -> float:
    return 10.0 ** (db / 20.0)


def resolve_source(ref: str) -> Path:
    group, rest = ref.split("/", 1)
    return SOURCES[group] / rest


def read_audio(path: Path) -> np.ndarray:
    data, sr = sf.read(path, always_2d=True)
    mono = data.mean(axis=1).astype(np.float32)
    if sr != TARGET_SR:
        gcd = math.gcd(sr, TARGET_SR)
        mono = resample_poly(mono, TARGET_SR // gcd, sr // gcd).astype(np.float32)
    return mono


def apply_fades(audio: np.ndarray, fade_in: float = 0.005, fade_out: float = 0.05) -> np.ndarray:
    out = audio.copy()
    in_n = min(len(out), int(fade_in * TARGET_SR))
    out_n = min(len(out), int(fade_out * TARGET_SR))
    if in_n > 1:
        out[:in_n] *= np.linspace(0.0, 1.0, in_n, dtype=np.float32)
    if out_n > 1:
        out[-out_n:] *= np.linspace(1.0, 0.0, out_n, dtype=np.float32)
    return out


def normalize_peak(audio: np.ndarray, peak: float) -> np.ndarray:
    current = float(np.max(np.abs(audio))) if len(audio) else 0.0
    if current <= 1e-6:
        return audio
    return audio * (peak / current)


def render_layers(asset: dict) -> np.ndarray:
    rendered_layers = []
    total_len = 0
    for source_ref, offset_s, gain_db in asset["layers"]:
        audio = read_audio(resolve_source(source_ref)) * db_to_gain(gain_db)
        offset = int(offset_s * TARGET_SR)
        rendered_layers.append((audio, offset))
        total_len = max(total_len, offset + len(audio))

    mix = np.zeros(total_len, dtype=np.float32)
    for audio, offset in rendered_layers:
        mix[offset : offset + len(audio)] += audio

    if asset.get("loop_seconds"):
        target_len = int(asset["loop_seconds"] * TARGET_SR)
        crossfade = int(asset.get("crossfade", 0.5) * TARGET_SR)
        source = mix
        mix = np.zeros(target_len, dtype=np.float32)
        pos = 0
        while pos < target_len:
            remaining = target_len - pos
            chunk = source[:remaining]
            if pos == 0 or crossfade <= 0:
                mix[pos : pos + len(chunk)] += chunk
            else:
                fade_n = min(crossfade, len(chunk), pos)
                mix[pos - fade_n : pos] = (
                    mix[pos - fade_n : pos] * np.linspace(1.0, 0.0, fade_n, dtype=np.float32)
                    + chunk[:fade_n] * np.linspace(0.0, 1.0, fade_n, dtype=np.float32)
                )
                mix[pos : pos + len(chunk) - fade_n] += chunk[fade_n:]
            pos += max(1, len(source) - crossfade)

    mix = apply_fades(mix, fade_out=asset.get("fade_out", 0.05))
    return normalize_peak(mix, asset.get("peak", 0.25))


def main() -> None:
    manifest = {}
    for asset_id, asset in ASSETS.items():
        audio = render_layers(asset)
        out = OUT / asset["path"]
        out.parent.mkdir(parents=True, exist_ok=True)
        sf.write(out, audio, TARGET_SR, subtype="PCM_16")
        manifest[asset_id] = {
            "path": "res://assets/audio/" + asset["path"],
            "duration_seconds": round(len(audio) / TARGET_SR, 3),
            "loop": asset["loop"],
            "description": asset["description"],
        }
        print(f"{asset_id}: {out} {len(audio) / TARGET_SR:.3f}s")

    (OUT / "audio_manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
