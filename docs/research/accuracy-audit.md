# Accuracy audit: 20 real drops from the build week (D6-5)

Run 3 Nov 2026. 20 episodes released between Thu 29 Oct and Mon 2 Nov 2026, across 15 services and networks in the
US, the UK and Japan. Each one pairs its real TVmaze data with the release time an independent source confirmed. The
check is `AccuracyAuditTests` on `MeridianTests/Fixtures/audit/`, recorded by
`scripts/record-fixtures.py --audit`, so it reruns on every test pass.

**SPEC's definition of correct:** in the tester's zone (Lagos), the shown day is right **and** the time is within 5
minutes of the confirmed release. A date-only drop is correct if its date is right and it shows no time, and at most 4
of the 20 may be date-only. The audit must include drops on both sides of the US clock change (Sun 1 Nov 2026,
02:00 ET).

## Result

| | Correct | Date only |
|---|---|---|
| **Before the fixes** (the rules file as it was) | 14 of 18 recorded (78%) | 3 |
| **After the fixes** | **20 of 20** | 3 (within the limit of 4) |

The 4 misses all came from cases the platform rules can't know about:

| Drop | App said (Lagos) | Confirmed (Lagos) | Cause | Fix (rules file, sourced) |
|---|---|---|---|---|
| WWE Raw (Netflix, live) | Mon 09:00 | Tue 00:00 | A live event, and that week a special 18:00 ET start; the Netflix rule assumes 00:00 PT | Episode override |
| Thursday Night Football (Prime Video, live) | Thu 08:00 | Fri 01:15 | Live sport; the Prime rule assumes 00:00 PT | Show override: Thursdays 20:15 ET |
| JoJo's Steel Ball Run (Netflix anime) | Fri 08:00 | Fri 09:00 | Netflix drops it on Japan's schedule, 17:00 JST | Show override: 17:00 JST |
| The Apothecary Diaries (NTV) | Fri 14:30 | Fri 15:40 | TVmaze's time was wrong: that night's broadcast ran 40 minutes late | Episode override |

**What this says about the app:**
- **Broadcast TV is reliable, the clock change included.** Every network episode with a TVmaze airtime matched, on both sides of the change.
- **Platform rules hold for scripted releases.** That's Apple TV, Paramount+ and Netflix's usual drops.
- **The blind spot is live events and Japan-scheduled anime on global streamers.** The rules file's overrides are the designed answer. Once the repo is public they can be fetched without an app update (D-34), and "Report a wrong time" is how they get found.

## The 20 drops

Times are in Lagos (UTC+1). "Strength" grades the source:
- **official:** the platform, network or broadcaster
- **press:** a reputable outlet stating that episode's time
- **weak:** inferred, old, or quoted second-hand

