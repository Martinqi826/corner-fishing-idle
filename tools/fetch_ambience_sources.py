"""Download the CC0 / public-domain source recordings for the ambience bed.

Fetches the raw nature recordings into SRC (outside the repo, like the other
free-SFX sources). After running this, run ``tools/prepare_ambience_assets.py`` to
turn them into the seamless game-ready loops under ``assets/audio/ambience/``.

Every source below is CC0 or public domain (verified on its source page). Origins
are recorded in ``docs/audio_asset_rules.md`` and in prepare_ambience_assets.py.

Run:
    E:\\ai-audio\\stable-audio-open\\.venv\\Scripts\\python.exe tools\\fetch_ambience_sources.py
"""
from __future__ import annotations

import time
import urllib.request
from pathlib import Path


SRC = Path(r"E:\ai-audio\free-sfx\ambience_sources")
UA = "Mozilla/5.0 corner-fishing-audio (martinqi826@gmail.com)"

# local name -> (url, license, what it is)
FILES = {
    # stream: Freesound #433589 (jackthemurray) mirrored on Wikimedia Commons, CC0
    "stream_src.wav": "https://upload.wikimedia.org/wikipedia/commons/5/54/433589_jackthemurray_stream-river-water-up-close.wav",
    # birds: OpenGameArt "Ambient Bird Sounds" by isaiah658, CC0
    "birds_src.ogg": "https://opengameart.org/sites/default/files/birds-isaiah658_0.ogg",
    # wind: OpenGameArt "wind1", CC0
    "wind1_src.wav": "https://opengameart.org/sites/default/files/wind1.wav",
    # night insects: OpenGameArt "Crickets ambient noise (loopable)", CC0
    "insects_src.mp3": "https://opengameart.org/sites/default/files/crickets_1.mp3",
    # cave drip: OpenGameArt "Dripping water loop" (atmosbasement), CC0
    "cave_src.flac": "https://opengameart.org/sites/default/files/atmosbasement.mp3_.flac",
    # ocean waves: OpenGameArt "Beach Ocean Waves" by jasinski (alkai beach), CC0
    "wave_01_src.flac": "https://opengameart.org/sites/default/files/wave_01_cc0-18363__jasinski__alkaibeach.flac",
    "wave_02_src.flac": "https://opengameart.org/sites/default/files/wave_02_cc0-18363__jasinski__alkaibeach.flac",
    "wave_03_src.flac": "https://opengameart.org/sites/default/files/wave_03_cc0-18363__jasinski__alkaibeach.flac",
    "wave_04_src.flac": "https://opengameart.org/sites/default/files/wave_04_cc0-18363__jasinski__alkaibeach.flac",
    # gulls: OpenGameArt "Solo Seagull Sound Effects" (Seagull Ambient), CC0
    "gulls_amb1_src.wav": "https://opengameart.org/sites/default/files/Seagull%20Ambient%201.wav",
    "gulls_amb2_src.wav": "https://opengameart.org/sites/default/files/Seagull%20Ambient%202.wav",
}


def download(name: str, url: str, tries: int = 3) -> None:
    dest = SRC / name
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            data = urllib.request.urlopen(req, timeout=120).read()
            dest.write_bytes(data)
            print("  ok  %-20s %8d B" % (name, len(data)))
            return
        except Exception as exc:  # noqa: BLE001
            if i == tries - 1:
                print("  FAIL %-20s %s" % (name, exc))
            else:
                time.sleep(2)


def main() -> None:
    SRC.mkdir(parents=True, exist_ok=True)
    for name, url in FILES.items():
        download(name, url)
    print("done -> %s" % SRC)


if __name__ == "__main__":
    main()
