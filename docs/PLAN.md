# Meridian: the one-week build

Rewritten 29 Oct 2026. It replaces the 7-week plan, which is archived in `archive/PLAN-7week-2026-10-29.md`. The decisions are D-17 to D-35 in `DECISIONS.md`, and the research is in `RESEARCH.md`.

## What "done" means

This is a **portfolio project**, not an App Store launch (D-32). We build it with AI in one week, stop at a **private beta**, and ship it as an **open-source GitHub repo** that Chime features on their portfolio site. The repo stays **private** while we build and goes **public** on Day 7. **Budget: $0** (D-35).

The finished project is:
1. A working app on Chime's iPhone, signed for free with Chime's Apple ID: Lock Screen countdowns, a scheduled release-night Live Activity, and honest times with a source on every one.
2. A public repo that reads like senior work: a README with a demo video, an architecture diagram, the time-rules story, tests, a CI badge, and a clean commit history.
3. A case study and a 30-second video for the portfolio site.

The selling point stays: **release times you can trust, wherever you are** (D-17). Every competitor has a countdown. None shows where its time came from or how sure it is.

## The week at a glance

| Day | Date | Focus | Gate (must pass before the next day) |
| --- | --- | --- | --- |
| 0 | Thu 29 Oct (tonight) | Setup | Empty app and widget build **on Chime's iPhone**; private repo pushed |
| 1 | Fri 30 Oct | Time engine (tests first) | Zone × DST test matrix green |
| 2 | Sat 31 Oct | UI direction (references → SwiftUI), data clients, Search | References and UI brief done; numeral style picked; Search works |
| 3 | Sun 1 Nov | App screens | Chime approves each screen; glance test 4 of 5 |
| 4 | Mon 2 Nov | Widgets | 5 families count down in the simulator and never count up |
| 5 | Tue 3 Nov | Live Activity and Debug menu | Fake drop works end to end on Chime's iPhone |
| 6 | Wed 4 Nov | Harden and private beta | CI green; accuracy audit 20 of 20; beta build on Chime's iPhone |
| 7 | Thu 5 Nov | Portfolio and open source | Repo public; README, video and case study done |

**Sun 1 Nov is the US clock change.** It falls on Day 3, so we capture real release times on either side of it for the accuracy audit.

## Scope for the week (D-33)

| Must (the demo breaks without it) | Should (if the day has room) | Cut (not this week) |
| --- | --- | --- |
| TimeResolver, PlatformRules, bundled rules file with overrides, and tests | Fetching rules updates from GitHub, switched on once the repo is public (D-34) | App Store listing, privacy label, age rating, name/trademark check |
| TVmaze and AniList clients, Search, follow | Settings time-zone override (great for the demo: "now show it in Tokyo") | `BGAppRefreshTask` (refresh happens when the app opens) |
| Upcoming with release wording (D-40), provider label, empty state | Delay badge (shown through Debug → "Simulate delay") | Multi-card onboarding (one welcome screen instead) |
| Show detail: next drop, Live Activity toggle, anime offset, unfollow | "Report a wrong time" (email while private, GitHub issue once public) | Interviews, competitor teardown, 14-day beta, 100-drop audit |
| 5 widget families with countdowns that never count up | Dynamic Type AX5 pass | Drop Day, importers, calendar, Watch, region data, pricing |
| Scheduled Live Activity and Debug fake drop | `.supplementalActivityFamilies` for the Watch and Mac | |
| Credits, privacy manifest, VoiceOver labels, CI | | Netflix Top 10 chip (dropped, D-44) |
| README, video, case study, open-source checklist | | |

If a day overruns, cut from its Should column first and never from Day 7. The portfolio material *is* the deliverable.

## Zero-cost rules (D-35)

| Thing | Free route | Limit to plan around |
| --- | --- | --- |
| Signing and installing | Free Apple ID (Xcode Personal Team) | Builds expire after **7 days**; reinstall from Xcode. No TestFlight, no App Store. |
| Private beta | Chime's iPhone; a friend's iPhone plugged into Chime's Mac | Few devices per free account; each must be connected to install |
| Widgets, App Group, Live Activities | Work on free signing; no push needed | Proven on Day 0 with the placeholder build |
| GitHub repo | Free private repo, then public | — |
| CI (GitHub Actions) | Runs on `main` pushes only while private | Free private minutes are limited and macOS counts 10×; unlimited once public |
| Data | TVmaze and AniList, both keyless | Rate limits only |
| references | Only the Day 2 query list | references warned AI usage is high this month |
| Video | QuickTime screen recording and iMovie | — |

---

## Day 0: Setup (Thu 29 Oct, tonight, about 1–2 hours)

