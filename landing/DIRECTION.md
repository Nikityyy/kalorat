# Kalorat landing: direction

Not deployed (the Pages workflow copies only `index.html`, `404.html` and
`assets/`). Read this before changing the page.

## Brief

- **What:** the landing page of Kalorat, a free, open-source calorie tracker
  that analyses a meal from one photo (Android APK, iPhone as a home-screen web
  app). Static, GitHub Pages, no build step.
- **The one job:** in ten seconds a visitor sees a real plate being read into
  parts, grams and calories, understands it is free, and can install it.
- **Feel:** precise, appetising, alpine. Outside references: an Austrian
  hiking map (Kompass/Freytag & Berndt), the red-white-red trail marker, a
  well-lit food magazine overhead shot.
- **Owner's asks:** award-level, better imagery, effects that feel right,
  tested like a real visitor, static.

## Current (before)

- Dark "night camera" hero with a dot-matrix scan over Wikimedia photos
  (dim, low resolution, one extended by AI), a plate that flies between
  sections, a day chart with floating thumbnails, 8 sections alternating dark
  and light, mono labels everywhere, cluttered install section.
- Scan: no FAILs; 6 texts invisible after a full scroll (reveals that never
  fired), nested boxes, default-reach fonts (Outfit, JetBrains Mono).
- Kept: the logo, the red "AT", Styrian Forest, the real numbers, the real
  app screens, the iPhone tutorial images, DE/EN, the 404 as a playful page,
  every fact on the page (see keep list).

### Keep list

- [ ] Plate hero with real Kalorat result (name, kcal, how sure, range)
- [ ] Android APK download (latest release) and iPhone install path
- [ ] Every part of the plate with grams and kcal; median of three estimates
- [ ] The day as a climb to the goal; goal from height, weight, age, activity
- [ ] Three ways in: photo, barcode (Open Food Facts), typed
- [ ] The four steps after the shutter with the real app screens
- [ ] Week average, weight trend
- [ ] Free: own Gemini key, meals on the phone, export JSON/Markdown, open source
- [ ] Release version, size and date from GitHub
- [ ] Credits for photos; the demo-data note
- [ ] DE / EN, remembered; the 404

## Refused defaults

- The category: fitness-app green/orange gradients, phone mockups floating on
  blobs, "#1 AI calorie app" badges, star ratings, testimonial carousels.
- The slop faces: the Paper Edition (warm paper, italic accent word, mono
  eyebrows), the Launch Page (dark, glow, gradient text), and the
  overcorrection (paper, mono, one rust accent, no images).
- The old page's own look: night camera + dot matrix.

## Three concepts (explore/ in the scratchpad)

- **A. Kalorat is an alpine trail map** (places/nature): the plate is
  terrain, every part a summit whose height is its calories; contour lines and
  spot heights; red-white-red trail markers; cool stone ground from the photo.
  Archivo (width axis). **Chosen.**
- B. Kalorat is a camera at night (media): dark viewfinder, dot scan.
  Lost: it is the current page again, and the dots muddy a good photo.
- C. Kalorat is a fruit sticker sheet (play): a colour field per meal, a
  round sticker of the plate, Fredoka. Lost: cartoonish for a precise tool.
  Taken from it: the giant kcal numeral and the meal switcher.

## Tokens

- Ground `#E7EAE7` stone, sampled from the lunch photo's concrete.
  Surface `#F5F7F5`. Ink `#111513`, ink-2 `#4A524D` (7.6:1), rule
  `rgba(17,21,19,.14)`.
- Night (one section, the camera): `#0C100E`, ink `#EEF2EF`, ink-2 `#A2ADA6`.
- Accent, one job, the action and the route: Styrian Forest `#0F5838`
  (on night: `#6BCB97`).
