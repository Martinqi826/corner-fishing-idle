from __future__ import annotations

import json
import math
import random
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio"
SAMPLE_RATE = 44_100


def envelope(t: float, duration: float, attack: float = 0.01, release: float = 0.08) -> float:
    if t < attack:
        return t / attack
    if t > duration - release:
        return max(0.0, (duration - t) / release)
    return 1.0


def sine(freq: float, t: float) -> float:
    return math.sin(2.0 * math.pi * freq * t)


def square(freq: float, t: float) -> float:
    return 1.0 if sine(freq, t) >= 0.0 else -1.0


def triangle(freq: float, t: float) -> float:
    phase = (freq * t) % 1.0
    return 4.0 * abs(phase - 0.5) - 1.0


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = max(1.0, max(abs(s) for s in samples))
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        for sample in samples:
            clamped = max(-1.0, min(1.0, sample / peak * 0.88))
            wav.writeframes(struct.pack("<h", int(clamped * 32767)))


def render(duration: float, fn) -> list[float]:
    count = int(duration * SAMPLE_RATE)
    return [fn(i / SAMPLE_RATE, i) for i in range(count)]


def ui_click() -> list[float]:
    duration = 0.12
    return render(duration, lambda t, _i: envelope(t, duration, 0.002, 0.04) * (0.7 * sine(920, t) + 0.25 * triangle(1840, t)))


def ui_error() -> list[float]:
    duration = 0.28

    def sample(t: float, _i: int) -> float:
        freq = 230 - 70 * min(1.0, t / duration)
        return envelope(t, duration, 0.004, 0.1) * (0.6 * square(freq, t) + 0.25 * sine(freq * 0.5, t))

    return render(duration, sample)


def cast() -> list[float]:
    duration = 0.42

    def sample(t: float, i: int) -> float:
        sweep = 900 - 620 * (t / duration)
        noise = (random.random() * 2.0 - 1.0) * max(0.0, 1.0 - t / duration)
        return envelope(t, duration, 0.008, 0.12) * (0.35 * sine(sweep, t) + 0.18 * noise)

    return render(duration, sample)


def bobber_splash() -> list[float]:
    duration = 0.52

    def sample(t: float, i: int) -> float:
        burst = random.random() * 2.0 - 1.0
        low = sine(115, t) * math.exp(-8.0 * t)
        droplets = sine(1400 + 220 * sine(7, t), t) * math.exp(-10.0 * t)
        return envelope(t, duration, 0.001, 0.18) * (0.45 * burst * math.exp(-7.0 * t) + 0.35 * low + 0.18 * droplets)

    return render(duration, sample)


def bite() -> list[float]:
    duration = 0.34

    def sample(t: float, _i: int) -> float:
        if t < 0.14:
            freq = 660
            local_t = t
        else:
            freq = 990
            local_t = t - 0.14
        pulse_env = math.exp(-10.0 * local_t)
        return (0.72 * sine(freq, t) + 0.18 * sine(freq * 2, t)) * pulse_env

    return render(duration, sample)


def catch_common() -> list[float]:
    duration = 0.46
    notes = [523.25, 659.25, 783.99]

    def sample(t: float, _i: int) -> float:
        idx = min(len(notes) - 1, int(t / 0.13))
        note_t = t - idx * 0.13
        return envelope(t, duration, 0.003, 0.1) * sine(notes[idx], t) * math.exp(-4.5 * note_t)

    return render(duration, sample)


def catch_rare() -> list[float]:
    duration = 0.86
    notes = [587.33, 739.99, 987.77, 1174.66]

    def sample(t: float, _i: int) -> float:
        idx = min(len(notes) - 1, int(t / 0.16))
        note_t = t - idx * 0.16
        shimmer = 0.2 * sine(notes[idx] * 3.01, t) * math.exp(-2.5 * t)
        return envelope(t, duration, 0.006, 0.18) * (sine(notes[idx], t) * math.exp(-4.0 * note_t) + shimmer)

    return render(duration, sample)


def coin() -> list[float]:
    duration = 0.22
    notes = [1174.66, 1567.98]

    def sample(t: float, _i: int) -> float:
        idx = 0 if t < 0.08 else 1
        note_t = t if idx == 0 else t - 0.08
        return envelope(t, duration, 0.002, 0.06) * (0.8 * triangle(notes[idx], t) + 0.25 * sine(notes[idx] * 2, t)) * math.exp(-6.5 * note_t)

    return render(duration, sample)


def upgrade() -> list[float]:
    duration = 0.92
    notes = [392.0, 493.88, 587.33, 783.99, 987.77]

    def sample(t: float, _i: int) -> float:
        idx = min(len(notes) - 1, int(t / 0.14))
        note_t = t - idx * 0.14
        chord = 0.55 * sine(notes[idx], t) + 0.24 * sine(notes[idx] * 1.5, t) + 0.16 * sine(notes[idx] * 2, t)
        return envelope(t, duration, 0.006, 0.22) * chord * math.exp(-3.2 * note_t)

    return render(duration, sample)


def ambience_water_loop() -> list[float]:
    duration = 8.0
    random.seed(1314)

    def sample(t: float, i: int) -> float:
        phase = t / duration
        loop_fade = math.sin(math.pi * phase)
        slow = 0.22 * sine(0.17, t) + 0.16 * sine(0.29, t + 1.7)
        ripple = 0.08 * sine(185 + 20 * sine(0.33, t), t)
        hiss = (random.random() * 2.0 - 1.0) * 0.035
        return loop_fade * (slow + ripple + hiss)

    base = render(duration, sample)
    fade_len = int(0.75 * SAMPLE_RATE)
    for i in range(fade_len):
        a = i / fade_len
        mixed = base[i] * a + base[-fade_len + i] * (1.0 - a)
        base[i] = mixed
        base[-fade_len + i] = mixed
    return base


ASSETS = {
    "ui/ui_click.wav": ("ui_click", ui_click, "Button click / tab tap."),
    "ui/ui_error.wav": ("ui_error", ui_error, "Invalid action or insufficient coins."),
    "fishing/cast.wav": ("cast", cast, "Rod cast and line movement."),
    "fishing/bobber_splash.wav": ("bobber_splash", bobber_splash, "Bobber entering water."),
    "fishing/bite.wav": ("bite", bite, "Fish bite prompt."),
    "fishing/catch_common.wav": ("catch_common", catch_common, "Common catch reward."),
    "fishing/catch_rare.wav": ("catch_rare", catch_rare, "Rare catch reward."),
    "economy/coin.wav": ("coin", coin, "Coins gained."),
    "economy/upgrade.wav": ("upgrade", upgrade, "Upgrade purchased."),
    "ambience/ambience_water_loop.wav": ("ambience_water_loop", ambience_water_loop, "Low-volume looping water ambience."),
}


def main() -> None:
    random.seed(20260613)
    manifest = {}
    for rel_path, (asset_id, factory, description) in ASSETS.items():
        path = OUT / rel_path
        samples = factory()
        write_wav(path, samples)
        manifest[asset_id] = {
            "path": "res://assets/audio/" + rel_path.replace("\\", "/"),
            "duration_seconds": round(len(samples) / SAMPLE_RATE, 3),
            "description": description,
        }

    manifest_path = OUT / "audio_manifest.json"
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Generated {len(ASSETS)} audio files in {OUT}")


if __name__ == "__main__":
    main()
