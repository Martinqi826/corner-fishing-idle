# Fish Icon Art Standard

This document is the production bar for every fish icon in Corner Fishing Idle.
It applies to the existing icons, the 46 newly requested icons, and all future
fish additions.

## Non-Negotiable Rule

The approved visual reference is the existing production icon set:

- `assets/art/fish/carp.png`
- `assets/art/fish/koi.png`
- `assets/art/fish/bass.png`
- `assets/art/fish/mandarin.png`
- `assets/art/fish/source/carp.png`
- `assets/art/fish/source/koi.png`
- `assets/art/fish/source/bass.png`
- `assets/art/fish/source/mandarin.png`

These are not loose inspiration. They are the quality and style target. A new
fish icon is not production-ready unless it can sit beside those icons without
looking flatter, more procedural, more realistic, more saturated, or from a
different illustration set.

## Required Output

For each accepted fish id:

- Runtime icon: `assets/art/fish/<id>.png`
- Source icon: `assets/art/fish/source/<id>.png`
- Runtime size: 64 x 64 PNG
- Source size: 128 x 128 PNG
- Background: transparent
- Subject: one fish or one aquatic creature only
- View: full-body side view, head facing right where anatomically possible
- Framing: centered, roughly matching the existing icon footprint

## Style Requirements

Every new icon must match the existing production icons in:

- watercolor / light ink texture
- soft but readable transparent edge
- muted winter palette
- restrained contrast
- hand-painted body volume
- fin and eye treatment
- small-icon readability at 64 x 64
- natural species color, never rarity-color tinting

Do not ship icons that look like:

- procedural drawings
- recolored templates with weak material depth
- scientific fish illustrations
- AI sticker art
- vector icons
- flat silhouettes
- photorealistic cutouts
- heavily saturated fantasy fish
- fish with hard black outlines

## Acceptance Checklist

Before any new icon may be placed in `assets/art/fish/<id>.png`, compare it in a
single row against `carp`, `koi`, `bass`, and `mandarin`.

Reject it if any answer is "no":

- Does it have the same painterly material quality as the references?
- Does it have comparable edge softness and alpha cleanup?
- Does it have comparable detail density at 64 x 64?
- Does it avoid looking more realistic or more procedural than the references?
- Does it use natural species color instead of tier color?
- Does it feel like it belongs to the exact same icon set?

## Current State

The original 28 icons are the approved production baseline.

The 46 newly requested ids are considered **not finally approved** until they
are redrawn to the exact baseline above. Automatically generated or template
derived versions may be kept only as WIP candidates and must not be treated as
final production art.

## Production Workflow For Future Additions

1. Generate or paint a source icon while using the approved icons above as
   strong references.
2. Save the candidate outside the runtime path, for example under
   `assets/art/fish/wip/`.
3. Build a comparison sheet with `carp`, `koi`, `bass`, `mandarin`, and the
   candidate.
4. Review against the acceptance checklist.
5. Only after acceptance, copy into:
   - `assets/art/fish/<id>.png`
   - `assets/art/fish/source/<id>.png`
6. Update `assets/art/fish/fish_art_manifest.json`.
7. Regenerate `docs/img/fish_icon_contact_sheet.png`.

If the icon does not pass review, leave it out of the runtime path. The game can
fall back to the tier generic icon; shipping a mismatched fish icon is worse than
using the fallback temporarily.