- Marker red `#D52B1E`: only the logo's "AT" and the trail-marker glyph that
  marks a waypoint (meals on the climb, the install button's flag).
- Type: **Archivo** variable (weight 100–900, width 62–125), one family.
  Display at width 112–125, weight 800, tracking −3.5%; text at width 100;
  every number tabular. Reason: the expanded cut reads like the lettering on
  Austrian trail signs and map titles; the width axis gives contrast without a
  second family.
- Scale: display clamp(48px…128px), h2 clamp(40px…80px), h3 24px, body 18px,
  small 15px, meta 13px.
- Spacing 4, 8, 12, 16, 24, 40, 64, 104, 168. Radius: 12 (brand) on
  photos and cards, pill on buttons.

## Richness

Photography, one shoot's look: overhead, soft daylight, single bowl on a cool
grey or white ground (Unsplash: Louis Hansel, Eiliv Aceron, Anh Nguyen).
Over it, the shape language: contour lines in ink, spot-height triangles.

## Grammar (scroll-story, six sections)

1. **The plate** (what is it?): the lunch bowl full-bleed, headline, action,
   the reading drawn on; breakfast / lunch / dinner switcher.
2. **Every part, weighed** (how exact?): the parts as a map legend, the
   estimates and the middle one.
3. **Your day, a climb** (what does it do for me?): the day's elevation
   profile to the goal, meals as waypoints; the week and the weight.
4. **After the shutter** (how does it work?), night: the four steps with the
   real screens; three ways in.
5. **Costs nothing, stays yours** (what's the catch?).
6. **Get it** (how?): Android and iPhone; footer with credits.

## Signature

**The plate becomes a map.** On load (and on switching meals) the contour
lines of the plate's "calorie terrain" draw themselves from the summits
outwards, 1.6 s, ease-out, staggered 60 ms per line; the spot heights pop in
with their grams; the kcal numeral counts up with them. Pointing at a part
lifts its rings. Reduced motion: the finished map, no drawing.

## Voice

Talks like a good mountain guide: brief, exact, calm. Numbers with units.
No exclamation marks, no "AI-powered".

## The bar (award level)

What separates a site of the day from a tidy product page, and what this
page must do to clear it:

1. **One idea, staged in every scene.** Every section is a scene of the map,
   never a list on plain ground.
2. **A choreographed entrance.** The plate opens like a lens (clip-path
   from the plate's centre), the title rises line by line out of a mask
   while its width axis opens from 80 to 118, then the terrain draws.
3. **Scroll is the camera.** While the parts scroll by, the map flies to
   each part (pan and zoom), as a map app flies to a summit. The steps after
   the shutter are one pinned stage, scrubbed by scroll.
4. **Type as image.** Archivo's width axis moves: €0 stretches open as it
   enters; the footer wordmark rises letter by letter.
5. **Curiosity is rewarded.** Over the plate the cursor becomes a map
   reticle that reads the terrain under it (the innermost contour ring:
   which part, how many kcal) and lifts that part's rings.
6. **Rhythm.** Huge, dense, quiet; no dead stretches of empty ground.
   The night section's top edge is straight, with one labelled index
   contour ("2000") above it, as on a survey map.
7. **Craft.** One easing family, transforms and opacity only, no layout
   shift; mobile has its own choreography (no pinning, inline screens);
   desktop gets a QR code to install on the phone; reduced motion gets
   the finished state.

Decided while building (critique rounds 1–3):

- **The trail.** A red-white-red route runs over the plate's visible
  summits, lowest kcal to highest; each part is a spot height (its kcal),
  not a label box. The steps after the shutter are waypoints with blazes on
  a vertical trail; the day is a mountain whose summit is the goal.
- **The phone.** On the phone the plate is sticky (44svh) while the parts
  scroll and flies to the part in view; it lets go after "Together".
- **One ground.** Stone everywhere outside the night section and footer;
  €0 on stone in a faint contour basin; no glow, no blur, no glass. The bar
  turns night over the dark sections.
- **Real screens.** Every app screen is a capture of the real web build
  (fake camera, dinner tofu bowl, a typed meal, a scanned barcode from Open
  Food Facts), in a mockuphone iPhone 15 Pro frame where a device is shown.
