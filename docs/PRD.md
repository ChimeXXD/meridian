> **★ Really like** — one of Chime's starred picks. In-depth PRD: research, competitors, build phases and a full checklist.
>
> **Timelines updated 25 Oct 2026:** durations assume building with an AI coding agent on focused days. Real-world testing, design polish and App Store review still set the pace.

# Next Episode

Next Episode is a local-first iPhone app that puts a live countdown to your next episode on the Lock Screen and Dynamic Island, in your own time zone, with where to watch it. It is worth building now because TV Time, the largest free tracker, shut down on 15 July 2026, and no major tracker we checked ships a release-night Live Activity.

## Summary

People who follow weekly shows and simulcast anime still guess at release times, especially outside the US. Netflix drops at midnight Pacific, Crunchyroll shifts by an hour when the US changes clocks, and a viewer in Lagos has to do the maths. Next Episode answers one question at a glance: how long until my next episode, and where do I watch it here. It uses TVmaze and AniList schedules, WidgetKit countdowns, and a scheduled Live Activity on release night, with no account and no server. For Chime it is a sharp portfolio piece in typography, system surfaces and data honesty, with a small paid tier as a later option.

## Problem and audience

**Who.** Viewers who follow 5 to 15 weekly series and simulcast anime, live outside the US release zone, and check their phone before bed. Chime is the archetype: Lagos (UTC+1), following Euphoria, Silo, House of the Dragon, From, Special Ops: Lioness, Widow's Bay and Kuroko's Basketball.

**When.** Three moments matter:

- **The night before.** "Is it out tonight or tomorrow morning here?"
- **Release hour.** The episode lands while the person is on their phone doing something else.
- **Quiet weeks.** Mid-season breaks and finales leave people unsure whether anything is coming.

**Evidence.**

