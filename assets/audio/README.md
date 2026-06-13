# Audio Generation

This folder contains the current runtime audio assets.

The active set is built from free CC0 source packs and processed for a soft, healing game tone. See `docs/audio_asset_rules.md` for source mapping, playback rules, and Claude-facing integration guidance.

Regenerate the current free-SFX set with:

```powershell
E:\ai-audio\stable-audio-open\.venv\Scripts\python.exe tools\prepare_free_sfx_assets.py
```

## Deprecated AI Generation

The previous procedural placeholder `.wav` files were removed because they sounded too synthetic for the game's art direction. Use the ElevenLabs workflow instead:

```powershell
$env:ELEVENLABS_API_KEY = "your_api_key_here"
py -3 tools\generate_elevenlabs_sfx.py
```

Useful options:

```powershell
py -3 tools\generate_elevenlabs_sfx.py --dry-run
py -3 tools\generate_elevenlabs_sfx.py --only cast bobber_splash bite
py -3 tools\generate_elevenlabs_sfx.py --skip-existing
```

Prompts live in `tools/elevenlabs_sfx_prompts.json`. The generated files are expected to match `assets/audio/audio_manifest.json`.

## Local Free Generation

The local environment is installed under `E:\ai-audio\stable-audio-open`.

AudioLDM2 is public and can generate a full local set without API credits:

```powershell
$env:HF_HOME = "E:\ai-audio\hf-cache"
$env:HUGGINGFACE_HUB_CACHE = "E:\ai-audio\hf-cache\hub"
E:\ai-audio\stable-audio-open\.venv\Scripts\python.exe tools\generate_audioldm2_sfx.py
```

Stable Audio Open is also configured, but its Hugging Face repository is gated. Accept the model license and login before running it:

```powershell
$env:HF_HOME = "E:\ai-audio\hf-cache"
$env:HUGGINGFACE_HUB_CACHE = "E:\ai-audio\hf-cache\hub"
$env:HF_TOKEN = "your_huggingface_token"
E:\ai-audio\stable-audio-open\.venv\Scripts\python.exe tools\generate_stable_audio_open_sfx.py
```
