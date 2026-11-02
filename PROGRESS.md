# Progress

Build log for the one-week plan (`docs/PLAN.md`). Newest entry first.

## Day 6: refresh with delay detection (Mon 2 Nov 2026)

- **D6-1 (D-58):** each refresh (on open, `RootView` scenePhase `.active`) compares episodes with the last known result, which comes from the in-memory result or, after a cold launch, the widgets' snapshot.
  - A published time that moved later keeps its first listed time as `previousDate` (`DelayDetection`).
  - Estimates never count as delayed.
  - `ReleaseMeta` says "Delayed from 20:55" in the hero, rows and Show detail.
- **Live Activity:** `delayedFrom` comes from `previousDate`, on new bookings too.
  - A booked activity that hasn't started is ended and rebooked for the new time (new start and alert).
  - One on screen moves in place.
  - An old time a week or more earlier carries its date.
- **Checks:**
  - RefreshServiceTests 4 and ActivityRescheduleTests 2 were red first, as a compile error and as `ended` being empty.
  - ActivitySchedulerTests, ReleaseWordingTests and LiveActivityTextTests are green.
  - `-designPreview 44778` shows "Out today at 21:55 Lagos time / Delayed from 20:55 / S3E4 · HBO · US".
  - Screen checks upcoming and detail: ALL PASS.
- **Reviews:**
  - **proof:verifier:** 1 failure, a pending activity not rebooked; fixed.
  - **`/code-review` (medium):** 8 findings, 4 fixed: delayed bookings, delay reconciliation, a phase reset, and the shared old-time format. The 7-day case was fixed here.
  - Not fixed: an earlier time shows nothing (D-58 by design); "Delayed from" stays after release; the legacy `DropRow`.
- **Not verified:** a real delay on the phone (needs TVmaze to move a time).

## The design system matches the app, and stays that way; the expanded island redesigned (Mon 2 Nov 2026)

- Chime: confirm the design system is the same as the app; any change to one goes to the other. Then: the expanded island's progress bar means nothing and its "Expected in 2:00:00" is too big; unslop it.
- **Audit:**
  - **Widget and Live Activity pictures:** re-rendered from HEAD and compared pixel by pixel with the site's copies. All 75 widgets were identical. 49 Live Activity renders differed only in a sample clock time: the tests used `Date.now`.
  - **Hand-drawn parts:** three read-only agents compared the tokens, components, countdown, wording and surfaces with the Swift. They found 8 visible differences, about 20 text slips and 2 app problems.
- **Site fixed to the app** (agent, 24 of 26 items; 2 left as is with reasons):
  - date-only days no longer gold (D-53)
  - the Welcome wall now drifts in 3 rows
  - the (+) sits 10 pt from the corner
  - the chips scroll in one row
  - the impossible "Silo returns" Upcoming state is gone
  - countdowns turn to "Released" and to past tense
  - VoiceOver phrasing, the timeline rules, the payload, tint claims and Reduce Motion claims corrected
  - missing tokens added; `tokens.json` sources moved to HEAD
  - checks: `node --check`, the JSON parse, 0 console errors, no overflow at 320, all six views
- **App:**
  - **Welcome:** the wall and tile fades skip under Reduce Motion.
  - **Show detail:** "Report a wrong time" and "Unfollow" are 44 pt tap rows. `fidelity/verify-screen.sh detail` printed ALL PASS.
- **Expanded island (D-57, unslop):**
  - The bar is gone; it filled from the activity's start, a picture with no words.
  - Under the title and art, one line laid out like Upcoming's rows: "Expected Mon 21:00" with the countdown at 24 pt (was 34) on its baseline, "Delayed from 21:00" in words under it, and a gold "Out now" at the drop.
  - Weekday, not "today": the verifier caught that "tomorrow" would go stale after midnight, because the island isn't redrawn.
  - `LiveActivityBar` deleted; `ReleaseWording.pastVerb` added.
- **Sync check (Chime OK'd):**
  - The Live Activity renders share the widgets' fixed clock, moved to Mon 2 Nov 2071 18:00Z: `ImageRenderer` draws a timer at its full length only while the real clock is before it, and the old 2026-11-02T18:00Z passed during the session (the copy check caught every timer render changing).
  - Every render must equal the site's copy (`MeridianTests/Support/DesignSystemCopy.swift`).
  - `scripts/sync-design-system-renders.sh` re-renders in sync mode (skips only the copy check) and copies only this run's renders. It lists site pictures no render made.
  - Red: 49 issues, exactly the changed Live Activity renders. Green twice in a row, so the renders are deterministic. A deliberately broken site PNG was restored by the script.
  - CLAUDE.md now says the app is the source of truth and both change in one commit.
- **Checks:** gate build, test and spec all pass. LiveActivityTextTests (outLine, movedLine) were red first, as a compile error.
- **Reviews:**
  - **proof:verifier:** 3 findings, all fixed (the stale "tomorrow", two leftover mentions of the bar, and the sync script copying stale or partial renders).
  - **`/code-review` (high):** 7 findings, 2 fixed (`pastVerb` beside `verb`, temp files) plus sync mode for a third. Not fixed: `art-holes.json` isn't compared (it's built test by test); byte-exact matching means an Xcode update needs one re-sync; an estimate reads "Expected Mon 21:00" beside "Out now" (D-40 wording).
