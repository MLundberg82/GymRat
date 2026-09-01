# GymRat character appearance pipeline

## Runtime rule

GymRat never places hats, chains, clothes, shoes, badges, or other cosmetic
images over the rat at runtime. Flutter renders one complete character asset at
a time. This prevents drifting equipment during breathing, incorrect placement
across identities, and front-facing clothing appearing in the back view.

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

When milestone-specific masters are introduced, the same six-file matrix is
required for every supported evolution stage. Until then, the complete base
appearance is used at all milestones and growth is applied by the existing
progression scale.

## Acceptance criteria

An appearance may be added to `RatAppearanceCatalog.all` only when:

1. every required full-character file has been reviewed and approved;
2. front and back assets use matching framing, canvas size, foot line, lighting,
   identity, outfit, and tail treatment;
3. transparent edges have been checked against the graphite hub background;
4. breathing and level/evolution scaling do not expose seams or clipped pixels;
5. all six assets are declared in Flutter and covered by catalog tests;
6. its store product is configured in both Apple and Google stores through
   RevenueCat before the product identifier is added to code.

Incomplete appearances remain collection concepts. The app must not spend
Armory Credits, initiate a store purchase, or change the equipped appearance
for them.

## Persistence and migration

Inventory version 2 stores a single `equippedAppearanceId`. Version 1
slot-based `equipped` data is deliberately ignored during migration because it
referred to runtime overlays. Credits, claimed quests, and owned item IDs are
preserved. Unknown or incomplete appearance identifiers safely fall back to
the base appearance.
