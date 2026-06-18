`FishIcon` — renders a painterly fish (or equipment) PNG with optional tier framing and rare-variant glow.

```jsx
<FishIcon src="assets/fish/koi.png" tier={4} size={34} />
<FishIcon src="assets/fish/koi.png" tier={4} variant={2} frame />   {/* 鎏金 shimmer */}
<FishIcon src="assets/fish/oarfish.png" tier={5} dimmed fallbackSrc="assets/fish/generic_tier5.png" />
```

- Icons are 64×64 source art; the box `size` scales them down (image sits at 84%).
- `frame` adds a dark backing + tier-coloured hairline (good for the codex grid). Without it, the icon floats transparent (bag rows).
- `variant` 1/2/3 adds the cyan / gilded-shimmer / prismatic glow that signals a rare catch.
- Always pass `fallbackSrc` (a `generic_tier{n}.png`) so a missing species art degrades gracefully — never breaks.
