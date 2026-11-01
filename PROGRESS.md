# Progress

Build log for the one-week plan (`docs/PLAN.md`). Newest entry first.

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
- Netflix chip, its link type and tests removed. `NetworkLogos` reads `rules/network-logos.json` (freely licensed Wikimedia Commons files, matched by exact TVmaze name; only URLs bundled, images load at runtime, rule 9). `AiringFilter.services(in:hasLogo:)` keeps the 6 services with the most shows, then puts logo ones first. `SearchFilterRow` shows the logo on a white 30 × 22 pt tile before the name; the tile holds its place while loading. `ArtworkLoader` sends an "Airstamp/1.0" user agent (Wikimedia asks for one). Credits names Wikimedia and lists required credits.
- Logo source chosen after measuring: each network's own site icon worked for about half (NBC, ABC, HBO, Netflix missing; hulu.com serves the Disney+ icon), and scraping sites is what blocked the Netflix chart; Google's favicon service is undocumented. An agent built and licence-checked the Commons list in its own worktree.

**Red → green**
- Red: the build failed on the removed Netflix type, then `NetworkLogosTests.bundled` failed on the empty placeholder list (the other new tests, `lookup`, `credits`, `logosGrouped`, passed once the code compiled). Green once the agent's list landed.
- The bundled test first required `upload.wikimedia.org`; Commons' API now hands out `thumb.wikimedia.org` thumbnails, so it accepts any `*.wikimedia.org` host. Credits use Commons' own credit wording (it already names the licence).

**Checked**
- The agent's list: 57 logos for 58 exact TVmaze names (54 public-domain text logos; AMC+, Hallmark Channel and BBC iPlayer need credit, shown on Credits). Skipped: ITVX (no free file). Every image fetched with the Airstamp user agent: 200 image/png (20 checked here, all 57 by the agent).
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
- Red: `AiringSoonTests` didn't compile (`'Pick' is not a member type of enum 'Airstamp.AiringSoon'`). Then `seasonDropKeepsEpisodeOne` failed: the test used Dead-End Job, which is Korean and rightly excluded; switched to English shows. Green: `AiringSoonTests` 11/11. The `picks` test changed from `count == limit` to `count > limit` because the spec moves the cap after filtering.
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
- `fidelity/inventory/<screen>.json` for welcome, upcoming, upcoming-empty, detail and settings: accessibility IDs and, where the UI brief fixes it, the exact copy. `AirstampUITests/FidelityTests` launches the real app on each screen (debug launch arguments, `-inMemoryStore` for a clean start), checks every item and saves a screenshot. `fidelity/verify-screen.sh [screen]` runs it on the separate `AirstampFidelity` scheme and prints ALL PASS. Chime approved the new check script (31 Oct). Not added to `.claude/proof.json`.
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
- App icon: a light New York serif "A" on Night Sky charcoal (`scripts/make-app-icon.swift`, `Airstamp/Resources/Assets.xcassets`).
- The art header shows the night base while art downloads, not a grey block (seen on the phone).

**Red → green**
- Red: `AiringSoonTests` (`cannot find type 'TVmazeScheduleItem'`), with fixtures recorded from TVmaze on 30 Oct (`schedule-web-2026-10-30`, `schedule-us-2026-10-30`). Green: 104 tests in 25 suites.

**Checked**
- Day 0 gate: free signing works for the app **and** the widget extension, both with the App Group `group.dev.chime.airstamp` in their signed entitlements (`codesign -d --entitlements`). Profile expires Fri 6 Nov 2026 21:27 UTC.
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
