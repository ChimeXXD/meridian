# Handoff: read this first when you pick the project back up

Updated 5 Nov 2026 (Lagos, Day 7, about 04:00) by the session that ran the ten skill reviews and applied them. Chime is they/them. **Start with "Latest: session of Thu 5 Nov 2026" just below**; the older sections follow, newest first. Then read, in order: `CLAUDE.md`, `docs/PLAN.md`, `PROGRESS.md` (newest entry first), `docs/DECISIONS.md` (D-64 and D-65 are the newest).

## Latest: session of Thu 5 Nov 2026 (ten skill reviews, then "fix everything")

### Where it stands

- **The repo is public** (`ChimeXXD/meridian`; Chime made it public). `main` is **`9b298ea`** plus this handoff, all pushed. 30 commits since `66a3398`, the start of this session.
- **The proof gate passed** (build, test, spec) on `9b298ea`: 337 tests. **CI** was red from `a346856` to `7f46e6b` (the new App Group tests can't pass in CI's unsigned build); `9b298ea` skips them when `MERIDIAN_UNSIGNED` is set, as ci.yml now does. Its CI run was still in progress at handoff: **check it went green** (`gh run list --limit 1`).
- **On the phone:** `9b298ea` is installed (install only; not launched, no screenshots). **Signing expires Mon 9 Nov 2026 00:59 Lagos** (read from the build's `embedded.mobileprovision`): reinstall before then.
- **The design system redeployed** itself on each push (Vercel). Not checked that the last deploy finished.

### What Chime asked for, in order

1. **"Follow all the prompts in the skill prompt file"** (`docs/SKILL-PROMPTS.md`, git-excluded). Each of the 10 prompts ran Pass 1 (findings only) in its own fresh agent: write-swift, break-ui, apple-design, emil-design-eng (app), animation-vocabulary, review-animations, emil-design-eng (site), mobile-native, remove-animations, find-animation-opportunities. About 110 findings went into one pick list.
2. **"Fix everything, push to GitHub, and push to my phone."** That approved every finding, with the recommended option at each choice. Pass 2 ran in 7 batches: Swift fixes; API refactors; widgets and Live Activity; app motion; app layout and loading; the site (in its own worktree, alongside); docs. Then `/code-review high --fix` over everything, the gate, and the install.
3. **"Can we work faster?"** Batches share one simulator, so they ran one at a time; only the site batch (no simulator) ran alongside. Each reply of the orchestrator started a Stop-hook gate run that collided with the running agent's simulator ("signal kill/term before establishing connection", "build.db is locked"): those failures were collisions, never code. Chime OK'd letting the batches finish before the gate ran again.
4. **Memory:** the Mac sat at 75–81% with 4.5 GB swapped. Chime closed Dia and kept Figma open.

### Choices made under "fix everything" (the recommended options)

- Phone menu drawer: keep the slide on an iOS curve, with the scrim fading with it (not removed). Tabs: no transition, plus a 2 px selected line. Hero band: band and phone fade together via `@property --night`.
- Widgets say today/tomorrow, then the weekday for 2–6 days, then the date from 7 days ("Out Wed 11 Nov 19:00"). Midnight wording kept ("Out tomorrow at 00:00"); "+N more this week" kept.
- Two-line titles on the Lock Screen banner and the large widget; the small widget stays at one line (D-46). To fit the banner's 160 pt, its padding went 14 → 12 pt and the gap above the countdown 12 → 10 pt.
- Upcoming rows show the poster at 2:3 (44×66), like the widgets' rows (D-47).
- Art keeps an opacity fade under Reduce Motion (Apple's cross-fade stand-in); the Welcome drift still stops.
- **Not done:** a haptic at the drop (an option, not a fix), and linking a real island clip from the site (needs a new decision; rule 9 / D-63).

### What changed (details per batch in PROGRESS.md)

- **Bugs:** a failed show kept its last drop by name, so two same-name follows duplicated a row (`c2cb691`). Every followed show was fetched twice on a cold launch (in-flight sharing in `TVmazeClient`, at most 6 requests at once). `WallClock` accepted junk and signed parts ("2026-11-05-junk", "-0:30"). The rules file's `updated` date is checked.
- **Tests:** a real airtime at 12/16/17Z stays exact (D-25); the App Group tests can fail; fixture tests are parameterised; a WallClock edge table; worst-case widget and Live Activity tests (Vision reads "US" and "4 more"; AX5 heights; "88:88:88" fits the compact slot); a midnight widget entry.
- **Refactors:** `ReleaseVerb` enum (payload byte-identical); `ReleaseSource.adjusted(base:)` carries its source; `ShowID` builds every ID string; Upcoming redraws on the minute and at section changes, with only its countdowns ticking each second (`UpcomingSchedule`).
- **Widgets and Live Activity:** the inline widget keeps its count, the country is never cut (`CountryKeepingText`), the small family keeps "+ N more", the compact timer scales to 0.7, widget countdowns don't grow at AX5, emoji-only initials. DropRow and SourceChip deleted. 57 renders synced to the site.
- **App feel:** "Out now" fades in without the page jumping (`CountdownSlot`); a solid status-bar shade (`StatusBarShade`); Settings, Credits and Debug on the night base; Search's field always visible (the title is now small and centred); one `PressStyle`; + morphs to ✓; the stepper and Live Activity toggle animate; the hourly still step rolls; Welcome crossfades into the tabs; the stray "the" in "the Crunchyroll's usual time" is gone.
- **App layout and loading:** Upcoming spacing (rows 16, header 8, sections 32); poster thumbnails; cached art shows on the first frame; placeholders instead of spinners; the show page holds its headline's space; a 200 pt hero for a show with no art; titles take 4 lines at AX sizes; tight leading on serif headings of 28 pt and up; Report opens in an in-app Safari sheet (GitHub issues, D-34).
- **Site:** every RA/RM/FO/ES/MN item (the IDs are in the reports). Mockup art fades in like the app's; phones share one scale; the hero phone sits on the band's foot; search sits at the top on phones with Close beside the field; the page no longer scrolls under the drawer or search; no tap flash or sticky hover; 44 pt hit areas; `viewport-fit=cover` removed; `theme-color` set.
- **Docs:** UI-BRIEF §2 and the site's Motion section describe the motion that now exists; a "Motion" paragraph in CASE-STUDY.md; SHOT-LIST step 4 and SITEMAP say "Delayed from 22:00" (not struck through).
- **The code review** (10 findings) fixed CI, signed clock parts, the three copies of the "today/tomorrow" wording (`DropFormatter.spokenRelativeDay`) and the copied "returns" sentence. It found that today/tomorrow went stale for up to an hour after midnight; fixed with a widget entry just after each midnight when a drop is under a week away (test first).

### Files and where they live

- **The ten reports, the pick list and the Pass 2 brief:** `docs/skill-runs/` (local only, git-excluded like `docs/SKILL-PROMPTS.md`). Finding IDs (WS-, BU-, AD-, EA-, RA-, ES-, MN-, RM-, FO-) in commits and PROGRESS refer to these.
- Screenshots, renders and recordings from this session were in the session's temporary scratch folder and won't survive. Worst-case widget and Live Activity renders regenerate into `fidelity/shots/worst-cases/` when their tests run.

### Not done, and why

- **ShowID** is only partly adopted: the stored `showID: String` fields and `[String: …]` dictionaries still hold strings, because the debug and sample shows use IDs that aren't real shows ("debug", "from", "tlou", "andor").
- **Making impossible Drop states unrepresentable** (WS-15) was skipped; it waits on the rest of ShowID. Suggested issue: `enum Release { case timed(Date, ReleaseSource, sure: Bool), case dateOnly(airdate: String?) }` with `confidence` derived from it, still decoding today's snapshot JSON (D-05).
- **The island past 24 h** still shows "26:00:00", not "1d 2h": it isn't redrawn between content updates, so a still count would go stale.
- **Snapshot writing** moved only the art I/O off the main actor; the small JSON write stayed synchronous.
- **The review skipped:** a shared helper for the two "6 at once" loops (it would hold all the art until the end), ShowID's unused Codable, and three micro-optimisations.
- **The 24 h hand-off** crossfades rather than rolls, because rolling it would need the shared CountdownText, which the widgets use.

### Next steps

1. Check that CI went green on `9b298ea`.
2. **Phone checks** (renders miss the device layout):
   - the inline and rectangular widgets with a long name and a long provider ("Paramount+ with Showtime · US")
   - the compact island with more than 10 h left (Debug fake activity)
   - the Lock Screen banner with a long name and with a delay
   - "Out now" on Upcoming at a drop
   - opening a show: the art should already be there
   - press feedback, + → ✓, the Report sheet, and the shade on a long show page
   - widgets across midnight
   - the site on the iPhone: tap flash, the menu, search with the keyboard up
3. **Chime to re-approve screens that changed on purpose:** Upcoming (spacing, posters), Search (field, small title), Settings (charcoal), Welcome and the empty states (tighter headings), and the Lock Screen banner (12 / 10 pt).
4. **Two lines in CLAUDE.md are out of date** (Chime's file, not edited): the layout lists `RefreshService`, which doesn't exist (its tests are now `DelayDetectionTests`), and rule 3 says `SourceChip` survives in the pre-Night-Sky views (it's deleted).
5. Then the Day 7 steps from 4 Nov below that are still open (the portfolio's repo link, the case study copy), and D-64 after Day 7.

## Session of Wed 4 Nov 2026 (footage, case study, history rewrite)

### Where it stands

- **The repo's history was rewritten on 4 Nov** to remove every mention of the design reference library before it goes public (Chime: "I don't want to disclose that workflow to the public"; then "Remove it from the repo. Yes."). Every commit ID changed. `main` is **`fb8df25`** plus this handoff, and the tag **v0.1.0** was moved to match (its release kept its 10 README images). Old IDs quoted in older docs and below (`818e0a7`, `f3fdfa8`, `dff65d4`…) no longer exist.
  - **Backup of the old history:** `~/Projects/Personal Projects/meridian-backup-before-history-rewrite-2026-11-04.bundle`.
  - **Removed from every commit:** `docs/design/{reference,search,style,direction}-board/`, `docs/design/REFERENCES.md`, and the board scripts (`build-reference-board.py`, `build-direction-board.py`, `picks-to-references.py`, `reference-sections.py`, `reference-board-template.html`). The rest was reworded ("design references"…). A search of every commit, message and blob found 0 mentions. Two permission lines for that library's tools in `.claude/settings.json` were removed with Chime's OK.
  - **Never** merge or push anything built on the old history, and never name the reference library in this repo, its commits or the case study. Another local session (`personal-projects-c6`) committed here earlier today and was messaged to reset to `origin/main` first.
  - GitHub can keep the old commits reachable by exact ID for a while. Nobody outside has those IDs; GitHub support can purge them if Chime wants certainty.
- **CI passed** on `fb8df25`. The proof gate (build, test, spec) passed on the Lock Screen change below.
- **On the phone:** the build with the Lock Screen "Out now" change is installed. **Signing expires Mon 9 Nov 2026 00:59 Lagos**: reinstall before then.
- **Portfolio case study is live:** https://chimexd.work/work/meridian (repo `My Portfolio`, `main` = `5b3c1f1`, deployed by Cloudflare Pages). The home page features **Meridian, Clepso, then Perpetual Trading**; Bulan moved to /work only (Chime's call).

### What Chime asked for, in order (the conversation, condensed)

1. **The screen-recording pill took over the Dynamic Island.** Fix: record with **QuickTime on the Mac** over a cable (File › New Movie Recording, iPhone as camera, Quality Maximum), never the phone's Screen Recording. `docs/SHOT-LIST.md` became one QuickTime take in a running order.
2. **"Record one video and you cut it."** Chime filmed takes 2 and 3 (standby, same night + Lock Screen widgets, Out now, three widgets). I cut the clips and stills from them.
3. **StandBy:** the small circle at the top *is* Silo's Live Activity (Chime corrected me). Still 21 uses it.
4. **Lock Screen at the drop ("do your recommendation"):** the banner now puts gold **"Out now" in the countdown's place**, 0.7× its size on its baseline, and keeps its height, with a hidden plain-text stand-in (not a timer, D-57). Commit `9cc291e` (renders and design system synced, five review fixes, gate green). **Not yet seen on the phone.**
5. **"Why is it one video? It should be cut into the states."** I cut **17 clips** (later 18) of single states.
6. **Zoom like the reference** (a portfolio video that eases in on what it shows, holds, eases out): built in HyperFrames, camera as a pure function of time (geometric scale, straight-line pan, `power2.inOut`, the phone's edge kept at the frame's edge).
7. **"Why 29 seconds, and why speed up the countdown?"** Chime was right: a 3× timer looks broken in an app about trustworthy time. Recut to **16.6 s at real speed** with the countdown only going down, and the island press kept as real footage.
8. **"Do all the different states, each with the zoom."** Nine state films, square, for the case study's 544 px column.
9. **Search › service chips should show "Popular"** (Chime watches a lot but didn't know the airing shows). An agent planned it; Chime chose: Wikipedia pageviews, the 3 newest season starts first, built **after Day 7**, refreshed by a **weekly GitHub bot**. Recorded as **D-64**; nothing built yet.
10. **Case study** drafted on a branch by an agent, reviewed (`/code-review`: 10 findings, 8 fixed: a refused play now restores controls, byte ranges in `serve-out.mjs`, etc.), previewed at `meridian-case-study.chimexd.pages.dev`.
11. **Remove Chime's Man United and X Lock Screen widgets without cropping:** painted out frame by frame by rebuilding rows 1998–2154 from the clean rows above and below (no trace in any frame). Originals are in `clips/with-widgets/` and `stills/with-widgets/`.
12. **The page says "demo"**; **home order** Meridian, Clepso, Perpetual Trading.
13. **"It was taking a long time."** Small copy and config edits are now done directly with narrow tests, not by agents running the whole suite.
14. **Nothing about the reference library in public;** say "I designed". Then: **say the first version was designed by hand in Figma** (a design engineer case study must show the design work). Recorded as **D-65** (supersedes D-31's "no Figma"); CLAUDE.md, PLAN, SPEC, UI-BRIEF and CASE-STUDY updated.
15. **Widgets:** the three sizes as one image cut out at near real size (`widgets.jpg`), in their own **Widgets** section under Key decisions.
16. **Posters in Figma:** a **Meridian** page in "Portfolio Elements" (file `mageMpQwkjfpW2jBY66fNl`, frame `73:6`): card at rest (Longitudes mark plus "Meridian" in Newsreader on night), hover (six real screens), list row (app icon and three preview cards). Chime approved, and an agent exported them to the site (new "night" tone) and published to chimexd.work.

### Files and where they live

- **Video project** `~/Projects/Personal Projects/Meridian Video/` (local git; footage, clips, stills and renders are git-ignored):
  - `footage/`: takes; `clips/`: 18 single-state MP4s (1180×2556, 60 fps); `stills/`: 21 phone stills plus `stills/app/` (7 simulator app screens; Settings had its Debug row painted out).
  - `build.mjs`: one shot list (`FILMS`) writes the reel (`square/`, `vertical/`) and each state's project (`films/<format>/<name>/`), with the zoom targets in `LOOK`.
  - Renders: `square/renders/meridian-square.mp4` and `vertical/renders/meridian-vertical.mp4` (16.6 s reel); `renders/states/*.mp4` (9 state films, square). The vertical state films are built but not rendered.
- **Portfolio** `~/Projects/Personal Projects/My Portfolio/`: `content/work/meridian.mdx`, `public/images/work/meridian/` (films, posters, screens, `widgets.jpg`, `logo.svg`, `icon.svg`, `page.jpg`, `card-1..3.jpg`), `tests/meridian.spec.ts` (fails if the page names the reference library; checks the Figma line, 9 films, 4 metrics). Chime's uncommitted GitHub/PSN/X data refreshes there were never touched.

### Next steps (Day 7, Thu 5 Nov, never cut)

1. **Make `ChimeXXD/meridian` public.** Then, in the portfolio, put `repo: "https://github.com/ChimeXXD/meridian"` back in `meridian.mdx`'s meta and restore the GitHub-link test (both marked TODO there). The case study already says the repo "went public" (three places).
2. **Confirm the Lock Screen "Out now" banner on the phone:** a short QuickTime clip of the Lock Screen through a drop (tap "Live Activity for Silo now", lock, wait about 3 minutes). That clip can replace the old-design still 13.
3. **Chime to read and confirm the case study copy** (drafted from these docs; every drafted line is marked `TODO(copy)` in the MDX's top comment).
4. After Day 7: **build D-64** (Popular per service) with the weekly GitHub Action; reinstall before 9 Nov.

### Open for Chime

- Copy approval (above); whether to ask GitHub support to purge the pre-rewrite commits; vertical state films if wanted; StandBy is the weakest film (Apple draws its ring tiny).

## What we're building

**Meridian** (GitHub `ChimeXXD/meridian`, private until Day 7; formerly Airstamp, repo formerly `next-episode`): an iPhone app that answers "how long until my next episode, in my time zone, and where is it on?". Lock Screen and Home Screen widgets plus a release-night Live Activity. Local-first, no account or server. Primary user: Chime in Lagos (UTC+1, no DST).

**The name:** a meridian is the line that sets your local time ("in your time zone"), and the line a star crosses at its highest point (the drop, "Out now"). The Longitudes logo is a globe drawn by its meridians, yours rising to a gold star.

## How Chime wants to work (keep these)

- **Portfolio project, one week** (Thu 29 Oct – Thu 5 Nov 2026), stopping at a **private beta** on Chime's iPhone. No App Store work. Open-sourced (MIT) on Day 7. **$0 budget.**
- **Show, don't describe.** Chime judges from screenshots and the phone. No legends or colour codes: say it in plain words (D-40).
- **Install on the iPhone after every app change** (over Wi-Fi, no cable). **Never launch the app or screenshot the phone without a fresh go-ahead.** When Chime asked to "reset" the app to see Welcome, a launch with `-inMemoryStore -welcomeDone NO` showed it without deleting their follows (a normal reopen restores everything).
- **Confirm when asked to.** If Chime says "let me know if you understand", restate the plan, ask the real questions (AskUserQuestion), then start.
- **Push to GitHub after every commit.** Commit in its own Bash command (the proof gate refuses a commit chained after a file-changing command), then push.
- After code changes run `/code-review medium --fix` (high for risky work), then make sure the checks pass. Never launch `/code-review ultra`.
- **Check definitions need Chime's OK:** `.claude/proof.json`, anything in `fidelity/` (inventories, `FidelityTests`, `verify-screen.sh`), and `.claude/settings.json`. Chime OK'd the rename-only edits this session; a review agent's added Welcome inventory item was undone pending their OK.
- **Speed over ceremony (4 Nov):** do small copy and config edits directly and run only the affected tests; keep agents for big or parallel work and tell them to run narrow tests.
- **Nothing about the design reference library in public:** the repo, commits and case study say "I designed"; the first version was designed by hand in Figma (D-65).
- **Never commit show artwork** (rule 9, D-37). The design-system site loads art at runtime from TVmaze/AniList (URLs only), and its widget renders are "art holes" (see below).
- **Agents in parallel** when Chime asks: give each a lane that touches different files, tell them not to commit, push, install or edit docs; then check their screenshots yourself, run `/code-review`, write the docs, commit and push. One simulator job at a time.
- **"Live" means ticking on two screenshots seconds apart**, never one render.
- The Mac has 24 GB; Dia and Claude hold the most. Never close Chime's apps.

## What happened this session (1–2 Nov)

1. **Widgets rebuilt on Chime's reference picks (D-46 to D-48):** Apple TV, Tripsy and Udemy. A large widget was added, with small 2:3 posters on rows, "+N more this week", and followed shows with nothing scheduled shown as "Nothing scheduled".
2. **Live Activity (Day 5, D-49, D-50):** rebuilt on Chime's picks (Duolingo, Instagram, Yazio, Tinder). Same-night merge, at most 3 pending, and a Debug `-fakeActivity <minutes>` option.
3. **Countdowns:**
   - D-51 made everything tick.
   - D-52 dropped `pauseTime`, which froze widget and Live Activity timers (CLAUDE.md rule 4 updated).
   - **D-56 (latest):** only the last 24 h ticks. Further out it's a still "4d 4h": rounded down, both parts always shown ("1d 0h"), spoken "1 day". Widget timelines add an exact entry at drop − 24 h and refresh 1 s after the hour beyond the last day.
4. **Renamed Airstamp → Meridian everywhere (D-54):**
   - targets, folders, schemes, display name and copy
   - bundle ID `dev.chime.meridian`, App Group `group.dev.chime.meridian`, repo `ChimeXXD/meridian`
   - memory notes and the description in `~/.claude/settings.json`

   TVmaze's `airstamp` field and `parseAirstamp` keep their name (it's the API's). The old Airstamp app was uninstalled from the phone; the phone then needed **Settings → General → VPN & Device Management → Trust** again.
5. **Brand:**
   - **Logo:** "Longitudes" (via the logo-generator skill).
   - **Brand colour (D-53):** **Meridian Gold `#E9C46A`**, only on the logo's star and "Out now" (`Tokens.gold`, `LiveActivityInk.out`). Starlight `#F4EFE4` is `Tokens.starlight`.
   - **App icon:** default, dark and tinted, drawn by `scripts/make-app-icon.swift`.
   - **In-app logo:** `Shared/Design/MeridianMark.swift` draws the logo.
6. **Welcome screen:**
   - **Art wall (D-55):** a drifting wall of this week's TV and anime art. Three rows, posters and wide art mixed, fading into night. Clock-driven offset, still under Reduce Motion, plain night when offline, retried on return.
   - **Unslop pass:** the logo lockup above the headline, and the text block in two groups (logo, 16, headline, 12, zone, 32, buttons).
7. **Design-system website** (`design-system/`, static HTML/CSS/JS):
   - Built, then QA'd (323 checks) and UX-audited.
   - Redesigned with the unslop skill: six views, Newsreader serif, honest contrast claims.
   - Real show art loads at runtime wherever a show is named.
   - The widget and Live Activity renders are **art holes**: `MeridianTests/Support/ArtMatte.swift` renders them with black, white and grey art and keeps only what sits over it. `art-holes.json` lists each hole, and the site puts the show's art behind it.
   - CSS-drawn **iPhone mockups** (Home Screen pages, Lock Screen, compact and expanded island) on our own night-sky wallpaper.
8. **Hosting:** Vercel project `meridian-design-system`, connected to GitHub.
   - **Deploys:** every push to `main` that changes `design-system/` deploys (root `design-system/`, no build, ignored-build-step `git diff HEAD^ HEAD --quiet -- .`).
   - **Address:** **https://meridian-designsystem.vercel.app** (the plain `meridian-design-system.vercel.app` belongs to someone else); also `-liart.vercel.app`.
   - `.vercelignore` keeps `.env*`/`.vercel` out.
   - **Gotchas:**
     - CLI deploys from inside the repo were "Blocked" because of the commit author's email (Git deploys work).
     - Chime's ISP sometimes can't reach some Vercel edge IPs (the `.3` group). It's a DNS/routing issue on their side; suggest DNS `1.1.1.1` / `8.8.8.8`.

## Where things stood on 2 Nov (before the 4 Nov history rewrite; IDs changed)

- **On Chime's iPhone 14 Pro** (UDID <your-iphone-udid>), installed over Wi-Fi. **Signing expires Mon 9 Nov 2026 00:59 Lagos** (2026-11-08T23:59Z, profile for `dev.chime.meridian`): reinstall before then.
- **Checks:** 252 tests pass (gate build + test + spec). The design-system site has 0 console errors, no overflow at 320, and deep links land.
- **Live:** https://meridian-designsystem.vercel.app has the latest site.

## Next steps as of 2 Nov (mostly done since; see the 4 Nov section)

1. **Chime's verdicts** on the phone: the new countdown rule, the Welcome wall and logo, the widgets and the Live Activity. D5-3 (Debug actions on the phone) and D5-4 (Chime's screen recording) are still open.
2. **Review leftovers worth doing:**
   - **Widget rows:** rows other than the widget's main show can read an hour high for up to an hour (their refreshes follow only the main show; fixing it means about 4x the timeline entries).
   - **Circular widget:** its "4h"/"38m" rounds down in the last day.
   - **Welcome logo:** can sit over the art's fade on short screens or with very large text.
   - **Design system:** Wednesday's and Severance's night bases aren't in its token table.
   - **Live Activity:** Always-On muted contrast is 3.60:1.
   - **Upcoming:** rebuilds its whole screen every second.
3. **Day 6:**
   - harden, the offline label, Report a wrong time, CI
   - the accuracy audit (D3-7 clock-change capture, Chime's job)
   - the AX5 pass
4. **Day 7 (never cut):** README, case study, video, open-source checklist, make the repo public (then the design-system and User-Agent GitHub links stop 404ing).

## Open questions for Chime

- Verdicts above.
- Whether to add the `welcome-logo` item to `fidelity/inventory/welcome.json` (needs their OK).
- O-5 AniList permission (before Day 7); O-12 artwork in README/video; O-3 name trademark check.

## Useful commands

```bash
# Build and install on Chime's iPhone over Wi-Fi. Don't launch or screenshot without asking.
xcodebuild -scheme Meridian -destination 'id=<your-iphone-udid>' -allowProvisioningUpdates -derivedDataPath build/device -quiet build
xcrun devicectl device install app --device <your-iphone-udid> build/device/Build/Products/Debug-iphoneos/Meridian.app
# Show Welcome on the phone without deleting follows (only with Chime's go-ahead):
xcrun devicectl device process launch --device <your-iphone-udid> --terminate-existing dev.chime.meridian -- -inMemoryStore -welcomeDone NO
# All checks (foreground, alone):
node "/Users/chimexd/.claude/plugins/cache/proof/proof/0.4.0/scripts/gate.mjs" --run
# Narrow tests: never -quiet; grep the result lines
xcodebuild -scheme Meridian -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' test -only-testing:MeridianTests/WelcomeWallTests 2>&1 | grep -E "✘|Test run with|error:"
# Re-render widget/Live Activity art-hole PNGs, then copy fidelity/shots/{widgets,live-activity} into design-system/assets/
xcodebuild -scheme Meridian -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' test -only-testing:MeridianTests/WidgetRenderTests -only-testing:MeridianTests/LiveActivityLayoutTests
# Design system: deploys itself on push; check status with
npx vercel@latest ls meridian-design-system
# Debug launch options: -designPreview [detail], -fakeActivity <minutes>, -follow <ids>, -followAnime <ids>,
#   -tab search|settings, -query <text>, -kind anime, -inMemoryStore, -welcomeDone NO, -openFirstResult YES
```

- **Simulator:** `iPhone 18 Pro, OS=27.0` (UDID <simulator-udid>). Shut it down after use.
- **Scratchpad:** the scratchpad of session `7d0987d9…` holds the reference pick pages, QA and UX reports, and the Playwright scripts (`pw-unslop.3vSP/`). `claude --resume` in this folder reopens the full transcript.

## Session of Tue 3 Nov 2026: the demo video (Phase 7)

**Where it stands:** the compositions are built and checked with simulator footage. Rendering waits for Chime's iPhone recording.

**Shipped in the app** (`f3fdfa8`, pushed, installed on the phone)
- Settings › Debug › **"Live Activity for <show> in 3 min (lead 1 min)"** copies the soonest followed episode with a time (show, episode, network, art) to a fake drop 3 minutes away. Its ID starts `debug:fake:`.
- Fixes from the review:
  - Show detail opens on the episode tapped, not the copy (`UpcomingTab.current` matches by ID first).
  - `RootView.syncActivities` never books a copy.
  - A stale copy can't come back from the last snapshot after an offline relaunch.
- `MeridianUITests/DemoRecordingTests` scripts a simulator recording of the plain "Debug Show". It runs only with `TEST_RUNNER_MERIDIAN_DEMO=1`, so CI and the screen checks skip it. To record:
  1. Build with `xcodebuild build-for-testing -scheme MeridianFidelity -derivedDataPath build/demo`.
  2. Start `xcrun simctl io <sim> recordVideo --codec=h264 --force take.mov`.
  3. Run `test-without-building -xctestrun build/demo/Build/Products/MeridianFidelity_*.xctestrun -only-testing:MeridianUITests/DemoRecordingTests`.
  4. Stop the recording with SIGINT.
- The simulator take (`take1`) wasn't usable as the final cut:
  - placeholder show with no art
  - the "Allow Live Activities?" prompt on the Lock Screen
  - test app icons on the Home Screen
  - "Carrier" in the status bar
  - 0:00 rather than "Out now" within 30 s
- So Chime chose to record on the iPhone.

**Phone shot list** (Do Not Disturb on, Live Activities on, a clean Home Screen page)
1. Debug › "Live Activity for <show>…". The island appears 2 minutes later.
2. Start Screen Recording at about 1:45, mic off.
3. Island ticking on the Home Screen, about 5 s.
4. Press and hold to expand, about 5 s.
5. Pull down from the top left for the Lock Screen banner, about 5 s.
6. Stay through 0:00 for "Out now". If it's still 0:00 after about 10 s, open Meridian for a second; that bit gets cut.
7. Expand again on "Out now", then stop.
8. AirDrop the file to the Mac.

**The video project:** `~/Projects/Personal Projects/Meridian Video/`
- It's local git only; footage and renders are git-ignored.
- `build.mjs` writes `square/index.html` (1080×1080) and `vertical/index.html` (1080×1920) from one `CUTS` list (seconds into the footage) and the footage size.
- It's a silent loop like the dahnizzy.com reference: the phone in a near-black frame with a thin rim, on a `#f4f4f2` card.
- To swap in the phone footage:
  1. Copy it to `footage/`.
  2. Point `square/assets/footage.mov` and `vertical/assets/footage.mov` at it (symlinks today).
  3. Set `FOOTAGE` width and height and pick new `CUTS`: `scratchpad/scripts/timesheet.swift` makes a labelled frame grid.
  4. Run `node build.mjs`.
  5. In each folder, run `npx hyperframes check --json` and `npx hyperframes snapshot --at …`, then `npx hyperframes render` once Chime approves the frames.
- Checked with the stand-in footage: lint and layout pass. The only warning is `film_silent`, which is intended.
- Tooling: HyperFrames CLI 0.9.8 via npx, with telemetry disabled. ffmpeg comes from Homebrew; snapshots and renders need it.

**Open for Chime** (resolved 4 Nov)
- The recording: done with QuickTime on the Mac.
- The card: near-black (`#0d0d0e`), to match the portfolio.

**Next**
1. Render both videos and review the frames.
2. Then the portfolio case study at chimexd.work. Read its CONTENT.md and the two MDX case studies first, and never open `.env.local`.
3. Reinstall on the phone before Mon 9 Nov 00:59 Lagos.
