# GymRat character appearance pipeline

## Runtime rule

GymRat never places hats, chains, clothes, shoes, badges, or other cosmetic
images over the rat at runtime. Flutter renders one complete character asset at
a time. This prevents drifting equipment during breathing, incorrect placement
across identities, and front-facing clothing appearing in the back view.

The equipped appearance ID follows the character through the hub, level-up,
reward, and evolution sequences. Every surface resolves the same approved stage
for the player's current level; an unknown or incomplete appearance falls back
to the base catalog before rendering.

The existing item PNG files are product concept thumbnails only. They may be
shown beside the character in Gym Armory, but never inside the character stack.

## Release matrix

Every selectable or purchasable appearance must contain all six approved
full-character renders:

| Identity | Front | Back |
| --- | --- | --- |
| Male | Required | Required |
| Female | Required | Required |
| Non-binary | Required | Required |

The same six-file matrix is required for every supported evolution stage. The
stage plan and visual acceptance rules live in
`docs/CHARACTER_EVOLUTION_ART_DIRECTION.md`. Until a complete stage is approved,
the catalog selects the latest approved stage at one stable display scale.
Flutter must never imply muscular development by stretching or enlarging the
same raster. Partial stages are never reachable at runtime.

## Acceptance criteria

An appearance may be added to `RatAppearanceCatalog.all` only when:

1. every required full-character file has been reviewed and approved;
2. front and back assets use matching framing, canvas size, foot line, lighting,
   identity, outfit, and tail treatment;
3. transparent edges have been checked against the graphite hub background;
4. breathing and level/evolution scaling do not expose seams or clipped pixels;
5. all six assets are declared in Flutter and covered by catalog tests;
6. its store product is configured in both Apple and Google stores through
   RevenueCat before the product identifier is added to code;
7. its Android and iOS bundle-size impact has been measured. Drafts and source
   masters must stay outside Flutter's bundled asset directories, and source
   plus runtime exports must never both ship in the app.

The base appearance defines the required release stages. When a new base stage
is activated, every purchasable appearance must provide that same complete
six-file stage before it can remain purchasable or equipable.

Incomplete appearances remain collection concepts. The app must not spend
Armory Credits, initiate a store purchase, or change the equipped appearance
for them.

## Persistence and migration

Inventory version 3 stores `equippedAppearanceId` and the selected front/back
character view. Version 1
slot-based `equipped` data is deliberately ignored during migration because it
referred to runtime overlays. Credits, claimed quests, and owned item IDs are
preserved. Unknown or incomplete appearance identifiers safely fall back to
the base appearance.

## Poses and emotes

The built-in power stance is a bounded squash, recoil, energy-ring, and haptic
response around the currently approved full-character asset. It works for every
identity and view, never pretends to change the limb pose, never composites an
item, and never replaces the selected master.

Any future authored pose or multi-frame emote follows the same release matrix
as an appearance: male, female, and non-binary, front and back, at every stage
where it is offered. A partial pose remains unavailable. Frames must preserve
canvas size, foot line, lighting, identity, outfit, and transparency so the
animation cannot jump or drift.

## Motion matrix

Authored breathing, blink, tail, and emote motion follows the same identity,
view, appearance, and approved-stage routing as the neutral render. The base
level-1 front and back masters for male, female, and non-binary each have
deterministic full-canvas breathing frames derived from their own exact
approved master. The frames preserve identity and transparency and are reused
for every player level that currently resolves to approved stage 1. Every
level-1 front view also has identity-specific authored blink, tail, and double
biceps frames. Back views currently use authored breathing only; front-only
motion is never mislabeled or reused behind the character.

Later-stage, back-view, and outfit motion frames must be exported from their
matching approved neutral render. Never reuse one identity's frames for another
and never reuse front frames for the back view. The level 1-100 Blender source
and export contract lives in `tool/character_pipeline/pipeline_manifest.json`.
Character Lab reports whether the selected combination has authored motion or
uses the safe fallback.

## Tail anchor contract

Every identity uses one anatomical tail root on the rear midline at the
coccyx. The rear waistband conceals the attachment; the tail must never appear
to begin at the crotch, below the shorts, or between the thighs. The Blender
rig therefore has an explicit `tail_root` bone parented to `pelvis`, followed
by the articulated tail chain.

The root position is identical in neutral, breathing, blinking, tail, and emote
exports. Motion may bend the articulated chain but may not translate its root.
Both front and back review renders must pass this check for male, female, and
non-binary before a stage is activated. The current female and non-binary
level-1 back references require an authored rerender at this anchor; an AI edit
that changes the shorts, body, framing, or transparency is not acceptable.