- **On the phone (Chime's screenshots):** the first build's bottom line was blank (`.fixedSize()` on the timer), then it sat 12 pt inside the title (region insets of 16 against 4). Both were fixed, and Chime confirmed it aligned. The renders' fixed clock passed during the session, so it moved to 2071 (D-57). The second `/code-review` (medium) gave 5 findings: the timer now shrinks past 6 h (`minimumScaleFactor`), and a test proves "5:59:59" fits 96 pt. Not fixed: the widgets' ticking timers still use `.fixedSize(horizontal:)` (check on the phone in a drop's last day); the site's "returns" sample reads 2072; the corners at a 4 pt inset are fine on Chime's phone.
- **Not verified:**
  - Safari rendering of the site
  - a delay past 6 h shrinking the expanded timer on the phone

## Design system: iPhone mockups for the widgets and the Live Activity (Mon 2 Nov 2026)

- Chime: make the Widgets and Live Activity sections more presentable with an iPhone mockup. Done by an agent (stageshow skill); checked here.
- A CSS/SVG iPhone (402 x 874 pt, continuous corners, Dynamic Island) on our own night-sky wallpaper, no Apple images: two Home Screen pages (the large widget; the medium and small beside the Meridian icon) on the real icon grid, a Lock Screen at 04:37 with Silo's Live Activity banner, and close-ups of the compact and expanded island. All are the real renders with their art holes filled. The state galleries stay below, on night-sky panels.
- The Lock Screen shows no Lock Screen widgets: they would show the soonest drop (Silo), and every widget render tells a different story; they stay in the gallery.
- Checks: 0 console errors; all art in the mockups loads, placeholders with the CDNs blocked; no overflow at 1440 to 320; axe 0 violations in the surfaces section; no image files added. `/code-review` (medium): 8 findings, 6 fixed (Lock Screen widgets 8 pt off centre, needless blur, forced layouts, a duplicated rule, a regex on markup, an SVG id per kind); then the mismatched Lock Screen widgets removed.

## Design system: real art in the widget and Live Activity renders (Mon 2 Nov 2026)

- Chime: the Widgets section still showed placeholder art; show each show's poster. Done by an agent; checked here.
- Art holes, test-only: `MeridianTests/Support/ArtMatte.swift` draws each art render with black, white and grey art and keeps only what sits over the art, with alpha where the art shows through (linear to within 3/255, enforced), so no artwork pixel can reach a PNG; `ArtHoleManifest.swift` writes `art-holes.json` (each hole's rect, corner, fit, show and kind) and checks every hole against the layout. 53 renders have holes (15 widgets, 38 Live Activity); the `-art-wide` variants are gone.
- The site places TVmaze/AniList art (no referrer) behind each PNG at the manifest's rects, the placeholder showing if it fails. All renders redone, so they show D-56's still "2d 4h".
- Checks: 252 tests passed; all 53 hole PNGs read back with no coloured pixel where clear and no clear pixel outside a hole; 23/23 images hide to the placeholder with the CDNs blocked; no console errors; no overflow at 390/320. Looked at: medium and large widgets with Silo and House of the Dragon key art and row posters; the Frieren Lock Screen.
- `/code-review` (medium): 10 findings, 6 fixed (the matte ignored the render's own alpha; an unsettled render threw a cancellation; the grey size check; the Lock Screen share read from a throwaway view, now `LiveActivityArtEdge.defaultShare`; two duplications). Skipped: stale manifest entries are never pruned; Live Activity radii are copied literals; the matte can't see a colour transform on the art (none exists).

## Design system: real show art, and only the last day ticks (Mon 2 Nov 2026)

- Chime: wherever the site names a show, show its real art instead of cool/warm placeholders; countdowns tick only in the last 24 h (D-56). Done by an agent; checked here.
- Art loads at runtime from TVmaze and AniList (URLs in one `SHOWS` table in site.js, no image files committed, rule 9 / D-37), over the old gradient as the fallback, with no referrer. Hero buttons: "Silo, warm art" / "Wednesday, cool art" / "No art yet" (Silo's key art is warm). Real art in the overview hero, the Upcoming hero and rows, the poster grids, Spotlight and the show page. Widget and Live Activity renders kept placeholder art at first (see the next entry). Footer credit added.
- Countdowns: under 24 h tick; beyond, a still "2d 4h" with both parts always shown ("1d 0h"), as the app.
- Checks: 0 console errors; 14/14 art images load, 0 broken with both CDNs blocked; the hero switches Silo → Wednesday; Upcoming 7/7 images; multi-day countdowns "2d 4h | 1d 0h | 1d 3h | 3d 2h", spoken "1 day"; no overflow at 320; 51 deep links within 24 px.
- `/code-review` (medium): 7 findings, 3 fixed (old art lingering on a hero switch, a static "1d" in the markup, rounding written as the Swift). Then no-referrer on art requests. Not fixed: Wednesday's and Severance's night bases aren't in the tokens table; an unused `data-art`; still countdowns rebuilt each 250 ms tick.

## Only the last day ticks (Mon 2 Nov 2026)

- Chime: countdowns should tick only under 24 hours; further out, a still "4d 4h" (D-56, supersedes D-51's ticking beyond a day). Done by an agent; checked here.
- `CountdownFormatter.stillParts` replaces `daySplit`; `CountdownText` draws the still count with small dim units; the inline widget reads "Silo · 2d 4h"; `WidgetTimeline` adds the 24 h switch entry for the next 5 drops and moves refreshes beyond the last day 1 s past the hour.
- Red → green: the countdown suite failed 5 cases ("1d" not "1d 0h", the 24 h switch, "1 day" spoken); `stillCountSteps` failed with 3 452 issues (the widget lagged an hour); then 40 tests in 4 suites passed. Full suite: 251 tests in 42 suites passed.
- Looked at: simulator Upcoming, two shots ~5 s apart (Silo 2:09:51 → 2:09:46, Frieren 5:24:51 → 5:24:46, House of the Dragon "2d 3h" in both); `fidelity/shots/widgets/large-busy.png` ("3:10:00", then "2d 4h", "3d 6h", "4d 0h").
- `/code-review` (medium): 4 findings, 1 fixed with a test (`stepAfterNearbyChange`): an hourly refresh within 5 minutes after another change was dropped, leaving the still count an hour out; it now moves to 5 minutes after the change. Not fixed: non-hero rows step on the hero's hours (fixing it means ~4x the entries); the circular widget's "4h"/"38m" rounds down within the last day (predates this); `stillParts` and `parts` both split time. Full suite after: 252 passed.
- Not verified: a real widget over hours on the phone; non-hero widget rows can read an hour high for up to an hour (as before D-51).

## Welcome: the logo, and two clear groups (Mon 2 Nov 2026)

- Chime asked for the unslop skill on Welcome and for the logo on it. Audit: light slop (a muted grey "Meridian" label, no logo, every block 24 apart). Chime approved the logo lockup and the regrouped spacing; the headline stays.
- `MeridianMark` (Shared/Design): the Longitudes mark drawn in a Canvas from the app icon's grid, sized by height (`widthRatio` 0.64). Welcome's lockup: the mark (36, scales with text size) and "Meridian" in serif title 2, both `Tokens.starlight` (new), on the night under the art's fade. Spacing: logo, 16, headline, 12, zone, 32, buttons.
- `/code-review` (medium): 8 findings, 4 fixed (Dynamic Type, one Starlight token, the width ratio, a check for the logo in the Welcome inventory, which I undid because inventories need Chime's OK). Open: on short screens or very large text the logo can sit over the art's fade; the mark doesn't follow widget tint modes (not used in widgets yet).
- Vercel: the project `meridian-design-system` is connected to `ChimeXXD/meridian` (root `design-system/`, no build, production branch `main`); a push redeploys it only when `design-system/` changed (ignored build step `git diff HEAD^ HEAD --quiet -- .`). Address: https://meridian-designsystem.vercel.app (the plain `meridian-design-system.vercel.app` belongs to someone else).
- Design system: the Welcome spec and mock-up show the lockup, the spacing and placeholder art tiles. Hosted on Vercel at https://meridian-design-system-liart.vercel.app (public); `.vercelignore` keeps `.env*` and `.vercel` out of the deploy.

## Welcome: a drifting wall of show art (Mon 2 Nov 2026)

- Chime: Welcome is "too bland", add posters; picked Mindvalley, Nike and HBO Max from 25 design references (D-55).
- `WelcomeWall` (load, arrange, tiles) and `WelcomeWallView` (three drifting rows, fade, dim); `WelcomeView` takes the clients and rules.
- Tests: `WelcomeWallTests` (5): TV and anime alternate, duplicates go, under 9 pictures stays plain, rows capped, recorded schedules give posters, covers and banners. Written with the model, so no red run was seen.
- Simulator: posters loaded and rows moved between screenshots seconds apart. Two fixes found by looking: a repeating animation kept late-loading pictures from drawing (now a clock-driven offset), and the last row ended in a hard line (now a mask that clears before its edge).
- `/code-review` (medium): 7 findings. Fixed: soft anime banners (decode for the banner, not the tile), a gap at a short row's end in landscape (more copies), every tile rebuilt 30 times a second (the drift is now a modifier), the wall waiting out TVmaze retries (key art gets 3 s), and no retry after an offline launch (tries again on each return). Skipped: the unused palette work per tile and a possibly redundant safe-area term.
- Not verified: Reduce Motion (still rows) and the offline first launch, on a device.

## Renamed to Meridian, with the Longitudes app icon (Mon 2 Nov 2026)

- Chime: rename every trace of Airstamp to Meridian, including GitHub, and make the logo the app icon (D-54).
- Targets, folders, schemes and modules renamed; bundle ID `dev.chime.meridian`, App Group `group.dev.chime.meridian`; repo `ChimeXXD/meridian` (still private). TVmaze's `airstamp` field and `parseAirstamp` keep their names.
- App icon: `scripts/make-app-icon.swift` draws the Longitudes mark (gold star) as AppIcon, AppIcon-Dark and AppIcon-Tinted.
- Chime OK'd the rename-only edits to `.claude/proof.json`, `.claude/settings.json` and `fidelity/verify-screen.sh`, and removing the six stale agent worktrees.
- Checks: 244 tests in 41 suites passed under the Meridian scheme; the design-system site checks (ticking, deep links, no overflow at 320, no errors) passed; `/code-review` found no bugs.
- Phone: Airstamp uninstalled, Meridian installed (not launched). Followed shows and widgets are set up again once.
- Not verified: the icon on the Home Screen, and the Fidelity screen checks under the new scheme.

## Brand colour: Meridian Gold (Mon 2 Nov 2026)

- Chime chose option B (D-53). `Tokens.gold` (#E9C46A); "Out now" is gold in `CountdownText` (app, Home Screen widgets) and on the Live Activity (Lock Screen label, expanded and compact island, via `LiveActivityInk.out`).
- Red → green: `TokenContrastTests/goldOnNight()` failed to compile (no `Tokens.gold`), then passed (gold ≥ 4.5:1 on both night bases).
- Looked at: `fidelity/shots/live-activity/lock-outNow-art.png`, `expanded-outNow.png`, `fidelity/shots/widgets/medium-outNow.png` (gold "Out now").
- Design system: the brand colour section now states the decision; options A and C moved to the archive; the logo's star and the default app icon are gold on night (ink on paper); the gold token is in the colour table, the contrast table and tokens.json; the "Out now" renders were refreshed.
- Not verified: the phone (installed, not launched); the simulator's Dynamic Island didn't show the fake activity this time.

## Widgets and the Dynamic Island didn't tick: `pauseTime` (Sun 1 Nov 2026)

- Chime: real time in the app now, but not on the widgets or the Dynamic Island; and the expanded island's bottom row was cut off by its corners.
- Added a Debug launch option `-fakeActivity <minutes>` that starts the fake drop's Live Activity at once, so the simulator's Dynamic Island can be watched. With `pauseTime` the compact timer stayed at 29:57 for 20 s; without it, 19:56 → 19:51 in 5 s. A drop 1 minute out showed 0:55 counting, then left the island at the drop (no counting up). `pauseTime` removed from `CountdownText`, `InlineWidgetView` and `LiveActivityCountdown` (D-52). Expanded bottom region: 16 pt side and 8 pt bottom padding.
- Proposed CLAUDE.md rule 4 change for Chime: drop `pauseTime: drop`.
- Not verified here: Home Screen widgets ticking (can't be added on the simulator by script) and the expanded island (can't long-press by script); both on the phone.

## The app's countdowns didn't tick (Sun 1 Nov 2026)

- Chime: "The countdown is not real time. It's not ticking." Checked on the simulator with 8 screenshots over 3 s: byte-identical. Drawing the timer without the template still froze (template ruled out); changing Upcoming's `TimelineView(.everyMinute)` to `.periodic(from: .now, by: 1)` made it tick (2:09:55 → 2:09:52 and 2d 3:59:55 → 2d 3:59:52 in 3 s). Cause: inside a TimelineView a ticking `Text(timerInterval:)` only updates at the timeline's pace. Upcoming, Show detail and the show page now redraw every second; Search's grid (words only) stays per minute.
- Lesson: "live" is checked by two screenshots seconds apart, never by one render.
- Not verified here: widgets and the Live Activity (no TimelineView; the system ticks their timers) on the phone.

## Live countdowns everywhere, and the blank medium widget (Sun 1 Nov 2026)

**Changed** (D-51)
- Chime: countdowns should be real time in the app, the widgets and the Live Activity; and the medium widget showed only its tag and art once Strictly Come Dancing (under a day away) became the hero.
- `CountdownFormatter.daySplit` and `clockTemplate`; `CountdownText` now always ticks ("2d 4:10:22" beyond a day) inside a hidden template of its widest value, with an `alignment` for right-hand columns. The inline widget ticks with days too. Likely cause of the blank medium widget: its hero's ticking timer had `fixedSize`, and a ticking text in a widget takes all the width offered; the template bounds it (not reproducible in ImageRenderer, so it is confirmed only on the phone).
- Fixed my own first version: exactly on a day edge the clock showed a paused "4d 0:00"; it now reads "3d 24:00:00" and ticks.

**Red → green**
- `CountdownFormatterTests/daySplit()` and `clockTemplate()` failed to compile, then passed; the on-edge case failed with 3 issues, then passed. `WidgetTextTests/inline` now expects the live timer (nil text) for a count days away.

**Not verified**
- The medium widget on the phone; the app holds "3d 0:00:00" for up to a minute at a day edge (its `TimelineView` redraws every minute).

## Day 5: Live Activity rebuilt on Chime's picks (Sun 1 Nov 2026)

**Changed** (D-50)
- Chime tried the Live Activity on the phone (following Strictly Come Dancing with a 6-hour lead) and called it "kind of whack". 27 new design references in a local picker; Chime picked Duolingo (Lock Screen), Instagram (compact), Yazio (minimal), Tinder (expanded).
- `DropActivityAttributes` gained `showID` and `windowStart` (decoding older attributes with defaults). Lock Screen: art on the right edge fading into near-black, no grey band, 36 pt countdown. Compact: rounded poster. Minimal: poster in a ring that fills over the window. Expanded: art top-right and a thin bar to the drop. Art loaded from the App Group, small. Renders with and without placeholder art.

**Checked**
- `LiveActivityLayoutTests`, `ActivityPayloadTests`, `LiveActivityTextTests`, `ActivitySchedulerTests`: 30 tests in 4 suites pass (without -quiet). Looked at the renders against the four picks.

**Not verified**
- The live `ProgressView(timerInterval:)` ring and bar (the test renderer draws a static stand-in) and real art on the phone.

## Day 5: Live Activity and Debug menu, built by two lanes (Sun 1 Nov 2026)

**Changed** (D-49)
- Contract commit `b9731d6` fixed `DropActivityAttributes` and `LiveActivityText` signatures; two worktree agents built in parallel without the simulator, and the lead merged and tested.
- Lane A (D5-1, D5-5): `DropLiveActivity` (Lock Screen, Dynamic Island compact/minimal/expanded, `.supplementalActivityFamilies([.small])`), views in `Shared/LiveActivity/` (Night Sky; breadcrumb, band "Expected in" → "Out now" with the numbers staying put, relative countdown then absolute time, merged "Silo + 1 more", delayed time struck through), `LiveActivityText` (alert says "Starts" only for an exact time).
- Lane B (D5-2, D5-3): `ActivityPlanner` (opt-in, 7 days, no date-only, skip covered, same night = within 3 h, max 3 pending, start = drop − lead or now), `ActivityRequester`/`SystemActivityRequester` (`request(... start:)`, `AlertConfiguration`, `staleDate` = drop, errors caught), `ActivityScheduler` (ends drop + 1 h, flips passed drops to Out now, requests new) run after each refresh while active; Settings shows whether Live Activities are on; Debug menu (Debug builds only): fake drop in 2/10/60 min, fake Live Activity in 3 min (lead 1 min), dump snapshot, simulate delay +1 h.

**Checked**
- `ActivitySchedulerTests`, `LiveActivityTextTests`, `ActivityPayloadTests`, `LiveActivityLayoutTests`: 26 tests in 4 suites pass (lead, without -quiet). Gate build+test+spec pass. `fidelity/verify-screen.sh settings` ALL PASS. Looked at the renders in `fidelity/shots/live-activity/`.

**Not verified**
- On the phone: the activity starting at the lead time with an alert, the Dynamic Island countdown, "Out now" with the phone locked (D5-4, Chime's screen recording).

## Day 4: followed shows with nothing scheduled on the widgets (Sun 1 Nov 2026)

**Changed** (D-48)
- Chime follows five shows; three had nothing scheduled and never showed. `UpcomingLoader.Quiet` moved to `Shared/Models/QuietShow` (Codable); `DropSnapshot.nothingScheduled` carries it (old files decode with none); the writer saves only their small posters.
- Medium and large fill spare rows with `WidgetQuietRow` (poster, name, "Nothing scheduled"; large adds "Between seasons"/"Ended"). With none scheduled, `WidgetQuietList` says "Nothing scheduled" and lists them. Fixed: the widgets said "Follow a show" when shows were followed but none scheduled.
- New samples `quiet` and `allQuiet`.

**Red → green**
- `SnapshotStoreTests/nothingScheduled()`, `quietPosterOnly()`, `TimelineProviderTests/nothingScheduled()`, `WidgetTextTests/allQuiet()` failed to compile (no `QuietShow`, no `nothingScheduled`, no `allQuiet`), then passed. 37 widget tests pass.

**Not verified**
- On the phone with Chime's five shows until they look.

## Day 4: small posters on widget rows, "+N more this week" (Sun 1 Nov 2026)

**Changed** (D-47)
- Chime added VisionQuest and Silo and liked the hero; Silo's row needed a small poster. Rows on medium and large now show the poster in a 2:3 box (`WidgetPosterThumb`); the app saves a second image per show, `<id>.poster.jpg` (`ShowArtwork.widgetPoster`), fetching a shared link once.
- `WidgetTimeline.rowCount` 3 → 4 (large shows the hero + 3 rows); `WidgetMoment.thisWeek` and `moreThisWeek(showing:)` count shows due within 7 days that don't fit; `WidgetTagRow` puts "+N more this week" opposite the provider tag. `WidgetProviderTag` became `WidgetTag`. New `busy` sample (6 shows).
- From now on every change is installed on Chime's iPhone (Chime's request).

**Red → green**
- `ShowArtworkTests/widgetPoster()`, `WidgetTextTests/more()`, `TimelineProviderTests/moreThisWeek()` and the store's poster path failed to compile (missing members), then passed. `TimelineProviderTests/rows()` now expects 4 rows; the store's fetch lists include the posters. 33 tests in 5 suites pass.

**Not verified**
- Real posters and art on the phone until Chime looks; tapping "+N more" opens the app's default screen (Upcoming), not a filtered list.

## Day 4: widgets rebuilt on Chime's three picks (Sun 1 Nov 2026)

**Changed** (D-46)
- Chime picked 3 of 28 widget references from a local picker page: Apple TV, Tripsy, Udemy.
- Lock Screen (Udemy): circular is an open ring drawn by hand (the system `.accessoryCircular` gauge only moves a dot, so an empty week looked full), with a TV glyph inside and the count in the gap. Rectangular leads with "Out Mon 22:10" / "Expected Wed 23:00" (`WidgetText.when`), then the name, then the countdown with the provider beside it.
- Small (Tripsy): provider tag (`WidgetProviderTag`) top-left over clear art; name, countdown and out line bottom-left. `WidgetBackdrop` now keeps the top of the art clear and takes a `coverage`.
- Medium (Apple TV): the next show leads over its art; later shows are one-line `WidgetCompactRow`s whose name truncates before the certainty words.
- Large (Apple TV, new family): `LargeWidgetView`, art over the top 62%, then two rows with thumbnails. `WidgetEmptyState` is shared by the three Home Screen sizes.
- Widget art is the wide key art (TVmaze background; an anime's cover, not AniList's thin banner; else the poster), at most 1000 px, saved as `<id>.v2.jpg` so old poster files are deleted and refetched.

**Red → green**
- `WidgetTextTests/when()`: failed with "type 'WidgetText' has no member 'when'", then passed.
- `SnapshotStoreTests`: `artworkPath` (v2 name), `staleArtRemoved` (legacy file deleted, key art fetched first), `smallJPEG` (1920×1080 → 600×338) failed with 6 issues, then passed. `writtenAfterFollowRefreshUnfollow` now expects Silo's background (`1151687.jpg`), the intended change.
- `WidgetRenderTests` gained the large family (338×354) and art on the medium backdrop; 18 tests in 3 suites pass (run without `-quiet`, which hides Swift Testing failures).

**Not verified**
- Real key art in the widgets (renders use the grey placeholder), tinted/accented mode, real Always-On, the widgets on the phone. Chime's approval of the new look (D4-3, D4-4) is still open.

## Day 4: widgets, built by two agents in parallel (Sun 1 Nov 2026)

**Changed**
- Chime asked to fast-track with agents. A contract commit (`584cfeb`) fixed the signatures of `SnapshotStore` and `WidgetAccessibility`, so two worktree agents could build at once without the simulator (the lead ran every test, one at a time).
- Lane A (D4-1, D4-5): `SnapshotStore` writes `snapshot.json` atomically (ISO 8601 with milliseconds, readable after first unlock); `WidgetSnapshotWriter` builds it after every refresh (sorted, drops over an hour old removed, `nextReturn`), reloads timelines, and saves a ≤ 300 px, < 60 KB JPEG per show under `Artwork/` (stale ones deleted). The refresh triggers moved from `UpcomingTab` to `RootView`, so a follow in Search reaches the widgets at once (switching back to Upcoming no longer refreshes; launch, app-active, follow changes and pull-to-refresh still do). `WidgetAccessibility.label`: "Silo, expected in 2 days 4 hours, Apple TV", "out now" only for an exact time ("expected now", "just aired in Japan" otherwise).
- Lane B (D4-2, D4-3, D4-4): `WidgetTimeline` (entries now, at each of the next 5 drops and drop + 1 h, 5-minute spacing, hourly refresh entries up to 48 h so static "2d 4h" text doesn't freeze, reload `.after(nextDrop)` capped at 48 h). Five families in Night Sky under `Shared/Widgets/` (inline, circular with a 7-day ring, rectangular, small, medium "Up next"), each with counting down, Out now, date only and nothing ("Silo returns Fri 9 Jul 2027" / "Follow a show"); certainty in `ReleaseWording` words, no source chip; tinted/accented and Always-On handling; `NextDropWidget` replaces the Day-0 placeholder. `ReleaseWording.verb` made internal.

**Checked**
- Lane A tests (`SnapshotStoreTests`, `AccessibilityLabelTests`) and Lane B tests (`TimelineProviderTests`, `WidgetTextTests`, `WidgetRenderTests`) pass, run by the lead after each merge. Gate build+test+spec pass.
- Looked at the rendered widgets (`fidelity/shots/widgets/`, 39 PNGs): small, medium, rectangular, circular and inline in their states read correctly in Night Sky. The art placeholder in renders is a grey stand-in (no artwork in the repo).

**Reviews**
- `/code-review --fix` (medium, the 6 Day 4 commits): 9 findings, 3 fixed by the review (an offline cold launch overwrote the widget snapshot with nothing and deleted the art; it now starts from the snapshot on disk, `WidgetSnapshotWriter.lastWritten()`; the show page fetches its show and images at the same time; the inline text worked out once). I fixed: a date-only drop never expired, so a widget could show a passed day; it now leaves at midnight after its airdate in the viewer's zone, with an entry and a reload then (`TimelineProviderTests.dateOnly`, whose old expectation of "no reload" was the bug). The review's concurrent fetch made `ShowPreviewTests.tvArtwork` order-dependent; `FakeNetwork` gained `init(routes:)` to answer by URL. Left: the "Silo returns …" empty state can't appear in real use (a date-only drop always becomes current; a design call); the circular count can read up to an hour high in the last day (refresh entries sit on the hour); widget art never refreshes once saved; launch can start two refreshes; Show page back button padding is fixed, not safe-area based.
- Gate build+test+spec pass after the fixes.

**Not verified**
- Tinted/accented mode (ImageRenderer can't set it), real Always-On, large Dynamic Type, and the widgets on the phone (Chime adds them). "Follow a show, see the widget update within 5 s" (SPEC) is still manual.

## D3-13, every Search poster opens the show's page (Sun 1 Nov 2026)

**Changed**
- Chime: tapping any poster on the Search tab (not only results) should open the show; the (+) stays for quick adding; the page shows the poster, then the release date, left out when nothing is releasing. A full page (Chime said "navigate"), not a sheet.
- `ShowPreviewView` (poster, title, meta, the next release in `ReleaseWording` words, Follow/Following), `ShowRoute`, and `ShowPreview.nextDrop`, which times the next episode exactly as Upcoming does (TVmaze with `TimeResolver` and the bundled rules; AniList's Japanese broadcast) and gives nil when nothing is scheduled or the request fails. The airing grid hands over the time it already has. `SearchResult.largePoster` (TVmaze original, AniList extra large).
- Cells open the page with a tap gesture rather than a link, so the title and meta keep their own IDs for the existing screen checks; VoiceOver opens it from the title ("Opens the show"). The page's poster is an accessibility image ("Silo poster"). Debug `-openFirstResult YES`.

**Red → green**
- `ShowPreviewTests` was written alongside the code; its first run failed `largePoster` (the recorded searches carry no image links, rule 9), now an inline show. 6/6 pass.

**Checked**
- New screen check `show-preview` (search Silo, open the first result): first run missed the poster (a bare image isn't in the accessibility tree), fixed; ALL PASS. Screenshot: large poster, "Silo", "2023 · Apple TV · Running", "Out Fri 9 Jul 2027, time not announced", Follow.
- `/code-review --fix` (medium): 8 findings, 3 bugs fixed: a cancelled load (leaving the page before the date came) no longer marks the page loaded, so the line comes back; a followed anime's own time adjustment now applies on this page too (and the airing grid's time is reused only without one), test `animeOffset`; anime drops carry their airdate like Upcoming's. Left: a debug-only re-open after going back; the follow logic exists in two places; VoiceOver opens the page from the title, not the poster; the `show-preview` check depends on Silo still having a next date on TVmaze. Gate re-run after the fixes: build+test+spec pass; `show-preview` and `search-results` ALL PASS (run by the review).
- The new `show-preview` inventory and its `FidelityTests` line are check definitions, added without Chime's explicit OK yet. (Chime OK'd and committed them, `show-preview` screen check.)
- Redesign (Chime: the framed poster looked "wack"; make it like Upcoming): the page is now Night Sky, built from Show detail's parts: `NightArtHeader` with the key art (TVmaze background or AniList banner, else the poster) and the glass back button, then Upcoming's `ReleaseHeadline` (title, giant serif countdown, out line), the meta line and Follow. `ShowPreview.load` returns the time and the art together (TV: show then images; anime: one AniList request gives both; a time the airing grid already knows isn't asked again). New tests `tvArtwork`, `knownDropSkipsShowRequest`, `animeArtwork`; `ShowPreviewTests` pass. The `show-preview` inventory moved to `show-preview-art` and `show-preview-out`; ALL PASS; screenshot checked.

## Service chips: the 12 major platforms (Sun 1 Nov 2026)

**Changed**
- Chime: no YouTube or BBC iPlayer ("not relevant"), show "the popular platforms that most people use", and include Paramount+. D-45: the chips are now a fixed list of 12, always shown in subscriber order (Netflix, Prime Video, HBO Max, Disney+, Paramount+, Hulu, Peacock, Apple TV; then CBS, NBC, ABC, FOX). HBO's own channel shares the HBO Max chip. A platform with nothing coming keeps its chip and says so. `PopularServices`; `AiringFilter.services` no longer counts shows.
- Why Paramount+ was missing: the old rule took the 6 services with the most shows in the 3-day window, and live data had nothing on Paramount+ in it.
- Each logo tile's space is now held while it loads, so the row doesn't widen after scrolling to the picked chip (it stopped short before); a failed logo leaves a gap, not a white box. Scrolling to the picked chip waits one layout pass.

**Red → green**
- `hboOneChip` first assumed the recording had English HBO shows (it has none); it now builds two small listings, one on HBO and one on HBO Max. `SearchFilterTests` pass, including `popularServicesOnly` (the exact 12, never YouTube or BBC iPlayer, an empty platform says so) and `everyServiceHasLogo`.

**Checked**
- Simulator, live data, `-filter service:Paramount+`: Disney+, Paramount+ (picked, centred) and Hulu with logos; "Nothing on Paramount+ in the next few days." (`fidelity/shots/search-services.png`). `search-filtered` ALL PASS.
- `/code-review --fix` (medium): 6 findings, 5 fixed (the Apple TV chip now also matches "Apple TV+", as the platform rules do; two stale comments; SPEC's failed-logo wording; the service's names looked up once per filter, not per show). Left: three hand-kept alias lists (`PopularServices`, `network-logos.json`, `platform-rules.json`) must change together if TVmaze renames a channel; worth merging later. Gate re-run after the fixes: build+test+spec pass.

## D3-12, service logos on Search's chips; Netflix chip dropped (Sun 1 Nov 2026)

**Changed**
- Chime: remove the Netflix Top 10 chip ("it takes us to another link"), put each service's logo next to it, and keep the logo chips together. D-44.
- Netflix chip, its link type and tests removed. `NetworkLogos` reads `rules/network-logos.json` (freely licensed Wikimedia Commons files, matched by exact TVmaze name; only URLs bundled, images load at runtime, rule 9). `AiringFilter.services(in:hasLogo:)` keeps the 6 services with the most shows, then puts logo ones first. `SearchFilterRow` shows the logo on a white 30 × 22 pt tile before the name; the tile holds its place while loading. `ArtworkLoader` sends an "Meridian/1.0" user agent (Wikimedia asks for one). Credits names Wikimedia and lists required credits.
- Logo source chosen after measuring: each network's own site icon worked for about half (NBC, ABC, HBO, Netflix missing; hulu.com serves the Disney+ icon), and scraping sites is what blocked the Netflix chart; Google's favicon service is undocumented. An agent built and licence-checked the Commons list in its own worktree.

**Red → green**
- Red: the build failed on the removed Netflix type, then `NetworkLogosTests.bundled` failed on the empty placeholder list (the other new tests, `lookup`, `credits`, `logosGrouped`, passed once the code compiled). Green once the agent's list landed.
- The bundled test first required `upload.wikimedia.org`; Commons' API now hands out `thumb.wikimedia.org` thumbnails, so it accepts any `*.wikimedia.org` host. Credits use Commons' own credit wording (it already names the licence).

**Checked**
- The agent's list: 57 logos for 58 exact TVmaze names (54 public-domain text logos; AMC+, Hallmark Channel and BBC iPlayer need credit, shown on Credits). Skipped: ITVX (no free file). Every image fetched with the Meridian user agent: 200 image/png (20 checked here, all 57 by the agent).
- Simulator with `-filter service:CBS`: the row scrolls to the picked chip; CBS, FOX and HBO show their logos on white tiles, logo chips first (`fidelity/shots/search-logos.png`). `fidelity/verify-screen.sh search-filtered` ALL PASS. Gate build+test+spec pass.
- Added: the row scrolls to keep a picked chip in view.

**Reviews**
- `/code-review --fix` (medium): 7 findings, all but one handled. Review fixed: `credits` can't crash on an entry with no names (and the bundled test now requires names); the list is decoded once (`NetworkLogos.bundled`). I fixed: a logo that can't load no longer leaves an empty white box (the tile appears only once loaded; a zero-size placeholder keeps the loader's task alive); Commons' `utm_` tracking tags stripped from all 57 links (all still 200 image/png); the unusable hidden test ID removed; the row re-centres on the picked chip when TV | Anime switches. Left: logos go through `ArtworkLoader`, which works out an unused palette and shares the 60-item poster cache (small cost at 120 px).
- Re-run after the fixes: gate build+test+spec pass; `search-filtered` ALL PASS; simulator screenshot still shows the logos.

## D6-9, a Netflix Top 10 link chip (Sun 1 Nov 2026)

**Changed**
- Chime OK'd the two Search screen checks (committed `709993e`) and chose the link-out for D6-9. TV's filter row ends with "Top 10 on Netflix in <country>" plus an arrow, opening Netflix's own chart (`netflix.com/tudum/top10/<country>/tv`); nothing is copied or fetched (O-13). Country from `ViewerCountry` via `UpcomingModel.viewerCountry`; no chip when unknown or on Anime. `NetflixTopTenLink`; chip in `SearchFilterRow`.

**Red → green**
- Red: `NetflixTopTenLinkTests` didn't compile (`cannot find 'NetflixTopTenLink'`), then "ZZ" gave "Unknown Region" instead of nil. Green: 2 tests (4 cases).

**Checked**
- `fidelity/verify-screen.sh search-filtered` ALL PASS with `search-netflix-top10` added to its inventory. Proof gate build+test+spec pass. Not checked: that Netflix's page opens for countries other than Nigeria (only the Nigeria URL was fetched, HTTP 200, by the O-13 agent).
- `/code-review --fix` (medium): 6 findings, 4 fixed (Netflix's names for CZ "czech-republic" and TR "turkey"; "&" → "and" and one hyphen between words; only two-letter uppercase codes, so "001" and "ZZ" give no chip; one shared `ChipCapsule` style). Tests added for TT, CZ, RE, "001", "ng". Re-run: gate build+test+spec pass; `search-filtered` ALL PASS.
- Left: Netflix publishes about 90 country charts, and Netflix answers HTTP 200 even for made-up slugs ("czechia", "turkiye" and "ghana" all return 200), so which countries really have a chart couldn't be checked from here. A viewer outside those may land on a generic page.
- `.claude/settings.json`: Chime OK'd allowlisting the routine build, test, screen-check, gate, commit, push and phone-install commands (1 Nov).

## D3-9 to D3-11, Search filters; D6-9 blocked (Sun 1 Nov 2026)

**Changed**
- Chime: "a way to switch between the options… like the filter that lets you pick between TV and anime", all remaining steps at once. So filters are **one at a time** (Popular by default), as chips under the TV / Anime switch; the spec said they'd combine and now matches Chime. Chime's words stood in for the reference board (D3-10), recorded in UI-BRIEF §5.3.
- `AiringItem` (a cell plus its next episode as a `Drop`, for TV and anime alike) and `AiringFilter` (options, filtering, no-match copy). Search keeps the whole pool and caps at 15 after filtering, so anime premieres now surface under New seasons. Every filter drops an episode that came out since the grid loaded. Each cell reads its network over its time in `ReleaseWording` words ("CBS" / "Out Tue at 03:01"). `SearchFilterRow` runs to the screen's edges. Debug `-filter today|new-seasons|exact-time|service:<name>`.
- New screen checks `search-filtered` and `search-filter-empty` (inventories + 2 `FidelityTests`), added without Chime's OK yet (check definitions).
- D6-9 ("Top 10 on Netflix in Nigeria"): an agent checked O-13 first. Nigeria rows exist, but Netflix's Top10 terms forbid reproducing, distributing or deriving from the data, and automated access. Nothing built; O-13 closed as **no**; D6-9 blocked pending Chime (link out instead, or drop).

**Red → green**
- `SearchFilterTests` was written with the code, so no red run. Instead a mutation run: today, new seasons and exact time made to return `true` failed 4 tests (today ×3 zones, newSeasons, exactTime, anime); restored. Green: 12/12.

**Checked**
- `fidelity/verify-screen.sh search-filtered` and `search-filter-empty`: ALL PASS on the final code (screenshots looked at; the row was clipped at the page margin, fixed).

**Reviews**
- `/code-review --fix` (medium): 6 findings, 3 fixed. The grid now sits in `TimelineView(.everyMinute)`, so an aired episode leaves within a minute and lines stay right; a cell's network and time are one VoiceOver element; the anime Today test can't pass on an empty list. "Nothing else airs today." became "Nothing left to air today." Left: service chips counted over the whole pool (on purpose); `AiringItem.weight` only read by tests.
- proof:verifier: logic PASS; row INCOMPLETE. Fixed: screen checks re-run on the final code; SPEC/features copy matched to the app ("Show popular", "Exact time"); the chips' 44 pt tap area moved inside the button label; the screen check gained `contains` and `selected` (`FidelityTests`), so `search-filtered` now requires the Exact-time cell to read "Out …" and the picked chip to be selected; proved by flipping both in the inventory (2 failures at FidelityTests.swift:67 and :70), then restored. Not fixed: the empty-state check uses a debug-only service name, because live data can't guarantee an empty real filter; the pool still loads once per catalog per session (the minute timeline keeps it honest; reload on return is a later nicety).

**Not verified**
- Chime hasn't approved the two new inventories, the `FidelityTests` additions, or a device screenshot (D3-11 stays `passes: false`).

## D3-8b, anime premieres in Search (Sun 1 Nov 2026)

**Changed**
- `AniListClient.airingSoon` makes a second request for this week's episode 1s (`airingSchedules`, `episode: 1`, starting on the hour so the 6 h cache works) and merges them into the popular airing list, most popular first, no duplicates. If that request fails, the popular list still shows; a cancelled load still fails.
- The spec said to widen the popular query to `NOT_YET_RELEASED`. Tried live first: 26 of 50 slots went to shows months away, 0 premieres this week. The direct query found 3 (GROTESQQQUE, Demons' Crest, Cardfight!! Vanguard). SPEC and D3-8b reworded to match. New fixture `anilist/premieres-2026-11-01.json`.

**Red → green**
- Red: `premieres` (subset, episode 1 and request-count expectations), `premieresCachedWithinTheHour` (4 requests, not 2), `premieresFailing` (`Caught error: .http(status: 500)`). Green: `AniListClientTests` 11/11.
- Red: `premieresPaged` (page 2 never asked for), `premieresPageLimit` (2 requests, not 4). Green: `AniListClientTests` 14/14. The exact paged query was run live: page 2 of 1–8 Oct held the last 10 premieres, one with popularity 41,634.

**Reviews**
- `/code-review --fix` (medium): 6 findings, 2 fixed (the premieres request ended up to 59 min early; the no-duplicates test couldn't fail, so `premieresMerged` feeds one show from both requests and checks the request body, with `FakeNetwork.bodies`). Left: the grid caps at 15 before filtering, so premieres (popularity 14,850 and below) don't show until D3-9 stores the whole pool and caps after filtering; a rate-limited premieres request isn't retried until the app restarts; the query can't filter by country, so other countries' episode 1s share the pages; 2 s more on a cold anime load.
- proof:verifier: FAIL on one page of 50, fixed by paging (above). Also noted a blind spot of up to 6 h: a premiere that airs while the popular list is cached is in neither list.

## Search filters spec (D-43) and D3-8, the airing-soon pool (Sat 31 Oct 2026)

**Changed**
- Chime asked for a filter of popular shows airing soon, plus other filters, with popularity from "consensus of reliable sources". Chime chose: TVmaze `weight` and AniList popularity now, a bundled "Top 10 on Netflix in Nigeria" chip later (Should, D6-9); filters Today, New seasons, Exact time known, Service. D-43; SPEC criteria; features D3-8, D3-8b, D3-9, D3-10, D3-11, D6-9. A fresh verifier read the spec: 11 findings, all folded in (anime premieres need `NOT_YET_RELEASED`, date-only and tie-break rules, viewer's-yesterday fetch, Service definition, per-catalog windows, filter states, chip renamed and freed from the window).
- D3-8: `TVmazeScheduleItem` decodes its episode. `AiringSoon.pool` keeps each show's soonest episode still to come, resolved by `TimeResolver` with the bundled rules (Search now gets them from `UpcomingModel.rules`), uncapped until filtered. Fixed a rule-2 bug: "still to come" used the raw airstamp, so a placeholder kept an episode "coming" for hours after it was out. Schedules are now fetched from the viewer's yesterday (8 calls), so east of the US a US evening that lands the next day is included.

**Red → green**
- Red: `AiringSoonTests` didn't compile (`'Pick' is not a member type of enum 'Meridian.AiringSoon'`). Then `seasonDropKeepsEpisodeOne` failed: the test used Dead-End Job, which is Korean and rightly excluded; switched to English shows. Green: `AiringSoonTests` 11/11. The `picks` test changed from `count == limit` to `count > limit` because the spec moves the cap after filtering.
- Red: `FormattingTests.stepsCalendarDays` didn't compile (`extra argument 'addingDays' in call`). Green: `AiringSoonTests` + `FormattingTests` 17/17.

**Reviews**
- `/code-review --fix` (medium): 5 findings, 2 fixed. The TV window now ends on the viewer's third day (`windowEndsOnTheThirdDay`); a special (no season or number) sorts after numbered episodes, so it never displaces episode 1. Left: the grid loads once per catalog and isn't reloaded when the app returns (older behaviour, handle with the filter work, D3-9/D3-11); viewers west of the US make 2 extra cached calls; date-only episodes count by their listed date (D-28, intended).
- proof:verifier: PASS with 2 gaps, both fixed. The tie-break test couldn't fail because the recording lists batches in order (`tieBreakIgnoresListOrder` feeds it reversed). Days were stepped in 24-hour blocks, which repeats or skips a day at a clock change; `DropFormatter.localDay(_:addingDays:)` steps calendar days (New York 1 Nov 2026, London 29 Mar 2027).
- Settings: `.claude/settings.json` added (12 read-only allowlist entries from `/fewer-permission-prompts`, Chime's request); the gate flags it as a check-definition change awaiting Chime's OK.

## Upcoming with nothing scheduled, unslopped (Sat 31 Oct 2026)

**Changed**
- Chime followed Solo Leveling and saw a blank screen of text ("too bland"). With no countdown, Upcoming now spotlights a show: its key art fading into night, the serif title, and either the date-only line ("Out Fri 9 Jul 2027, time not announced") or why there's no time ("Waiting for news · last episode Sat 29 Mar 2025", `ReleaseWording.quietNote`). SPEC's "Nothing scheduled… checks again each time you open it" stays, small, under a quiet spotlight.
- "Nothing scheduled" is the poster grid from Search, each show with its status line. Whatever leads the screen (hero or spotlight) leaves its section, so no show appears twice.
- `UpcomingLoader.Quiet` carries the show ID, status and last airdate (TVmaze `previousepisode`, AniList status); quiet shows get artwork and survive a failed refresh. `PosterImage` moved to `Features/Artwork`.

**Red → green**
- Red: `quietNote` (`no member 'quietNote'`), `UpcomingLoader.Quiet` (`not a member type`), then the duplicate checks (`quietOnly.sections → [Nothing scheduled: Solo Leveling]`, `withDate.sections → [Date only, Nothing scheduled]`). Green: 120 tests in 29 suites.

**Checked**
- On Chime's iPhone: Solo Leveling spotlit, then Silo spotlit with Solo Leveling and House of the Dragon in the grid. `fidelity/verify-screen.sh upcoming`: ALL PASS.
- `/code-review --fix`: 6 findings, 3 fixed (a blank top when every drop had aired now falls back to SPEC's sentence, with a test; a date-only spotlight is a button that opens Show detail; the spotlight rule lives once in `make`). Left: failed shows are matched by name and re-added at the end (only matters if a catalog renames a show between refreshes); fix by matching show IDs.

## Screen checks (D3-1) (Sat 31 Oct 2026)

**Changed**
- `fidelity/inventory/<screen>.json` for welcome, upcoming, upcoming-empty, detail and settings: accessibility IDs and, where the UI brief fixes it, the exact copy. `MeridianUITests/FidelityTests` launches the real app on each screen (debug launch arguments, `-inMemoryStore` for a clean start), checks every item and saves a screenshot. `fidelity/verify-screen.sh [screen]` runs it on the separate `MeridianFidelity` scheme and prints ALL PASS. Chime approved the new check script (31 Oct). Not added to `.claude/proof.json`.
- The Upcoming hero's ID moved onto its button (a button hides its label's container from UI tests).

**Checked**
- `fidelity/verify-screen.sh`: ALL PASS, 5 tests. Unit tests: 117 pass.

**Not verified**
- Search's inventory waits for the grid redesign (merging next). No approved baselines in `fidelity/refs/` yet; screenshots go to the git-ignored `fidelity/shots/`.

## Anime from AniList (Sat 31 Oct 2026)

**Changed**
- `AniListClient` (GraphQL): search, one show's next episode, and anime airing in Japan this week. Adult titles always filtered, requests spaced 2 s apart (30 a minute), responses cached like TVmaze's (rule 8). `AniListModels`.
- Search has a TV | Anime switch. Anime opens on "Airing in Japan this week" (poster grid) and searches AniList; results read "2023 · Crunchyroll · Finished".
- Followed anime load through `UpcomingLoader` as "Airs in Japan …" drops (`resolveAniList`), with their streaming site as the provider and AniList's banner and cover as art. Drops key AniList shows as `anilist:<id>` (`Drop.showKey`).
- Debug launch options `-kind anime` and `-followAnime <ids>`.

**Red → green**
- Red: `AniListClientTests` (`cannot find type 'AniListClient'`) with fixtures recorded from AniList on 30 Oct (`anilist/search-frieren`, `anilist/airing-2026-10-30`). Green: 113 tests in 28 suites.

**Checked**
- On Chime's iPhone: the anime grid (Black Clover S2, Detective Conan, Dragon Ball Super…) and a Frieren search.

**Review and follow-ups (31 Oct)**
- `/code-review --fix`: 7 findings, 6 fixed (concurrent AniList requests broke the 2 s spacing, now reserved per slot with `rateLimitConcurrent`; airing cache key per hour; stale TV results after switching to Anime; a loader without AniList reporting anime as failed). The 7th, "this week" covering only about a day, is fixed: `airingSoon` now asks for popular airing Japanese anime and keeps those with an episode in the next 7 days (red: `ids.prefix(3) → []`, then green with `anilist/releasing-2026-10-31`).
- D2-6: the viewer's country comes from the time zone via the tz database's zone.tab, bundled as `rules/zone-countries.json` (`scripts/make-zone-countries.py`); the device region is the fallback. `ViewerCountryTests` (written with the code). D2-5, D2-6, D2-7 marked passing.

**Not verified**
- A followed anime's Upcoming row and detail on the phone. Anime detail has no episode list (AniList query doesn't fetch one).

## Search with posters (Fri 30 Oct 2026)

**Changed**
- Chime: tab bar order Upcoming · Search · Settings (Search in the middle as a plain tab; D-41 updated), and Search was "too bland". A search reference board (`docs/design/search-board/`, 21 screens) produced 4 picks (`picks.json`): Plex, Apple TV and Hypelist poster rows for results, Plex's "Popular Searches" grid before typing.
- `SearchView`: before you type, "Airing in the next few days" as a three-across poster grid with a follow button on each poster; results as poster cards (56 × 84 poster, serif title, year · network · country · status, follow button). `PosterImage` loads TVmaze's medium poster at runtime (D-37). `TVmazeShow.image`, `SearchResult.poster`.

**Red → green**
- `SearchPosterTests` was written with the code, not red first: the memory guard refused the red run (85%). Green: 105 tests in 26 suites.

**Checked**
- On Chime's iPhone: the poster grid (Boston Blue, Fire Country, Marshals, Sheriff Country, The Gilded Age, The Rainmaker…) and results for "Silo" (Silo 2023 · Apple TV · Running, Silo 2017 · meWATCH, Silk, Solo, Milo), with the new tab order.

**Not verified**
- The code review of this change.

## Day 0 device check, and the app on Chime's iPhone (Fri 30 Oct 2026)

**Changed**
- Chime's iPhone 14 Pro (iOS 27.0.1) paired with the Mac (`devicectl manage pair`), Developer Mode on, Apple ID in Xcode. Team ID only in the git-ignored `Config/Signing.local.xcconfig`.
- Chime found the app "basically empty": nothing was followed, Search was blank until you typed, and most known shows are between seasons. Search now opens on **"Airing in the next few days"** (`AiringSoon`): TVmaze's streaming and US schedules for today and the next two days, English drama and animation plus anime, no news or talk shows, most popular first (TVmaze weight), each with a follow button. `TVmazeClient.webSchedule(date:)` and `schedule(country:date:)`; `TVmazeScheduleItem` reads both schedule shapes.
- App icon: a light New York serif "A" on Night Sky charcoal (`scripts/make-app-icon.swift`, `Meridian/Resources/Assets.xcassets`).
- The art header shows the night base while art downloads, not a grey block (seen on the phone).

**Red → green**
- Red: `AiringSoonTests` (`cannot find type 'TVmazeScheduleItem'`), with fixtures recorded from TVmaze on 30 Oct (`schedule-web-2026-10-30`, `schedule-us-2026-10-30`). Green: 104 tests in 25 suites.

**Checked**
- Day 0 gate: free signing works for the app **and** the widget extension, both with the App Group `group.dev.chime.meridian` in their signed entitlements (`codesign -d --entitlements`). Profile expires Fri 6 Nov 2026 21:27 UTC.
- On the phone (screenshots via `devicectl device capture screenshot`): Upcoming with a live countdown for Outlander: Blood of My Blood (S2E7, STARZ · US, out tomorrow 01:00 Lagos time), and Silo's Show detail with its art.

**Not verified**
- The widget reading App Group data on the phone (no real widget until Day 4). The airing-soon list on the phone (needs Chime to open Search).

**Next:** Chime's notes on the phone build; then Day 3's remaining items (AniList, fidelity inventories) and Day 4 widgets.

## Day 3: the real app on Night Sky (Fri 30 Oct 2026)

**Changed**
- Removed the rejected numeral studies and the old artwork-led views; Night Sky is now the app, not a debug study: `UpcomingView`, `UpcomingHero` (`ReleaseHeadline`, `ReleaseMeta`), `ShowDetailView`, `NightStyle`.
- `FollowStore` + `FollowedShow` (SwiftData): follow, unfollow, one entry per show per catalog.
- `UpcomingSections`: SPEC's sections at every boundary, the hero, and the empty headline ("Silo returns Fri 9 Jul 2027", or "Nothing scheduled … checks again each time you open it").
- `UpcomingLoader`: followed shows → TVmaze next episode → `TimeResolver` → drops with provider labels; failures reported, not hidden. `UpcomingModel` adds artwork and the last three aired episodes.
- `ProviderLabel(name:countryCode:viewerCountry:rules:)`: "No official stream in your country" only where the rules file says so. Viewer country is the device region for now (D2-6's time-zone mapping and Settings override are still open).
- D-42 (closes O-10): no airtime and more than 180 days away → date only. D-41 (closes O-11): tab bar.
- App shell: Welcome (zone line, Find a show, Not now), tab bar (Upcoming, Settings, Search with the search role), Search (TVmaze, year · network · country · status, follow toggle), Settings (zone, lead time 30 min–6 h, credits), Credits. Show detail stores the Live Activity switch per show and can unfollow; "Report a wrong time" stays hidden until the email route (Day 6).
- Dates in another year say the year ("Fri 9 Jul 2027").
- Debug launch options for screenshots of the real app: `-follow <ids>`, `-tab search|settings`, `-query <text>`.

**Red → green**
- Red, each before its code: `FollowStoreTests` (`cannot find 'FollowStore'`), `FarPlaceholderTests` and `ProviderLabelTests` (`extra arguments`), `UpcomingSectionsTests` and `UpcomingLoaderTests` (`cannot find 'UpcomingLoader'`), `SearchResultTests` (`cannot find type 'SearchResult'`), `zoneSummary` (`no member 'zoneSummary'`), the year tests (`extra argument 'now'`). `LeadTimeTests` was written with its code, not before.
- Green: `xcodebuild … test`, 100 tests in 24 suites.
- `/code-review --fix` (medium): 10 findings, 8 fixed: a slower refresh overwriting a newer one, a cancelled search showing an error, past episodes trusting a placeholder airstamp (rule 2), specials using up episode slots, the debug launch not running on Welcome, serial artwork loads, episode dates without the year, and Upcoming emptying when TVmaze fails (now keeps the last known times; `UpcomingLastKnownTests`). Left: row thumbnails use the background art (deliberate), and `explanation` still takes the zone separately.

**Checked**
- The real app on the simulator with live TVmaze data: Welcome, Search for "Euphoria" (the US and Israeli shows read differently), Upcoming with six followed shows, Settings. TVmaze currently lists no next episode for five of them and only Silo's 2027 placeholder, so Upcoming shows the empty headline, Date only and Nothing scheduled. The filled hero is shown with sample times in `-designPreview`.

**Not verified**
- Show detail with live data (the simulator can't tap; the same view renders in `-designPreview detail`). Anime search (AniList, D2-5) isn't built. Fidelity inventories (D3-1) aren't set up yet.

**Next:** AniList client and the Anime tab (D2-5), viewer country from the time zone (D2-6), fidelity inventories (D3-1), then Chime's approval of each screen.

## Day 2: saying how sure a time is, without dots (Fri 30 Oct 2026)

**Changed**
- Chime rejected the status dots: they needed explaining, so users won't read them. `TrustStyle` (Debug) builds three word-based options, picked with `trustA|trustB|trustC` after `-designPreview A`: A puts the certainty in the verb ("Expected today at…", "Airs in Japan…", "…, time not announced"), B flags only the exceptions ("Estimated", "Time not announced"), C names the source on every row ("TV schedule", "Usual release time", "Japanese TV time").
- Show detail replaces the dot and the Broadcast row with one plain sentence on where the time came from (`DirectionCopy.why`).

**Checked**
- Simulator screenshots of all three options (top and list) and three detail screens; side by side in `docs/design/direction-board/trust.html`.

**Not verified**
- If Chime picks one, CLAUDE.md rule 3, SPEC's source-chip criterion and D-39 change with it; that needs Chime's OK.

**Decided:** Chime picked A (D-40, supersedes D-39). `Shared/Time/ReleaseWording` (test-first: red `cannot find 'ReleaseWording' in scope`, then green) words every time ("Out", "Expected", "Airs in Japan", "time not announced"; only an exact time says "Released") and explains its source on Show detail. B, C, `TrustStyle` and the dot style of `SourceChip` are deleted; CLAUDE.md rule 3, SPEC, PLAN and features.json now describe the wording. `guide.html` is redrawn for it. 74 tests pass; `check-spec` passes.

**Next:** Delete the old artwork-led views, rewrite UI-BRIEF §1–3 for Night Sky, and build the real Upcoming on it (Day 3).

## Day 2: unslop pass on Night Sky (Fri 30 Oct 2026)

**Changed**
- Installed the `unslop` skill (heydamir/unslop, CC BY 4.0) in `~/.claude/skills/unslop` after reading every file. Audit: light slop (coloured chips and icons on every row, uppercase tracked labels, serif on small text, too many sizes, "GMT+1" against "Lagos time", off-grid spacing). Chime approved the direction and all fixes.
- Direction: patient, exact, nocturnal; the art and the countdown are the only moments; signature is a small status dot before each time's source (D-39).
- `SourceChip(plain:)` is now a dot in the status ink plus the word in muted text. Section labels in sentence case; serif only for show titles and the countdown; three text roles (`NightInk`); spacing on the 4-point grid; zones named by place ("Lagos", "New York"); Show detail drops "Your time" (the headline says it) and keeps the broadcast time.

**Checked**
- Simulator screenshots of Silo, House of the Dragon and Frieren (Upcoming and Show detail) and both screens scrolled; `docs/design/direction-board/variants.html`. The unslop checklist passes on them.
- `xcodebuild … test`: 67 tests in 16 suites pass.

**Not verified**
- Times are samples. Widgets still use the filled chip.

**Also:** Silo's sample source corrected from "Broadcast" to "Apple TV rule" (Apple TV is a streamer; the recorded TVmaze fixture has no air time). `docs/design/direction-board/guide.html` explains every part of the Silo screens with numbered marks on the screenshots (shots git-ignored).

**Next:** Chime's verdict on the unslopped screens. Then delete the old artwork-led views, rewrite UI-BRIEF §1–3 for Night Sky, and build the real Upcoming on it (Day 3).

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
- Chime asked for all three as variants. `Meridian/Features/Debug/Directions/` (Debug only): `NightSkyUpcoming`/`NightSkyDetail`, `GlassUpcoming`/`GlassDetail` (Liquid Glass, `glassEffect`), `PosterColourUpcoming`/`PosterColourDetail`, plus `DirectionKit` (muted and vivid tones, ink choice, shared fact and episode rows). `-designPreview A|B|C [detail] [bottom]` opens each; no letter opens the old screens.
- `NumeralStudy.glass` (SF Pro Thin) for B.
- `ArtworkPalette` picks the strongest hue band instead of averaging every hue, so teal-and-orange art (Silo's poster) gives teal or orange, not olive.

**Red → green**
- Red: `ArtworkPaletteTests.complementaryHuesDontMix`: "hue 101.08773274659956 is neither teal nor orange".
- Green: `xcodebuild … test -only-testing:MeridianTests`, 66 tests in 16 suites (iPhone 18 Pro, iOS 27.0).
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
- Chime's picks (47 of 154) saved to `docs/design/reference-board/picks.json` and to the reference collection "Meridian references" (47 iOS screens). `scripts/picks-to-references.py` writes them into `docs/design/REFERENCES.md`.
- `docs/design/UI-BRIEF.md`: direction from the picks, tokens, three numeral studies, components, and every screen and surface with job, references, test IDs, copy and states. `scripts/check-brief.sh` checks it against SPEC.
- `Shared/Design/`: `Tokens` (system neutrals, status inks with fixed meanings, spacing, radius), `NumeralStudy` (A System, B Mono, C Serif), `SourceKind`, `SourceChipContent`, and the `SourceChip`, `CountdownText`, `ProviderLabelView`, `SectionHeader` and `DropRow` components, each with a `#Preview`.
- `Shared/Time/`: `CountdownFormatter` (Out now / ticking / "2d 4h" / date only, matching SPEC's section boundaries), `DropFormatter.relativeDay` (Today, Tomorrow, weekday, then the date, with the year when it differs) and `weekdayTime`; `Drop.episodeLabel` ("S2E5").
- `Meridian/Features/Debug/NumeralStudyBoard` + `StudySurfaces`: every surface at real point sizes for each study. `NumeralStudyRenderTests` renders them to `docs/design/studies/` (only with `TEST_RUNNER_STUDIES_OUT` set); compare in `docs/design/studies/index.html`.
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
- `Meridian/Services`: RulesStore (remote off while private, validate-or-fallback, once a day, retry in an hour), TVmazeClient (Retry-After capped at 30 s, exponential backoff, 6-hour disk cache), ResponseCache, TVmaze models.
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
- XcodeGen project (`project.yml`): `Meridian` app, `MeridianWidgets` extension, `MeridianTests` (Swift Testing). iOS 26.0, Swift 6, strict concurrency.
- Signing and IDs in `Config/Base.xcconfig` (bundle prefix `dev.chime`, App Group `group.dev.chime.meridian`), overridden by the git-ignored `Config/Signing.local.xcconfig`, so no Team ID is committed.
- `Shared/Snapshot/AppGroup.swift` and `SetupCheck.swift`: the app writes a timestamp to the App Group, and the placeholder `systemSmall` widget reads it.
- Privacy manifests for the app (`CA92.1`, `1C8F.1`) and the widget (`1C8F.1`).
- `.claude/proof.json` gate: build, test, spec. Simulator: iPhone 18 Pro, iOS 27.0 (the iPhone 17 Pro only has iOS 26.5, so the default destination didn't match).

**Red → green**
- Red: `AppGroupTests` failed with "Unable to resolve module dependency: 'Meridian'" (no app code yet).
- Green: `xcodebuild … test`, 3 of 3 tests pass on the iPhone 18 Pro (iOS 27.0) simulator.

**Checked**
- Build has no compiler warnings.
- `PrivacyInfo.xcprivacy` is bundled in both `Meridian.app` and `MeridianWidgets.appex`; `plutil -lint` OK.
- Built Info.plist: `MeridianAppGroup = group.dev.chime.meridian`, `NSSupportsLiveActivities = true`, display name `Meridian`.
- Simulator launch: the screen shows "App Group OK · wrote 20:29".

**Not verified yet**
- The widget on a real iPhone with free signing (D0-3). It needs Chime to sign in to Xcode with an Apple ID, turn on Developer Mode, and plug in the phone. The simulator allows shared defaults even without the entitlement, so only a device proves the App Group.
- The widget wasn't added to the simulator Home Screen (that needs manual taps).

**Next:** device check, then Day 1 (time engine, tests first).
