# Handoff: read this first when you pick the project back up

Written 30 Oct 2026 at the end of a long session with Chime. It summarises the whole conversation so a new session can continue without it. Then read, in order: `CLAUDE.md`, `docs/PLAN.md`, `PROGRESS.md` (newest entry first), `docs/DECISIONS.md`.

## What we're building

**Airstamp** (repo `next-episode`, GitHub `ChimeXXD/next-episode`, private until Day 7): an iPhone app that answers "how long until my next episode, in my time zone, and where is it on?". Lock Screen and Home Screen widgets plus a release-night Live Activity. Local-first, no account or server. Primary user: Chime in Lagos (UTC+1, no DST).

## How Chime wants to work (keep these)

- **Portfolio project, one week** (Thu 29 Oct – Thu 5 Nov 2026), stopping at a **private beta**. No App Store work. Open-sourced (MIT) on Day 7.
- **$0 budget**: free Apple ID signing, no TestFlight, no paid services.
- **No Figma.** "We are strictly vibe coding this product." references (MCP) is the reference library; UI goes straight into SwiftUI.
- **Push to GitHub after every change.** Commit in its own Bash command (the proof gate refuses combined commands), then push.
- After code changes run `/code-review --fix` (medium; high for risky work), then make sure the checks pass. Never launch `/code-review ultra`.
- Changes to `.claude/proof.json` need Chime's OK. Never commit a Team ID. No `rm -rf`.
- **Show, don't describe.** Chime judges from screenshots. Show real rendered screens early.

## The big correction this session (don't repeat it)

The first UI pass was **type-only, with no artwork** (old decision D-13) and three numeral studies (System / Mono / Serif). Chime rejected it outright ("terrible", "disgusting"). Two instructions followed:
1. **Show the artwork.** When a row says Silo, show Silo's banner or poster. Recorded as **D-37** (supersedes D-13): artwork is fetched at runtime from TVmaze/AniList, cached on the phone, and **never committed** to the repo. Committed screenshots and test baselines use a placeholder.
2. **Pick a new visual style from references.** A style board of 96 screens in 10 directions was built; Chime liked 15.

**The chosen direction (artwork-led):** full-bleed key art that fades into a deep colour sampled from the art, a very large **thin serif countdown** over it (Chime: "I like the visual of this product. Let's focus more on this" about **Insight Timer**), and each show as a slab tinted from its own poster. Other liked references: Apple TV, HBO Max and Apple Music heroes; Plex and Paramount+ (page colour from the art); Peacock and Letterboxd poster walls; Apple TV and Spotify widgets; the NFL Dynamic Island; the Duolingo Live Activity ("Love this."); the TIDE glass look; Fixtured colour slabs; the Sunlitt widget. Full list: `docs/design/style-board/picks.json`.

## Where things stand (commit `7359ecc`)

- **Done:** Day 0 setup (except the on-device check); Day 1 time engine (tests first; rules file; TVmaze client); the sitemap (`docs/SITEMAP.md`); the reference board (47 picks, structural) and the style board (15 picks, visual), both saved to the reference collection "Airstamp references"; the UI brief (`docs/design/UI-BRIEF.md`, §1–3 marked "being redone" for D-37, §4–6 still valid; `scripts/check-brief.sh` checks it); tokens and components in `Shared/Design/`.
- **Latest work:** artwork-led `UpcomingArtView`, `UpcomingHero`, `ArtDropRow` and `ShowDetailArtView`, plus `ArtworkPalette`, `ShowArtwork`, `ArtworkLoader` and `TVmazeClient.images`. They run with live TVmaze art and **sample times** in the Debug-only `DesignPreview`. 65 tests pass.
- **Waiting on Chime:** feedback on the four screenshots of the artwork-led Upcoming and Show detail. Ask what to change (serif countdown, colour strength, slab rows or poster cards) before building on it.

### See the screens again

```bash
xcodegen generate
xcodebuild -scheme Airstamp -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' build
# install the built Airstamp.app (DerivedData) with `xcrun simctl install booted …`, then:
xcrun simctl launch booted dev.chime.airstamp -designPreview              # Upcoming
xcrun simctl launch booted dev.chime.airstamp -designPreview bottom       # Upcoming, scrolled
xcrun simctl launch booted dev.chime.airstamp -designPreview detail       # Silo's Show detail
xcrun simctl io booted screenshot shot.png
```
Artwork loads a few seconds after launch. Shut the simulator down afterwards (the Mac is tight on memory).

## Next steps

1. Get Chime's verdict on the artwork-led screens and adjust.
2. Then clean up: remove the rejected numeral studies (`NumeralStudyBoard`, `StudySurfaces`, `NumeralStudyRenderTests`, `docs/design/studies/`), rewrite UI-BRIEF §1–3 for the artwork-led direction, and mark D2-4 in `docs/features.json` as superseded.
3. Day 2 leftovers: `AniListClient` behind `CatalogSource` (30 requests a minute, `isAdult` filtered, anime artwork from `coverImage`/`bannerImage`), ProviderLabel country logic, SwiftData `FollowedShow`, Search.
4. Day 3: real Upcoming data (`UpcomingViewModel` with tested section boundaries) behind the new views; first-run Welcome.
5. Day 4: widgets and the Live Activity in the artwork style. Widgets can't load from the network, so the app saves small art files to the App Group.

## Open questions for Chime

- **O-11 navigation:** tab bar (Upcoming, Search, Settings; recommended) or one screen with toolbar buttons. Needed before Day 3.
- **O-12:** may README screenshots and the demo video show show artwork? (Claude checks TVmaze/AniList image terms before Day 4.)
- **Day 0 device check:** sign in to Xcode with an Apple ID, turn on Developer Mode, plug in the iPhone, and send the Team ID (it goes only in `Config/Signing.local.xcconfig`).
- O-5 (AniList permission email), O-7 (HBO in Nigeria), O-10 (TVmaze placeholder dates, decide by Day 3), confirm D-36 (Disney+ has no default rule).

## Useful facts

- Simulator: `iPhone 18 Pro, OS=27.0` (the 17 Pro only has iOS 26.5). Use `-collect-test-diagnostics never` on test runs, or a failing run waits 600 s.
- TVmaze IDs used in the preview: Silo 38052, Frieren 69956, House of the Dragon 44778, Wednesday 53647, The Last of Us 46562, Severance 44933. TVmaze "typography" images are JPEGs (no transparency), so titles are set as text.
- Board builder: `python3 -I scripts/build-reference-board.py [--board docs/design/style-board] refs.json …`. reference screenshots are git-ignored.
- references returns a "usage is high this month" notice on searches; show it to Chime verbatim.
- The full chat transcript is saved by Claude Code; `claude --resume` in this folder reopens it.
