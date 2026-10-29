# Progress

Build log for the one-week plan (`docs/PLAN.md`). Newest entry first.

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
