# GymRat character evolution art direction

The male level-100 front-view silhouette direction was approved on 2026-09-04.
It remains a production reference, not a runtime milestone asset, until its
matching back view, exact canvas export, motion set, and validation gate pass.

## Source of truth

Every evolution line starts from the approved level-1 master for that identity
and view. Male, female, and non-binary are three independent character lines;
front and back are paired views of the same character. A later stage must be an
identity-preserving progression, never a newly invented rat.

The runtime stages are level 1, 5, 10, 15, 20, 30, 40, 50, 60, 70, 80, 90,
and 100. A stage is not eligible for release until all six files exist and
pass the asset contract.

## Physique progression

| Level | Visual read | Growth ceiling |
| --- | --- | --- |
| 1 | Smallest starting body; trained enough to belong in the world, but clearly at the beginning | Baseline |
| 5 | First earned change; subtly broader shoulders, stronger limbs, and firmer torso/back | Early trained |
| 10 | Clearly athletic; visible upper-body and leg development | Athletic |
| 15 | Advanced trainee; stronger V-taper and muscle separation | Muscular |
| 20 | Serious lifter; dense chest/back, shoulders, arms, and legs | Highly muscular |
| 30 | Competitive build; imposing without losing the character silhouette | Elite |
| 40 | Near-final champion; extreme but anatomically coherent | Near Olympia |
| 50 | National champion; substantially larger while retaining room to evolve | Champion |
| 60 | International competitor; dense and imposing | Elite champion |
| 70 | Professional bodybuilding silhouette with balanced extreme mass | Pro |
| 80 | Top professional; exceptional whole-body size and separation | Top pro |
| 90 | Near-final champion; extreme but anatomically coherent | Near Olympia |
| 100 | Maximum transformation and unmistakable final reward | Mr Olympia scale |

Growth must be visible in both views and distributed over the whole body. Do
not express progression by enlarging only the chest or arms. Keep hands, feet,
head, tail, and joints believable. Gender identity must remain readable without
stereotyping or changing the face between stages.

## Locked visual properties

For every stage, preserve:

- face, expression, eye color, ears, muzzle, whiskers, fur palette, and texture;
- neutral stance, camera height, camera angle, symmetry, and foot line;
- black training shorts and their green accent treatment;
- warm rim light, premium realistic game-render style, and full-body crop;
- complete ears, hands, feet, claws, and tail inside safe transparent margins.

Do not add text, level badges, logos, equipment, scenery, platforms, auras,
store items, or UI to an evolution master. Purchasable appearances are authored
as separate complete character renders, never Flutter overlays.

## File contract

Use these paths for every approved stage, with two-digit levels:

```text
assets/characters/male/level_05.png
assets/characters/male/level_05_back.png
assets/characters/female/level_05.png
assets/characters/female/level_05_back.png
assets/characters/non_binary/level_05.png
assets/characters/non_binary/level_05_back.png
```

Each PNG must use genuine 32-bit RGBA transparency. Checkerboards, black/white
matte backgrounds, opaque corner pixels, alpha halos, and cropped tails are
release blockers. A front/back pair must keep canvas aspect ratio and dimensions
within three percent so evolution morphs remain anchored.

## Review sequence

1. Compare the new render with its own level-1 master at identical display size.
2. Compare front and back for identity, musculature, shorts, tail, and foot line.
3. Compare all three identities at the same level for equivalent progression.
4. Run the character asset contract tests.
5. Review every milestone in the debug-only Character Lab on a device.
6. Measure the runtime export's Android and iOS bundle-size impact; keep draft
   and archival source files outside the bundled `assets/characters` folders.
7. Add the complete six-file stage to `RatAppearanceCatalog.base.stages` in one
   commit. Never activate a partial stage.

Until a full stage passes this sequence, the catalog intentionally falls back
to the latest approved stage at a stable display scale. Runtime scaling must
never be presented as physique growth. The evolution sequence is shown only
when the source and target are distinct, complete, approved stage assets.

## Identity-preserving production brief

Use the correct approved gender/view master as the only reference. Replace the
bracketed stage direction with the matching row from the physique table:

> Edit this exact approved GymRat level-1 character master into the matching
> level [LEVEL] evolution. Preserve the same rat identity, face, expression,
> eyes, ears, whiskers, fur, shorts, pose, camera, warm rim light, full-body
> framing, foot line, tail, and premium realistic game-render style. Change only
> the physique: [STAGE DIRECTION]. Keep anatomy believable and symmetric. Add
> no accessories, equipment, text, logos, badges, scenery, platforms, auras, or
> UI. Keep ears, hands, feet, claws, and the complete tail visible. Output a PNG
> with genuine 32-bit RGBA transparency and alpha-0 corner pixels—never a
> checkerboard or matte background.

This is an edit brief, not permission to invent a replacement character. A
render that changes identity or fails the alpha/canvas contract is discarded.
