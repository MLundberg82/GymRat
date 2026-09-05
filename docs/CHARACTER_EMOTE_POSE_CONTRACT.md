# GymRat authored emote pose contract

## Sources and interpretation

GymRat uses the International Federation of Bodybuilding and Fitness pose
definitions as the anatomical reference. The primary references are the IFBB
Men's Bodybuilding Rules 2024 and Women's Physique Rules 2024:

- https://ifbb.com/wp-content/uploads/2024/02/Mens-Bodybuilding-Rules-2024.pdf
- https://ifbb.com/wp-content/uploads/2024/02/Womens-Physique-Rules-2024.pdf

The pose mechanics are shared across male, female, and non-binary GymRat
identities. Identity, proportions, face, outfit, fur, palette, and muscle mass
remain those of the matching approved master. Women's Physique uses open hands
for double biceps; the male and non-binary lines use clenched, downward-turned
fists unless a later reviewed identity-specific direction says otherwise.

## Double biceps

The entry is part of the authored animation, not a synthetic Flutter transform.
Both arms first extend straight outward until the upper arms are at shoulder
height. The elbows then bend inward while the upper arms remain at that height.
The front pose moves one leg forward and outward. The back pose uses the same
arm mechanics while one foot moves backward and rests on the toes. Arms may not
remain beside the torso or curl only at waist height.

## Chest flex

This is the IFBB side-chest pose. The character turns to present the stronger
side, bends the near arm to a right angle, and uses the far hand to grip the
near wrist. The near leg bends and rests on the toes while the chest expands.
Front and back camera exports use independently authored turn directions so the
chest remains readable from the selected view.

## Leg pose

This is the IFBB abdominals-and-thighs pose. Both hands move behind the head,
one leg steps forward, and the torso crunches slightly while the abdominal and
front-thigh muscles contract. The feet remain grounded and the character's
canvas foot line does not jump.

## Triceps

This is the IFBB side-triceps pose. Both arms move behind the back and the rear
hand grips the front wrist. The near foot stays flat, the far foot rests on its
toes, the chest stays raised, and the front arm extends under pressure. Front
and back exports use independently authored sides.

## Animation and release requirements

Every sequence uses 48 frames at 24 fps: neutral at frame 1, readable entry at
frame 10, full contraction at frame 24, held contraction through frame 38, and
the exact neutral master again at frame 48. The root, canvas, camera, lighting,
foot line, and coccyx-level tail attachment stay fixed. Only the pose bones and
the muscle deformation needed for contraction may change.

No emote is registered in Flutter until all four poses exist for male, female,
and non-binary, front and back, at the matching evolution stage and appearance.
Each PNG must be 1024×1792 RGBA with genuine alpha transparency. Purchased
appearances follow the same complete matrix; front-only, identity-swapped, or
static-image approximations are rejected.
