"""Turn real CC0 field recordings into the layered ambience bed (biome x time-of-day).

Companion to ``prepare_free_sfx_assets.py``. The seven natural ambience layers used
by ``audio_manager.gd`` (stream / birds / wind / night insects / waves / gulls /
cave drip) are built here from **real CC0 / public-domain recordings** (the local
SFX packs hold no nature field recordings). Each source is converted to mono 44.1k,
gently softened, and turned into a seamless loop >= 15 s that sits quietly as a bed.

Source recordings live OUTSIDE the repo under SRC (not committed, like the other
free-SFX sources). Download them with ``tools/fetch_ambience_sources.py`` first.

Loop seamlessness:
  * Continuous textures (stream, wind, birds, insects, cave) use an equal-power
    boundary crossfade: a segment of length target+xfade is taken and its tail is
    blended back over its head, so sample[end] flows into sample[0] with no click.
  * Event beds (waves, gulls) are scattered into a ring buffer of exactly the loop
    length with wrap-around, so calls/crashes that cross the loop point stay seamless.

Levels: file peaks 0.12-0.18 (below the 0.20-0.32 SFX peaks). At runtime AudioManager
attenuates further by ambience_volume * recipe gain, keeping the bed 10-16 dB under SFX.

Run (after fetching sources):
    E:\\ai-audio\\stable-audio-open\\.venv\\Scripts\\python.exe tools\\prepare_ambience_assets.py
"""
from __future__ import annotations

import json
import math
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import butter, sosfiltfilt, resample_poly


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio" / "ambience"
MANIFEST = ROOT / "assets" / "audio" / "audio_manifest.json"
SRC = Path(r"E:\ai-audio\free-sfx\ambience_sources")
SR = 44_100


# ----------------------------------------------------------------------------
# Source provenance (all CC0 / public domain). Kept here as the single record
# of where each layer came from; mirrored into docs/audio_asset_rules.md.
# ----------------------------------------------------------------------------
SOURCES = {
    "amb_stream_loop": "Freesound #433589 'jackthemurray' stream-river-water-up-close (via Wikimedia Commons), CC0.",
    "amb_birds_day": "OpenGameArt 'Ambient Bird Sounds' by isaiah658, CC0.",
    "amb_wind_loop": "OpenGameArt 'wind1' open-air wind, CC0.",
    "amb_night_insects": "OpenGameArt 'Crickets ambient noise (loopable)', CC0.",
    "amb_waves_loop": "OpenGameArt 'Beach Ocean Waves' by jasinski (alkai beach), CC0.",
    "amb_gulls_day": "OpenGameArt 'Solo Seagull Sound Effects' (Seagull Ambient), CC0.",
    "amb_cave_drip": "OpenGameArt 'Dripping water loop' (atmosbasement), CC0.",
}


# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

