# UI brief

How each Meridian screen and surface looks and behaves. Chime designed the first version by hand in Figma (D-65); from it, this brief, `REFERENCES.md` (Chime's 47 reference picks, numbered `#n`) and `SITEMAP.md` go into SwiftUI. Chime approves each screen from simulator screenshots, and the approved shots become the `fidelity/refs/` baselines.

> **Being redone (D-37).** Chime rejected the type-only look and the numeral studies, and the app now shows show artwork. The visual direction (§1–3) is re-chosen from the style board (`docs/design/style-board/`). The screen inventory, test IDs, copy and states (§4–6) still stand.

Written 30 Oct 2026 from Chime's picks. Copy marked **SPEC** is quoted from `docs/SPEC.md` and must match it. Copy marked *new* is proposed here and can change at screen review.

## 1. Direction

What the 47 picks have in common, and the rules that follow from it.

1. **Type does the work.** There's no poster art (D-13), so the time is the picture: a relative day over a huge local time, then where to watch (#62 Fixtured, #94 Posh, #7 Numo).
2. **Relative first, absolute second.** "in 2 h 10 min" leads and "Fri 02:00" follows (#130 Transit, #139 Lumy, #62 Fixtured).
3. **Bright number, dim unit.** In "2d 4h" the digits are full-strength and the units are smaller and dimmer (#117 one year, #135 Waymo, #33 Any Distance). Digits are always tabular, so a ticking timer never jitters.
4. **Status lives in small chips: a glyph plus a word** (#31 WHOOP, #33 Any Distance, #43 Qantas). Colour is a second signal, never the only one (SPEC accessibility criterion).
5. **Headers carry the date so rows stay short.** Section headers have a small count (#1 Brink), and day headers combine date, relative word and weekday (#6 Todoist, #14 MLS).
6. **Quiet honesty.** Freshness is a muted footer line ("Updated 3 h ago", #43 Qantas). A moved time keeps the old one struck through (#43). "No official stream in your country" is added under the provider ("HBO · US" stays) without hiding the show (#53 Grab).
7. **Surfaces outside the app are dark and spare** (#126 Once, #139 Lumy, #140 Moonlitt). The app follows the system light or dark setting.

Taken as counterexamples, not patterns: #24 Paramount+ (US-only times) and #64 Posh (times in the source zone). They go in the case study as the problem Meridian solves.

## 2. Tokens (`Shared/Design/Tokens.swift`)

- **Light-mode inks are darkened** until they pass WCAG AA as text on the background, the card and their own chip fill (`TokenContrastTests`).
- **Neutrals are system colours** (`label`, `secondaryLabel`, `tertiaryLabel`, grouped backgrounds), so light, dark and Increase Contrast work without custom values.
- **Status tints have fixed meanings** and always sit next to a word:

  | Meaning | Tint | Used by |
  | --- | --- | --- |
  | Exact time | green | `Broadcast`, `Confirmed`, `JP broadcast` chips |
  | Estimated by a rule | blue | `<Platform> rule` chip |
  | Adjusted | purple | `Adjusted` chip (unconfirmed override or anime offset) |
  | No time yet | grey | `Date only` chip |
  | Delayed | orange | "Delayed" pill, struck-through old time |
  | Not in your country | red | "No official stream in your country" |

- **Tinted and accented widgets:** status inks fall back to primary, and the countdown is the one `widgetAccentable` element. Glyphs and words keep the meaning.
- **One accent**, set by the chosen numeral study (§3). It is used for the countdown tint in the Dynamic Island and for controls, never for status.
- **Spacing:** 4 · 8 · 12 · 16 · 24 · 32 pt. **Radius:** chip = capsule, row card 14 pt, sheet 20 pt.
- **Type:** text styles so Dynamic Type works (SPEC AX5 criterion). The numeral face comes from the chosen study. Everything else is SF Pro.
- **Motion:** system defaults only, with no custom animations. Reduce Motion needs no extra work.

## 3. Numeral studies (Chime picks one)

Rendered by `NumeralStudyRenderTests` into `docs/design/studies/` (compare them in `index.html`) for every widget family, the Lock Screen Live Activity and the Upcoming hero.

| Study | Numerals | Accent | From the picks |
| --- | --- | --- | --- |
| **A · System** | SF Pro Heavy, tabular | None: white on dark, black on light | #117 one year, #135 Waymo, #62 Fixtured |
| **B · Mono** | SF Mono Medium | Lime | #33 Any Distance, #117 one year |
| **C · Serif** | New York Semibold, tabular | Warm yellow | #126 Once, #149 Tiimo, #75 Fable |

Once Chime picks one, `EnvironmentValues.numeralStudy` defaults to it and the other two are deleted, with the study board.

## 4. Shared components (`Shared/Design/`)

| Component | Job | Test IDs |
| --- | --- | --- |
| `SourceChip` | Glyph + word for a `ReleaseSource` and `Confidence`: `Broadcast`, `Netflix rule`, `Confirmed`, `Adjusted`, `JP broadcast`, `Date only` (**SPEC**). Override shows `Confirmed` when exact, otherwise `Adjusted`. | `source-chip` |
| `CountdownText` | Only the last day ticks (D-56): over 24 h a still "2d 4h" (whole days and hours, rounded down, units small and dim), within 24 h a ticking `Text(timerInterval:countsDown:)` with no `pauseTime` (CLAUDE.md rule 4, D-52). After the drop: "Out now". `dateOnly`: no timer. Units dim (§1.3). | `countdown` |
| `ProviderLabelView` | "HBO · US" (D-20); when the rules file says so, "No official stream in your country" (**SPEC**) under it in the no-stream ink with a glyph | `provider-label` |
| `SectionHeader` | Title plus a small count, e.g. "Next 24 hours" over "2 shows" (#1 Brink) | `section-header-<id>` |
| `DropRow` | One drop: show name, `S2E5`, local day and time, countdown, source chip, provider label; "Delayed" pill with the old time struck through (#43) | `drop-row-<n>` with children `drop-row-<n>-title` and `drop-row-<n>-time` ("S2E5 · Tomorrow 02:00") |

## 5. Screens

Navigation is still O-11 (`SITEMAP.md`). This brief assumes the proposed tab bar: Upcoming, Settings and a Search tab.

### 5.1 Welcome (first run only)

- **Job:** show the detected zone, then get the first show followed (SPEC core flow 1). One screen, no carousel (SPEC non-goal).
- **Borrows:** #94 Posh (almost all type, one line, two buttons); #91 Rocket Money (a widget preview with a one-line caption); #88 Moonlitt and #114 Cal AI (steps for adding a widget, Home Screen / Lock Screen switch).
- **Elements:** `welcome-zone` "Times shown for Lagos, UTC+1" (**SPEC**); `welcome-find` "Find a show"; `welcome-later` "Not now"; `welcome-widget-preview`.
- **States:** default; any other zone ("Times shown for London, UTC+0"); widget prompt after the first follow, shown as a sheet with `widget-steps-1…3`.

### 5.2 Upcoming (home)

- **Job:** "how long, when, where" for everything followed (SPEC Upcoming criteria).
- **Borrows:** #62 Fixtured for the hero (no hero was picked, so this stands in); #1 Brink for headers with counts; #6 Todoist for day sub-headers in This week ("Thu 5 Nov · Tomorrow"); #14 MLS for the provider as the last line; #28 Apple Invites for the empty card; #43 Qantas for the footer.
- **Elements:**
  - `upcoming-zone` "Times in Lagos (WAT, UTC+1)" with `upcoming-updated` "Updated 3 h ago" (*new*)
  - `upcoming-hero`: relative day, huge local time, countdown, source chip, provider label
  - sections in this order (**SPEC**): `section-header-out-now` "Out now", `-next-24` "Next 24 hours", `-this-week` "This week", `-later` "Later", `-date-only` "Date only", `-nothing` "Nothing scheduled"
  - rows `drop-row-1…n`
- **States:**
  - no shows: card with `upcoming-empty-follow` "Follow a show to see its countdown here" (*new*) and "Find a show"
  - nothing scheduled: "Nothing scheduled for your shows yet. Meridian checks again each time you open it." (**SPEC**), or the next real date, "Silo returns 9 Jul 2027" (**SPEC**)
  - offline: last known times plus "Offline · Updated 3 h ago" (*new*)
  - delayed row; no-stream row; `dateOnly` row ("Wed 29 Apr", "time not announced", **SPEC**); long show name (wraps to 2 lines, the countdown is never truncated)

### 5.3 Search

- **Job:** find and follow the right show; never auto-select (SPEC).
- **Borrows:** #80 Hypelist (media switch above the field); #83 Apple TV (dense rows, dot-separated metadata); #84 Shelf (trailing (+) to follow); #87 PlayStation (the typed query in bold inside titles).
- **Elements:** `search-kind` TV / Anime; `search-field`; `search-result-<n>` with `-title` and `-meta` showing year, network and status (**SPEC**), e.g. "2019 · HBO · Running"; `search-result-<n>-follow`.
- **States:** empty field; typing; results; no results; network error; already followed (the (+) becomes a check).
- **Show page (Chime, 1 Nov 2026):** tapping any poster or its title on the Search tab (results or the airing grid) pushes the show's page; the poster's (+) still follows in one tap. The page is Night Sky like Upcoming's hero and Show detail (Chime: "similar to the way we designed the upcoming screen"): `show-preview-art` (the key art, TVmaze background or AniList banner, else the poster, fading into the night base, 500 pt, with the glass back button), then Upcoming's `ReleaseHeadline` (`show-preview-title` serif, the giant serif countdown, `show-preview-out` "Out Fri 9 Jul 2027, time not announced"; with **nothing scheduled, only the title**), `show-preview-meta` ("2023 · Apple TV · Running"), `show-preview-follow` (white "Follow" → dark "Following" with a check). Screen check: `show-preview`.
- **Filters before typing (D-43, Chime 1 Nov 2026: "switch between the options… like the filter that lets you pick between TV and anime"):** `search-filters`, a row of chips under the TV / Anime switch, one picked at a time, running to the screen's edges. TV: `search-filter-popular` "Popular" (default), `search-filter-today` "Today", `search-filter-new-seasons` "New seasons", `search-filter-exact-time` "Exact time", then the 12 major platforms, always and in this order (D-45): Netflix, Prime Video, HBO Max, Disney+, Paramount+, Hulu, Peacock, Apple TV, CBS, NBC, ABC, FOX (`search-filter-service-<name>`). No YouTube, BBC iPlayer or small channels. A service with a known logo shows it on a 30 × 22 pt white rounded tile before its name (hidden from VoiceOver, since the name says it; its space is held while loading, so the row never shifts; a logo that can't load leaves a gap, never a white box). The row scrolls to keep the picked chip in view. No Netflix Top 10 chip (dropped, D-44). Anime: Popular, Today, New seasons. Picked chip: white with black text; others dark with a hairline, like the follow button. Header stays "Airing in the next few days" / "Airing in Japan this week". Each `airing-<n>-meta` reads the network over its time in `ReleaseWording` words ("CBS" / "Out Tue at 03:01"), so Today and Exact time show why a show is there. No match: `search-filter-empty` "Nothing left to air today." / "No new seasons in the next few days." / "No confirmed times in the next few days." / "Nothing on Netflix in the next few days." (anime: "this week"), with `search-filter-clear` "Show popular". Screen checks: `search-filtered`, `search-filter-empty`.

### 5.4 Show detail

- **Job:** everything about one show.
- **Borrows:** #75 Fable (title with the network beneath, full-width primary button); #62 Fixtured (next-episode block); #72 Fable and #73 IMDb (date-first episode rows; year range by the title); #76 NFL (confirmation when the Live Activity switch is on); #79 Substack (the report form's disclosure line).
- **Elements:** `detail-title`, `detail-network`; `detail-next` (relative day, local time, countdown, source chip, provider label); `detail-broadcast` "Broadcast 21:00 ET · Mon" (*new*); `detail-episode-1…3`; `detail-live-activity` switch; `detail-offset` (anime only); `detail-report` "Report a wrong time" (**SPEC**); `detail-unfollow`.
- **States:** exact; estimated; `dateOnly`; delayed; no upcoming episode; Live Activities denied (switch off, with a link to Settings); anime with an offset.

### 5.5 Sheets

- **About this time** (#30 Airbuds rule sentence, #31 WHOOP): the source chip, one sentence on where the time came from (for a rule: "Netflix releases at 00:00 Pacific", *new*), and the broadcast time. `about-source`, `about-explainer`, `about-broadcast`.
- **Report a wrong time** (#79 Substack): Wrong time / Wrong date / Wrong platform, an optional note, and what will be sent (show, episode, time shown, source and zone, **SPEC**). `report-kind`, `report-note`, `report-send`.
- **Unfollow:** "Stop following Silo?" (*new*), the only destructive action.

### 5.6 Settings

- **Job:** preferences and information: the zone override, the Live Activity lead time and permission, credits, privacy.
- **Borrows:** #96 Life Reset ("System: …" / "Meridian will use: …" summary for the zone override); #103 Lumy (radio list for lead time); #56 Ultrahuman (status and last-sync pairs).
- **Elements:** `settings-zone` with summary; `settings-lead` 30 min, 1 h, 2 h (default), 3 h, 4 h, 6 h, each with the local start time; `settings-la-permission`; `settings-credits`; `settings-privacy`; `settings-debug` (Debug builds only).
- **Copy:** *new*: "Time zone", "Automatic", "System: Lagos (WAT)" / "Meridian will use: London (GMT)", "Live Activity lead time", "Starts at 00:00 for a 02:00 drop", "Live Activities: Allowed" / "Off in iOS Settings", "Credits & licences", "Privacy". The lead-time range, 30 min to 6 h, is from SPEC.
- **States:** automatic zone; overridden zone (the summary names both); Live Activities allowed; denied (with a link to iOS Settings); Debug build (Debug row shown); release build (hidden).

### 5.7 Credits

- **Job:** credit the data sources and licences, and say that no data is collected (SPEC).
- **Borrows:** #111 Pillow (credits grouped under the licence name, then the works).
- **Elements:** `credits-tvmaze` with `credits-tvmaze-link`; `credits-anilist`; `credits-licence` (MIT); `credits-no-data`; `credits-privacy` linking `PRIVACY.md`.
- **Copy:** *new*, written to SPEC's content list (TVmaze CC BY-SA with a link, AniList, no data collected): "Show and episode data from TVmaze, licensed under CC BY-SA 4.0", "Anime schedules from AniList", "Meridian is open source under the MIT licence", "Meridian collects no data. Nothing leaves your phone except requests to TVmaze and AniList."
- **States:** default; long licence text at AX5 (scrolls, nothing clipped); link tapped (opens Safari).

## 6. Surfaces outside the app

### 6.1 Widgets

- **Job:** answer "how long, and where is it on" from the Lock Screen and Home Screen without opening the app (SPEC Goal).
- **Borrows:** Chime's picks from 1 Nov (D-46): Apple TV (medium, large), Tripsy (small), Udemy (Lock Screen). Earlier: #135 Waymo, #117 one year, and #114 Cal AI for the in-context preview on Welcome.

| Family | Content | Test IDs | Borrows | States |
| --- | --- | --- | --- | --- |
| `accessoryInline` | `Silo · 2d 4h` (**SPEC**). The system draws it in its own font. | `widget-inline` | — | counting down; Out now ("Silo · Out now", *new*); `dateOnly` ("Silo · Wed 29 Apr"); nothing followed ("Follow a show", *new*) |
| `accessoryCircular` | An open ring that fills over the last 7 days, a TV glyph inside, "2d" / "4h" / "38m" in the gap at the bottom | `widget-circular-value`, `widget-circular-ring` | Udemy (open ring, value in the gap); #135 Waymo (big number, small unit) | counting down; Out now (full ring, "Out"); `dateOnly` (calendar glyph and day number, no ring); nothing followed (empty ring) |
| `accessoryRectangular` | Top line "Out Wed 02:00" / "Expected Mon 09:00" with a TV glyph; the show name; the countdown with the provider beside it | `widget-rect-meta`, `widget-rect-title`, `widget-rect-countdown`, `widget-rect-provider` | Udemy (glyph and status first) | counting down; Out now ("Released Mon 18:40", "Out now"); `dateOnly` ("Time not announced", the day in the countdown's place); no official stream (keeps "HBO · US") |
| `systemSmall` | The provider tagged top-left over clear art; the name, a big countdown and the out line bottom-left | `widget-small-provider`, `widget-small-title`, `widget-small-countdown`, `widget-small-out` | Tripsy (text bottom-left, art on top); #117 one year (bright number, dim unit) | counting down; Out now; `dateOnly`; nothing followed |
| `systemMedium` | The next show leads over its fading art (name, out line, big countdown); the next two as one-line rows, each with a small poster and its certainty words; "+N more this week" top-right when more are due (D-47); spare rows show followed shows with "Nothing scheduled" (D-48) | `widget-medium-row-1`…`-3`, `widget-more`, `widget-medium-empty` | Apple TV (hero over fading art, smaller rows) | 1, 2 or 3 drops; more than fit; some with nothing scheduled; none scheduled ("Nothing scheduled" and the list); nothing followed |
| `systemLarge` | Art over the top 62% with the provider tag; the name, a big countdown and the out line over the fade; the next three as rows with small posters; "+N more this week" top-right (D-46, D-47); spare rows show followed shows with "Nothing scheduled" and why (D-48) | `widget-large-row-1`…`-4`, `widget-more`, `widget-large-empty` | Apple TV (large) | 1 to 4 drops; more than fit; some with nothing scheduled; none scheduled; nothing followed |

- **States:** in every family, counting down; Out now for 1 hour; a `dateOnly` drop shows "Wed 29 Apr" with no timer (**SPEC**); nothing followed.
- **Rendering modes in every family:** light, dark, tinted/accented and Always-On (SPEC §5). In tinted or accented mode the status inks fall back to primary and secondary, the countdown is the accentable element, and the chip keeps its glyph and word, so no meaning is lost (`SourceChip`, `ProviderLabelView`). Always-On dims everything and keeps the countdown.
- **Accessibility:** every view has the full-phrase `accessibilityLabel` (CLAUDE.md), e.g. "House of the Dragon, in 3 hours, HBO US, no official stream in your country" (SPEC).

### 6.2 Live Activity

- **Job:** count down on release night on the Lock Screen and in the Dynamic Island, then show "Out now" without the app running (SPEC core flow 4).
- **Borrows:** #128 Apple Sports (breadcrumb), #130 Transit (relative first, absolute second), #146 Strava (header band for the state change), #132 Flighty (compact), #135 Waymo (big number, small unit), #140 Moonlitt and #141 Tide Guide (expanded), #145 NFL (before the countdown).
- **Elements:**
  - **Rebuilt on Chime's picks (D-50):** Duolingo (Lock Screen), Instagram (compact), Yazio (minimal), Tinder (expanded).
  - Lock Screen (at most 160 pt, near-black, the show's key art on the right edge fading leftwards): `la-title` (serif) over `la-details` "S2E5 · Apple TV · US"; `la-countdown`, which a gold "Out now" replaces at the drop; `la-time`, the absolute local time ("Expected Fri 02:00"); `la-more` "+ 1 more" when merged; `la-previous`, a moved time struck through.
  - Compact: `la-compact-poster`, a small rounded poster (the initial on a dark disc without one) leading; `la-compact-timer` trailing. Minimal: `la-minimal`, the poster in a circle inside a ring that fills from the activity's start to the drop, fitting 28 pt (SPEC).
  - Expanded (D-57): `la-expanded-title` (show name, then `S2E5 · Apple TV`), `la-expanded-art` top-right, then one line laid out like Upcoming's rows: `la-expanded-time`, the time in words ("Expected Wed 23:00", by weekday so it never goes stale), with `la-expanded-countdown` at 24 pt beside it on its baseline, and `la-expanded-moved` ("Delayed from 22:00") under the words when the time moved. At the drop a gold "Out now" takes the numbers' place. No progress bar.
  - Alert: "Silo starts in 2 hours · 02:00 · Apple TV" (**SPEC**).
- **States:** before the window opens (the date and time centred, no timer, #145 NFL); counting down; "Out now" (**SPEC**) once the content is stale at the drop, in the numbers' place on the Lock Screen and in the island (the small family keeps 0:00 under it); merged same-night drops ("Silo + 1 more", *new*); delayed (old time struck through); ended an hour after the drop.
