# Spec: Meridian v1

Updated 29 Oct 2026 for the one-week portfolio build (D-32). Earlier versions are in `archive/`. The decisions it relies on are D-01 to D-34 in `DECISIONS.md`. Criteria marked **(Should)** come from the Should column of the scope table in `PLAN.md`.

## Goal

Meridian is for people who follow weekly TV and simulcast anime from outside the US release zone, starting with Lagos (UTC+1, no DST). It answers one question at a glance on the Lock Screen, Home Screen and Dynamic Island: **"How long until my next episode, here, and where is it on?"** Every time says where it came from, and the app never shows a made-up time as exact. When it works, the viewer stops googling release times, stops doing time-zone maths, and trusts the number they see.

This version is a **portfolio project**: it's built in one week, ends at a private beta, and is published as an open-source GitHub repo with a README, demo video and case study (D-32).

## Non-goals

- No App Store release, App Store listing, privacy label, age rating or pricing (D-32).
- No spending: no Apple Developer Program, TestFlight or paid services (D-35).
- No account, no server we run, no analytics SDK, no ads.
- No `BGAppRefreshTask`; refresh happens when the app opens (D-27, D-33).
- No multi-card onboarding; one welcome screen.
- No region-aware "where to watch" from TMDB/JustWatch (see "After the week" in `PLAN.md`).
- No social features, ratings, reviews or watch history beyond "followed".
- No importers (TV Time, Trakt), calendar export, Apple Watch app, iCloud sync or paid tier in v1.
- No artwork files committed to the repo. Show artwork is fetched at runtime from TVmaze or AniList and cached on the phone (D-37).
- No scraping of LiveChart, Crunchyroll or any site without an API.
- Search filters narrow only the grid shown before typing, not typed results. Popularity comes from keyless sources, with no live trending service that needs a key (D-43, D-06).

## Users

