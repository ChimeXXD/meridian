# Progress

Build log for the one-week plan (`docs/PLAN.md`). Newest entry first.

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
