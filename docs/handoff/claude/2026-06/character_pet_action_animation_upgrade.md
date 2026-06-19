# Claude Handoff: Character And Pet Action Animation Upgrade

Status: engineering handoff
Owner: Codex
Created: 2026-06-19

## Goal

Improve fisher and cat animation quality. The current result still feels like sprites are being moved by coordinates instead of characters performing actions.

Target feeling:

- Fisher has anticipation, weight shift, pull force, hold, and follow-through.
- Cat reacts with head/body intent before pawing or stealing.
- Feet/paws stay grounded; no visible sliding across the scene.
- Motion supports fishing events rather than looking like wallpaper/UI effects.

Do not change gameplay rules.

## Current Context

Relevant files:

```text
scene_painter.gd
main.gd
assets/art/character/
assets/art/pets/
docs/prototypes/scene_living_slice_demo.html
```

Current runtime assets include:

```text
assets/art/character/fisher_idle.png
assets/art/character/fisher_pull_01.png
assets/art/character/fisher_pull_02.png

assets/art/pets/cat_idle.png
assets/art/pets/cat_blink.png
assets/art/pets/cat_paw.png
assets/art/pets/cat_steal.png
assets/art/pets/cat_sleep.png
assets/art/pets/cat_shadow_soft.png
```

`docs/prototypes/scene_living_slice_demo.html` demonstrates the desired event sequence, but do not copy its CSS transform approach directly. That prototype still exposes the problem: it moves sprites instead of playing body-action clips.

## Hard Rules

1. Do not change fishing economy, fish roll, pet steal chance, inventory, save data, or achievements.
2. Keep existing public hooks:
   - `fisher_cheer()`
   - `pet_react("paw")`
   - `pet_react("steal")`
   - `set_fisher_context(night, idle)`
3. Keep existing anchors unless there is a clear visual bug:
   - `fisher_anchor`
   - `pet_anchor`
   - `rod_tip_off` / `rod_tip()`
4. Do not solve this by adding bigger coordinate offsets, random shaking, or stronger rotation.
5. Feet/paws should remain visually planted. Any per-frame offset should preserve bottom-center grounding.
6. Existing assets must remain valid fallback if new action frames are absent.

## Important Cleanup Check

Before implementing, inspect the current `scene_painter.gd`. If merge artifacts still exist, clean them inside this narrow animation pass only.

Specifically check `_pet_state_key()`: if it still references undefined variables like `key` or `breath`, remove those stale lines and restore a valid state selector.

Expected logic:

```gdscript
func _pet_state_key() -> String:
	if pet_action == "steal":
		return "steal"
	if pet_action == "paw":
		return "paw"
	if ctx_night and ctx_idle:
		return "sleep"
	if _pet_tail_active > 0.0 and _pet_tex.has("tail_01"):
		if _pet_tex.has("tail_02"):
			return "tail_01" if int(t * 4.0) % 2 == 0 else "tail_02"
		return "tail_01"
	if _pet_blink_t < 0.14:
		return "blink"
	return "idle"
```

## Desired Engineering Shape

Replace ad-hoc transform motion with small frame-based action clips.

Use a lightweight clip system inside `scene_painter.gd`, not a new scene tree or AnimationPlayer dependency unless you have a strong reason.

Suggested concepts:

```gdscript
var _fisher_action := "idle"
var _fisher_action_t := 0.0
var _fisher_action_dur := 1.0
var _fisher_clips: Dictionary = {}

var _pet_clip := "idle"
var _pet_clip_t := 0.0
var _pet_clip_dur := 1.0
var _pet_clips: Dictionary = {}
```

Each clip can be a dictionary:

```gdscript
{
	"frames": Array[Texture2D],
	"dur": 0.9,
	"loop": false,
	"holds": [0.12, 0.18, 0.36, 0.20, 0.14],
	"offsets": [Vector2.ZERO, Vector2(0, 0), ...],
	"rot": [0.0, ...],
	"scale": [Vector2.ONE, ...],
}
```

The key point: transforms are only secondary polish. The primary action should come from pose frames.

## Asset Contract For Better Frames

If new frames are added, place them under action folders, not directly in the crowded root folders:

```text
assets/art/character/actions/
assets/art/pets/actions/
```

Recommended fisher frame names:

```text
fisher_idle_01.png
fisher_idle_02.png
fisher_alert_01.png
fisher_alert_02.png
fisher_pull_01.png
fisher_pull_02.png
fisher_pull_03.png
fisher_pull_04.png
fisher_release_01.png
fisher_cheer_01.png
fisher_cheer_02.png
fisher_shiver_01.png
fisher_shiver_02.png
fisher_doze_01.png
```

Recommended cat frame names:

```text
cat_idle_01.png
cat_idle_02.png
cat_blink_01.png
cat_sleep_01.png
cat_sleep_02.png
cat_look_01.png
cat_paw_01.png
cat_paw_02.png
cat_paw_03.png
cat_steal_01.png
cat_steal_02.png
cat_steal_03.png
cat_tail_01.png
cat_tail_02.png
```