- **Primary:** Chime in Lagos. Follows 5–15 weekly shows (HBO, Apple TV, Netflix, Prime) and a few airing anime, and checks the phone before bed.
- **Secondary:** viewers in the UK, India, South Africa and elsewhere outside the US whom current trackers show US times or "12am" placeholders. Also anime-first viewers who track simulcasts.
- **Moments:** the night before ("tonight or tomorrow morning here?"), release hour (the episode lands while they're doing something else), and quiet weeks ("is anything coming?").

## Core flows

1. **First run:** open the app → one welcome screen shows "Times shown for Lagos (UTC+1)" → follow the first show → prompt to add a Lock Screen widget → Upcoming.
2. **Follow a show:** Search → choose TV or Anime → type a title → results show year, network and status → tap the right result → Follow → Upcoming updates and the snapshot is rewritten.
3. **Glance:** look at the Lock Screen widget → "Silo · 2d 4h" → the long-press or the app shows the day and time, how sure it is ("Out", "Expected") and the provider label.
4. **Release night:** a show is opted in → when the app is foregrounded, Meridian schedules the activity → it starts 2 h before (lead time) with an alert → the Dynamic Island counts down → at the drop it shows "Out now" → it ends at drop + 1 h.
5. **A time changes:** refresh finds a later time for the same episode → the row shows "Delayed" with the old time → widgets and the activity are rescheduled.
6. **Report a wrong time (Should):** Show detail → "Report a wrong time" → an email opens, prefilled with show, episode, time shown, source and time zone (while the repo is private) → a prefilled GitHub issue once the repo is public (D-34).
8. **Publish:** Day 7 → the open-source checklist passes → the repo goes public → the README, video and case study go up on the portfolio site.
7. **Nothing scheduled:** no followed show has an upcoming episode → the empty state names the next real date, or says "Nothing scheduled for your shows yet. Meridian checks again each time you open it."
9. **Browse what's popular (D-43):** Search → TV or Anime → before typing, the grid shows popular shows airing in the next few days → tap Today, New seasons, Exact time known or a service → the grid narrows at once → follow from the grid, or tap "Show popular".

## Acceptance criteria

- [ ] Every stored time is a UTC `Date`, formatted only in views with `TimeZone.current` or the Settings override. verify: unit test `FormattingTests` renders one fixed instant in 6 zones and checks the strings; grep shows no `TimeZone(` use outside `Shared/Time/` and Settings.
- [ ] A TVmaze episode with `airtime == ""` is never `exact`, whatever its airstamp hour (12:00Z, 16:00Z or 17:00Z). verify: `TimeResolverTests.placeholderNeverExact` over fixtures for Netflix (12:00Z) and Peacock/Hulu (16:00Z, 17:00Z).
- [ ] Each platform rule resolves correctly in Lagos, London, Kolkata, Tokyo, New York and Sydney, in both US summer and US winter. verify: parameterised Swift Testing matrix `PlatformRulesTests` (rule × zone × season), all green.
- [ ] Clock-change weeks give the right local times: US (8 Mar 2026, 1 Nov 2026, 14 Mar 2027), EU (25 Oct 2026, 28 Mar 2027) and Sydney (4 Oct 2026, 4 Apr 2027). verify: `PlatformRulesTests.dstChangeover` has cases on each side of each date.
- [ ] An anime episode's UTC instant doesn't move when US clocks change. verify: `TimeResolverTests.animeIgnoresUSDST` with fixtures from either side of 1 Nov 2026.
- [ ] A per-episode override in the rules file wins over the platform rule. verify: `TimeResolverTests.overrideBeatsRule` using the Stranger Things 5 17:00 PT fixture.
- [ ] The rules file loads the bundled copy. A fetched copy (Should; behind a flag that stays off until the repo is public, D-34) is used only if it passes schema validation, and the app falls back on a network error or invalid JSON. verify: `RulesStoreTests` with the flag off (no network call made) and on (a stub URLProtocol returning a valid file, invalid JSON and a 500).
- [ ] Every displayed time says how sure it is in words (D-40): `Out`/`Released` for an exact time (broadcast or a confirmed override), `Expected` for an estimate (a platform rule, an unconfirmed override or an offset), `Airs in Japan` for an AniList time, and `time not announced` for a date-only drop; Show detail explains the source in one sentence. No colour code or dot carries certainty. verify: `ReleaseWordingTests` asserts the wording and explanation for each `ReleaseSource` case; the screenshot passes `fidelity/verify-screen.sh upcoming`.
- [ ] `dateOnly` drops show their airdate and "time not announced" with no ticking timer, in the app and in widgets. The airdate is the same calendar day whatever zone is used to show it. verify: `DateOnlyTests` formats one `dateOnly` drop in Africa/Lagos, America/New_York and Pacific/Auckland and gets the same day each time; a widget preview for `dateOnly` shows no timer.
- [ ] The provider label shows the origin network or channel and its country ("HBO · US"); "No official stream in your country" appears only when a rules-file entry lists the viewer's country. The viewer's country is the country of the current time zone (bundled zone-to-country table), unless Settings overrides it. verify: `ProviderLabelTests` covering network, web channel, the no-stream flag, Africa/Lagos → NG, and the Settings override.
- [ ] Search never auto-selects; each result shows year, network or channel, and status; AniList results with `isAdult == true` are excluded. verify: `SearchViewModelTests` with the "Euphoria" fixture (2 results) and an adult AniList fixture.
- [ ] Before typing, Search shows shows airing soon, most popular first (TVmaze `weight` for TV, AniList popularity for anime). **Windows:** TV covers the viewer's today and the next two days, fetched from the viewer's yesterday because TVmaze dates an episode in its own country (east of the US a Friday 21:00 ET episode lands on Saturday); anime covers the next 7 days. Each show keeps its soonest episode still to come, judged by its resolved time, never by a placeholder airstamp (rule 2, D-25). A date-only episode stays through its airdate in the viewer's zone (D-28). Episodes released together keep the lowest season and episode, so a new season keeps episode 1. The 15-show cap applies after filtering. verify: `AiringSoonTests` over the recorded schedules of 30 Oct 2026 (Apple TV placeholder `airtime ""` at 12:00Z, a CBS broadcast, a Peacock date-only episode, a Netflix season drop, a Paramount+ batch of E10–E13) checks resolved times, confidence, order, the date-only day, the tie-break, that a placeholder isn't kept after its real release, and that Auckland asks for the viewer's yesterday.
- [ ] Anime premieres reach the pool: besides the popular airing shows, AniList is asked for this week's episode 1s, so a season that isn't released yet but premieres in the window is included, merged most popular first with no duplicates. A season's opening week has more episode 1s than one page (60 in 1–8 Oct 2026), so up to 3 pages are read. If that request fails, the popular list still shows. (Widening the first query to not-yet-released shows was tried on 1 Nov 2026: it filled 26 of 50 slots with shows months away and found no premieres.) verify: `AniListClientTests` over `releasing-2026-10-31` and `premieres-2026-11-01` checks the premieres are kept, the order, no duplicates, the failure case, and that two loads in the same hour make one pair of requests.
- [ ] Search filters (D-43) narrow that grid, **one at a time** like the TV | Anime switch (Chime, 1 Nov 2026), with **Popular** (no narrowing) as the default. Every filter also drops an episode that has come out since the grid loaded. **Today**: still to come and on the viewer's calendar day in the zone Meridian formats times in (`TimeZone.current`; the Settings override once it exists); a date-only episode counts when its airdate is today. **New seasons**: the kept episode is episode 1 of any season, brand-new shows included. **Exact time known** (TV only): the time would read "Out", not "Expected" (D-40); date-only never counts. **Service** (TV only): one of 12 major platforms, always shown in the same order (D-45): Netflix, Prime Video, HBO Max (also holding HBO's own channel), Disney+, Paramount+, Hulu, Peacock, Apple TV, CBS, NBC, ABC, FOX; a show belongs to one when the name its cell shows (its network, else its web channel) is among that platform's TVmaze names; one with nothing coming says so; no other service gets a chip. The filter keeps the popular-first order and shows at most 15. Changing a filter makes no TVmaze or AniList request. Anime offers Today and New seasons. Each airing cell reads its network over its time in ReleaseWording words ("CBS" / "Out Tue at 03:01", rule 3). verify: `SearchFilterTests` (a pure function over the `AiringSoonTests` pool and an AniList fixture, fixed clock, run in Africa/Lagos, America/New_York and Pacific/Auckland) covers each filter, the service list, the cap, the anime subset and the cell's release line; grep shows the filter type has no client dependency.
- [ ] The filter row sits under the TV | Anime switch and shows whenever the airing-soon grid shows (no query, or under 2 characters), not while it is loading or has failed. Each catalog keeps its own pick for the session, so Anime (Popular, Today or New seasons) never carries Exact time or a service. Each chip tells VoiceOver whether it is selected. A filter with no matches shows one plain line and "Show popular", never a blank grid. Each cell shows its time in `ReleaseWording` words (rule 3). verify: `fidelity/verify-screen.sh search-filtered` prints ALL PASS (a new inventory covering a selected filter and the no-match state, added with Chime's OK); Chime approves a device screenshot.
- [ ] Service chips show the service's logo on a small white tile before its name when the bundled list (`rules/network-logos.json`, freely licensed Wikimedia Commons files matched by exact TVmaze name) has one (D-44). Every one of the 12 platforms has a logo, so the logo chips sit together by construction (D-45). Logos load at runtime and are never committed as images (rule 9); the tile's space is held while it loads, so the row never shifts, and the white tile appears only once its logo has loaded, so one that can't load leaves a gap, never an empty box; Credits names Wikimedia and lists required credits. (The Netflix Top 10 chip was dropped, D-44; a copied chart is forbidden by Netflix's terms, O-13.) verify: `NetworkLogosTests` (lookup by exact name, credits, the bundled file valid: Commons https images, a licence each, no name twice) and `SearchFilterTests.popularServicesOnly`, `everyServiceHasLogo`, `hboOneChip`; every `image` URL in the bundled file returns 200 image/png (curl loop); Chime approves a screenshot of the row with logos.
- [ ] Every poster on the Search tab (search results and the airing grid) opens the show's page when its poster or title is tapped; the poster's (+) still follows in one tap. The page is Night Sky like Upcoming's hero: the show's key art (TVmaze background or AniList banner, else the poster) fading into night, the title, the serif countdown and the next release in `ReleaseWording` words, year · network · status (timed as Upcoming times it: `TimeResolver` with the bundled rules, or AniList's Japanese broadcast), and Follow/Following. With nothing scheduled, or if the request fails, the release line is left out entirely. The airing grid passes the time it already knows, so its page asks nothing. verify: `ShowPreviewTests` (Silo's date-only next episode, a show with nothing scheduled, an airing and a finished anime, a failed request, the key art for TV and anime, a known time not asked again); `fidelity/verify-screen.sh show-preview` (search "Silo", open the first result: art, title, "Out …", meta, Follow) prints ALL PASS; Chime taps through on the phone.
- [ ] Upcoming is sorted by time to drop, with these sections: **Out now** (drop ≤ now < drop + 1 h), **Next 24 hours** (now < drop ≤ now + 24 h), **This week** (up to now + 7 days), **Later**, **Date only**, **Nothing scheduled**. verify: `UpcomingViewModelTests` with a fixed clock and a drop on each side of every boundary.
- [ ] The empty state names the next real date ("Silo returns 9 Jul 2027") or shows "Nothing scheduled for your shows yet. Meridian checks again each time you open it." It never promises a refresh interval. verify: view model tests for both cases; the screenshot passes `fidelity/verify-screen.sh upcoming--empty`.
- [ ] Widgets never count up after the drop: they use `Text(timerInterval:countsDown:)` without `pauseTime` (D-52) and have an "Out now" entry at the drop. verify: grep finds no `.timer` style in `MeridianWidgets/`; `TimelineProviderTests` checks there is an entry at `drop` and at `drop + 1h`.
- [ ] Timeline entries are at least 5 minutes apart and the reload policy is `.after(nextDrop)`. verify: `TimelineProviderTests.spacingAndPolicy` with 6 drops 2 minutes apart.
- [ ] All 5 widget families render in light, dark, tinted/accented and Always-On, with every element and string from `docs/design/UI-BRIEF.md`. verify: widget previews captured as PNGs (simulator screenshot or the Xcode MCP preview tool) to `fidelity/shots/`, `fidelity/verify-screen.sh` prints ALL PASS, and Chime approves them; approved captures become the `fidelity/refs/` baselines that `proof:screen-judge` checks later changes against.
- [ ] Widgets stay correct with no app launch for 24 hours. verify: manual: 1. follow a show with a drop more than 24 h away; 2. lock the phone; 3. don't open Meridian for 24 h; 4. the Lock Screen widget shows the right countdown.
- [ ] (Should) The Settings time-zone override reaches widgets and Live Activities, not just the app. verify: `SnapshotStoreTests` shows that the override is written to the App Group suite; `WidgetFormattingTests` reads it.
- [ ] The app writes the snapshot to the App Group after every follow, unfollow and refresh, then reloads timelines. verify: `SnapshotStoreTests` round trip; manual: follow a show and see the widget update within 5 s in the simulator.
- [ ] Scheduled Live Activities use `request(... start:)` with an `AlertConfiguration`, run only in the foreground, keep at most 3 pending, merge same-night drops (matched by `dropIDs`), and catch `ActivityAuthorizationError`. verify: `ActivitySchedulerTests` using a protocol-wrapped requester fake; manual on device: Debug → fake drop in 3 min.
- [ ] At the drop, the Live Activity shows "Out now" without the app running, because the content's `staleDate` is the drop time and the view renders "Out now" when `context.isStale`. The next time the app becomes active, it ends any activity whose drop was more than 1 h ago. verify: on device: 1. Debug → fake activity in 3 min (lead 1 min); 2. lock the phone; 3. at the drop, the Lock Screen and Dynamic Island show "Out now" within 1 minute. Plus `ActivitySchedulerTests.endsExpired`.
- [ ] When a drop moves, its pending or running activity is ended and a new one is scheduled for the new time. verify: `ActivitySchedulerTests.reschedulesOnDelay`.
- [ ] The Live Activity payload is under 4 KB. verify: unit test encodes the largest realistic attributes and state with `JSONEncoder` and asserts under 2 KB.
- [ ] The compact and minimal Dynamic Island views fit a 28 pt circle when `isDynamicIslandLimitedInWidth` is true. verify: `LiveActivityLayoutTests` renders the minimal view with `ImageRenderer` with the environment value forced and checks it fits 28 × 28 pt.
- [ ] The Lock Screen Live Activity view is no taller than 160 pt. verify: `LiveActivityLayoutTests` renders the view with `ImageRenderer` at a 360 pt width with the longest show name and checks the height is 160 pt or less.
- [ ] A later time for the same episode sets `previousDate` and shows "Delayed". verify: `RefreshServiceTests.delayDetection`.
- [ ] (Should) "Report a wrong time" opens a prefilled email while the repo is private, and a prefilled GitHub issue URL once it's public; both carry show, episode, time shown, source and zone. verify: `ReportURLBuilderTests` decodes the `mailto:` and the issue URL and checks each field in both modes.
- [ ] The app works offline: it shows the last known times with "Updated <time>" and never crashes on a network failure. verify: manual: 1. follow 3 shows; 2. turn on flight mode; 3. relaunch; 4. see the times and the "Updated" label.
- [ ] VoiceOver reads every widget and activity view as a full phrase built from the provider label ("Silo, in 2 days 4 hours, Apple TV"; "House of the Dragon, in 3 hours, HBO US, no official stream in your country"). verify: `AccessibilityLabelTests` on the label builder; manual VoiceOver pass on the device.
- [ ] First run shows one welcome screen with the detected time zone ("Times shown for Lagos, UTC+1"), leads to Search, and prompts the user to add a Lock Screen widget. verify: `OnboardingUITests` with the simulator zone set to Africa/Lagos finds each string.
- [ ] (Should) App screens work at Dynamic Type AX5 with no clipped countdowns, honour Reduce Motion, and never rely on colour alone. verify: simulator screenshots at AX5 for Upcoming, Show detail and Settings pass `verify-screen.sh` (every element visible) and Chime's review; the UI test `AX5LayoutTests` asserts no countdown label is truncated.
- [ ] The Credits screen credits TVmaze (CC BY-SA with a link) and AniList, and says no data is collected. verify: UI test opens Credits and finds both links and the statement.
- [ ] The privacy manifest declares the UserDefaults reasons `CA92.1` and `1C8F.1`, and `PRIVACY.md` states that no data is collected. verify: `plutil -lint` on `PrivacyInfo.xcprivacy` plus a grep for both codes; `PRIVACY.md` exists and is linked from Credits and the README.
- [ ] The accuracy audit shows 20 of 20 real drops from the build week correct, including drops on either side of the 1 Nov 2026 US clock change, in the tester's zone. "Correct" means the shown local day is right **and** the shown time is within 5 minutes of the confirmed release; a `dateOnly` drop is correct if its date is right and it shows no time. No more than 4 of the 20 may be `dateOnly`. verify: `docs/research/accuracy-audit.md` lists 20 rows with the app time, the confirmed time and the source, all matching.
- [ ] The README lets a reader understand the project in 60 seconds: pitch and demo video or GIF at the top, the problem, a Mermaid architecture diagram, the rules table with a sourcing explainer, a CI badge, how to run it, and credits and licences. verify: `scripts/check-readme.sh` greps for each section heading, a ```mermaid block, the badge URL and the video link; Chime reads it on GitHub once it's public.
- [ ] The repo is public with nothing that shouldn't be in it: no secrets, no committed artwork files, the TVmaze fixtures marked CC BY-SA, LICENSE (MIT) present, and AniList's answer recorded. verify: the open-source checklist in `PLAN.md` Day 7 is ticked; `git log -p | grep -iE "api[_-]?key|secret|token"` finds nothing; `gh repo view --json visibility` returns PUBLIC.
- [ ] CI builds and runs the tests on every push to `main`. verify: `gh run list --branch main --limit 1` shows success, and the README badge is green.
- [ ] People understand the Upcoming screen at a glance. verify: on Day 3, a 5-second test with 5 people using a screenshot of the simulator build; at least 4 of 5 answer "when and where" correctly, logged in `docs/research/glance-test.md`.

## Risks and assumptions

- **One week is tight.** The riskiest days are 4 and 5 (widgets and the Live Activity on a real device). Mitigation: a gate every day, the Should column cut first, and Day 7 protected (D-33).
- **Wrong times erode trust.** The rules may be wrong for some titles. Cheapest test: Day 1 fixtures (2 per rule) and the Day 6 audit of 20 drops across the 1 Nov clock change. Mitigation: per-episode overrides in the rules file (D-18).
- **AniList may refuse tracker use.** Cheapest test: the Day 0 email. Fallback: TVmaze anime listings behind the same `CatalogSource` protocol. Its answer must be in before the repo goes public.
- **Free signing might block something on a real device.** App Groups and local Live Activities are listed as available to free accounts, but that's untested here. Cheapest test: Day 0 installs the placeholder on Chime's iPhone and reads App Group data from the widget. Free builds expire after 7 days, so reinstall on Day 6 for the beta.
- **CI minutes on the private repo are limited.** Mitigation: CI runs only on `main` pushes until the repo goes public (D-35).
- **Live Activities may silently fail to schedule** (an unpublished limit, or the user switched them off). Cheapest test: on-device fake drops with 4 pending; check `ActivityAuthorizationInfo().areActivitiesEnabled` and show the state in Settings.
- **Background refresh is not guaranteed.** Assumption: widget timelines carry the countdowns on their own, and refresh happens when the app opens. Test: leave the phone 24 h without opening the app and confirm the widget still counts to the right drop.
- **A portfolio reader may not get the point in 60 seconds.** Mitigation: the README leads with the demo video and the "times you can trust" problem; Chime reads it cold on Day 7.

## Decision log

- 2026-10-26: D-01 to D-16 (name, stack, sources, design direction). See `DECISIONS.md`.
- 2026-10-29: Lead with trustworthy times outside the US (D-17), because Live Activity countdowns are now common. Revisit if interviews show people value something else more.
- 2026-10-29: Remote rules file with overrides (D-18), because release rules have exceptions that change faster than App Review. Revisit if the fetch causes privacy concerns in review.
- 2026-10-29: Anime source gated on AniList's answer (D-19). Revisit when they reply.
- 2026-10-29: Provider label with country (D-20), because HBO has no known legal stream in Nigeria.
- 2026-10-29: No Figma. UI is vibe-coded in SwiftUI from design references and a written UI brief; Chime approves screenshots, which become regression baselines (D-31, supersedes D-21). Chime's call.
- 2026-10-29: Empty-state copy no longer promises a refresh interval (D-27); `dateOnly` stores the airdate (D-28); Drop Day is cut (D-29).
- 2026-10-29: About 7 weeks to the App Store with a 14-day beta (D-23). Superseded the same day by D-32.
- 2026-10-29: Zero spend: free Apple ID signing, no TestFlight, CI on `main` only while private (D-35). Chime's call.
- 2026-10-29: Portfolio project: one week, private beta, private repo made public on Day 7; no App Store (D-32). Week scope in D-33. Rules fetch and GitHub reporting switch on only once the repo is public (D-34). Chime's call.
- 2026-10-31: Search filters (Today, New seasons, Exact time known, Service), with popularity taken from TVmaze and AniList now and Netflix's official Top 10 later (D-43). Chime's call, from three options: free scores, official charts bundled, or a keyed trending service. Revisit if the TVmaze ranking looks wrong to Chime, or a keyless consensus source appears.

## Open questions

- O-1 Crunchyroll per-title offset data source. Owner: Chime.
- O-3 Trademark and domain check for "Meridian". Deferred: only needed for an App Store release.
- O-5 AniList permission, needed before the repo goes public. Owner: Chime, Day 0.
- O-7 Legal HBO source in Nigeria (sets the provider label copy). Owner: Chime, by Day 3.
- O-13 Answered 1 Nov 2026: Nigeria has Top 10 TV rows, but the Top10 terms (help.netflix.com/en/legal/top10-terms-and-conditions) forbid it: "You agree not to archive, download …, reproduce, distribute, modify, … create derivative works from … content and information … obtained from or through the Website without express written permission from Netflix", and ban "robot, spider, scraper or other automated means". So no bundled list. Chime chose a link out to Netflix's own chart (D6-9).

---

# Reference

## 1. Screens

| Screen | Purpose | Key content |
| --- | --- | --- |
| Welcome (one screen) | Explain, then follow the first show | Shows your time zone ("Times shown for Lagos, UTC+1"), a button to follow shows, a prompt to add a widget |
| Search | Find TV (TVmaze) and anime (AniList or TVmaze, D-19) | Segmented TV / Anime; before typing, popular shows airing in the next few days with filters (D-43); each result shows year, network and status; never auto-pick the first result (searching "Euphoria" also returns an Israeli show) |
| Upcoming (home) | Every followed show sorted by time to drop | Big countdown, show name, `S1E4`, local day and time worded by certainty ("Out", "Expected", "Airs in Japan", D-40), provider label (D-20); sections: Out now · Next 24 hours · This week · Later · Date only · Nothing scheduled |
| Show detail | One show | Next drop, the last 3 aired episodes, a Live Activity toggle, an anime offset field, "Report a wrong time", unfollow |
| Settings | Preferences | Time zone override, Live Activity lead time (30 min to 6 h), Live Activities permission state, credits, Debug menu (Debug builds only) |
| Credits | Licences | TVmaze (CC BY-SA, with link), AniList, and a "no data collected" statement |

## 2. Data model

```swift
// Shared/Models
enum Catalog: String, Codable { case tvmaze, anilist }
enum Confidence: String, Codable { case exact, estimated, dateOnly }
enum ReleaseSource: Codable, Hashable {
    case broadcast(network: String)        // TVmaze airtime + network timezone
    case platformRule(String)              // e.g. "Netflix: midnight PT"
    case override(note: String)            // rules-file per-episode override (D-18)
    case anilist                           // AniList airingAt (JP broadcast)
    case adjusted(base: String, offsetMinutes: Int) // user anime offset on any anime path
    case dateOnly
}
struct ProviderLabel: Codable, Hashable { var name: String; var countryCode: String?; var noOfficialStream: Bool }
struct Drop: Codable, Hashable, Identifiable {
    var id: String                // "\(catalog):\(showID):\(episodeID)"
    var showID: String
    var showName: String
    var season: Int?; var number: Int?
    var episodeTitle: String?     // hide in widgets (spoiler-safe)
    var date: Date                // UTC instant; for dateOnly it's only a sort key
    var airdate: String?          // "yyyy-MM-dd" as listed; dateOnly rows are formatted from this, never from `date`
    var confidence: Confidence
    var source: ReleaseSource
    var provider: ProviderLabel?
    var previousDate: Date?       // set when a refresh moved the time
}
struct DropSnapshot: Codable { var generatedAt: Date; var drops: [Drop]; var nextReturn: Drop? }
```

SwiftData (app only): a `FollowedShow` holds `catalog`, `externalID`, `name`, `provider`, `liveActivityEnabled`, `animeOffsetMinutes`, `addedAt`, plus cached `[Drop]` for the next 30 days.

## 3. Time resolution

### 3.1 Order

`TimeResolver.resolve(episode:show:rules:) -> (Date, Confidence, ReleaseSource)`:

0. **Override:** if the rules file has an entry for this episode ID (or, failing that, this show), use it → `exact` if the entry says `confirmed`, otherwise `estimated`; `.override(note)`.
1. **AniList:** `airingAt` + the show's `animeOffsetMinutes` → `exact` if the offset is 0 (labelled "JP broadcast"), otherwise `estimated` (`adjusted`).
   **TVmaze anime fallback (D-19):** a TVmaze show whose network country is JP resolves through step 2 but is worded as a Japanese TV time ("Airs in Japan …"), and the per-show offset applies in the same way.
2. **TVmaze with `airtime != ""`:** trust `airstamp` → `exact`, `broadcast(network)`.
3. **TVmaze with `airtime == ""`:** look up the platform rule by `webChannel.name` or `network.name` → `estimated`. Placeholders are detected **only** by the empty airtime (D-25).
4. Otherwise → `dateOnly` ("Wed 29 Apr · time not announced").

### 3.2 Rules file (`rules/platform-rules.json`, D-18)

```json
{
  "schemaVersion": 1,
  "updated": "2026-10-29",
  "platforms": [
    { "match": ["Netflix"], "zone": "America/Los_Angeles", "time": "00:00", "dayOffset": 0,
      "label": "Netflix rule", "sources": ["https://…", "https://…"] }
  ],
  "overrides": [
    { "episode": "tvmaze:<episodeID>", "instant": "2025-11-27T01:00:00Z", "confirmed": true,
      "note": "Netflix event drop 17:00 PT", "source": "https://…" }
  ],
  "providers": [
    { "match": ["HBO"], "country": "US", "noOfficialStreamIn": ["NG"] }
  ]
}
```

An override is keyed by `episode` (one drop) or by `show` with `zone`, `time` and `dayOffset` (a whole series that breaks its platform's rule, such as a Disney+ Marvel show at 18:00 PT). Episode overrides beat show overrides, and both beat platform rules. Zones are IANA IDs, never fixed offsets. Each platform entry needs 2 sources. The bundled copy is the fallback, and the fetched copy must pass validation.

### 3.3 Platform rules v1 (re-verified 29 Oct 2026)

| Platform (TVmaze name) | Rule | Lagos time (US summer / US winter) |
| --- | --- | --- |
| Netflix | 00:00 America/Los_Angeles on airdate; event drops via overrides (17:00 PT) | 08:00 / 09:00 |
| Prime Video / Amazon | 00:00 America/Los_Angeles on airdate; early premieres via overrides | 08:00 / 09:00 |
| Apple TV | 21:00 America/New_York on airdate − 1 day | 02:00 / 03:00 on airdate |
| Disney+ | No default rule → `dateOnly` (D-36); Marvel live action via show overrides at 18:00 PT | Date only; Marvel 02:00 / 03:00 next day |
| Paramount+ | 03:00 America/New_York on airdate | 08:00 / 09:00 |
| HBO / HBO Max | Has an airtime (21:00 or 22:00 ET), so step 2 applies | 02:00–04:00 next day |
| Peacock, Hulu, anything else | `dateOnly` | — |

**Required tests (Swift Testing):** each rule × {US summer, US winter} × {Africa/Lagos, Europe/London, Asia/Kolkata, Asia/Tokyo, America/New_York, Australia/Sydney}; the US changeovers 8 Mar 2026, 1 Nov 2026 and 14 Mar 2027; the EU changeovers 25 Oct 2026 and 28 Mar 2027 (the weeks when London and New York are 4 hours apart instead of 5); the Sydney changeovers 4 Oct 2026 and 4 Apr 2027; an anime case with a fixed UTC time; placeholder airstamps at 12:00Z, 16:00Z and 17:00Z never `exact`; an override beating a rule; delay detection.

## 4. Networking

| API | Endpoints | Limits | Notes |
| --- | --- | --- | --- |
| TVmaze `https://api.tvmaze.com` | `/search/shows?q=`, `/shows/{id}?embed[]=nextepisode&embed[]=previousepisode`, `/shows/{id}/episodes` | 20 calls / 10 s per IP; HTTP 429 → back off | `_embedded.nextepisode` is missing when there is none. Fields: `airdate, airtime, airstamp, season, number, name`; show `network{name,country{code,timezone}}`, `webChannel{name,country}`, `status` |
| AniList `https://graphql.anilist.co` (POST) | `Page{media(search:, type: ANIME, isAdult:false){id title{romaji english} status nextAiringEpisode{airingAt episode} airingSchedule(notYetAired:true, perPage:10){nodes{airingAt episode}}}}` | **30/min while degraded** (normally 90); 429 with `Retry-After` | Filter `isAdult`; depends on O-5 |
| Rules file (raw GitHub URL of this repo) | `rules/platform-rules.json` | At most once a day | Schema-validated; bundled fallback |

