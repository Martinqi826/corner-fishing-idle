from __future__ import annotations

import argparse
import json
from pathlib import Path

import soundfile as sf
import torch
from diffusers import AudioLDM2Pipeline
from transformers import GPT2LMHeadModel


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PROMPTS = ROOT / "tools" / "elevenlabs_sfx_prompts.json"
DEFAULT_OUTPUT = ROOT / "assets" / "audio"
DEFAULT_MODEL = "cvssp/audioldm2"
SAMPLE_RATE = 16_000


NEGATIVE_PROMPT = (
    "music, melody, speech, voice, singing, synthetic beep, chiptune, arcade, sci-fi, "
    "distorted, clipped, harsh, loud alarm, noisy, low quality"
)


def load_config(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def target_path(output_root: Path, rel_path: str) -> Path:
    return output_root / Path(rel_path).with_suffix(".wav")


def write_manifest(output_root: Path, assets: list[dict]) -> None:
    manifest = {}
    for asset in assets:
        rel = Path(asset["path"]).with_suffix(".wav").as_posix()
        manifest[asset["id"]] = {
            "path": "res://assets/audio/" + rel,
            "duration_seconds": max(2.0, float(asset["duration_seconds"])),
            "loop": bool(asset.get("loop", False)),
            "description": asset["prompt"],
        }
    (output_root / "audio_manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate local SFX with public AudioLDM2.")
    parser.add_argument("--config", default=str(DEFAULT_PROMPTS))
    parser.add_argument("--output-root", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--only", nargs="*", help="Asset ids to generate.")
    parser.add_argument("--steps", type=int, default=80)
    parser.add_argument("--guidance-scale", type=float, default=3.5)
    parser.add_argument("--seed", type=int, default=20260613)
    parser.add_argument("--skip-existing", action="store_true")
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
    language_model = GPT2LMHeadModel.from_pretrained(
        args.model,
        subfolder="language_model",
        torch_dtype=torch.float16,
    )
    pipe = AudioLDM2Pipeline.from_pretrained(
        args.model,
        language_model=language_model,
        torch_dtype=torch.float16,
    )
    device = "cuda" if torch.cuda.is_available() else "cpu"
    pipe = pipe.to(device)
    generator = torch.Generator(device).manual_seed(args.seed)

    for asset in assets:
        duration = max(2.0, float(asset["duration_seconds"]))
        prompt = f"{asset['prompt']}\n\nOverall style: {style_guide}"
        out = target_path(output_root, asset["path"])
        if args.skip_existing and out.exists():
            print(f"Skipping existing {out}")
            continue
        out.parent.mkdir(parents=True, exist_ok=True)
        print(f"\n[{asset['id']}] {duration:.1f}s -> {out}")
        audio = pipe(
            prompt,
            negative_prompt=NEGATIVE_PROMPT,
            num_inference_steps=args.steps,
            guidance_scale=args.guidance_scale,
            audio_length_in_s=duration,
            num_waveforms_per_prompt=1,
            generator=generator,
        ).audios[0]
        sf.write(out, audio, SAMPLE_RATE)

    write_manifest(output_root, config["assets"])
    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
