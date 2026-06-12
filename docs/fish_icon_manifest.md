# Fish Icon Manifest

All fish in `fish_data.gd` now have production-style painterly icons.

Runtime icons are stored at:

```text
assets/art/fish/{fish_id}.png
```

Larger source icons are stored at:

```text
assets/art/fish/source/{fish_id}.png
```

The generated source sheets are stored at:

```text
assets/art/source/fish_sheets/
```

Machine-readable mapping:

```text
assets/art/fish/fish_art_manifest.json
```

## Fish IDs

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