Both API clients are `actor`s with exponential backoff on 429 (honouring `Retry-After`) and a 6-hour on-disk cache. Parsers are built against recorded fixtures in `MeridianTests/Fixtures/`.

## 5. Widgets (`MeridianWidgets`)

| Family | Content |
| --- | --- |
| `accessoryInline` | `Silo · 2d 4h` |
| `accessoryCircular` | Big numeral ("2d" / "4h" / "38m") with a progress ring over the last 7 days |
| `accessoryRectangular` | Show name, countdown, `Wed 02:00 · Apple TV` |
| `systemSmall` | Huge typographic countdown, the show name small, the out line ("Out Sun 21:00", "Expected Mon 09:00") |
| `systemMedium` | The next 3 drops as rows |

- The provider reads `DropSnapshot` from the App Group. Timeline: one entry now, one at each of the next 5 drops (and drop + 1 h for "Out now → next"), all at least 5 minutes apart. Reload policy is `.after(nextDrop)`.
- At the drop time the widget shows "Out now" for 1 hour, then moves to the next drop. A `dateOnly` drop shows "Wed 29 Apr" with no timer.
- Rendering: `.containerBackground(for: .widget)`; `widgetRenderingMode` for accented/tinted; `isLuminanceReduced` for Always-On.

## 6. Live Activity

