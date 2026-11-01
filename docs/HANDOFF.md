# Handoff: read this first when you pick the project back up

Written 1 Nov 2026 (early hours, Lagos) at the end of the third long session with Chime, who continues tomorrow. It summarises the session so a new one can carry on without it. Then read, in order: `CLAUDE.md`, `docs/PLAN.md`, `PROGRESS.md` (newest entry first), `docs/DECISIONS.md` (D-43 to D-45 are new).

## What we're building

**Meridian** (GitHub `ChimeXXD/meridian`, formerly `next-episode` and Airstamp, private until Day 7): an iPhone app that answers "how long until my next episode, in my time zone, and where is it on?". Lock Screen and Home Screen widgets plus a release-night Live Activity. Local-first, no account or server. Primary user: Chime in Lagos (UTC+1, no DST).

## How Chime wants to work (keep these)

- **Portfolio project, one week** (Thu 29 Oct – Thu 5 Nov 2026), stopping at a **private beta** on Chime's iPhone. No App Store work. Open-sourced (MIT) on Day 7. **$0 budget.**
- **Show, don't describe.** Chime judges from screenshots and the phone. No legends or colour codes: say it in plain words (D-40).
- **Design in Night Sky.** New screens reuse Upcoming's look (`NightArtHeader`, `GlassCircleButton`, `ReleaseHeadline`, serif countdown). Chime rejected a framed-poster page as "wack"; when in doubt, match Upcoming and Show detail.
- **Confirm when asked to.** If Chime says "confirm before you begin", restate the plan and wait.
- **Push to GitHub after every change.** Commit in its own Bash command, then push.
- After code changes run `/code-review --fix` (medium; high for risky work), then make sure the checks pass. Never launch `/code-review ultra`.
- **Check definitions need Chime's OK:** `.claude/proof.json`, anything in `fidelity/` (inventories, `FidelityTests`), and `.claude/settings.json`. The commit gate refuses `.claude/settings.json` changes until Chime confirms after an `NEEDS-INPUT:` line.
- **Fewer approval prompts (Chime was frustrated by them).** `.claude/settings.json` allowlists read-only tools plus, with Chime's OK, `xcodebuild -scheme Meridian *`, `xcodegen generate`, `fidelity/verify-screen.sh *`, the proof gate `--run`, `git add/commit *`, `git push -q origin main` and `xcrun devicectl device install app *`. Rules match one simple command, so run **one plain command per Bash call**: no `cd … &&`, no `&&` chains or pipes on these, no `sed`/Python heredocs for edits (use Edit/Write). Chime can also switch on auto mode (Shift+Tab).
- **The phone is personal.** Installing over Wi-Fi is fine; **never launch the app on it or take a screenshot without a fresh go-ahead** (a capture once caught private messages; it was deleted). Use the simulator for checks.
- **One simulator job at a time.** Run the gate in the foreground (`node "/Users/chimexd/.claude/plugins/cache/proof/proof/0.4.0/scripts/gate.mjs" --run`) and wait; parallel test runs (a background gate, a `/code-review` fork, another session) crash with "Mach error -308" or "Test crashed with signal kill". If that happens, rerun alone; it isn't the code. Tell agents not to run xcodebuild tests.
- **Agents to fast-track (Chime asked for this).** Commit a contract first (fixed type and function signatures with placeholder bodies), give each agent a worktree and a lane that touches different files, forbid simulator runs (one `build-for-testing` compile allowed after checking memory), then merge and run their tests yourself, one at a time.
- The Mac has 24 GB; Figma and Brave hold ~6 GB. Check `mem.mjs` before heavy work; never close Chime's apps.

## What happened this session

1. **Search filters (D-43).** Before typing, Search shows popular shows airing soon (TVmaze `weight`, AniList popularity), with a chip row picked **one at a time like the TV | Anime switch**: Popular (default), Today, New seasons, Exact time, then service chips. Each poster shows its network and its time in `ReleaseWording` words. The 15-show cap applies after filtering; an episode leaves the grid within a minute of coming out. Fixed a rule-2 bug: "still to come" now uses the resolved time, never a placeholder airstamp. Anime premieres come from a second AniList request for this week's episode 1s (up to 3 pages).
2. **Popularity from "reliable sources":** Netflix's official Top 10 has Nigeria rows, but its terms forbid copying, distributing or scraping it (O-13, quoted in DECISIONS). A link chip was built and then **dropped by Chime** ("it takes us to another link").
3. **Service chips (D-44, D-45).** Exactly **12 major platforms, always shown, in subscriber order**: Netflix, Prime Video, HBO Max (also holds HBO), Disney+, Paramount+, Hulu, Peacock, Apple TV, then CBS, NBC, ABC, FOX. No YouTube or BBC iPlayer (Chime: "not relevant"). One with nothing coming says "Nothing on Paramount+ in the next few days." Each chip shows the service's **logo** on a white tile, from a hand-checked list of 57 freely licensed **Wikimedia Commons** files (`rules/network-logos.json`, URLs only, loaded at runtime; 3 need credit, shown on Credits).
4. **Show page (D3-13).** Tapping any poster or title on the Search tab (results or the airing grid) opens the show's page; the poster's (+) still follows in one tap. The page is Night Sky like Upcoming: key art fading into night, the title, serif countdown and out line, year · network · status, Follow/Following. With nothing scheduled, only the title. Times match Upcoming's exactly.
5. **Day 4 widgets (built by two agents).** `SnapshotStore` + `WidgetSnapshotWriter` write `snapshot.json` and small art to the App Group after every refresh (refresh now runs from `RootView`, so a follow in Search reaches the widgets). `WidgetTimeline` (5-minute spacing, Out now hour, hourly refresh entries up to 48 h, date-only drops leave at midnight after their day). Five families in Night Sky (`Shared/Widgets/`, `MeridianWidgets/NextDropWidget`), each with counting down, Out now, date only and nothing. `WidgetAccessibility.label` ("Silo, expected in 2 days 4 hours, Apple TV"; "out now" only for an exact time).

