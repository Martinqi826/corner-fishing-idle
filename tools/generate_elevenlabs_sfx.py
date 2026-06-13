from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
PROMPTS_PATH = ROOT / "tools" / "elevenlabs_sfx_prompts.json"
API_URL = "https://api.elevenlabs.io/v1/sound-generation"
DEFAULT_OUTPUT_FORMAT = "mp3_44100_128"


def load_config(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise SystemExit(f"Prompt config not found: {path}")
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Invalid JSON in {path}: {exc}") from exc


def request_sound(
    api_key: str,
    text: str,
    duration_seconds: float,
    prompt_influence: float,
    loop: bool,
    output_format: str,
) -> bytes:
    payload = {
        "text": text,
        "duration_seconds": duration_seconds,
        "prompt_influence": prompt_influence,
        "loop": loop,
    }
    data = json.dumps(payload).encode("utf-8")
    url = f"{API_URL}?output_format={output_format}"
    request = Request(
        url,
        data=data,
        method="POST",
        headers={
            "xi-api-key": api_key,
            "Content-Type": "application/json",
            "Accept": "audio/mpeg",
        },
    )
    try:
        with urlopen(request, timeout=180) as response:
            return response.read()
    except HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"ElevenLabs HTTP {exc.code}: {detail}") from exc
    except URLError as exc:
        raise RuntimeError(f"ElevenLabs request failed: {exc}") from exc


def build_prompt(style_guide: str, asset: dict) -> str:
    return f"{asset['prompt']}\n\nOverall style: {style_guide}"


def write_manifest(output_root: Path, entries: list[dict]) -> None:
    manifest = {
        entry["id"]: {
            "path": "res://assets/audio/" + entry["path"].replace("\\", "/"),
            "duration_seconds": entry["duration_seconds"],
            "loop": entry["loop"],
            "description": entry["prompt"],
        }
        for entry in entries
    }
    manifest_path = output_root / "audio_manifest.json"
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate game SFX with ElevenLabs Sound Effects API.")
    parser.add_argument("--config", default=str(PROMPTS_PATH), help="Prompt config JSON path.")
    parser.add_argument("--only", nargs="*", help="Optional list of asset ids to generate.")
    parser.add_argument("--skip-existing", action="store_true", help="Do not overwrite existing audio files.")
    parser.add_argument("--dry-run", action="store_true", help="Print prompts without calling the API.")
    parser.add_argument("--output-format", default=DEFAULT_OUTPUT_FORMAT, help="ElevenLabs output_format query value.")
    parser.add_argument("--delay", type=float, default=1.0, help="Seconds to wait between API calls.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    config = load_config(Path(args.config))
    style_guide = config.get("style_guide", "")
    output_root = ROOT / config.get("output_root", "assets/audio")
    selected_ids = set(args.only or [])
    assets = [asset for asset in config["assets"] if not selected_ids or asset["id"] in selected_ids]

    missing_ids = selected_ids - {asset["id"] for asset in config["assets"]}
    if missing_ids:
        raise SystemExit(f"Unknown asset ids: {', '.join(sorted(missing_ids))}")

    api_key = os.environ.get("ELEVENLABS_API_KEY")
    if not api_key and not args.dry_run:
        raise SystemExit("Set ELEVENLABS_API_KEY before generating audio, or use --dry-run.")

    for asset in assets:
        prompt = build_prompt(style_guide, asset)
        target = output_root / asset["path"]
        print(f"\n[{asset['id']}] -> {target.relative_to(ROOT)}")
        print(prompt)

        if args.dry_run:
            continue
        if args.skip_existing and target.exists():
            print("Skipped existing file.")
            continue

        audio = request_sound(
            api_key=api_key,
            text=prompt,
            duration_seconds=float(asset["duration_seconds"]),
            prompt_influence=float(asset.get("prompt_influence", 0.7)),
            loop=bool(asset.get("loop", False)),
            output_format=args.output_format,
        )
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(audio)
        print(f"Wrote {len(audio):,} bytes.")
        time.sleep(max(0.0, args.delay))

    write_manifest(output_root, config["assets"])
    print(f"\nManifest written: {(output_root / 'audio_manifest.json').relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