```swift
struct DropActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable { var phase: Phase; var dropDate: Date; var delayedFrom: Date? }
    enum Phase: String, Codable { case upcoming, outNow }
    var dropIDs: [String]          // one or more merged same-night drops
    var showName: String; var episodeLabel: String; var provider: String?
}
```

- **Staleness:** every content update sets `staleDate: dropDate`; views render "Out now" when `context.isStale`. Activities are ended when the app next becomes active, after drop + 1 h; otherwise the system ends them at its 8-hour limit.
- **Compact leading:** a monogram. **Compact trailing:** a timer. **Minimal:** the timer, fitting 28 pt when `isDynamicIslandLimitedInWidth`. **Expanded:** show name, `S2E5`, big countdown, "Apple TV · 02:00".
- **Lock Screen:** at most 160 pt tall; iOS 27 StandBy scales it 200%. Add `.supplementalActivityFamilies([.small])` for the Watch Smart Stack, Mac menu bar and CarPlay.
- **Scheduling:** `ActivityScheduler` runs when the scene becomes active. For opted-in drops in the next 7 days that aren't `dateOnly`, it calls `Activity.request(attributes:content:pushType:nil, style:.standard, alertConfiguration:..., start: drop − leadTime)`. It keeps at most 3 pending, skips drops that already have one, merges same-night drops, and catches `ActivityAuthorizationError` (D-24).
- **At the drop:** update to `.outNow` if the app is running; otherwise the system marks the content stale at `dropDate` and the view shows "Out now". The countdown uses `Text(timerInterval:countsDown:)`, whose interval stops at 0:00, so it never counts up; no `pauseTime`, which freezes it (D-52). The app ends it after drop + 1 h when it next runs (see Staleness).
- **Alert copy:** "Silo starts in 2 hours · 02:00 · Apple TV" (from `ProviderLabel`, never "on HBO" for a country without HBO).

## 7. Debug menu (Debug builds only)

- "Fake drop in 2 / 10 / 60 minutes" injects a fake followed show and drop and rewrites the snapshot.
- "Schedule Live Activity for fake drop in 3 minutes (lead 1 min)".
- "Dump snapshot JSON", "Simulate delay +1h", "Reload rules file".

## 8. Out of scope for v1

See Non-goals and the Cut column of the scope table in `PLAN.md`.