## Where things stand (commit `ae49deb`, all pushed, tree clean)

- **On Chime's iPhone 14 Pro**, installed over **Wi-Fi** (devicectl reaches it on the local network; no cable needed while it's unlocked and on the same Wi-Fi). **Signing expires Fri 6 Nov 2026 22:27 Lagos** (21:27Z): reinstall before then (an install reuses the profile, so the date only moves when Xcode makes a new one).
- **Checks:** gate build + test + spec pass. Screen checks (`fidelity/verify-screen.sh`): welcome, upcoming, upcoming-empty, detail, settings, search, search-results, search-filtered, search-filter-empty, show-preview. `show-preview` relies on live TVmaze still listing a next date for Silo.
- **Widget renders:** `WidgetRenderTests` writes every family × state to `fidelity/shots/widgets/` (git-ignored); the lead looked at them.
- **features.json passing this session:** D3-8, D3-8b, D3-9, D3-10, D6-9 (dropped), D4-1, D4-2, D4-5.

## Next steps

1. **Chime's approvals (on the phone):** the Search filter row (D3-11), the logo chips (D3-12), the show page (D3-13), and the widgets once added (D4-3, D4-4: Lock Screen and Home Screen; tinted, Always-On and large text couldn't be rendered here). Chime has "seen the updates" but hasn't given a verdict yet; ask.
2. **Review leftovers worth doing:** the circular widget's count can read up to an hour high in the last day (refresh entries sit on the hour); widget art never refreshes once saved; launch can start two refreshes (`task(id:)` and scene phase); the "Silo returns …" widget state can't appear (a date-only drop always becomes current; a design call for Chime); the show page's back button uses fixed padding, not the safe area; three hand-kept alias lists (`PopularServices`, `network-logos.json`, `platform-rules.json`) must change together if TVmaze renames a channel; logos share the poster image cache.
3. **Day 5:** the Live Activity (D5-1 to D5-5) and the Debug menu.
4. **Day 6:** harden, offline label, Report a wrong time, CI, the accuracy audit (needs real times either side of the 1 Nov US clock change: D3-7, Chime's job, due today), the AX5 pass.
5. **Day 7 (never cut):** README, case study, video, open-source checklist, make the repo public.

## Open questions for Chime

- Verdict on Search, the show page and the widgets on the phone (above).
- Clock-change capture (D3-7) and the 5-person glance test (D3-6).
- O-12 artwork in README/video; O-5 AniList permission (before Day 7); O-7 HBO in Nigeria; D-36 Disney+.
- Earlier skipped items: a poster that fails to load shows an empty tile; posters are cropped about 6%.

## Useful commands

```bash
# Build and install on Chime's iPhone over Wi-Fi (UDID 00008120-001044862EC0201E). Don't launch or screenshot without asking.
xcodebuild -scheme Meridian -destination 'id=00008120-001044862EC0201E' -allowProvisioningUpdates -derivedDataPath build/device -quiet build
xcrun devicectl device install app --device 00008120-001044862EC0201E build/device/Build/Products/Debug-iphoneos/Meridian.app
# All checks (foreground, alone):
node "/Users/chimexd/.claude/plugins/cache/proof/proof/0.4.0/scripts/gate.mjs" --run
# One screen check:
fidelity/verify-screen.sh search-filtered
# Debug launch options: -follow <ids>, -followAnime <ids>, -tab search|settings, -query <text>, -kind anime,
#   -inMemoryStore, -filter today|new-seasons|exact-time|service:<label>, -openFirstResult YES, -designPreview
```

- Simulator: `iPhone 18 Pro, OS=27.0` (UDID 3B97D55E-ECD1-4062-9CDB-525FA31CCB10). Use `-collect-test-diagnostics never`. Swift Testing names need parentheses with `-only-testing` (`…/premieresFailing()`). Shut it down after use.
- Agent worktrees from this session remain under `.claude/worktrees/` (merged; safe to leave).
- `claude --resume` in this folder reopens the full transcript.