def load_mono(name: str) -> np.ndarray:
    """Read a source file, downmix to mono, resample to 44.1 kHz."""
    data, sr = sf.read(SRC / name, always_2d=True)
    mono = data.mean(axis=1).astype(np.float32)
    if sr != SR:
        g = math.gcd(sr, SR)
        mono = resample_poly(mono, SR // g, sr // g).astype(np.float32)
    return mono


def soften(x: np.ndarray, hp: float = 45.0, lp: float = 11000.0) -> np.ndarray:
    """Zero-phase high-pass (kill rumble/DC) + gentle low-pass (tame harsh highs)."""
    out = x.astype(np.float64)
    out = sosfiltfilt(butter(2, hp / (SR / 2), btype="high", output="sos"), out)
    if lp < SR / 2:
        out = sosfiltfilt(butter(2, lp / (SR / 2), btype="low", output="sos"), out)
    return out.astype(np.float32)


def normalize_peak(x: np.ndarray, peak: float) -> np.ndarray:
    cur = float(np.max(np.abs(x))) if len(x) else 0.0
    if cur <= 1e-9:
        return x.astype(np.float32)
    return (x * (peak / cur)).astype(np.float32)


def rms(x: np.ndarray) -> float:
    return float(np.sqrt(np.mean(np.square(x)))) if len(x) else 0.0


def seamless_loop(x: np.ndarray, target_s: float, xfade_s: float = 0.75) -> np.ndarray:
    """Equal-power boundary crossfade -> a click-free loop of length target_s.

    Take target+xfade samples (tiling the source if it is shorter), then blend the
    tail overlap back over the head so the last sample flows into the first.
    """
    n = int(target_s * SR)
    xf = int(xfade_s * SR)
    need = n + xf
    if len(x) < need:
        x = np.tile(x, int(np.ceil(need / len(x))))
    seg = x[:need].astype(np.float64)
    out = seg[:n].copy()
    t = np.linspace(0.0, 1.0, xf, dtype=np.float64)
    fin = np.sin(0.5 * np.pi * t)     # 0 -> 1
    fout = np.cos(0.5 * np.pi * t)    # 1 -> 0
    out[:xf] = seg[n:n + xf] * fout + seg[:xf] * fin
    return out.astype(np.float32)


def place(buf: np.ndarray, start: int, kernel: np.ndarray, gain: float = 1.0) -> None:
    """Add `kernel` into ring buffer `buf` at `start`, wrapping past the end."""
    n = len(buf)
    idx = (int(start) + np.arange(len(kernel))) % n
    np.add.at(buf, idx, (kernel * gain).astype(np.float32))


# ----------------------------------------------------------------------------
# Layer builders
# ----------------------------------------------------------------------------

def build_stream() -> np.ndarray:
    # Quiet up-close brook; lift level and loop a calm interior 24 s window.
    x = soften(load_mono("stream_src.wav"))
    return normalize_peak(seamless_loop(x, 24.0), 0.18)


def build_wind() -> np.ndarray:
    x = soften(load_mono("wind1_src.wav"))
    return normalize_peak(seamless_loop(x, 26.0), 0.15)


def build_birds() -> np.ndarray:
    x = soften(load_mono("birds_src.ogg"))
    return normalize_peak(seamless_loop(x, 28.0, xfade_s=1.0), 0.14)


def build_night_insects() -> np.ndarray:
    # 11 s loopable crickets -> tiled to a 22 s seamless bed.
    x = soften(load_mono("insects_src.mp3"))
    return normalize_peak(seamless_loop(x, 22.0), 0.13)


def build_cave() -> np.ndarray:
    x = soften(load_mono("cave_src.flac"))
    return normalize_peak(seamless_loop(x, 20.0), 0.15)


def build_waves(seconds: float = 24.0, seed: int = 11) -> np.ndarray:
    # Scatter the 4 short real wave crashes into a 24 s ring buffer -> rolling surf.
    rng = np.random.default_rng(seed)
    clips = [normalize_peak(soften(load_mono(f"wave_{i:02d}_src.flac")), 1.0) for i in (1, 2, 3, 4)]
    n = int(seconds * SR)
    buf = np.zeros(n, dtype=np.float32)
    n_waves = 6                                  # ~one swell every 4 s
    for k in range(n_waves):
        clip = clips[k % len(clips)]
        onset = int((k + rng.uniform(-0.25, 0.25)) * n / n_waves)
        place(buf, onset, clip, gain=rng.uniform(0.75, 1.0))
    return normalize_peak(buf, 0.18)


def build_gulls(seconds: float = 30.0, seed: int = 22) -> np.ndarray:
    # Sparse real gull calls scattered over a 30 s ring buffer (rides over waves in-game).
    rng = np.random.default_rng(seed)
    calls = [soften(load_mono("gulls_amb1_src.wav")), soften(load_mono("gulls_amb2_src.wav"))]
    calls = [normalize_peak(c, 1.0) for c in calls]
    n = int(seconds * SR)
    buf = np.zeros(n, dtype=np.float32)
    onsets = sorted(rng.uniform(0, n, size=6).astype(int))
    for k, onset in enumerate(onsets):
        place(buf, onset, calls[k % len(calls)], gain=rng.uniform(0.55, 0.85))
    return normalize_peak(buf, 0.13)


# ----------------------------------------------------------------------------
# Manifest + write-out
# ----------------------------------------------------------------------------

ASSETS = {
    "amb_stream_loop": (build_stream, "Seamless mountain-stream/riffle bed."),
    "amb_birds_day": (build_birds, "Quiet daytime woodland birdsong bed."),
    "amb_wind_loop": (build_wind, "Open-air wind bed."),
    "amb_night_insects": (build_night_insects, "Warm-night cricket bed."),
    "amb_waves_loop": (build_waves, "Ocean swell bed (rolling surf)."),
    "amb_gulls_day": (build_gulls, "Coastal gull bed (sparse calls)."),
    "amb_cave_drip": (build_cave, "Cavern-pool water-drip bed."),
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = {}
    if MANIFEST.exists():
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))

    for asset_id, (builder, blurb) in ASSETS.items():
        audio = builder()
        out = OUT / (asset_id + ".wav")
        sf.write(out, audio, SR, subtype="PCM_16")
        manifest[asset_id] = {
            "path": "res://assets/audio/ambience/" + asset_id + ".wav",
            "duration_seconds": round(len(audio) / SR, 3),
            "loop": True,
            "description": blurb + " Source: " + SOURCES[asset_id],
        }
        print("%-18s %5.2fs  peak=%.3f rms=%.4f  %s" % (
            asset_id, len(audio) / SR, float(np.max(np.abs(audio))), rms(audio), out.name))

    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("manifest merged -> %s (%d entries)" % (MANIFEST.name, len(manifest)))


if __name__ == "__main__":
    main()