Fallback rule:

- If `actions/` frames exist, use them.
- If they do not exist, build clips from the current root-level assets.
- Never crash or blank the scene because optional frames are missing.

## Fisher Clip Behavior

### idle

Loop slowly. If only `fisher_idle.png` exists, draw it with no large motion.

Allowed transform polish:

- breathing scale under 1.5%
- vertical offset under 0.5px
- no visible sliding

### bite_alert

When `dip` starts rising or bobber bite begins, play a short alert/anticipation clip before the main pull.

Target:

- body leans slightly forward
- rod hand prepares
- no jump upward

Duration: `0.25 - 0.40s`.

### pull

Do not map `dip` directly to sprite position. Use `dip` to enter/hold/release the clip.

Suggested stages:

1. anticipation: slight settle / brace
2. pull_start: rod begins loading
3. pull_hold: weight is held
4. release/follow-through: returns toward idle

Duration: about `0.85 - 1.15s`, with hold extendable while `dip` remains high.

### cheer

Triggered by existing `fisher_cheer()`. Should be a distinct action clip, not just a jump/scale.

Duration: `1.2 - 1.6s`.

## Cat Clip Behavior

### idle/sleep

Cat should feel alive without fidgeting constantly.

Allowed:

- blink
- very low-frequency tail frame
- tiny breathing

Avoid:

- continuous bobbing
- sliding
- large rotation

### paw

Triggered by `pet_react("paw")`.

Use a three-stage clip:

1. look/prepare
2. paw up / peak
3. paw down / settle

Duration: `0.65 - 0.85s`.

Do not move the whole cat upward as the main action. Paw pose should carry the action.

### steal

Triggered by `pet_react("steal")`.

Use a three-stage clip:

1. crouch / focus
2. grab fish
3. return / settle

Duration: `1.0 - 1.4s`.

Do not change `main.gd` pet stealing rules.

## Rod Tip And Fishing Line

The fishing line should follow the fisher action without hard snapping.

Keep `rod_tip()` as the public source for line start, but base it on the current fisher action pose:

- idle: current `fisher_anchor + rod_tip_off`
- alert/pull_start/pull_hold/release: use per-stage rod tip offsets

Suggested offsets can remain simple:

```gdscript
var _fisher_rod_tip_offsets := {
	"idle": Vector2(-22, -50),
	"alert": Vector2(-20, -53),
	"pull_start": Vector2(-16, -57),
	"pull_hold": Vector2(-8, -60),
	"release": Vector2(-18, -54),
}
```

Interpolate between offsets with eased progress. Avoid line snapping.

## Timing And Easing

Use non-linear easing:

```gdscript
func _ease_out_cubic(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - x, 3.0)

func _ease_in_out_sine(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 0.5 - 0.5 * cos(PI * x)
```

For actions, prefer:

- anticipation: ease-in
- main pull: fast ease-out
- settle: ease-out with small follow-through

Do not use linear progress for the whole action.

## Implementation Notes

Recommended functions:

```gdscript
func _load_clip_frames(paths: Array) -> Array:
	...

func _clip_frame(clip: Dictionary, p: float) -> Dictionary:
	# returns {tex, next_tex, blend, offset, rot, scale}
	...

func _start_fisher_action(name: String, dur := -1.0) -> void:
	...

func _start_pet_clip(name: String, dur := -1.0) -> void:
	...
```

For frame blending:

- Crossfade only adjacent frames.
- Keep crossfade short, around `0.05 - 0.08s`.
- Avoid long crossfade between very different poses because it creates ghosting.

## Acceptance Criteria

1. In normal idle state, fisher and cat are calm, grounded, and not constantly bobbing.
2. On bite/pull, fisher shows anticipation → pull → hold/release, not a coordinate shake.
3. Fishing line start follows the rod tip smoothly.
4. On `pet_react("paw")`, cat paw motion reads as a body action, not a whole-sprite hop.
5. On `pet_react("steal")`, cat has crouch/grab/return timing while gameplay remains unchanged.
6. Missing optional action frames do not break the scene.
7. No new save fields are introduced.
8. No gameplay values are changed.
9. `scene_living_slice_demo.html` should look less like hard sprite movement after equivalent changes are reflected there or after in-game screenshots are captured.

## Validation

Run:

```powershell
godot --headless --editor --path . --quit
godot --headless -s tools/validate_game.gd
```

Then manually validate in-game:

- wait idle for 20 seconds
- trigger bite/pull cycle
- catch a high rarity fish to trigger `fisher_cheer()`
- trigger/observe `pet_react("paw")`
- if possible, trigger/observe `pet_react("steal")`

Report:

- files changed
- any new action assets added
- whether fallback works with `assets/art/character/actions/` and `assets/art/pets/actions/` temporarily absent
- validation command results
