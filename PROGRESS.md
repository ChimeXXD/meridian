# Progress

Build log for the one-week plan (`docs/PLAN.md`). Newest entry first.

## Day 2: Night Sky cleaned up (Fri 30 Oct 2026)

**Changed**
- Chime called the Night Sky screens cluttered ("unslop this", the progress bar made no sense for a release countdown). Removed the progress bar, the bell and "…" icons, the zone pill, the big bell on the art and the share button.
- Every screen now leads with the same three lines (`NightSkyHeadline`): title, giant serif countdown, "Out today at 19:21" (`DirectionCopy.outLine`), then one dim line with episode, provider and source (`NightSkyMeta`).
- Upcoming after the hero is one row pattern in SPEC's sections (Next 24 hours, This week, Later, Date only) under small caps headers, replacing the shelf plus list. The row's countdown sits beside the title so the meta line gets the full width.
- Show detail keeps only your time (with its zone) against the broadcast time, the Live Activity switch, episodes and the report link.
- `SourceChip(plain:)`: glyph and word without the capsule, for quiet lines; the filled chip stays the default.

**Checked**
- Simulator screenshots of Silo, House of the Dragon and Frieren (Upcoming and Show detail) and both screens scrolled; in `docs/design/direction-board/variants.html`. Fixed after looking: meta lines cut off in rows, a wrapping date-only line.

