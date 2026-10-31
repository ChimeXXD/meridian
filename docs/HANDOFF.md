# Handoff: read this first when you pick the project back up

Written 31 Oct 2026 (early hours, Lagos) at the end of the second long session with Chime. It summarises the whole conversation so a new session can continue without it. Then read, in order: `CLAUDE.md`, `docs/PLAN.md`, `PROGRESS.md` (newest entry first), `docs/DECISIONS.md` (D-37 to D-42 are new).

## What we're building

**Airstamp** (repo `next-episode`, GitHub `ChimeXXD/next-episode`, private until Day 7): an iPhone app that answers "how long until my next episode, in my time zone, and where is it on?". Lock Screen and Home Screen widgets plus a release-night Live Activity. Local-first, no account or server. Primary user: Chime in Lagos (UTC+1, no DST).

## How Chime wants to work (keep these)

- **Portfolio project, one week** (Thu 29 Oct – Thu 5 Nov 2026), stopping at a **private beta** on Chime's iPhone. No App Store work. Open-sourced (MIT) on Day 7. **$0 budget.**
- **No Figma.** references (MCP) is the reference library; UI goes straight into SwiftUI. Chime picks designs from **HTML boards** of reference screens (`scripts/build-reference-board.py --board <dir>`; picker with Use this / Not for us and Export). They like this workflow.
- **Show, don't describe.** Chime judges from screenshots on their phone. When explaining a screen, draw numbered marks on the real screenshot (`docs/design/direction-board/guide.html` is the model), not text alone.
- **No legends.** If a UI needs explaining (colour-coded dots), it's wrong; say it in plain words (D-40). Memory: `no-legend-ui`.
- **Push to GitHub after every change.** Commit in its own Bash command (the proof gate refuses commands that edit files and commit together), then push.
- After code changes run `/code-review --fix` (medium; high for risky work), then make sure the checks pass. Never launch `/code-review ultra`.
- Changes to check definitions (`.claude/proof.json`, anything in `fidelity/`) need Chime's OK. Never commit a Team ID. No `rm -rf`.
- Chime is happy for background agents to take a unit in parallel (a worktree each). Two simulator jobs at once collide: run one at a time.
- The Mac has 24 GB and fills up (Figma, browsers, Electron apps). Check `mem.mjs` before builds; never close Chime's apps without naming them and asking.

## Design decisions this session (don't reopen)

