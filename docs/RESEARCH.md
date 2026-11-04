# Research update (26 Oct 2026)

This builds on the original PRD (`★ Next Episode.md`). Each item was checked against primary pages or live API calls on 26 Oct 2026. **Bold** marks a change to the PRD.

## What changed since the PRD

1. **The Live Activity gap has closed.** Two indie apps launched in July 2026 with release-night countdowns:
   - **Up Next** ([App Store](https://apps.apple.com/us/app/up-next-tv-show-tracker/id6786803491)) is a free TV tracker with no account. It has a Dynamic Island countdown, Lock Screen, Home and StandBy widgets, and time zone–correct reminders. It is rated 4.6 from 39 ratings, and one reviewer asks for where-to-watch.
   - **Rexy** ([App Store](https://apps.apple.com/us/app/rexy-anime-tracker-schedule/id6780322886)) covers anime only. Its Dynamic Island and Lock Screen countdown is a subscriber feature with Now and Aired states. When sources disagree, it picks the air time most of them agree on.
   - **What's left for us:** honest exact times outside the US, TV and anime in one app, where to watch, and open source.
2. **Showmax shut down on 30 Apr 2026.** Selected originals moved to DStv Stream and DStv/GOtv. ([Legit.ng](https://www.legit.ng/business-economy/industry/1704114-multichoice-finds-home-showmax-contents-announces-date-final-app-closure/)) JustWatch Nigeria lists Netflix, Prime Video, Crunchyroll and IROKOTV. ([JustWatch NG](https://justwatch.com/ng))
3. **TVmaze `airstamp` is a placeholder whenever `airtime` is empty.** That means 12:00 UTC for global web channels such as Netflix and Apple TV (Widow's Bay showed `2026-04-29T12:00:00+00:00`), and noon in the channel's own zone for local ones. Only shows with an airtime (HBO's `21:00`) are exact. Platform rules are therefore essential, not optional. ([live API](https://api.tvmaze.com/singlesearch/shows?q=silo&embed=nextepisode))
4. **Most of Chime's shows have nothing scheduled.** Euphoria ended on 31 May 2026. Silo S4E1 shows `2027-07-09` (placeholder). HotD, FROM, Lioness and Widow's Bay have no next episode. The empty state and a debug fake-drop mode are first-class needs.
5. **Prime Video drops at 12am PT, not midnight UTC.** Apple TV, renamed from Apple TV+, drops at 9pm ET the evening before its listed date. ([TechRadar](https://www.techradar.com/streaming/amazon-prime-video/what-is-the-release-date-for-the-boys-season-5-episode-3-on-prime-video), [TVLine](https://tvline.com/2239636/ted-lasso-season-4-release-schedule-new-episodes-apple-tv))
6. **Apple publishes no cap on simultaneous Live Activities.** Scheduled ones count toward the limit, so catch errors. ([Apple](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities))
7. **AniList is free only under $150/month revenue.** Above that it needs a licence. It also bans bulk collection. ([AniList terms](https://docs.anilist.co/guide/terms-of-use))
8. **TVmaze `externals` has no TMDB id**, only tvrage, thetvdb and imdb. Map through TMDB `/3/find`. ([TMDB find](https://developer.themoviedb.org/reference/find-by-id))
9. **TV Time successor:** co-founder Antonio Pinto launched **Bingers** on 4 Aug 2026. It is social, on-device, with no paid tier. JustWatch shipped a TV Time importer. Users moved to Trakt, Simkl, Serializd, Sofa Time and Showline. ([TechCrunch](https://techcrunch.com/2026/08/04/tv-time-co-founder-launches-bingers-to-revive-the-beloved-tv-tracking-app/), [9to5Mac](https://9to5mac.com/2026/07/09/as-tv-time-prepares-to-shut-down-justwatch-launches-migration-tool/), [MacRumors](https://macrumors.com/2026/07/02/show-tracking-app-tv-time-shutting-down))

## Platform facts (Apple)

| Fact | Value | Source |
| --- | --- | --- |
| Scheduled Live Activity | `Activity.request(attributes:content:pushType:style:alertConfiguration:start:)`, **iOS 26.0+**. `AlertConfiguration` is required. Works with `pushType: nil`. The call must be made in the foreground or from a `LiveActivityIntent`. | [Apple symbol](https://developer.apple.com/documentation/activitykit/activity/request(attributes:content:pushtype:style:alertconfiguration:start:)) |
| Duration | Up to 8 h active, then up to 4 h more on the Lock Screen (12 h total) | [Apple guide](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities) |
| Payload | 4 KB covering static and dynamic data | same |
| Network | A Live Activity can't access the network | same |
| `.after(date)` dismissal | Capped at 4 h after the activity ends | same |
| Widget budget | About 40–70 reloads a day. Entries at least 5 minutes apart. StandBy and foreground reloads don't count toward the budget. | [Apple](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date) |
| Timer text | `.timer` counts **up** after the date passes. Use `Text(timerInterval:pauseTime:countsDown:)`. | [Apple](https://developer.apple.com/documentation/widgetkit/displaying-dynamic-dates) |
| Liquid Glass | Clear and tinted Home Screens render widgets in accented mode. Check `widgetRenderingMode`. | [WWDC25 278](https://developer.apple.com/videos/play/wwdc2025/278) |
| iOS 26 extras | Live Activities appear in the macOS Tahoe menu bar. CarPlay and Watch Smart Stack use `.supplementalActivityFamilies([.small])`. | same |
| iOS 27 (WWDC26) | Compact Dynamic Island in landscape (`isDynamicIslandLimitedInWidth`). StandBy scales the Lock Screen view to 200%. New widget family `systemExtraLargePortrait`. | [WWDC26 223](https://developer.apple.com/videos/play/wwdc2026/223), [277](https://developer.apple.com/videos/play/wwdc2026/277) |
| Adoption | iOS 26 was on 79% of iPhones by June 2026 | [iPhoneItalia](https://www.iphoneitalia.com/?p=847870) |
| Free provisioning | 3 apps per device, 7-day expiry. App Groups on free accounts: unconfirmed. | [Apple](https://developer.apple.com/support/compare-memberships/) |

## Tooling for Claude CLI

- **Xcode 26.3+** can give external agents access to its tools: Settings › Intelligence › "Allow external agents to use Xcode tools", then `claude mcp add --transport stdio xcode -- xcrun mcpbridge`. ([Apple](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode))
- **Xcode 27** adds built-in coding agents that can use the model you choose. ([Apple](https://developer.apple.com/xcode/whats-new/))
- **XcodeBuildMCP**, now owned by Sentry: `claude mcp add XcodeBuildMCP -- npx -y xcodebuildmcp@latest mcp`. Tools include `build_run_sim`, `test_sim` and `screenshot`. ([guide](https://mcp.directory/blog/xcodebuildmcp-complete-guide-2026))
- **XcodeGen**: `project.yml` → `.xcodeproj`. ([GitHub](https://github.com/yonaskolb/XcodeGen))

## Data sources

| Source | Licence and cost | Limit | Use |
| --- | --- | --- | --- |
| [TVmaze](https://www.tvmaze.com/api) | CC BY-SA 4.0, any use with credit | 20 calls / 10 s per IP; responses cached 60 min | TV shows, episodes, network and web channel |
| [AniList](https://docs.anilist.co/guide/rate-limiting) | Free under $150/month revenue | 90/min (30 degraded) | Anime `nextAiringEpisode`, `airingSchedule` |
| [TMDB](https://developer.themoviedb.org/docs/faq) | Non-commercial only; a commercial licence is needed for a paid tier | about 40/s | Later: watch providers (credit JustWatch) |
| [TheTVDB v4](https://github.com/thetvdb/v4-api) | No free tier | — | Not used |

## Release-time rules (sources)

- Netflix originals: 00:00 PT, which is 08:00 Lagos during US summer time. ([What's on Netflix](https://whats-on-netflix.com/news/what-time-does-netflix-release-movies-and-tv-series))
- Prime Video: 00:00 PT. ([TechRadar](https://www.techradar.com/streaming/amazon-prime-video/what-is-the-release-date-for-the-boys-season-5-episode-3-on-prime-video))
- Apple TV: 21:00 ET the evening before. ([TVLine](https://tvline.com/2239636/ted-lasso-season-4-release-schedule-new-episodes-apple-tv))
- Disney+: 18:00 PT. Needs verifying (O-2). ([SuperHeroHype](https://www.superherohype.com/?p=660775))
- HBO: Sunday 21:00 ET. HBO Max sometimes drops early. ([Tom's Guide](https://www.tomsguide.com/entertainment/hbo-max/hbo-max-just-moved-up-the-release-date-of-a-knight-of-the-seven-kingdoms-and-industry-to-avoid-super-bowl-2026))
- Crunchyroll: no fixed offset found. Use the AniList JST broadcast plus a per-show offset (O-1).

## Demand signals

- "If you're outside the US, you've probably noticed some shows appear in your Upcoming/Latest lists a day early (or late)." ([Emby, Aug 2026](https://emby.media/community/topic/148586-trakt-air-dates-%E2%80%94-outside-the-us-fixes-us-shows-landing-on-the-wrong-day/))
- "TMDB stores those broadcast dates as a bare date with no time or timezone." (same thread)
- A countdown builder was told local time zone handling "needs to be bulletproof". ([r/webdev mirror](https://supabase.com/contribute/t/860-66969-11493-reddit_post_1t0ztlw))
- "a little off at the beginning of a season (like every other app)" (MeronPan review). ([App Store](https://apps.apple.com/app/id6745256779))
- Gap: Reddit was blocked from the research tools. The Reddit and X scan stays in the launch backlog.

## Name check

- **Meridian:** no App Store or brand match found. **Recommended.**
- **Drop Night:** no tracker found, but the "Drop" space is crowded.
- **Episode Clock:** free, but descriptive and weak as a trademark.
- **Taken:** Next Drop (a sneaker app), Airtime (many apps), Dropclock (a Mac screensaver).
- Domain and USPTO/EUIPO checks are still to do (O-3).

## Portfolio lessons

- Flighty's Live Activity advice: be "boringly obvious", design for losing connectivity, and borrow real-world conventions. ([Apple Developer](https://developer.apple.com/news/?id=970ncww4))
- Tide Guide, a single-purpose glance app with Live Activities, widgets and complications, won a 2026 Apple Design Award. ([Apple Newsroom](https://apple.com/newsroom/2026/06/apple-reveals-winners-of-the-2026-apple-design-awards/))

---

# Research update (29 Oct 2026)

Three research passes ran on 29 Oct 2026: competitors and users, Apple platform and APIs, and release rules plus Nigeria. Claims are **Verified** (with a source) unless marked *Inferred*. Reddit was blocked from the research tools again. The user voices below come from 2,150 App Store reviews across 11 storefronts (NG, GB, IN, ZA and others) pulled through Apple's public review feed, plus TVmaze forum threads.

## Competitors (Oct 2026)

| App | Price | Live Activity | Time zone | Import |
| --- | --- | --- | --- | --- |
| [Up Next](https://apps.apple.com/us/app/id6786803491) | Free | Yes, countdown in the Dynamic Island | "timezone-correct" reminders | TV Time, Trakt, Simkl |
| [Rexy](https://apps.apple.com/us/app/id6780322886) (anime) | $9.99/yr, $29.99 lifetime | Paid tier only | Local zone | Paid tier |
| [Kiroku](https://apps.apple.com/us/app/id6752566277) (AniList/MAL) | $24.99 lifetime | Lock Screen countdown | Not stated | Not stated |
| [Sofa Time](https://apps.apple.com/us/app/id1491037404) | $9.99 lifetime, $14.99/yr | No | Not stated | TV Time GDPR, Bingers |
| [Sequel](https://apps.apple.com/us/app/id1630746993) | Up to $99.99 lifetime | No | Fixed a "wrong in some time zones" bug in 2.7.2–2.7.3 | TV Time |
| [Showline](https://apps.apple.com/us/app/id6596766307) | $14.99/yr, $79.99 lifetime | No | Global air-time adjustment setting | TV Time |
| [Trakt](https://apps.apple.com/us/app/id1514873602) | $59.99/yr | Check-ins only | Reviews say 1–2 h off | TV Time |
| Bingers ([TechCrunch](https://techcrunch.com/2026/08/04/tv-time-co-founder-launches-bingers-to-revive-the-beloved-tv-tracking-app/)) | Free, account | No | n/a | TV Time |

**What follows:** the Live Activity countdown is a must-have, not something that sets us apart. No competitor shows where a time came from (D-17). Pricing anchors are about $10–15/yr and $25–30 lifetime (D-26). Apple's iOS 27 TV app added auto-downloads, not an upcoming-episode widget ([9to5Mac](https://9to5mac.com/2026/07/20/ios-27-beta-4-adds-a-useful-apple-tv-app-feature-heres-how-it-works/)).

## User voices (App Store reviews and the TVmaze forum)

- "cannot get the scheduled show times right. It is always 1-2 hours off." Trakt, 22 Oct 2026
- "the time the show comes out is wrong or just says 12am as a placeholder." Trakt, 9 Jul 2026
- "The widgets don't update until I go into the app… defeats the purpose." Sofa, 27 Sep 2026
- "keeps telling me when shows are on in US… even though my setting is set to local time." Next Episode (GB)
- "Episodes from Amazon Prime… should appear at midnight in Paris but show at 14:00." [TVmaze forum](https://www.tvmaze.com/threads/4440/calendar-and-watchlist-wrong-hour-for-streaming-episodes)
- TVmaze staff on streamer times: "we have no quick fix in place right now." [TVmaze forum](https://www.tvmaze.com/threads/5862/ahsoka-disney-wrong-time)
- "no subscription… $1 a month, or $5 a year." Sofa, 13 Oct 2026 (willingness to pay)

## Release rules, re-verified

| Platform | Rule | Confidence | Examples |
| --- | --- | --- | --- |
| Netflix | 00:00 America/Los_Angeles, listed date. **Event drops at 17:00 PT** | High | Wednesday S2 Pt 2 ([soapcentral](https://www.soapcentral.com/shows/when-will-wednesday-season-2-part-2-dropped-netflix-release-timings-different-regions-explored)); Stranger Things 5 at 17:00 PT ([NBC NY](https://www.nbcnewyork.com/entertainment/entertainment-news/what-time-stranger-things-season-5-netflix/6423120/)) |
| Prime Video | 00:00 PT, listed date. Premieres sometimes move earlier | Medium–high | The Boys S5, Reacher S4; Fallout S2 moved to 16 Dec 2025 at 18:00 PT ([Bloody Disgusting](https://bloody-disgusting.com/tv/3921877/fallout-season-2-delivers-holiday-surprise-with-early-release-date/)) |
| Apple TV | 21:00 America/New_York, listed date − 1 | High | Severance S2E10 ([TechRadar](https://www.techradar.com/streaming/apple-tv-plus/what-time-is-severance-season-2-episode-10-going-to-be-released-on-apple-tv)); Pluribus ([TheWrap](https://www.thewrap.com/?p=7880659)) |
| Disney+ | Marvel live action 18:00 PT; other shows 00:00 PT | Medium | Daredevil: Born Again S2, Wonder Man; Maul at 00:00 PT |
| HBO / HBO Max | Use TVmaze `airtime`. The slot is 21:00 **or 22:00** ET | High | HotD S3 at 21:00; A Knight of the Seven Kingdoms ep 2 at 22:00 |
| Paramount+ | 03:00 America/New_York (= 00:00 PT) | Medium | Landman S2 eps 1–2 ([Newsweek](https://newsweek.com/entertainment/tv/landman-season-2-episode-2-release-date-how-to-watch-11064092)) |
| Peacock, Hulu | No single rule → `dateOnly` | Low | Peacock 03:01 ET originals; The Bear S5 at 18:00 PT |
| Crunchyroll | Fixed UTC time per title, offset from the JST broadcast | Medium | JJK S3E11: "1 h later" on US clocks only ([Outlook Respawn](https://respawn.outlookindia.com/pop-culture/pop-culture-news/jujutsu-kaisen-season-3-episode-11-delay-and-new-release-time)) |

- **The TVmaze placeholder is noon in the channel's country time zone**, not always 12:00 UTC. Netflix shows `12:00Z`, while Peacock and Hulu show `16:00Z` (`17:00Z` after 1 Nov). Detect it by `airtime == ""` only (D-25). Verified with live `/schedule/web` calls, 28–30 Oct 2026.
- *Inferred:* global releases are simultaneous. UK times match 00:00 PT and 21:00 ET exactly, and we found no Africa-specific offset.
- Lagos after 1 Nov 2026 (arithmetic): Netflix, Prime and Paramount+ move to 09:00 WAT; Apple TV and HBO's 21:00 ET slot move to 03:00 WAT; HBO's 22:00 ET slot moves to 04:00 WAT.

## Nigeria

- Showmax closed on 30 Apr 2026, and its content moved to DStv Stream. **HBO and Warner Bros. content left in January 2026** ([Wikipedia](https://en.wikipedia.org/wiki/Showmax)). We found no HBO Max launch in Nigeria (O-7).
- Disney+ runs in only six African countries, and Nigeria isn't one of them ([Techpoint](https://techpoint.africa/insight/disney-iwaju-premiere/)).
- *Inferred:* Netflix, Prime Video, Apple TV and Crunchyroll are available. We found no reliable data on the size of the anime audience in Nigeria.

## Apple platform and App Store

- Scheduled activity API: `request(attributes:content:pushType:style:alertConfiguration:start:)`, iOS 26.0+. `startDate:` exists only on 26.0. Activities start even in the background, but the request must come from the foreground or a `LiveActivityIntent`. **Scheduled activities count toward an unpublished simultaneous limit** ([Apple](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)).
- iOS 27 adds Dynamic Island compact views in landscape, the `isDynamicIslandLimitedInWidth` environment value (iPhone Duo, landscape, two activities), the `systemExtraLargePortrait` widget family, and Live Activities in CarPlay, the Mac menu bar and the Watch Smart Stack via `.supplementalActivityFamilies([.small])` ([WWDC26 223](https://developer.apple.com/videos/play/wwdc2026/223), [277](https://developer.apple.com/videos/play/wwdc2026/277)).
- Uploads have needed the iOS 26 SDK since 28 Apr 2026, and **will need the iOS 27 SDK from April 2027** ([Apple news](https://developer.apple.com/news/upcoming-requirements/)).
- Guideline 4.5.3 (June 2026): no spam through Live Activities. New guidelines 2.3.14 and 2.5.19 (Oct 2026). New age ratings 13+, 16+ and 18+.
- Privacy manifest reasons: UserDefaults `CA92.1` (the app's own defaults) and `1C8F.1` (the App Group suite). File timestamps `C617.1`, only if the app reads them.
- **App Groups work on free provisioning** ([Apple capabilities table](https://developer.apple.com/help/account/reference/supported-capabilities-ios)). TestFlight still needs the paid program.
- Widgets get about 40–70 reloads a day. `Text(timerInterval:pauseTime:countsDown:)` ticks without any reload. `BGAppRefreshTask` has no frequency guarantee (*Inferred:* hours apart, and never after a force-quit).

## Data sources

- **AniList:** the API is "currently in a degraded state… limited to 30 requests per minute", and rate-limit increases aren't being granted ([docs](https://docs.anilist.co/guide/rate-limiting)). The terms ban "competing, non-complementary… anime and manga list or tracker services" ([terms](https://docs.anilist.co/guide/terms-of-use)). *Inferred:* it's unclear whether Meridian counts as one. Ask AniList (O-5, D-19).
- **TVmaze:** no changes in 2026. TVmaze shipped its own TV Time importer on 2 Jul 2026 ([blog](https://www.tvmaze.com/blogs/63/the-tv-time-importer-is-now-available)).
- **TMDB:** the basic licence allows no commercial use. Its logo must be less prominent than ours, cached data can be kept 6 months at most, and watch-provider data needs JustWatch credit ([terms](https://www.themoviedb.org/api-terms-of-use)).
- **TV Time export (for a later importer):** a zip holding `tracking-prod-records-v2.csv` with columns `s_id` (TVDB), `s_no`, `ep_no`, `episode_id`/`ep_id`. Column names vary between exports ([watchd](https://watchd.pro/articles/tv-time-export-files/), [seriesly](https://seriesly.tv/guide/tv-time-export/)).

## Tooling

- XcodeBuildMCP is now published as `mobilebuildmcp` (npm 2.7.1, checked 29 Oct). `xcodebuildmcp` 2.7.0 still installs.
- Reference search works.

## Network logos (1 Nov 2026)

- **Source:** Wikimedia Commons. `rules/network-logos.json` holds only URLs and licence data. The app loads each logo at runtime, so no artwork is committed (rule 9).
- **Names:** every `names` string is the exact TVmaze `network.name` / `webChannel.name`, read from the TVmaze API through a known show on that network (for example `singlesearch/shows?q=Severance` gives `Apple TV`). TVmaze names worth knowing: HBO Max is `HBO Max` (webchannel 329), and there is no `Max`. Showtime appears as `Paramount+ with Showtime` (network 9) and `Showtime on Demand` (webchannel 315). ITV is `ITV1`. Sky's UK originals mostly sit on the `Now` webchannel; Sky names in use are `Sky One`, `Sky Atlantic` and `Sky Go`. `History` exists as both a US (53) and a Canadian (118) network.
- **Licences:** each file's licence came from the Commons API (`prop=imageinfo&iiprop=extmetadata`: `LicenseShortName`, `AttributionRequired`, `Artist`) and its licence templates (`prop=templates`). It was not taken from memory. Only public domain, CC0, CC BY and CC BY-SA files were accepted. 54 files are `PD-textlogo`. Three need credit, which goes in `attribution` and on the Credits screen: AMC+ (CC BY-SA 4.0), Hallmark Channel (CC BY 4.0) and BBC iPlayer (CC BY-SA 4.0).
- **Image:** `image` is the Commons 120 px wide PNG thumbnail. All 57 URLs returned `200 image/png` with a descriptive User-Agent. Each logo was checked by eye on a white rounded tile at full size and at 20 px tall, and the version that reads on white was chosen (for example purple Tubi over yellow, and pink Freeform over lime).
- **Count:** 57 entries (58 TVmaze names) cover 54 of the 55 requested networks. **Skipped:** ITVX, because the only logo is a local non-free file on English Wikipedia and Commons has no free file. Names seen in TVmaze but not mapped yet: `Now` (Sky's streaming service), `ITV2` and `BBC Three`.