**Not verified**
- Times are samples. "Your time" shows "GMT+1" for Lagos (the zone's short name from the system), not "WAT".

**Next:** Chime's verdict. Then delete the old artwork-led views, rewrite UI-BRIEF §1–3 for Night Sky, and build the real Upcoming on it (Day 3).

## Day 2: Night Sky chosen, no brown (Fri 30 Oct 2026)

**Changed**
- Chime picked Night Sky (D-38) and dropped Glass and Poster Colour ("ugly"): their views and `NumeralStudy.glass` are deleted.
- Chime disliked the brownish base under Silo. `ArtworkPalette.night` replaces `muted`: near-black, with warm art (reds, oranges, yellows) going neutral charcoal and cool art keeping a faint tint, because a darkened warm hue reads as brown.
- `DesignPreview`: a TVmaze ID after `-designPreview A` gives that show the soonest sample time, so any show can be the hero. Show detail hides Episodes when there are none.

**Checked**
- Simulator screenshots of Silo, House of the Dragon and Frieren as the hero, Upcoming and Show detail each, plus Silo before and after; side by side in `docs/design/direction-board/variants.html` (shots git-ignored). Silo and House of the Dragon now sit on charcoal, Frieren on dark slate.

**Not verified**
- Times are samples; no episode lists for House of the Dragon or Frieren (no recorded fixtures). On Show detail the round bell sits mid-art and can cover a face (Frieren).

**Next:** Chime's verdict on the three demos. Then delete the old artwork-led views, rewrite UI-BRIEF §1–3 for Night Sky, and build the real Upcoming on it (Day 3).

## Day 2: three directions, three variants (Fri 30 Oct 2026)

**Changed**
- Chime rejected the artwork-led screens and asked for three style groups from references, each built around Insight Timer (their starred pick) and their other liked picks. `docs/design/direction-board/` (`directions.json`, `index.html`, built by `scripts/build-direction-board.py`): A Night Sky, B Glass, C Poster Colour, 20 references (10 liked, 8 new). Screenshots are git-ignored.
- Chime asked for all three as variants. `Airstamp/Features/Debug/Directions/` (Debug only): `NightSkyUpcoming`/`NightSkyDetail`, `GlassUpcoming`/`GlassDetail` (Liquid Glass, `glassEffect`), `PosterColourUpcoming`/`PosterColourDetail`, plus `DirectionKit` (muted and vivid tones, ink choice, shared fact and episode rows). `-designPreview A|B|C [detail] [bottom]` opens each; no letter opens the old screens.
- `NumeralStudy.glass` (SF Pro Thin) for B.
- `ArtworkPalette` picks the strongest hue band instead of averaging every hue, so teal-and-orange art (Silo's poster) gives teal or orange, not olive.

**Red → green**
- Red: `ArtworkPaletteTests.complementaryHuesDontMix`: "hue 101.08773274659956 is neither teal nor orange".
- Green: `xcodebuild … test -only-testing:AirstampTests`, 66 tests in 16 suites (iPhone 18 Pro, iOS 27.0).
- `/code-review --fix` (medium): 8 findings, 5 fixed. Greys (hue 0) were voting for the red band, so a muted blue subject on grey came out red (new test `greysDontVoteForRed`, 67 tests pass); three copies of the detail facts merged into `DirectionCopy.facts`; date-only day stamps now show the weekday; Report buttons take the page ink; one predicate for Night Sky's shelf and list. Left: source-chip colours on vivid or glass backgrounds (a design call for the winning direction) and an index lookup in debug code.

**Checked**
- Simulator screenshots of all nine views (Upcoming, Upcoming scrolled and Show detail for A, B and C) with live TVmaze art; side by side in `docs/design/direction-board/variants.html` (shots git-ignored). Fixed after looking: B's ticking timer overlapping the title, C's cut-off titles and brown cards for warm posters, A's cut-off shelf titles and a duplicate bell.
- The simulator needed CoreSimulator's stale service replaced after an Xcode update; `simctl` did it on its own.

**Not verified**
- Times are samples. Dynamic Type, VoiceOver and light/dark switching weren't checked on the variants (they are throwaway until one is picked).

**Next:** Chime picks A, B or C. Then delete the other two and the old artwork-led views, rewrite UI-BRIEF §1–3 for the winner, and build the real Upcoming on it (Day 3).

## Day 2: artwork-led direction (Fri 30 Oct 2026)

**Changed**
- Chime rejected the type-only design and the numeral studies, so shows now display their artwork (D-37, supersedes D-13). The new style board (`docs/design/style-board/`, 96 reference screens in 10 directions) produced 15 picks (`picks.json`, also saved to the reference collection). Insight Timer is the one Chime asked to focus on.
- `Shared/Design/ArtworkPalette` + `RGBColor`: a deep tone of the artwork's hue for page and slab backgrounds (white text at 7:1 or better) and a pale accent.
- `TVmazeClient.images(showID:)`, `ShowArtwork` (background near 1920 px; a sharp one beats a soft main one; main poster), `ArtworkLoader` (runtime download, ImageIO downsampling, `NSCache`), `ArtworkLoaderView`.
- `UpcomingArtView` / `UpcomingHero` / `ArtDropRow` and `ShowDetailArtView`: full-bleed key art fading into the art's colour, a thin serif countdown (`NumeralStudy.night`), slabs tinted from each poster. `DesignPreview` (Debug, `-designPreview [detail] [bottom]`) shows them with live TVmaze art and sample times.
- `DropFormatter.zoneAbbreviation` ("EDT"/"EST", not "GMT-4").

**Red → green**
- Red: `ArtworkPaletteTests` / `ShowArtworkTests` didn't compile (`no member 'images'`, `cannot find 'TVmazeImage'`).
- Green: `xcodebuild … test`, 65 tests in 16 suites (code-review run, iPhone 18 Pro, iOS 27.0).

**Checked**
- Simulator screenshots of Upcoming and Show detail, top and scrolled, with Silo, Frieren, House of the Dragon, Wednesday, The Last of Us and Severance art. Fixed after looking: a hard edge under the hero, the zone pill floating over the list, no status-bar backdrop, "GMT-4".
- `/code-review --fix` (medium): 10 findings, 8 fixed (date-only drops showing a made-up time on Show detail, a broadcast zone assumed for every source, stale art when the URL changes, delay line across midnight, slab contrast, soft heroes, unbounded image cache, soft main background winning). Left: row index lookup and the meta line built in three places (Day 3, with `UpcomingViewModel`).
- Screenshots are kept out of the repo (they contain artwork, D-37).

**Not verified**
- Real drops: times are samples; the data layer is Day 3. Widgets and the Live Activity in this style are Day 4.
- Anime artwork from AniList, and image terms (O-12).

**Next:** Chime reviews the screens. Then Day 3 builds the real Upcoming data on these views; AniList client and Search are still open from Day 2.

## Day 2: UI direction (Fri 30 Oct 2026)

**Changed**
- Chime's picks (47 of 154) saved to `docs/design/reference-board/picks.json` and to the reference collection "Airstamp references" (47 iOS screens). `scripts/picks-to-references.py` writes them into `docs/design/REFERENCES.md`.
- `docs/design/UI-BRIEF.md`: direction from the picks, tokens, three numeral studies, components, and every screen and surface with job, references, test IDs, copy and states. `scripts/check-brief.sh` checks it against SPEC.
- `Shared/Design/`: `Tokens` (system neutrals, status inks with fixed meanings, spacing, radius), `NumeralStudy` (A System, B Mono, C Serif), `SourceKind`, `SourceChipContent`, and the `SourceChip`, `CountdownText`, `ProviderLabelView`, `SectionHeader` and `DropRow` components, each with a `#Preview`.
- `Shared/Time/`: `CountdownFormatter` (Out now / ticking / "2d 4h" / date only, matching SPEC's section boundaries), `DropFormatter.relativeDay` (Today, Tomorrow, weekday, then the date, with the year when it differs) and `weekdayTime`; `Drop.episodeLabel` ("S2E5").
- `Airstamp/Features/Debug/NumeralStudyBoard` + `StudySurfaces`: every surface at real point sizes for each study. `NumeralStudyRenderTests` renders them to `docs/design/studies/` (only with `TEST_RUNNER_STUDIES_OUT` set); compare in `docs/design/studies/index.html`.
- SPEC §1: "Welcome (one screen)" replaces the old "Onboarding (3 cards)", which contradicted the non-goals. SITEMAP: the no-stream row keeps the provider.

**Red → green**
- Red: the new suites didn't compile (`cannot find 'SourceKind' in scope`). Later red: `RelativeDayTests` with "Fri 9 Jul 2027" got the date without the year.
- Red found by a test: `TokenContrastTests` failed for 4 light-mode inks (exact on chip 4.30, delayed 4.14, no-stream 4.50, mono accent 4.16 against 4.5). Inks darkened until all pass.
- Green: `xcodebuild … test`, 56 tests in 14 suites pass on iPhone 18 Pro (iOS 27.0).

**Checked**
- Every render looked at: two layout bugs found and fixed (the no-stream label was cut off; the serif "2d 4h" shrank in rows).
- `/code-review --fix` (medium): 8 findings; fixed VoiceOver for "2d 4h" (now "2 days 4 hours"), provider country in Live Activity mock-ups, the day on a struck delayed time across midnight, the minimal island after the drop; year on far dates fixed afterwards. Left: `now` is the caller's job (documented; `TimelineView` on Day 3), sample data in `Shared/` until the study code is deleted.
- proof:verifier: found the widget and Live Activity sections incomplete and a check that only looked for markers, copy marked as SPEC that wasn't, the network hidden when there's no stream, no tinted handling, and `TimeZone(` outside `Shared/Time`. All fixed; `check-brief.sh` now fails on a misquoted SPEC string and on a missing part (both tried).

**Not verified**
- Tinted/accented and Always-On rendering: handled in code (inks fall back to primary, the countdown is `widgetAccentable`), but `ImageRenderer` can't set the widget rendering mode, so it's first seen on Day 4 with the real widgets.
- The study frames are mock-ups at real sizes, not WidgetKit renders.

**Next:** Chime picks A, B or C (D2-4), then AniListClient, ProviderLabel country logic, FollowedShow and Search (D2-5 to D2-7).

## Day 2 (started): design reference board

**Changed**
- `docs/design/reference-board/index.html`: a local picker with 154 iOS references from references in 4 groups (Home & schedules 39, Widgets & Live Activities 39, Time & honesty 37, Search, detail & settings 39). Each one has Claude's reason and tags, Use this / Not for us, 9 reason chips, a note field, filters, search, zoom, and Export → `picks.json`. Picks persist in localStorage.
- `scripts/build-reference-board.py` + `scripts/reference-board-template.html`: merge agent results, drop duplicates (5), download screenshots, build the page.
- Screenshots live in `docs/design/reference-board/images/` (git-ignored, 24 MB: other apps' copyrighted UI, CLAUDE.md rule 9). Run the build script to fetch them again.

**Checked (Playwright, Chromium headless)**
- 154 cards, 0 broken images, 0 console errors.
- Reason chips auto-mark "Use this"; decision, reasons and note survive a reload.
- Filters (decision, group, search) work; Export gives valid JSON with reason counts; zoom opens.
- No horizontal scroll at 390 px; the toolbar stops being sticky on phones.

**Gaps references couldn't fill:** real Lock Screen accessory widgets (only Udemy and Cal AI), StandBy, a Live Activity on/off toggle, a streaming "not available in your region" screen other than HBO Max.

**Next:** Chime picks → save the liked screens to the reference collection → UI brief.

## Day 1: Time engine (Thu 29 – Fri 30 Oct 2026)

**Changed**
- `Shared/Models`: Drop (with `airdate`), DropSnapshot, Confidence, Catalog, ReleaseSource (adds `override` and `adjusted`), ProviderLabel, RulesFile, PlatformRule, ReleaseOverride, ProviderRule, RulesValidationError.
- `Shared/Time`: WallClock (zone-aware wall clock → UTC; IANA-only zones), EpisodeListing, Resolution, TimeResolver (override → broadcast → rule → date only), DropFormatter.
- `rules/platform-rules.json` v1: Netflix, Prime Video, Apple TV, Paramount+; 4 overrides (Stranger Things 5, Fallout S2, two Disney+ Marvel shows); Disney+ marked no official stream in NG. Bundled in the app.
- `Airstamp/Services`: RulesStore (remote off while private, validate-or-fallback, once a day, retry in an hour), TVmazeClient (Retry-After capped at 30 s, exponential backoff, 6-hour disk cache), ResponseCache, TVmaze models.
- `scripts/record-fixtures.py`: records 17 rule fixtures (real TVmaze data + independently confirmed release time + source) and 4 client fixtures.
- Decisions: D-36 (Disney+ has no default rule). Open: O-10 (TVmaze placeholder dates such as Silo 2027-07-09).

**Red → green**
- Red: build-for-testing failed with "cannot find 'WallClock' in scope", then "cannot find type 'TVmazeClient' in scope".
- Green: 41 tests in 9 suites, including 48 matrix cases, 21 clock-change cases and 17 real episodes.
- Mutation: changing Apple TV's `dayOffset` from -1 to 0 made the fixture, matrix and clock-change tests fail (12 cases). Restored.

**Reviews**
- proof:verifier found 10 gaps. Fixed: Disney+ decision not recorded (D-36), coverage test that couldn't catch a deleted rule, `TimeZone(` outside Shared/Time, no HTTP 500 test or real fetch, show overrides with an instant, fixed-offset zones, episode→show override fallback, Paramount+ changeover cases, missing round trips, a dead source link (The Boys S5).
- /code-review medium --fix: fixed unbounded Retry-After, undecodable cache entries, midnight clock changes in WallClock (Santiago), per-episode date formatter, duplicated fixture decoder. I then added rejection of ambiguous episode overrides and duplicate channel names.

**Deferred, on purpose**
- Persisting RulesStore state across launches: added to Day 7, before remote updates switch on.
- TVmaze anime fallback with the "JP broadcast" chip (D-19): Day 2, with the AniList work.
- A `DropFormatter.day(for: Drop)` guard so views can't format a date-only drop from `date`: Day 3, with Upcoming.

**Not verified**
- The live URLSession path: tests replay recorded real responses.
- Four fixture sources could not be read by the verifier (Sportskeeda, Bloody Disgusting, both Landman). Wednesday S2E1 now cites PinkNews; the others stand.

**Next:** Day 2, UI direction (references → UI brief → SwiftUI tokens), AniList client, Search.

## Day 0: Setup (Thu 29 Oct 2026)

**Changed**
- XcodeGen project (`project.yml`): `Airstamp` app, `AirstampWidgets` extension, `AirstampTests` (Swift Testing). iOS 26.0, Swift 6, strict concurrency.
- Signing and IDs in `Config/Base.xcconfig` (bundle prefix `dev.chime`, App Group `group.dev.chime.airstamp`), overridden by the git-ignored `Config/Signing.local.xcconfig`, so no Team ID is committed.
- `Shared/Snapshot/AppGroup.swift` and `SetupCheck.swift`: the app writes a timestamp to the App Group, and the placeholder `systemSmall` widget reads it.
- Privacy manifests for the app (`CA92.1`, `1C8F.1`) and the widget (`1C8F.1`).
- `.claude/proof.json` gate: build, test, spec. Simulator: iPhone 18 Pro, iOS 27.0 (the iPhone 17 Pro only has iOS 26.5, so the default destination didn't match).

**Red → green**
- Red: `AppGroupTests` failed with "Unable to resolve module dependency: 'Airstamp'" (no app code yet).
- Green: `xcodebuild … test`, 3 of 3 tests pass on the iPhone 18 Pro (iOS 27.0) simulator.

**Checked**
- Build has no compiler warnings.
- `PrivacyInfo.xcprivacy` is bundled in both `Airstamp.app` and `AirstampWidgets.appex`; `plutil -lint` OK.
- Built Info.plist: `AirstampAppGroup = group.dev.chime.airstamp`, `NSSupportsLiveActivities = true`, display name `Airstamp`.
- Simulator launch: the screen shows "App Group OK · wrote 20:29".

**Not verified yet**
- The widget on a real iPhone with free signing (D0-3). It needs Chime to sign in to Xcode with an Apple ID, turn on Developer Mode, and plug in the phone. The simulator allows shared defaults even without the entitlement, so only a device proves the App Group.
- The widget wasn't added to the simulator Home Screen (that needs manual taps).

**Next:** device check, then Day 1 (time engine, tests first).
