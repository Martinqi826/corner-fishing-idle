from __future__ import annotations

import argparse
import json
import os
import shutil
from pathlib import Path

import soundfile as sf
import torch
from diffusers import StableAudioPipeline


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PROMPTS = ROOT / "tools" / "elevenlabs_sfx_prompts.json"
DEFAULT_OUTPUT = ROOT / "assets" / "audio"
DEFAULT_MODEL = "stabilityai/stable-audio-open-small"


NEGATIVE_PROMPT = (
    "low quality, distorted, clipped, noisy, harsh, synthetic beep, chiptune, arcade, "
    "sci-fi laser, spoken words, human voice, singing, melody-heavy jingle, busy music"
)


def load_config(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def target_path(output_root: Path, rel_path: str, output_format: str) -> Path:
    rel = Path(rel_path)
    return output_root / rel.with_suffix(f".{output_format}")


def write_manifest(output_root: Path, assets: list[dict], output_format: str) -> None:
    manifest = {}
    for asset in assets:
        rel = Path(asset["path"]).with_suffix(f".{output_format}").as_posix()
        manifest[asset["id"]] = {
            "path": "res://assets/audio/" + rel,
            "duration_seconds": asset["duration_seconds"],
            "loop": bool(asset.get("loop", False)),
            "description": asset["prompt"],
        }
    (output_root / "audio_manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate local SFX with Stable Audio Open.")
    parser.add_argument("--config", default=str(DEFAULT_PROMPTS))
    parser.add_argument("--output-root", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--only", nargs="*", help="Asset ids to generate.")
    parser.add_argument("--steps", type=int, default=120)
    parser.add_argument("--cfg-scale", type=float, default=7.0)
    parser.add_argument("--seed", type=int, default=20260613)
    parser.add_argument("--output-format", choices=["wav"], default="wav")
    parser.add_argument("--skip-existing", action="store_true")
    parser.add_argument("--copy-to-project", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    config = load_config(Path(args.config))
    style_guide = config.get("style_guide", "")
    output_root = Path(args.output_root)
    output_root.mkdir(parents=True, exist_ok=True)

    selected = set(args.only or [])
    assets = [asset for asset in config["assets"] if not selected or asset["id"] in selected]
    unknown = selected - {asset["id"] for asset in config["assets"]}
    if unknown:
        raise SystemExit(f"Unknown asset ids: {', '.join(sorted(unknown))}")

    print(f"Loading {args.model}")
    pipe = StableAudioPipeline.from_pretrained(args.model, torch_dtype=torch.float16)
    pipe = pipe.to("cuda" if torch.cuda.is_available() else "cpu")
    sample_rate = pipe.vae.sampling_rate
    generator = torch.Generator(pipe.device).manual_seed(args.seed)

    for asset in assets:
        duration = max(2.0, float(asset["duration_seconds"]))
        prompt = f"{asset['prompt']}\n\nOverall style: {style_guide}"
        out = target_path(output_root, asset["path"], args.output_format)
        if args.skip_existing and out.exists():
            print(f"Skipping existing {out}")
            continue
        out.parent.mkdir(parents=True, exist_ok=True)
        print(f"\n[{asset['id']}] {duration:.1f}s -> {out}")
        audio = pipe(
            prompt,
            negative_prompt=NEGATIVE_PROMPT,
            num_inference_steps=args.steps,
            guidance_scale=args.cfg_scale,
            audio_end_in_s=duration,
            num_waveforms_per_prompt=1,
            generator=generator,
        ).audios[0]
        sf.write(out, audio.T, sample_rate)

    write_manifest(output_root, config["assets"], args.output_format)
    if args.copy_to_project and output_root.resolve() != DEFAULT_OUTPUT.resolve():
        for item in output_root.iterdir():
            dest = DEFAULT_OUTPUT / item.name
            if item.is_dir():
                shutil.copytree(item, dest, dirs_exist_ok=True)
            else:
                DEFAULT_OUTPUT.mkdir(parents=True, exist_ok=True)
                shutil.copy2(item, dest)
    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