1. **Night Sky** (D-38) from three references directions (Glass and Poster Colour were "ugly"): the show's key art fades into a near-black base, giant light serif countdown, serif titles. **No brown**: warm art gets neutral charcoal (`ArtworkPalette.night`). Memory: `airstamp-visual-direction`.
2. **Unslopped** with the `unslop` skill (installed in `~/.claude/skills/unslop`, CC BY 4.0): no player controls or progress bar, sentence-case labels, serif only for titles and countdown, three greys (`NightInk`), zones named by place ("Lagos", "New York").
3. **Certainty in words, not dots** (D-40, supersedes D-39 and the source chip): "Out today at 21:00", "Expected Mon at 09:00", "Airs in Japan …", "Out Thu 19 Nov, time not announced". Show detail explains the source in one sentence. Code: `Shared/Time/ReleaseWording`. CLAUDE.md rule 3 was rewritten for this.
4. **Tab bar** (D-41): Upcoming · Search · Settings, Search in the middle as a plain tab.
5. **Search is a poster grid only** (Chime's picks on `docs/design/search-board/picks.json`: Plex "Popular Searches" grid). Before typing: "Airing in the next few days" (TV, from TVmaze schedules) or "Airing in Japan this week" (Anime, AniList). Results use the same grid with "year · network · country" and status. The list/card design was killed.
6. **Nothing scheduled is never blank**: with no countdown, Upcoming spotlights a show (art, title, "Waiting for news · last episode Sat 29 Mar 2025" or "Out Fri 9 Jul 2027, time not announced"); the rest are a poster grid with status lines. A show never appears twice.
7. **Far placeholder dates** (D-42, closes O-10): no airtime and more than 180 days away → date only.
8. App icon: a light New York serif "A" on Night Sky charcoal (`scripts/make-app-icon.swift`). Chime hasn't commented on it.

## Where things stand (commit `22c00fe`, all pushed)

- **The real app runs on Chime's iPhone 14 Pro** (iOS 27.0.1, free signing, Team ID only in git-ignored `Config/Signing.local.xcconfig`). **Signing expires Fri 6 Nov 2026 ~22:27 Lagos**: plug in and reinstall (commands below).
- **Built:** Welcome (zone line), tab bar, Search (TVmaze + AniList, poster grid, follow), Upcoming (live data, sections, spotlight, quiet grid, offline keeps last known times), Show detail (per-show Live Activity switch, last 3 episodes, unfollow), Settings (zone, lead time 30 min–6 h), Credits. `FollowStore` (SwiftData), `UpcomingLoader`/`UpcomingModel`, `AniListClient` (adult filter, 2 s spacing, cache), `ViewerCountry` (country from time zone via bundled zone.tab; Lagos → NG).
- **Day 0 gate passed:** app and widget extension both sign with the App Group `group.dev.chime.airstamp` on free signing.
- **Tests:** 120 unit tests pass. **Screen checks (D3-1, approved by Chime):** `fidelity/verify-screen.sh [screen]` runs `AirstampUITests/FidelityTests` (scheme `AirstampFidelity`) against `fidelity/inventory/*.json` for welcome, upcoming, upcoming-empty, detail, settings, search, search-results: ALL PASS. Not in `.claude/proof.json`. Search checks need the network.
- **features.json passing:** D2-1–3, D2-5–7, D3-1 and the Day 0/1 items. D2-4 superseded.

## Next steps

1. **Day 4: widgets** in Night Sky (`accessoryInline/Circular/Rectangular`, `systemSmall/Medium`), using `ReleaseWording` (never the old `SourceChip`), `Text(timerInterval:pauseTime:countsDown:)`, `SnapshotStore` writing App Group JSON, timeline entries ≥ 5 min apart, `.after(nextDrop)`. The app must save small art files to the App Group (widgets can't download).
2. Small follow-ups: failed shows in `UpcomingLoader.keepingLastKnown` are matched by name and re-added at the end; match by show ID. UI-BRIEF §1–3 and §5.3 still describe old designs; rewrite for Night Sky and the grid. Old `SourceChip`/`DropRow` survive only for widget mock-ups.
3. Day 5 Live Activity, Day 6 harden + accuracy audit, Day 7 README/video/case study/open source (never cut).

## Open questions for Chime

- Approve the screens on the phone (Day 3 gate); log real times either side of Sunday 1 Nov's US clock change (D3-7); glance test with 5 people (D3-6).
- O-12 artwork in README/video; O-5 AniList permission email (before Day 7); O-7 HBO in Nigeria; D-36 Disney+.
- Skipped review items left for Chime: a poster that fails to load shows an empty tile (no TV glyph); posters are cropped about 6%.

## Useful commands

```bash
# Build and install on Chime's iPhone (UDID 00008120-001044862EC0201E), then screenshot it
xcodebuild -scheme Airstamp -destination 'id=00008120-001044862EC0201E' -allowProvisioningUpdates -derivedDataPath build/device build
xcrun devicectl device install app --device 00008120-001044862EC0201E build/device/Build/Products/Debug-iphoneos/Airstamp.app
xcrun devicectl device process launch --device 00008120-001044862EC0201E --terminate-existing dev.chime.airstamp -- -tab search
xcrun devicectl device capture screenshot --device 00008120-001044862EC0201E --destination shot.png
# Simulator: -designPreview [detail] [bottom] [<TVmaze id>] shows the real views with sample times.
# Debug launch options: -follow <ids>, -followAnime <ids>, -tab search|settings, -query <text>, -kind anime, -inMemoryStore
```

- Simulator: `iPhone 18 Pro, OS=27.0`. Use `-collect-test-diagnostics never`. Shut it down after use.
- Files outside the project (Desktop, Downloads) can't be read; capture the phone screen with `devicectl` instead.
- references returns a "usage is high this month" notice on searches; show it to Chime verbatim.
- `claude --resume` in this folder reopens the full transcript.