- Release times are tied to the platform's home zone. Netflix originals drop at midnight Pacific, which is 8am in the UK and 9am in mainland Europe. Licensed titles drop at midnight local time instead ([Woman & Home](https://www.womanandhome.com/life/news-entertainment/what-time-does-netflix-release-new-episodes/)).
- Anime simulcasts move when the US changes clocks. Jujutsu Kaisen season 3 episode 11 shifted one hour later on Crunchyroll because Japan does not observe daylight saving. The press had to publish a per-zone table, and the Indian time was still "not confirmed" ([Outlook Respawn](https://respawn.outlookindia.com/amp/story/pop-culture/pop-culture-news/jujutsu-kaisen-season-3-episode-11-delay-and-new-release-time)).
- TV Time had 26.4 million lifetime installs and was still gaining about 29,000 downloads a month when it closed on 15 July 2026 ([TechCrunch](https://techcrunch.com/2026/07/02/popular-tv-tracking-app-tv-time-is-shutting-down-as-company-focuses-on-ai)). Its upcoming-episode reminders, with alerts an hour before airing, were a core feature ([Wikipedia](https://en.wikipedia.org/wiki/TV_Time)).
- Other trackers keep closing. Marathon TV shut down in March 2026, and its users moved to Trakt ([Tom's Guide](https://www.tomsguide.com/entertainment/streaming/my-favorite-streaming-app-shut-down-today-heres-what-im-using-instead)).
- Regional catalogues differ. Showmax carries House of the Dragon in Nigeria with "new episodes weekly", but publishes no drop time ([Showmax Stories](https://stories.showmax.com/ng/house-of-the-dragon-now-available-to-stream-on-showmax-in-nigeria)).
- Gap in this research: Reddit threads asking for countdown widgets did not surface in search, and none were opened. Run a Reddit and X scan before launch (see checklist).

## Research findings

- **TV Time is gone.** It stopped on 15 July 2026. Whip Media said a free app was "no longer sustainable" and paid demand was too low ([TechCrunch](https://techcrunch.com/2026/07/02/popular-tv-tracking-app-tv-time-is-shutting-down-as-company-focuses-on-ai)). Lesson: a free app that needs servers dies; a local-first app with near-zero running cost does not.
- **Trakt doubled VIP from $30 to $60 a year** and capped free users at 2 lists of 100 items and 100 watchlist items ([AlternativeTo](https://alternativeto.net/news/2025/2/trakt-tv-has-set-stricter-limits-for-free-users-and-raised-vip-subscription-prices-by-100-/)). Apps built on Trakt inherit that cost.
- **No leading tracker lists Live Activities.** Next Episode (next-episode.net), Sequel, Serializd, Hobi, TV Next and ShowCal mention widgets or none at all. Sofa uses the Dynamic Island only for its session timer ([App Store listings](https://apps.apple.com/app/id347009526)).
- **Live Activities last 8 hours active, 12 hours on the Lock Screen.** The Dynamic Island drops them at 8 hours ([Apple Developer Forums](https://developer.apple.com/forums/thread/797676)).
- **Live Activities can be scheduled for a date without a server.** `request(...startDate:)` needs an `AlertConfiguration`. Payloads cap at 4 KB. Scheduled activities count towards the simultaneous limit ([Apple ActivityKit docs](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities.md)).
- **Widgets get 40 to 70 refreshes a day,** roughly every 15 to 60 minutes. Timeline entries should be at least 5 minutes apart. Countdown text updates live without a reload. StandBy refreshes do not count against the budget ([Apple WidgetKit docs](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date.md)).
- **TVmaze is CC BY-SA 4.0,** usable "for any purpose" with credit and ShareAlike. The limit is at least 20 calls per 10 seconds per IP. `/schedule/web` covers streaming drops; `/schedule/full` holds all future episodes ([TVmaze API](https://www.tvmaze.com/api)).
- **TMDB is free only for non-commercial use.** Commercial use needs a licence. Attribution must sit in About or Credits with the line "This product uses the TMDB API but is not endorsed or certified by TMDB" ([TMDB FAQ](https://developer.themoviedb.org/docs/faq)).
- **TMDB watch-provider data must be credited to JustWatch,** and TMDB may revoke access for misuse ([FileBot forum](https://www.filebot.net/forums/viewtopic.php?p=64177)).
- **JustWatch's own API bans commercial use** and works only with larger partners ([dewey/api readme](https://github.com/dewey/api)).
- **AniList allows 90 requests a minute,** dropping to 30 when degraded. It warns App Store apps that ecchi titles are not flagged as adult ([rate limiting](https://docs.anilist.co/guide/rate-limiting), [considerations](https://docs.anilist.co/guide/considerations)).
- **Price anchors:** Next Episode Pro $4.99, Premium $24.99. Sofa $49.99 a year or $249.99 lifetime. Sequel+ lifetime $99.99. Hobi up to $34.99. ShowCal lifetime $59.99.

## Competitors

### Hard competitors

| Product | What it does | Price | Strengths | Gaps |
| --- | --- | --- | --- | --- |
| [Next Episode](https://apps.apple.com/app/id347009526) (next-episode.net) | Tracks shows and films, countdowns, alert 15 minutes before airtime, calendar export | Free; Pro $4.99, Premium $24.99 | 4.8 from 2.5K ratings; imports from Trakt and TV Time; streaming availability | Needs sign-in; no Live Activities listed; owns the "Next Episode" name |
| [TV Time](https://techcrunch.com/2026/07/02/popular-tv-tracking-app-tv-time-is-shutting-down-as-company-focuses-on-ai) | Social tracker with episode reminders | Was free | 26.4M installs, big community | Shut down 15 July 2026 |
| [Trakt](https://alternativeto.net/news/2025/2/trakt-tv-has-set-stricter-limits-for-free-users-and-raised-vip-subscription-prices-by-100-/) | Sync backbone for many apps | Free with caps; VIP $60/yr | Huge catalogue, scrobbling, ecosystem | Free tier capped at 100 items; doubled price; account required |
| [Sequel](https://apps.apple.com/app/1630746993) | Media wishlist for TV, film, books, games with Trakt sync | Free; Sequel+ lifetime $99.99 | Polished; countdown, Upcoming and Out Now widgets | Broad scope; no Live Activities; time zone and region not a focus |
| [Sofa](https://apps.apple.com/us/app/sofa-downtime-organizer/id1276554886) | Downtime organiser; episodes appear on a Planner timeline | Free (2 items); $49.99/yr or $249.99 lifetime | Beautiful, iCloud sync, Lock Screen widgets | Release countdown is a side feature; Dynamic Island used only for session timer |
| [Serializd](https://apps.apple.com/us/app/-/id1581244120) | "Letterboxd for TV": log, rate, review, reminders | Free | 4.6 from 2.1K ratings; social | Reviews cite crashes and slow loads; widgets basic; no Live Activities |
| [Hobi](https://apps.apple.com/us/app/id1387915223) | Tracker with next-episode countdown and Trakt sync | Free; Premium $0.99 to $34.99 | Countdown in app; premiere alerts | No widgets or Live Activities listed |
| [Showly](https://github.com/trakt/showly) | Open-source Trakt-based tracker, iOS since January 2025 | Free | GPL-3.0, 1.5K GitHub stars | Codebase "grew a bit rusty"; tied to Trakt |
| [TV Next](https://apps.apple.com/ca/app/tv-next/id6757971087) | Simple tracker, iPhone and Watch, no tracking | Free; tips $0.99 to $12.99 | Next-episode widget with mark-watched; Watch complications | 1 rating; no Live Activities; no region data |
| [ShowCal](https://apps.apple.com/us/app/track-tv-movies-showcal/id6499238562) | Calendar tracker with AI "Show Buddy", Plex and Jellyfin | Free; Pro up to $59.99 lifetime | Trakt sync, TV Time import, where-to-watch | No widgets, Live Activities or time zone features listed |
| [MeronPan](https://apps.apple.com/app/id6745256779) | Anime release calendar with notifications | Free with ads; donations | Simulcast platforms per title | 1 rating; no widgets or time zone control listed |
| [AniChart](https://alternativeto.net/software/anichart/) / [LiveChart](https://www.livechart.me/anime/11911/schedules/13887) | Web seasonal anime charts with countdowns and Crunchyroll times | Free | Best anime schedule data | Web only; not on the Lock Screen |

### Soft competitors

| Substitute | Why people use it | Where it fails |
| --- | --- | --- |
| Google "when does X come out" | Instant, free, no install | Answers in US time; SEO pages contradict each other |
| Entertainment news articles | Per-zone tables on big release nights | Only for hit shows; often "not confirmed" for Africa and India |
| Streaming apps' "Remind me" | Built into Netflix, Prime, Showmax | One service per app; no cross-service view; no countdown |
| Calendar reminders | Reliable and on every device | Manual entry; breaks on delays and clock changes |
| Reddit episode threads and X accounts | Community confirms the drop in real time | You must already be looking; noisy; spoilers |
| Trakt calendar plus a client | Power users already sync there | Account, capped free tier, $60/yr VIP |

**The opening.** Every tracker treats the release time as a line of text inside the app. None we checked turns release night into a system event with a Live Activity, a StandBy clock and a region-aware "watch on" label. TV Time's closure frees millions of users, and a local-first app avoids the server costs that killed it.

## Brainstorm

- **Typographic countdown widgets.** One huge numeral ("2d 14h") with the show title set small. Variants for Lock Screen circular, rectangular and inline.
- **Release-night Live Activity.** Scheduled with `startDate` 2 to 6 hours before the drop. Dynamic Island shows a live timer, then flips to "Out now on Showmax".
- **StandBy "drop clock".** Full-screen countdown on the bedside phone, refreshed outside the widget budget.
- **Drop Day mode.** Whole-season releases get a binge view: episode count, total runtime, and "finish by" if you start now.
- **Simulcast translator.** Show the JST broadcast and the Crunchyroll time side by side, both in your zone, with a note when US clock changes shift it.
- **"Your time" honesty label.** Every time carries a source chip: "TVmaze airstamp", "Netflix midnight PT rule" or "estimated".
- **Nothing new this week.** A calm empty state that names the next real date ("Silo returns in 23 days") instead of a blank widget.
- **Region-aware "watch on".** Provider by country from TMDB/JustWatch data, so Lagos sees Showmax for House of the Dragon, not HBO Max.
- **Apple Watch complication.** The nearest drop as a corner or circular countdown.
- **Calendar export.** One-tap ICS feed or EventKit events, updated when dates move.
- **Delay detection.** Diff the schedule each refresh. If an airstamp moves, update the widget and say "Delayed 1 hour".
- **Spoiler shield.** After release, hide episode titles and stills until you mark it watched.
- **Season arc ring.** A thin ring showing episodes aired out of total, so a finale feels like a finale.
- **Weekly digest notification.** Sunday evening: "3 episodes this week" with days and times.
- **Control Center control.** Start the release-night Live Activity from a control via `LiveActivityIntent`.
- **Shareable countdown card.** Export a poster-free typographic image for group chats.
- **TV Time and Trakt import.** Read their export files so switchers keep their list.
- **Name options.** "Next Episode" collides with next-episode.net and its App Store app. Alternatives: **Airstamp**, **Drop Night**, **Tonight's Episode**. Airstamp is short, ownable and names the core idea.

**Chosen direction:**

1. **Release-night Live Activity plus StandBy.** No major tracker ships it, and it shows deep ActivityKit craft.
2. **Typographic Lock Screen widgets with a "nothing new" state.** This is the portfolio hero shot and works without poster art.
3. **Your-time honesty with simulcast translation.** It solves the real Lagos and anime pain and makes data quality visible.
4. **Region-aware "watch on"** using TMDB watch providers with JustWatch credit. It makes the app local to Nigeria, not just translated.
5. **Local-first, no account.** TVmaze and AniList are called from the device. There is no server to pay for, which is why TV Time died.

## How we'd build it

**Architecture and stack**

- **App:** Swift 6, SwiftUI, iOS 18 minimum. SwiftData for the followed-shows store, shared with extensions through an App Group.
- **Widget extension:** WidgetKit timelines with `Text(date, style: .timer)` for live countdowns. One entry per upcoming drop, spaced at least 5 minutes apart, reload policy `.after(nextDrop)`.
- **Live Activities:** ActivityKit in the same extension. Schedule with `request(...startDate:)` and an `AlertConfiguration`, so no push server is needed. End with `.after(drop + 2h)`.
- **Background refresh:** `BGAppRefreshTask` every few hours re-fetches schedules, diffs airstamps, reloads timelines and reschedules activities.
- **Data sources:** TVmaze for TV episodes and airstamps (UTC). AniList GraphQL `airingSchedule` for anime. TMDB `watch/providers` for country availability, credited to JustWatch.
- **Time logic:** All times stored as UTC instants. Format with the device `TimeZone` and locale. A rules table covers platform drops (Netflix 00:00 PT, Crunchyroll offsets) when no airstamp exists.
- **Watch app:** WidgetKit complications sharing the same timeline provider.
- **Tooling:** Xcode, Swift Testing, snapshot tests for widget families, GitHub Actions for builds, TestFlight.

**Data and permissions**

- No account, no analytics SDK, no server. Data stays on device; optional iCloud sync via CloudKit private database in Phase 2.
- Permissions: notifications (for Live Activity alerts and digests), Live Activities toggle, calendar write-only access for export.
- Country comes from the device region, overridable in Settings for VPN or travel.
- Network calls go straight to TVmaze, AniList and TMDB. The TMDB key ships in the app; budget for its rotation.
- Licences: TVmaze CC BY-SA credit and links; TMDB logo and notice in Credits; "Streaming data by JustWatch" beside every provider label; AniList credit.

### Product phases

#### Phase 0: Prototype (1–2 days)

**Goal:** Prove the countdown feels right on a real Lock Screen.

- Hard-code 5 of Chime's shows with real TVmaze airstamps.
- One rectangular Lock Screen widget and one Home Screen widget with live timer text.
- One scheduled Live Activity firing at a test time.
- Figma type studies for 3 widget styles.

**Done when:** Chime runs it for 7 days and the widget shows the right Lagos time for every drop.

#### Phase 1: MVP (about 1 week)

**Goal:** A shippable TestFlight app that replaces checking Google.

- Search and follow shows (TVmaze) and anime (AniList).
- Upcoming list sorted by time to drop, in local time, with source chip.
- Lock Screen circular, rectangular and inline widgets; small and medium Home Screen widgets.
- Release-night Live Activity, opt-in per show, with Dynamic Island compact, minimal and expanded views.
- "Nothing new this week" state with the next real date.
- Drop Day view for whole-season releases.
- Credits screen with all attributions.

**Done when:** 20 TestFlight users follow at least 3 shows each, and no wrong-time bug is open for 14 days.

#### Phase 2: Region and craft (3–5 days)

**Goal:** Make the app local and delightful.

- Region-aware "watch on" via TMDB watch providers, with Nigeria tested against Showmax, Netflix and Prime.
- StandBy layout using `isActivityFullscreen`.
- Simulcast translator for anime with JST shown.
- Delay detection and "Delayed" badge.
- Calendar export and Sunday digest.
- TV Time and Trakt export import.

**Done when:** App Store release live, and 95% of drops for followed shows show a provider in the user's country or an explicit "not listed here".

#### Phase 3: Reach and revenue (ongoing)

**Goal:** Grow beyond the portfolio and test money.

- Apple Watch complications and Control Center control.
- Spoiler shield and season arc ring.
- iCloud sync across iPhone and iPad.
- Optional Plus tier: unlimited Live Activities per night, custom widget themes, Watch app. Requires a TMDB commercial licence first.
- Localised copy for top markets.

**Done when:** 1,000 monthly active users and a decision, backed by data, on whether Plus is worth the licence cost.

## Feature and deliverable checklist

**Product**

- [ ] Decide final name (Next Episode vs Airstamp) after App Store and trademark search
- [ ] Write the one-line positioning and App Store subtitle
- [ ] Define the time rules table for Netflix, Prime, Showmax, Disney+, HBO Max and Crunchyroll
- [ ] Define the "nothing new this week" logic and copy
- [ ] Define Drop Day rules for whole-season releases
- [ ] Scan Reddit and X for countdown and time zone complaints; log 20 quotes
- [ ] Interview 5 viewers outside the US, including 2 in Nigeria
- [ ] Decide Live Activity defaults: lead time, end time, per-show opt-in

**Design**

- [ ] Type system: one display face for numerals, one text face; test tabular figures
- [ ] Lock Screen circular, rectangular and inline widget designs
- [ ] Home Screen small and medium widget designs, light, dark and tinted
- [ ] Dynamic Island compact, minimal, expanded and reduced-width (28 pt circle) views
- [ ] Lock Screen Live Activity under 160 pt tall, plus StandBy full-screen layout
- [ ] Upcoming list, show detail, search and onboarding screens
- [ ] Empty, delayed, estimated-time and offline states
- [ ] Source chip and JustWatch credit treatment
- [ ] App icon and Watch complication set

**Engineering**

- [ ] SwiftData model and App Group container
- [ ] TVmaze client with backoff on HTTP 429 and edge-cache-friendly requests
- [ ] AniList GraphQL `airingSchedule` client under 90 requests a minute
- [ ] TMDB watch-provider client keyed by device region
- [ ] UTC-only time model with formatting tests across 10 zones and DST changes
- [ ] Widget timeline provider with entries 5+ minutes apart and `.after` reloads
- [ ] Scheduled Live Activity with `startDate` and `AlertConfiguration`
- [ ] Handle the simultaneous Live Activity limit gracefully
- [ ] `BGAppRefreshTask` schedule diff and delay detection
- [ ] Calendar export via EventKit write-only access
- [ ] TV Time and Trakt export importers

**Quality**

- [ ] Unit tests for time conversion, including the JST/US DST shift case
- [ ] Snapshot tests for every widget family and Dynamic Island state
- [ ] VoiceOver labels on every widget and Live Activity view
- [ ] Dynamic Type up to AX5 in the app; widget text fits at large sizes
- [ ] Always-On display check using `isLuminanceReduced`
- [ ] Adult-content filter for AniList results
- [ ] Battery and network audit over 7 days

**Launch and portfolio**

- [ ] Credits screen with TVmaze, TMDB, JustWatch and AniList attribution
- [ ] Privacy policy stating no data collection; App Privacy label "Data Not Collected"
- [ ] Public GitHub repo with README, architecture diagram and licence
- [ ] Case study: problem, research, type studies, release-night video
- [ ] 30-second screen recording of a live drop in the Dynamic Island
- [ ] TestFlight public link and App Store submission
- [ ] Launch posts to TV Time switchers, r/iOSapps and anime communities

## Insights and considerations

**Risks**

- **API terms.** TVmaze is the safest base: CC BY-SA allows any use with credit. TMDB is free only while the app is non-commercial; any paid tier needs a TMDB licence first. JustWatch's own API is off-limits for consumer apps, so provider data must come through TMDB with JustWatch credit.
- **ShareAlike.** CC BY-SA applies to TVmaze data we redistribute, such as a shareable schedule export. Keep exports under the same licence and credit TVmaze.
- **Rate limits.** 20 calls per 10 seconds (TVmaze) and 90 a minute (AniList) are per device, which suits local-first. Batch refreshes and cache for 6 hours.
- **Poster artwork copyright.** Studio key art is copyrighted. Ship a typographic design that needs no posters. Where images appear in the app, load them from TMDB at runtime and never bundle them in screenshots or the repo.
- **Name collision.** next-episode.net already ships "Next Episode - Track TV Shows" on the App Store with 2.5K ratings. Using the same name risks rejection under guideline 4.1 and a trademark complaint. Keep "Next Episode" as the project codename and launch as Airstamp or similar.
- **Wrong times.** One wrong drop time costs trust. Show the source of every time and mark estimates clearly.
- **Live Activity limits.** 8 hours active, 4 KB payload and a device cap on simultaneous activities. Allow one activity per night by default and merge same-night drops.

**Privacy.** No account, no tracking, no analytics SDK. The followed list never leaves the device unless the user turns on iCloud. Network requests reveal show IDs to TVmaze, AniList and TMDB; say so in the privacy policy.

**Accessibility.** VoiceOver reads countdowns as full phrases ("Silo, in 2 days 4 hours, on Apple TV+"). Respect Reduce Motion and Always-On luminance. Avoid colour as the only cue for "out now".

**App Store review.** Scheduled Live Activities must carry an alert so users know they started. Filter adult AniList entries. Include working attributions and a privacy policy. Avoid any wording that suggests piracy or unofficial streams.

**Monetisation later.** Comparable apps price at $4.99 one-off (Next Episode Pro) to $49.99 a year (Sofa). A $9.99 lifetime Plus with themes, Watch app and multiple Live Activities fits a local-first app. Tip jar first, Plus only after the TMDB licence.

**Portfolio story.** Lead with the release-night video: Lock Screen countdown, Dynamic Island flip, StandBy clock. Then show the research, including TV Time's closure and the JST shift case. Close with the craft: type studies, the UTC time model, and the attribution design. Publish the repo with a clear README and tests.

## Success metrics

| Metric | Target |
| --- | --- |
| Drop times correct in user's zone (spot check of 100 drops) | 99% |
| Users who add a Lock Screen widget in week 1 | 60% |
| Users who enable a release-night Live Activity | 40% |
| Day-30 retention | 35% |
| Followed shows with a provider in the user's country | 90% |
| Crash-free sessions | 99.5% |
| GitHub stars in 3 months | 300 |
| Monthly active users by Phase 3 | 1,000 |

## Sources

- [TechCrunch: TV Time is shutting down](https://techcrunch.com/2026/07/02/popular-tv-tracking-app-tv-time-is-shutting-down-as-company-focuses-on-ai)
- [Wikipedia: TV Time](https://en.wikipedia.org/wiki/TV_Time)
- [Tom's Guide: Marathon TV shut down](https://www.tomsguide.com/entertainment/streaming/my-favorite-streaming-app-shut-down-today-heres-what-im-using-instead)
- [Woman & Home: Netflix release times](https://www.womanandhome.com/life/news-entertainment/what-time-does-netflix-release-new-episodes/)
- [Outlook Respawn: Jujutsu Kaisen S3 E11 delay](https://respawn.outlookindia.com/amp/story/pop-culture/pop-culture-news/jujutsu-kaisen-season-3-episode-11-delay-and-new-release-time)
- [Showmax Stories: House of the Dragon in Nigeria](https://stories.showmax.com/ng/house-of-the-dragon-now-available-to-stream-on-showmax-in-nigeria)
- [AlternativeTo: Trakt VIP price doubled](https://alternativeto.net/news/2025/2/trakt-tv-has-set-stricter-limits-for-free-users-and-raised-vip-subscription-prices-by-100-/)
- [AlternativeTo: AniChart](https://alternativeto.net/software/anichart/)
- [App Store: Next Episode](https://apps.apple.com/app/id347009526)
- [App Store: Sequel](https://apps.apple.com/app/1630746993)
- [App Store: Sofa](https://apps.apple.com/us/app/sofa-downtime-organizer/id1276554886)
- [App Store: Serializd](https://apps.apple.com/us/app/-/id1581244120)
- [App Store: Hobi](https://apps.apple.com/us/app/id1387915223)
- [App Store: TV Next](https://apps.apple.com/ca/app/tv-next/id6757971087)
- [App Store: ShowCal](https://apps.apple.com/us/app/track-tv-movies-showcal/id6499238562)
- [App Store: MeronPan](https://apps.apple.com/app/id6745256779)
- [App Store: countdown: for TV](https://apps.apple.com/in/app/id6602898375)
- [GitHub: Showly](https://github.com/trakt/showly)
- [LiveChart schedule page](https://www.livechart.me/anime/11911/schedules/13887)
- [TVmaze API](https://www.tvmaze.com/api)
- [TMDB FAQ](https://developer.themoviedb.org/docs/faq)
- [FileBot forum: TMDB JustWatch attribution](https://www.filebot.net/forums/viewtopic.php?p=64177)
- [dewey/api: JustWatch API terms](https://github.com/dewey/api)
- [AniList: rate limiting](https://docs.anilist.co/guide/rate-limiting)
- [AniList: considerations](https://docs.anilist.co/guide/considerations)
- [Apple: Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities.md)
- [Apple Developer Forums: Live Activity max duration](https://developer.apple.com/forums/thread/797676)
- [Apple: Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date.md)
