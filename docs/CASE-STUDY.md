# Meridian: release times you can trust, wherever you are

*Case study draft. An iPhone app built in one week (Thu 29 Oct – Thu 5 Nov 2026) by Chime, a designer-engineer in Lagos, with Claude Code.*

TODO(Chime): demo video link, and the repo link once it is public on Day 7.

## Summary

Meridian answers one question at a glance: **how long until my next episode, in my time zone, and where is it on?** It shows a countdown on the Lock Screen and Home Screen and books a release-night Live Activity in the Dynamic Island. It is for viewers outside the US, starting with me in Lagos (UTC+1). With one week, $0 and no App Store, it ends at a private beta on my iPhone and an open-source repo. It is local-first (no account, server or analytics), and every time it shows says how sure it is. In an audit of 20 real releases from the build week, it got 14 of 18 right on the first pass and 20 of 20 after sourced fixes.

I set the direction, made the product calls and approved every screen on the phone. Claude Code wrote the code and tests within rules I set. TODO(Chime): confirm this split in your own words.

## The problem

Streaming release times are set in the platform's home zone. Netflix drops at midnight Pacific, 08:00 or 09:00 in Lagos. Apple TV drops at 21:00 Eastern the evening before its listed date. Most trackers show a US time and leave the viewer to do the maths.

The data is worse. TVmaze, the open TV database, gives each episode an `airstamp`. With no `airtime`, that stamp is a **placeholder**: noon in the channel's country. That is 12:00 UTC for Netflix and 16:00 or 17:00 UTC for Peacock and Hulu, which I checked against the live API over three days. An app that trusts the field counts down to a time nobody announced.

Users notice. Of 2,150 App Store reviews pulled across 11 storefronts, Trakt users wrote that times are "always 1-2 hours off" or show "12am as a placeholder". A UK user of Next Episode wrote that it "keeps telling me when shows are on in US… even though my setting is set to local time." TVmaze's own staff wrote of streamer times: "we have no quick fix in place right now."

TV Time (26.4 million lifetime installs) had shut down in July 2026. My first pitch was the Live Activity, but research on 29 Oct showed others had shipped one:

| App | Price | Live Activity | Time zones |
| --- | --- | --- | --- |
| Up Next | Free | Dynamic Island countdown | "timezone-correct" reminders |
| Rexy (anime) | $9.99/yr | Paid tier only | Local zone |
| Kiroku | $24.99 lifetime | Lock Screen countdown | Not stated |
| Trakt | $59.99/yr | Check-ins only | Reviews say 1–2 h off |

## The insight: trust, in words

None of them shows where a time came from. So the countdown became table stakes, and **trust became the product** (D-17). Every time in Meridian says how sure it is, inside the sentence itself:

- **"Out today at 21:00"**: a published broadcast time or a confirmed override.
- **"Expected Mon at 09:00"**: an estimate from the platform's usual release time.
- **"Airs in Japan tomorrow at 01:24"**: an anime's Japanese broadcast.
- **"Out Thu 19 Nov, time not announced"**: a date only, with no ticking timer.

Show detail names the source in one sentence: "Apple TV doesn't publish release times, so this is when its new episodes usually arrive."

## Design

**Direction.** I designed the first version in Figma, to get a feel for the product and how I'd build it (D-65). From that design and a written brief I built the screens in SwiftUI. I turned down the type-only studies, so the app shows show art, fetched at runtime and never committed (D-37). Of three directions I chose **Night Sky**, after Insight Timer's player (D-38). The art fades into a near-black base under a large serif countdown. Warm art gets neutral charcoal, because darkened reds read as brown. One brand colour, Meridian Gold, appears only on the logo's star and the words "Out now" (D-53).

**Words, not colour codes.** The first trust signal was a coloured dot with a word. I had to ask what the dots meant, so users wouldn't know either. Three word-based options were built and compared, and I picked putting the certainty in the verb. It adds nothing to the screen and needs no legend (D-40).

**Redesigned surfaces.** On my phone, the first Live Activity looked "kind of whack", so I redesigned it and the widgets:
- **Widgets:** the small and medium ones, a new large one, and the Lock Screen's (D-46).
- **Live Activity:** the Lock Screen banner, the compact and expanded island, and the minimal ring (D-50).

**The expanded island.** It had a progress bar that filled from whenever the activity started: a picture with no words. An unslop pass removed it, cut the timer from 34 pt to 24 pt and wrote delays as "Delayed from 22:00" instead of a struck-through time (D-57).

