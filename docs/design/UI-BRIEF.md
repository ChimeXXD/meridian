# UI brief

How each Airstamp screen and surface looks and behaves. There is no Figma (D-31): this brief, `REFERENCES.md` (Chime's 47 reference picks, numbered `#n`) and `SITEMAP.md` go straight into SwiftUI. Chime approves each screen from simulator screenshots, and the approved shots become the `fidelity/refs/` baselines.

Written 30 Oct 2026 from Chime's picks. Copy marked **SPEC** is quoted from `docs/SPEC.md` and must match it. Copy marked *new* is proposed here and can change at screen review.

## 1. Direction

What the 47 picks have in common, and the rules that follow from it.

1. **Type does the work.** There's no poster art (D-13), so the time is the picture: a relative day over a huge local time, then where to watch (#62 Fixtured, #94 Posh, #7 Numo).
2. **Relative first, absolute second.** "in 2 h 10 min" leads and "Fri 02:00" follows (#130 Transit, #139 Lumy, #62 Fixtured).
3. **Bright number, dim unit.** In "2d 4h" the digits are full-strength and the units are smaller and dimmer (#117 one year, #135 Waymo, #33 Any Distance). Digits are always tabular, so a ticking timer never jitters.
4. **Status lives in small chips: a glyph plus a word** (#31 WHOOP, #33 Any Distance, #43 Qantas). Colour is a second signal, never the only one (SPEC accessibility criterion).
5. **Headers carry the date so rows stay short.** Section headers have a small count (#1 Brink), and day headers combine date, relative word and weekday (#6 Todoist, #14 MLS).
6. **Quiet honesty.** Freshness is a muted footer line ("Updated 3 h ago", #43 Qantas). A moved time keeps the old one struck through (#43). "No official stream in your country" replaces the provider line without hiding the show (#53 Grab).
7. **Surfaces outside the app are dark and spare** (#126 Once, #139 Lumy, #140 Moonlitt). The app follows the system light or dark setting.

Taken as counterexamples, not patterns: #24 Paramount+ (US-only times) and #64 Posh (times in the source zone). They go in the case study as the problem Airstamp solves.

## 2. Tokens (`Shared/Design/Tokens.swift`)

- **Neutrals are system colours** (`label`, `secondaryLabel`, `tertiaryLabel`, grouped backgrounds), so light, dark and Increase Contrast work without custom values.
- **Status tints have fixed meanings** and always sit next to a word:

  | Meaning | Tint | Used by |
  | --- | --- | --- |
  | Exact time | green | `Broadcast`, `Confirmed` chips |
  | Estimated by a rule | blue | `<Platform> rule`, `JP broadcast` chips |
  | Adjusted | purple | `Adjusted` chip (unconfirmed override or anime offset) |
  | No time yet | grey | `Date only` chip |
  | Delayed | orange | "Delayed" pill, struck-through old time |
  | Not in your country | red | "No official stream in your country" |

- **One accent**, set by the chosen numeral study (§3). It is used for the countdown tint in the Dynamic Island and for controls, never for status.
- **Spacing:** 4 · 8 · 12 · 16 · 24 · 32 pt. **Radius:** chip = capsule, row card 14 pt, sheet 20 pt.
- **Type:** text styles so Dynamic Type works (SPEC AX5 criterion). The numeral face comes from the chosen study. Everything else is SF Pro.
- **Motion:** system defaults only, with no custom animations. Reduce Motion needs no extra work.

## 3. Numeral studies (Chime picks one)

Rendered by `NumeralStudyRenderTests` into `docs/design/numeral-studies/` for every widget family, the Lock Screen Live Activity and the Upcoming hero.

| Study | Numerals | Accent | From the picks |
| --- | --- | --- | --- |
| **A · System** | SF Pro Heavy, tabular | None: white on dark, black on light | #117 one year, #135 Waymo, #62 Fixtured |
| **B · Mono** | SF Mono Medium | Lime | #33 Any Distance, #117 one year |
| **C · Serif** | New York Semibold, tabular | Warm yellow | #126 Once, #149 Tiimo, #75 Fable |

Once Chime picks one, `Tokens.numeral` is fixed to it and the other two are deleted.

## 4. Shared components (`Shared/Design/`)

| Component | Job | Test IDs |
| --- | --- | --- |
| `SourceChip` | Glyph + word for a `ReleaseSource` and `Confidence`: `Broadcast`, `Netflix rule`, `Confirmed`, `Adjusted`, `JP broadcast`, `Date only` (**SPEC**). Override shows `Confirmed` when exact, otherwise `Adjusted`. | `source-chip` |
| `CountdownText` | Over 24 h: static "2d 4h". Within 24 h: a ticking `Text(timerInterval:pauseTime:countsDown:)` (CLAUDE.md rule 4). After the drop: "Out now". `dateOnly`: no timer. Units dim (§1.3). | `countdown` |
| `ProviderLabelView` | "HBO · US" (D-20), or "No official stream in your country" (**SPEC**) in red with a glyph | `provider-label` |
| `SectionHeader` | Title plus a small count, e.g. "Next 24 hours" over "2 shows" (#1 Brink) | `section-header-<id>` |
| `DropRow` | One drop: show name, `S2E5`, local day and time, countdown, source chip, provider label; "Delayed" pill with the old time struck through (#43) | `drop-row-<n>` with children `drop-row-<n>-title`, `-episode`, `-time` |

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
  - nothing scheduled: "Nothing scheduled for your shows yet. Airstamp checks again each time you open it." (**SPEC**), or the next real date, "Silo returns 9 Jul 2027" (**SPEC**)
  - offline: last known times plus "Offline · Updated 3 h ago" (*new*)
  - delayed row; no-stream row; `dateOnly` row ("Wed 29 Apr", "time not announced", **SPEC**); long show name (wraps to 2 lines, the countdown is never truncated)

### 5.3 Search

- **Job:** find and follow the right show; never auto-select (SPEC).
- **Borrows:** #80 Hypelist (media switch above the field); #83 Apple TV (dense rows, dot-separated metadata); #84 Shelf (trailing (+) to follow); #87 PlayStation (the typed query in bold inside titles).
- **Elements:** `search-kind` TV / Anime; `search-field`; `search-result-<n>` with `-title` and `-meta` "2019 · HBO · Running" (year, network, status, **SPEC**); `search-result-<n>-follow`.
- **States:** empty field; typing; results; no results; network error; already followed (the (+) becomes a check).

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

- **Borrows:** #96 Life Reset ("System: …" / "Airstamp will use: …" summary for the zone override); #103 Lumy (radio list for lead time); #111 Pillow (credits grouped under the licence name); #56 Ultrahuman (status and last-sync pairs).
- **Elements:** `settings-zone` with summary; `settings-lead` 30 min, 1 h, 2 h (default), 3 h, 4 h, 6 h (**SPEC** range), each with the local start time; `settings-la-permission`; `settings-credits`; `settings-privacy`; `settings-debug` (Debug builds only).
- **Credits:** TVmaze (CC BY-SA 4.0, with a link) and AniList, and that no data is collected (**SPEC**).

## 6. Surfaces outside the app

### 6.1 Widgets

All copy is from SPEC §5. Every view has the full-phrase `accessibilityLabel` (CLAUDE.md).

| Family | Content | Borrows |
| --- | --- | --- |
| `accessoryInline` | `Silo · 2d 4h` | — |
| `accessoryCircular` | Big "2d" / "4h" / "38m" with a 7-day ring | #135 Waymo (big number, small unit) |
| `accessoryRectangular` | Show name, countdown, `Wed 02:00 · Apple TV` | #128 Apple Sports (dot-separated line) |
| `systemSmall` | Huge countdown, the show name small, the source chip | #117 one year (bright number, dim unit) |
| `systemMedium` | The next 3 drops as rows; the first row has an "UP NEXT" label | #119 Speak ("UP NEXT") |

- **States:** counting down; Out now (1 hour); `dateOnly` ("Wed 29 Apr", no timer); nothing followed; light, dark, tinted/accented and Always-On (SPEC).

### 6.2 Live Activity

All copy is from SPEC §6.

- **Lock Screen** (at most 160 pt): a breadcrumb `Silo · S2 E5 · Apple TV` (#128 Apple Sports), then the relative countdown big and the absolute time below, "in 2 h 10 min" then "Fri 02:00" (#130 Transit). A header band flips to "Out now" without moving the numbers (#146 Strava).
- **Compact:** leading monogram, trailing tinted timer (#132 Flighty). **Minimal:** the timer, fitting 28 pt (SPEC). Coarse values use big number, small unit (#135 Waymo).
- **Expanded:** title top-left, accent "in 2:57:30" top-right (#140 Moonlitt), caption "Out in" over the value (#141 Tide Guide), "Apple TV · 02:00" (**SPEC**).
- **Before the window opens:** the date and time centred, not a timer (#145 NFL).
- **Alert:** "Silo starts in 2 hours · 02:00 · Apple TV" (**SPEC**).