### Chime does
- [x] `brew install xcodegen`, and check `gh auth status`. (Done by Claude, 29 Oct: XcodeGen 2.46.0; gh signed in as ChimeXXD.)
- [ ] Sign in to Xcode with your Apple ID (Xcode > Settings > Accounts). This creates your free **Personal Team**. Note its Team ID, which Xcode shows there.
- [ ] Turn on **Developer Mode** on your iPhone (Settings > Privacy & Security > Developer Mode), and plug the phone into your Mac.
- [ ] Connect the build tools:
  ```bash
  claude mcp add MobileBuildMCP -- npx -y mobilebuildmcp@latest mcp
  # Xcode > Settings > Intelligence > "Allow external agents to use Xcode tools", then:
  claude mcp add --transport stdio xcode -- xcrun mcpbridge
  ```
- [ ] Choose a bundle prefix (e.g. `dev.chime`) and an App Group (`group.dev.chime.meridian`), and note your Team ID.
- [ ] Send the AniList permission email (O-5). It doesn't block the week, but have the answer before the repo goes public.

### Claude CLI does
- [x] `git init`, `.gitignore`, `LICENSE` (MIT), `git mv "★ Next Episode.md" docs/PRD.md`.
- [x] `project.yml`: the `Meridian`, `MeridianWidgets` and `MeridianTests` targets, the `Shared/` sources, the App Group, `NSSupportsLiveActivities`, and `PrivacyInfo.xcprivacy` (`CA92.1`, `1C8F.1`).
- [ ] A placeholder app screen and `systemSmall` widget. Build and take a simulator screenshot, then **install on Chime's iPhone** with free signing and confirm that the widget can read a value the app wrote to the App Group. That proves the free route works before we build on it.
- [x] `.claude/proof.json` with the build and test checks.
- [x] Create the **private** repo and push: `gh repo create next-episode --private --source=. --remote=origin --push`.
- [x] Create the reference collection `Meridian references`.

**Prompt**
> Day 0 from docs/PLAN.md. Bundle prefix `<dev.chime>`, App Group `<group.dev.chime.meridian>`, Personal Team ID `<XXXX>`. Set up git, project.yml, the privacy manifest and placeholder screens. Build, take a screenshot, install on my iPhone with free signing and prove the App Group works, commit, then create the private GitHub repo and push.

**Gate:** `xcodebuild build` passes, the placeholder widget runs on Chime's iPhone and reads App Group data, and the private repo is on GitHub.

---

## Day 1: Time engine (Fri 30 Oct)

**Goal:** the part that must be right, written tests first. It needs no UI.

### Claude CLI does
- [x] Models in `Shared/Models`: `Drop`, `DropSnapshot`, `Confidence`, `ReleaseSource`, `ProviderLabel`.
- [x] Record fixtures in `MeridianTests/Fixtures/`: 2 real episodes per platform rule, the override examples (Stranger Things 5 at 17:00 PT, the early Fallout S2 premiere), and placeholders at 12:00Z and 16:00Z.
- [x] `rules/platform-rules.json` v1, bundled with the app (SPEC §3.2).
- [x] `PlatformRules` and `TimeResolver`, plus the test matrix: each rule × 6 zones × US summer and winter, the US, EU and Sydney clock-change dates, placeholders never `exact`, overrides beating rules, and anime unaffected by US clock changes.
- [x] `TVmazeClient` actor: backoff that honours `Retry-After`, and a 6-hour cache.
- [x] Commit after each green step.

**Prompt**
> Day 1 from docs/PLAN.md, tests first. Record the fixtures, write rules/platform-rules.json, then implement the models, PlatformRules, TimeResolver and TVmazeClient per SPEC §3. Show me the test matrix output.

**Gate:** all tests pass, and every rule is backed by 2 fixtures.

---

## Day 2: UI direction, clients and Search (Sat 31 Oct)

**Goal:** know what each screen looks like before building it. There is no Figma (D-31). design references go into a written brief, and the brief goes straight into SwiftUI.

### Claude CLI does
- [x] **reference sweep:** (Done 30 Oct as the reference board: 154 references, Chime liked 47, all saved to the collection.) One iOS search per surface, following the `references:search` skill rules. Save the best 3–5 per surface to `Meridian references`, and note the pattern taken from each in `docs/design/REFERENCES.md`. The seed pass is already there.

  | Surface | Query |
  | --- | --- |
  | Upcoming | "upcoming schedule grouped by day with times" |
  | Time-zone honesty | "schedule with my time and local time toggle" (seed: Formula 1) |
  | Search | "search results with year and network to tell apart same-name titles" |
  | Show detail | "TV show detail with next episode and episode list" |
  | Empty state | "schedule with nothing upcoming" |
  | Settings | "settings screen with time zone picker" |
  | Live Activity | "lock screen live activity with countdown timer" (seeds: Apple Fitness, Once, Duolingo) |
  | Widgets | "lock screen widgets countdown", "home screen widget countdown large numeral" |