| # | Drop | Service | App shows | Confirmed | Clock change | Strength | Source |
|---|---|---|---|---|---|---|---|
| 1 | Grey's Anatomy S23E3 | ABC | Fri 03:00 | Fri 03:00 | before | press | [seat42f](https://seat42f.com/greys-anatomy-season-23-episode-3-photos/) |
| 2 | Dark Matter S2E10 | Apple TV | Fri 02:00 (expected) | Fri 02:00 | before | weak | [dexerto.fr](https://www.dexerto.fr/films-series/calendrier-dark-matter-saison-2-sortie-episodes-1657234/) |
| 3 | The Celebrity Traitors S2E9 | BBC One | Thu 21:00 | Thu 21:00 | before | official | [BBC schedule](https://www.bbc.co.uk/schedules/p00fzl6p/2026/10/29) |
| 4 | FBI S9E5 | CBS | Tue 02:00 | Tue 02:00 | **after** | press | [showbizjunkies](https://www.showbizjunkies.com/tv/fbi-season-9-episode-5-preview/) |
| 5 | Georgie & Mandy's First Marriage S3E4 | CBS | Fri 01:00 | Fri 01:00 | **before** | official (via search snippet) | [Paramount Press Express](https://www.paramountpressexpress.com/cbs-entertainment/shows/georgie-mandys-first-marriage/releases?episode=26987) |
| 6 | Dancing with the Stars S35E9 | Disney+ / ABC | Tue 02:00 | Tue 02:00 | after | press | [TV Insider](https://www.tvinsider.com/1300281/dancing-with-the-stars-schedule-change-disney-night-2026-election/) |
| 7 | The Simpsons S38E5 | FOX | Mon 02:00 | Mon 02:00 | after | press | [TV Insider](https://www.tvinsider.com/1288260/the-simpsons-season-38-cast-episode-details-premiere-date-trailer-more/) |
| 8 | The Howard Stern Show S1E7 | HBO Max | 29 Oct, no time | Thu 08:01 | before | official | [WBD press](https://press.wbd.com/us/media-release/hbo-max-brings-howard-stern-show-streaming-debuting-september-17) |
| 9 | The Gilded Age S4E1 | HBO | Mon 03:00 | Mon 03:00 | after | press | [TVLine](https://www.tvline.com/2243685/the-gilded-age-season-4-release-date-hbo/) |
| 10 | The Kardashians S8E4 | Hulu | 29 Oct, no time | Thu 05:00 | before | weak | [Reelgood](https://blog.reelgood.com/how-to-watch-the-kardashians-season-8-outside-the-us) |
| 11 | Law & Order: SVU S28E4 | NBC | Fri 02:00 | Fri 02:00 | before | press | [seat42f](https://seat42f.com/law-order-svu-season-28-episode-4-photos-arcana/) |
| 12 | Saturday Night Live S52E4 | NBC | Sun 04:29 | Sun 04:30 | straddles | press | [TVLine](https://tvline.com/2294958/is-snl-new-tonight-october-24-2026-host-musical-guest-watch-details/) |
| 13 | JoJo's Steel Ball Run S2E7 | Netflix | Fri 09:00 (expected) | Fri 09:00 | before | official | [Netflix Tudum](https://www.netflix.com/tudum/articles/steel-ball-run-jojos-bizarre-adventure-2nd-3rd-stage-how-to-watch) |
| 14 | WWE Raw S33E44 | Netflix | Tue 00:00 (expected) | Tue 00:00 | after | weak | [sacnilk](https://www.sacnilk.com/news/wwe_raw_11226_predictions_preview_match_card_and_how_to_watch) |
| 15 | Ranma ½ S3E5 | NTV | Sat 16:55 | Sat 16:55 | before | official (regular slot) | [ranma-pr.com](https://ranma-pr.com/onair/) |
| 16 | The Apothecary Diaries S3E5 | NTV | Fri 15:40 (expected) | Fri 15:40 | before | press | [animeanime.jp](https://animeanime.jp/article/2026/10/29/104314.html) |
| 17 | Dexter: Resurrection S2E1 | Paramount+ | Fri 08:00 (expected) | Fri 08:01 | before | press | [HollywoodLife](https://hollywoodlife.com/feature/dexter-resurrection-season-2-release-date-start-time-5564968/) |
| 18 | Days of Our Lives (29 Oct) | Peacock | 29 Oct, no time | Thu 11:00 | before | weak | [KTLA](https://ktla.com/news/nationworld/days-of-our-lives-no-longer-on-nbc-starting-monday-heres-how-you-can-still-watch/amp/) |
| 19 | Thursday Night Football S5E7 | Prime Video | Fri 01:15 | Fri 01:15 | before | official | [About Amazon](https://www.aboutamazon.com/news/entertainment/thursday-night-football-schedule-prime-video) |
| 20 | Detective Conan (31 Oct) | YTV | Sat 10:00 | Sat 10:00 | before | official | [ytv.co.jp](https://www.ytv.co.jp/conan/data/caseTop.json) |

**The clock-change pair:** the same 20:00 ET CBS slot. Georgie & Mandy (Thu 29 Oct, EDT) was at 00:00 UTC, and FBI
(Mon 2 Nov, EST) at 01:00 UTC. The app moved with it; 01:00 and 02:00 in Lagos respectively.

## Limits

- **Weak sources:** 4 of the 20 (#2, #10, #14, #18). Two of those are date-only rows, where only the day is checked. Rows #2 and #14 still match their stated times.
- **#15 confirms the regular slot**, not this episode's time; a one-off shift can't be ruled out.
- **Two candidates had no source for their release hour** and were left out, not guessed: HBO Max's Furia S2E4 and Netflix's Dead-End Job S1E1.
- **The fixes were made after seeing the misses.** So "20 of 20" shows the override mechanism can correct them, not that the rules alone would have. The honest first-pass figure is 14 of 18.
- **TVmaze quirks found:**
  - Late-night anime keep the broadcast day as `airdate` with an after-midnight `airtime` (Ranma: 31 Oct 00:55). Only `airstamp` is right, and the app uses it.
  - SNL is listed at 23:29, not 23:30. That's inside the 5-minute tolerance.
