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
the catalog selects the latest approved stage and the existing progression
scale supplies visual growth. Partial stages are never reachable at runtime.

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

Inventory version 2 stores a single `equippedAppearanceId`. Version 1
slot-based `equipped` data is deliberately ignored during migration because it
referred to runtime overlays. Credits, claimed quests, and owned item IDs are
preserved. Unknown or incomplete appearance identifiers safely fall back to
the base appearance.