- [x] **`docs/design/UI-BRIEF.md`:** one section per screen and surface: its job, the design references it borrows from, its elements with test IDs, its copy taken from SPEC, and every state.
- [x] **Style in code:** `Shared/Design/Tokens.swift` (colours for light, dark and tinted; a type scale with tabular numerals), plus `SourceChip`, `CountdownText`, `DropRow`, `ProviderLabelView` and `SectionHeader`, each with a `#Preview`.
- [x] **3 numeral studies** (`docs/design/studies/index.html`) rendered from previews across the widget families and the Lock Screen Live Activity, then shown side by side.
- [x] `AniListClient` behind a `CatalogSource` protocol (30 requests a minute, `isAdult` filtered out). SwiftData `FollowedShow`. The Search screen with TV and Anime tabs and disambiguation. (Done 31 Oct: `AniListClient` and `TVmazeClient` side by side rather than behind one protocol; Search has a TV | Anime switch.)

### Chime does
- [ ] React to the reference board, and **pick a numeral style**.

**Prompt**
> Day 2 from docs/PLAN.md. Run the reference sweep and update REFERENCES.md, write UI-BRIEF.md, build the tokens and components with previews, and show me 3 numeral options. While I choose, build AniListClient, FollowedShow and Search.

**Gate:** every screen has a brief section, Chime has picked a numeral style, and Search finds and follows "Silo" and one airing anime.

---

## Day 3: App screens (Sun 1 Nov, the US clock-change day)