**UX audit.** After my 15-minute walkthrough, three read-only agents audited typography, flows and accessibility. They found **34 issues**: 27 are fixed, 2 partly, 3 planned, 1 skipped and 1 is awaiting my decision. The fixes included:
- swipe-back, which a custom back button had switched off
- an 88 pt countdown, now 64 pt
- serif titles that didn't grow with the text size
- a Live Activity switch that promised a booking that wouldn't happen

**Design system.** The design system is live at https://meridian-designsystem.vercel.app. The app is its source of truth: render tests fail if a widget or Live Activity picture on the site differs from the app's.

## Engineering

**Stack.**
- Swift 6 with strict concurrency, SwiftUI and SwiftData, on iOS 26. XcodeGen generates the project.
- No dependencies, and no API keys: TVmaze and AniList need none.
- WidgetKit and ActivityKit read a small **JSON snapshot** in the App Group instead of sharing the database (D-05).
- Live Activities are scheduled with iOS 26's `request(… start:)`. Each goes stale at the drop, so it says "Out now" without the app running. At most 3 are booked at once.

**The time resolver.** Each episode resolves in a fixed order:
1. a sourced override
2. AniList's broadcast, for anime
3. a broadcast airtime
4. a platform rule
5. date only

Placeholders are spotted **only** by an empty airtime, never by the hour (D-25). A date-only drop keeps its date as text, because a UTC "start of day" shows the day before further west (D-28).

| Platform | Rule | Lagos (US summer / winter) |
| --- | --- | --- |
| Netflix, Prime Video | 00:00 Los Angeles | 08:00 / 09:00 |
| Apple TV | 21:00 New York, the evening before | 02:00 / 03:00 |
| HBO | Published airtime | 02:00–04:00 next day |
| Disney+, Peacock, Hulu | No reliable rule | Date only |

**Honest plumbing.** Only a published time can be "Delayed"; a refined estimate isn't a delay (D-58). A 15-minute cache keeps "Updated 14:05" true (D-59).

**Proof.**
- **Tests first for time logic.** Day 1 ended with 41 tests, including 48 zone × season cases, 21 clock-change cases and 17 real episodes. As a check, I changed Apple TV's day offset from −1 to 0, and 12 cases failed.
- **About 285 Swift Testing tests** today. Build, test and spec checks gate every commit.
- **Fixed-clock renders.** Widget and Live Activity images render at a fixed time in 2071, because the renderer draws a timer correctly only before that time.
- **CI is green on GitHub Actions.**

One habit became a rule: "live" means two screenshots seconds apart that differ. That is how we found `pauseTime` freezing every widget timer (D-52).

## Measuring accuracy

The audit checked 20 real episodes released 29 Oct – 2 Nov across 15 services, either side of the US clock change, against independently sourced times. "Correct" means the right day in Lagos and a time within 5 minutes.

| | Correct | Date only |
| --- | --- | --- |
| First pass | 14 of 18 (78%) | 3 |
| After 4 sourced overrides | 20 of 20 | 3 (limit 4) |

**The misses:**
- two live events on streamers (WWE Raw on Netflix, Thursday Night Football on Prime Video)
- a Netflix anime on Japan's schedule (JoJo's Steel Ball Run)
- a wrong TVmaze time after a broadcast ran 40 minutes late (The Apothecary Diaries)

**What they taught:**
- Broadcast TV was right every time, across the clock change.
- Platform rules hold for scripted releases.
- The blind spot is live events and Japan-scheduled anime on global streamers.

Overrides are the designed fix, but they were added after seeing the misses, so the honest first-pass figure is 14 of 18. The audit states its limits too: 4 sources are weak, and 2 candidates were dropped because no source gave the hour.

## What I'd do next

- Turn on remote rules and GitHub-issue reports when the repo goes public, so a fix needs no app update.
- Check the March 2027 clock changes (US 14 Mar, EU 28 Mar).
- Add where to watch by region, through TMDB.
- Add StandBy and the extra-large portrait widget.

TODO(Chime): a short personal reflection.

## Credits

- **TV data:** TVmaze, CC BY-SA 4.0.
- **Anime data:** AniList, under its API terms.
- **Network logos:** Wikimedia Commons, loaded at runtime. The in-app Credits screen lists the required attributions.
- **Built with:** Claude Code.
