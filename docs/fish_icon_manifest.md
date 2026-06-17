# Fish Icon Manifest

This file tracks fish icon paths, but production approval is governed by
`docs/fish_icon_art_standard.md`.

The original 28 icons are the approved production baseline. New icons must match
that baseline before they are treated as final art.

Runtime icons are stored at:

```text
assets/art/fish/{fish_id}.png
```

Larger source icons are stored at:

```text
assets/art/fish/source/{fish_id}.png
```

Historical/generated source sheets are stored at:

```text
assets/art/source/fish_sheets/
```

Machine-readable mapping:

```text
assets/art/fish/fish_art_manifest.json
```

## Fish IDs

Approved baseline ids:

Common:

- `whitebait`
- `topmouth`
- `loach`
- `crucian`
- `bighead`
- `yellowhead`

Good:

- `dace`
- `carp`
- `grass`
- `bream`
- `blackcarp`

Rare:

- `bass`
- `fangbream`
- `barbel`
- `culter`
- `mandarin`

Epic:

- `snakehead`
- `trout`
- `pike`
- `zander`
- `longsnout`
- `lenok`

Legendary and Mythical:

- `koi`
- `salmon`
- `sturgeon`
- `taimen`
- `chinese_sturgeon`
- `kaluga`

## Compatibility Aliases

The older generic icons are kept in sync for current UI mockups or code that still references them:

- `fish_common_01.png` -> `whitebait`
- `fish_common_02.png` -> `dace`
- `fish_rare_01.png` -> `fangbream`

## Preview

```text
docs/img/fish_icon_contact_sheet.png
```

## Quality Gate

Do not add future fish icons directly to the runtime path just because a PNG was
generated. First review them against `docs/fish_icon_art_standard.md`. If they do
not match the approved baseline (`carp`, `koi`, `bass`, `mandarin`), keep them in
WIP and let the game use its fallback icon.