### Claude CLI does
- [x] Set up the `proof:build` fidelity check: `fidelity/inventory/<screen>.json` built from the UI brief, plus `fidelity/verify-screen.sh`. (Done 31 Oct: native, an XCUITest per screen checking IDs and copy; scheme `MeridianFidelity`.)
- [ ] Upcoming (sections, countdown, release wording, provider label, empty state), Show detail, a one-screen welcome showing "Times shown for Lagos, UTC+1" with a widget prompt, Settings (lead time, plus the time-zone override as a Should), and Credits.
- [ ] For each screen: run `verify-screen.sh` until it prints ALL PASS, then show the screenshots next to their design references. Approved screenshots go to `fidelity/refs/` as baselines.
- [ ] Search filters (D-43, added 31 Oct at Chime's request, before widgets): the airing-soon pool with resolved times (D3-8), anime premieres (D3-8b), filter logic (D3-9), a reference board for the filter row (D3-10), then the row in Night Sky (D3-11).

### Chime does
- [ ] Approve or redirect each screen, with one round of notes per screen.
- [ ] Follow 6–8 real shows, and **log the times shown on either side of today's clock change** for the audit.
- [ ] Glance test: show 5 people the Upcoming screenshot for 5 seconds and ask "When is the next episode out where you are, and where can you watch it?" Log the answers in `docs/research/glance-test.md`.

**Gate:** every screen passes `verify-screen.sh` and has Chime's approval, and at least 4 of 5 people pass the glance test.

---

## Day 4: Widgets (Mon 2 Nov)

### Claude CLI does
- [x] `SnapshotStore`: App Group JSON written after every change, then `reloadAllTimelines()`.
- [x] Timeline provider: entries at least 5 minutes apart, "Out now" at the drop, the next drop an hour later, and `.after(nextDrop)`.
- [ ] `accessoryInline`, `accessoryCircular`, `accessoryRectangular`, `systemSmall`, `systemMedium` and `systemLarge` (D-46) in the chosen style, using `Text(timerInterval:countsDown:)` only (no `pauseTime`, D-52), in light, dark, tinted and Always-On.
- [x] VoiceOver labels built from the provider label.

### Chime does
- [x] Add the widgets in the simulator (and on your phone if it's ready) and approve their look. (Approved on the phone, 1 Nov; tinted and Always-On still to check.)

**Gate:** all 5 families render and count down to a fake drop, flip to "Out now", and never count up.

---

## Day 5: Live Activity and Debug menu (Tue 3 Nov)

### Claude CLI does
- [x] `DropActivityAttributes` (with `dropIDs`) and the compact, minimal, expanded and Lock Screen views. The minimal view fits 28 pt when `isDynamicIslandLimitedInWidth`, and the Lock Screen view is 160 pt tall or less.
- [x] `ActivityScheduler`: `request(... start:)` with an `AlertConfiguration` and `staleDate: drop`. At most 3 pending, same-night drops merged, `ActivityAuthorizationError` caught, and expired activities ended when the app opens.
- [ ] Debug menu: fake drop in 2, 10 or 60 minutes; fake Live Activity in 3 minutes; dump the snapshot; simulate a delay.

### Chime does
- [ ] Install on your iPhone. Run Debug → "Live Activity for fake drop in 3 min" with the phone locked, and **screen-record it**. That recording is the raw material for the portfolio video.

**Gate:** on your iPhone, the activity starts at the lead time with an alert, the Dynamic Island counts down, and "Out now" appears at the drop without the app open.

---

## Day 6: Harden and private beta (Wed 4 Nov)

### Claude CLI does
- [x] Refresh when the app opens, with delay detection (`previousDate` and "Delayed from 20:55" in words, D-58) and rescheduling.
- [x] An offline "Updated <time>" label, "Report a wrong time" (email while the repo is private), and `PRIVACY.md`.
- [x] GitHub Actions: build and test by hand (`workflow_dispatch`) while private. Pushes to `main` were left out: the free plan's $12 a month buys about 190 macOS minutes and we push after every commit (checked 2 Nov). No SPM dependencies, so no cache step. On Day 7, widen it to every push and PR.
- [x] **Accuracy audit:** 20 real drops from this week, including Chime's Day 3 clock-change logs, comparing the app's time with each platform's confirmed time. Log them in `docs/research/accuracy-audit.md`.
- [ ] **Private beta:** a fresh install on Chime's iPhone (the 7-day clock restarts), plus any friend's iPhone plugged into Chime's Mac. Testers use it for the rest of the week and report through "Report a wrong time" or a message.

### Chime does
- [ ] Do a 15-minute walkthrough and list up to 10 polish issues. Claude fixes them the same day.

**Prompt**
> Day 6 from docs/PLAN.md. Build refresh with delay detection, the offline label, Report a wrong time and PRIVACY.md, add GitHub Actions (main-only while private), run the 20-drop accuracy audit, and prepare the beta build. Install the beta build on my iPhone. Then fix my polish list: <paste>.

**Gate:** CI is green, the audit shows 20 of 20 correct, the polish list is closed, and the beta build is on Chime's iPhone.

---

## Day 7: Portfolio and open source (Thu 5 Nov)

### Claude CLI does
- [x] **README** written for a recruiter or engineer who gives it 60 seconds:
  - the one-line pitch and the demo video or GIF at the top
  - the problem: "release times are tied to US zones; placeholders lie"
  - how it works: a Mermaid architecture diagram (app → JSON snapshot in the App Group → widgets and Live Activity)
  - the time-rules table and a "how every time is sourced" explainer
  - the test count, the CI badge, how to run it (with a free Apple ID: set your own bundle prefix and App Group), credits and licences
- [x] **Case study** draft for the portfolio site, in `docs/CASE-STUDY.md`: the problem, the research (TV Time's closure, the placeholder discovery, the clock-change matrix), design decisions with design references, the engineering, the accuracy audit result, and what's next.
- [x] **Open-source checklist:**
  - no secrets in the history (`git log -p` grep, and GitHub secret scanning once public)
  - no artwork files committed (art is fetched at runtime, D-37)
  - the TVmaze fixtures noted as CC BY-SA in `MeridianTests/Fixtures/README.md`
  - AniList's answer recorded (O-5)
  - LICENSE and credits present
  - personal device IDs removed
- [x] Switch on the remote rules fetch and the GitHub-issue reporting now that the repo will be public (D-34), and widen CI to every push and PR (D-35). Before switching on, persist `RulesStore`'s last good copy and next-attempt time to Caches, so cold launches and offline launches keep the newest valid rules (Day 1 review item 6).
- [x] Tag `v0.1.0`. **Make the repo public:** `gh repo edit --visibility public --accept-visibility-change-consequences`. Add topics and a description.

### Chime does
- [ ] Edit the 30-second video: Lock Screen countdown → Live Activity start → Dynamic Island → "Out now". Use the Debug fake drop recording.
- [ ] Put the case study and video on the portfolio site, linking to the repo.

**Gate:** the repo is public, the README renders with the video and diagram, CI is green on `main`, the case study is on the portfolio site, and the open-source checklist is all ticked.

---

## After the week (only if you want to)

The 7-week plan in `archive/` still holds the path to an App Store release. Good next steps for the repo, in order:
1. The March 2027 clock-change regression check (US 14 Mar, EU 28 Mar).
2. Region-aware "where to watch" through TMDB.
3. StandBy and the `systemExtraLargePortrait` widget.
4. The App Store, if the project ever earns the $99/yr.

## How we know it worked

| Measure | Target | Evidence |
| --- | --- | --- |
| Correct times | 20 of 20 audited drops | `docs/research/accuracy-audit.md` |
| Understood at a glance | At least 4 of 5 people | `docs/research/glance-test.md` |
| Tests | The full time matrix green in CI | CI badge on the README |
| Demo | Fake drop works end to end on device | The video |
| Portfolio-ready | Public repo, README, case study, video | The links on Chime's site |
