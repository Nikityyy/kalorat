# Kalorat landing: critique

One critic (fresh eyes, separate agent) for the whole job, rubric
`web-designer/references/critique.md`. Renders in the scratchpad (`r4`, …).

## Round 1 (renders r4)

| # | Line | Score |
|---|---|---|
| 1 | Concept on the page | 3 |
| 2 | Not the category average | 3 |
| 3 | Not a slop face | 3 |
| 4 | First screen | 3 |
| 5 | Typography | 3 |
| 6 | Colour | 3 |
| 7 | Richness | 4 |
| 8 | Structure and rhythm | 3 |
| 9 | Craft | 2 |
| 10 | Responsive | 3 |
| 11 | Everyone's computer | 3 |
| 12 | Signature | 3 |
| 13 | The screenshot test | 3 |
| 14 | Fidelity | 4 |

Not done (2 of 13 at 4+, craft at 2).

Five changes:

1. Cartographic terrain carried down the page: index contours, spot heights
   instead of label boxes, a red-white-red trail between the summits, the day
   as an elevation profile on the same trail, a contour line instead of the
   jagged ridge divider.
2. Parts section: sharper, gentler map fly (zoom 1.6), the active spot height
   always visible, no stray contour; "three estimates" not beside a void; on
   the phone the plate stays (sticky) while the parts scroll.
3. Phone and 768 first screens: how sure and range on the card, the tempeh
   label visible, both install paths above the fold; 768 without a dead
   column.
4. Surfaces: one ground, €0 off the action green, no glow, no backdrop blur,
   no glass card, no flag as the Android icon.
5. After the shutter at 1440: no void between text and phone, waypoint
   blazes on a vertical trail instead of "01 /04", screen 3 showing the
   median of three, screen 4 showing lower / now / higher.

Defects named: overlapping day axis labels, dinner thumb on the goal line,
clipped map label, orphan contour, soft zoom, tempeh label under the nav,
seam between photo concrete and panel, step texts hidden by default, a
smeared install screenshot, the footer "AT" baseline, the week peaks'
shading, the static weight trend without its line.

### What changed after round 1 (renders r5)

1. Terrain: index contours every fourth line, spot heights (kcal as the
   elevation, name below) instead of label boxes, a red-white-red trail
   through the summits from lowest to highest, the day climb without the
   ridge, the goal as a summit ("▲ Goal"), and a smooth contour edge with two
   contour lines above it instead of the jagged ridge into the dark section.
2. Parts: zoom 1.6, the hot spot height always shown, no stray contour; on
   the phone the plate is sticky (44svh) and flies to the part whose row is in
   the middle of the space below it.
3. Phone and 768: name, kcal, how sure and range on the card; both install
   paths above the fold at 390; 768 map 60svh with no dead column.
4. Surfaces: one stone ground (no second surface), €0 on stone, no glow, no
   backdrop blur, a solid bar, an Android head instead of the flag.
5. After the shutter: text and phone centred with a fixed gap (no void),
   four waypoints with red-white-red blazes on a vertical trail that fills
   with scroll (no "01 /04"), the active step opens; screen 3 now shows the
   three estimates running in parallel (recaptured), screen 4 the result
   scrolled to Lower / Now / Higher; the step hiding is `.js` and ≥861px only.

Defects: day axis labels no longer overlap; the time now sits under the
walker on the empty side; the week peaks are flat summits, ink above the goal.

### Declined, with reasons

- Footer "AT" baseline: it is the logo as drawn; the brand file is not ours
  to re-set.
- The green blur in the iPhone install screenshot: that is iOS's own share
  sheet over the app; the screenshot is real.
- Step texts collapsed at 1280 (scan warning): the pinned stage shows one
  step at a time on purpose; all titles stay visible, and without JS or below
  861px every step is open.
- The void beside "Three estimates": a full-page capture artifact; in use the
  map is sticky beside it (scenes-d/c-est).
- Static weight line: a capture artifact; it draws on scroll.
- The 7-line H1 in the pseudo-locale: a stress test at +40 % length; real DE
  sets in 4 lines.

## Round 2 (renders r5)

Scores: concept 4, category 3, slop 3, first screen 4, type 3, colour 4,
richness 4, structure 3, craft 3, responsive 4, everyone's computer 3,
signature 4, screenshot 3; fidelity 5. Not done (6 of 13 at 4+).

### What changed after round 2 (renders r6)

1. The day is a mountain: a contour-filled face whose summit is the goal
   (cross, blaze, spot height), the walked trail in green, waypoint blazes,
   and the kcal still to climb measured between walker and goal. The week:
   each summit carries its spot height; Monday reads "+50" over the goal.
2. Hero trail: one route over the summits you can see, lowest to highest, no
   legs under the card; spot labels with a crisp 5px halo; on the phone the
   active part shows its name.
3. Lower half: "No plate to photograph?" is three real app screens (camera,
   a scanned barcode from Open Food Facts, a typed meal being read). €0 sits
   in a faint contour basin. The edge into the dark is straight, with one
   labelled index contour ("2000") above it.
4. Phone: the map flies to the highlighted row (it may pull a low part up
   past the plate edge); the plate lets go when "Together" passes; spot
   heights no longer vanish after the intro (the entrance restarted on
   re-show).
5. Craft: both install links on one line at 1280; install annotations
   recoloured to forest / leaf; screen 3 recaptured with the parts streaming
   in ("Estimate 1 of 3 · so far 432 kcal"); hints at 15px; all four step
   texts visible (active one brighter), so nothing is hidden for the scan;
   footer reveal falls back at the very bottom. Matrix: 0 fail, 0 warn.

### Declined in round 2

- The blue iOS "Add": that is iOS's own button; the annotation is ours, the
  button is not.
- Lens entrance "not visible": measured in a live page, the circle opens from
  0.5 s to 1.6 s (2 % → 33 % → 83 % → 110 %); the 400 ms filmstrip frame
  falls before the start.

## Round 3 (renders r6): done

Scores: concept 4, category 4, slop 4, first screen 4, type 3, colour 4,
richness 4, structure 4, craft 3, responsive 4, everyone's computer 4,
signature 4, screenshot 4; fidelity 5. 11 of 13 at 4+, none below 3, matrix
0 fail 0 warn: done by the stop rule.

### Fixed after the last round, not rescored (renders r7)

1. Day chart: one line. The mountain face is the day itself (everything
   eaten, in contour lines, the walked part tinted), the trail is its ridge;
   the "kcal to the summit" gauge is ink, not red; meals not reached yet are
   dashed outlines at full strength instead of 30 % grey.
2. Week: the goal line sits under the peaks, and a spot height that would
   meet it moves just above it, on a stone halo.
3. Ways in: three screens across the full width (up to 400 px each); "Type
   it" is the real typed result (380 kcal with lower / now / higher; 367 in
   German).
4. The bar turns night over the dark sections (night at 94 %, leaf action).
5. Spot labels on a small stone plate instead of the jagged stroke halo; the
   phone gap under "Install on iPhone" closed (parts padding 32 px); the
   first install picture is cut to the tapped control.

Declined: the H1 in three lines at 1440. The hero column is about 480 px;
"reads your plate" at the display size needs about 800. Shrinking the H1 to
fit costs more than one short line.
