# Meridian UX audit (2 Nov 2026)

Chime asked for a full audit after a 15-minute walkthrough on the iPhone. Three read-only specialists reviewed the app
in parallel:
- typography and hierarchy
- flows and interaction
- accessibility, including the Dynamic Type AX5 pass for D6-8

They worked from 14 default-size simulator screens, 7 screens at the largest accessibility text size, the widget and
Live Activity renders, and the SwiftUI source. Measurements come from the 3x screenshots (1 pt = 3 px, the screen is
874 pt tall) and contrast from the colour values in code. "Inferred" marks anything not seen directly.

Severity: **Critical** blocks a core task or breaks a platform convention · **High** hurts the core question or a Must
· **Medium** confuses or misleads · **Low** polish.

Status: **Fixed** · **Planned** (agreed direction, in the current polish round) · **Decide** (needs Chime's call).

## What works

- The core answer reads clearly: the hero, the out line in words and the provider.
- First launch to first follow is obvious, gives instant feedback, and can be undone.
- Search filter chips and "Show popular" recover well from no results.
- Upcoming keeps the last known times offline and says which shows didn't refresh.
- Every text colour passes WCAG AA on the night bases: white 17:1, secondary 10:1, muted 5.95:1, gold 10.2:1. The
  worst hero title over art is 8.1:1.
- Tap targets are 44 pt or more. Reduce Motion stops the wall and the fades. Every widget and Live Activity state has a
  full spoken label.

## Findings

| # | Sev | Where | Finding | Recommendation | Status |
|---|---|---|---|---|---|
| 1 | Critical | Show detail, show page | Swiping from the left edge didn't go back: both screens hid the system navigation bar and drew their own button, which switches the gesture off. | Keep the system bar, invisible, with its own back button. | **Fixed** (`NavigationTests`) |
| 2 | High | Upcoming hero, Show detail, show page | The countdown is 88 pt, 2.75 times the title: digits 64 pt tall and 263 pt wide (65% of the width), the block 14.8% of the screen. The widgets sit at 1.7–2.25 times. | One countdown scale: 64 pt on the hero and detail, 48 on the show page, 24 in rows. | **Fixed** (64 / 48) |
| 3 | Critical | Every screen at large text sizes | Serif titles have fixed sizes, so they never grow, while everything else does. At AX5 "Silo" stays 32 pt under a 53 pt out line, and the countdown grows 3.1 times. The order of importance flips. | Serif text styles (`.largeTitle`, `.title`, `.title2`, `.title3`); the countdown scales with `.largeTitle` (1.76 times). | Partly fixed: show titles and countdowns grow; row and other titles planned |
| 4 | High | Show detail | "Report a wrong time" and "Unfollow" look disabled: 15 pt, 60% white, no icon. The grey overrides Unfollow's destructive red. At AX5 the wrapped label is centred. | A grouped inset card: symbol and label rows, Report with an "opens elsewhere" arrow, Unfollow in system red, kept the confirmation. | **Fixed** |
| 5 | High | Show detail (anime) | The anime offset control, a **Must** in PLAN.md, isn't built. There's no way to move Frieren from the Japan time to the stream time. | "Streams N min after Japan" stepper, 0–180 in 15s, for anime only. | **Fixed** (stepper; Chime to approve) |
| 6 | High | Every hero and row | "Where it's on", a third of the core question, is the weakest text: a 13 pt muted footnote limited to one line. At AX5 it truncates and loses the country ("S3E1 · HBO ·…", against rule 11). | 15 pt at 75% white, two lines at accessibility sizes. | Planned |
| 7 | High | Show detail, AX5 | The episode label column is fixed at 52 pt, so "S3E9" stacks one letter per line. | Scaled width; at accessibility sizes, stack the label over the title. | Planned |
| 8 | High | Upcoming rows, AX5 | The row countdown grows to 75 pt and won't shrink (`fixedSize`), squeezing the title to "The Last / of Us". | Scale it with `.largeTitle`; at accessibility sizes, put the countdown under the title. | Planned |
| 9 | High | Welcome, AX5 | The taller text pushes the logo onto the poster wall, where contrast can drop to about 2.1:1. There's no scrolling, so a short phone can't fit it (inferred). | Scroll view; at accessibility sizes, a shorter wall. | Planned |
| 10 | High | Show page, spotlight (date-only) | The date is said twice: "Fri 9 Jul 2027" in 53 pt type, then "Out Fri 9 Jul 2027, time not announced". | No big line for a date-only show, as the rows already do. | **Fixed** |
| 11 | High | Show detail | The Live Activity switch says "Starts 2 hours before" even when nothing will be booked: Live Activities are off in iOS Settings, the episode is date-only or more than 7 days away, or 3 are already booked. | Say the truth in the subtitle, with Open Settings when they're off. | Planned |
| 12 | High | Upcoming | Shows with nothing scheduled can't be tapped, so they can't be unfollowed from Upcoming; only through Search. | A long-press Unfollow (quick), or Show detail by show (full). | Decide |
| 13 | Medium | Settings | Changing the lead time doesn't move activities already booked, so the footer overpromises. | When the lead time changes, end the ones that haven't started and book again. | Planned |
| 14 | Medium | Show detail | An open detail keeps the drop it was opened with, so a refresh's delay doesn't reach it until you go back. | Read the drop from the latest result by show. | **Fixed** |
| 15 | Medium | Search, show page | Unfollowing is one tap there but asks for confirmation in detail, and silently drops the show's Live Activity setting and offset. | The same confirmation everywhere. | Decide |
| 16 | Medium | Search | While the airing grid loads, when it fails and when it's empty, it shows the same line. A search error has no retry button. | `ContentUnavailableView` states with "Try again"; no TV results → "Search Anime". | Planned |
| 17 | Medium | Upcoming, scrolled | The hero countdown slides under the status bar, and its ghost overlaps the clock. | A fade over the status bar. | Planned |
| 18 | Medium | Section headers | One role, three styles: Upcoming's 15 pt muted sans, Search's 22 pt white serif "Results", Settings' system headers. | 15 pt semibold, muted, everywhere. | Planned |
| 19 | Medium | Rows, widgets | The "d" and "h" units are half the numeral size, 7.5 pt in widget compact rows, under the 11 pt minimum. | Half size with an 11 pt floor. | **Fixed** |
| 20 | Medium | Show detail | Live Activity switch on and off look almost the same (white at 60% tint), and the control contrast is 2.49:1 (under 3:1). | A stronger tint; state in the subtitle (#11). | Planned |
| 21 | Medium | Lock Screen widgets, Live Activity | In Always-On, muted text dims again to about 3.45:1. | Dim to 85%, not 70%, for muted text. | Planned |
| 22 | Medium | Widgets (VoiceOver) | The spoken countdown is computed per timeline entry, so it can be up to 59 minutes behind the ticking timer. | While ticking, speak the release time instead. | Planned |
| 23 | Medium | Art everywhere | With Smart Invert, posters, art and logos invert. | `accessibilityIgnoresInvertColors` on images. | Planned |
| 24 | Medium | Search, AX5 (inferred) | A fixed 3-column grid with two-line limits cuts titles and certainty words. | One column at accessibility sizes. | Planned |
| 25 | Medium | Show detail, Upcoming, AX5 | The art header is fixed at 472–500 pt, more than half the screen, pushing the facts below the fold. | 280 pt at accessibility sizes. | Planned |
| 26 | Low | Search grid | Titles (13 pt) and info lines (12 pt) differ by 1 pt and read as one block. | Titles 15 pt. | Planned |
| 27 | Low | Primary buttons | Three styles for one role (Welcome, show page, empty Upcoming). | One white 50 pt capsule with `.headline` text. | Planned |
| 28 | Low | Report a wrong time | Without Mail, the copied text doesn't say where to send it. | Offer the share sheet with the report. | Planned |
| 29 | Low | Whole app | No haptics. | Success on follow; selection on chips and the TV/Anime switch. | Planned |
| 30 | Low | Lock Screen Live Activity | "Expected" twice ("Expected in" over the timer, "Expected Mon 21:00" under it), and a delay is a strike-through rather than words. | The expanded island's wording (D-57). | Decide |
| 31 | Low | Widgets and Live Activity | Title weights and small sizes drift (serif regular, medium or semibold; 11, 12 and 13 pt). | Serif regular, small text 12 pt medium. | Planned |
| 32 | Low | VoiceOver | Spotlight, empty and Welcome headlines aren't headers; "S4E1" is spelled letter by letter; the show page reads its art aloud; a failed refresh is heard only at the end. | Header traits, "Season 4, episode 1", hide the art, an announcement. | Planned |
| 33 | Low | Code | `DropRow` and `SectionHeader` aren't used anywhere. | Delete them. | Planned |
| 34 | Low | Search (inferred) | No search field shows in the screenshots. | Check on the phone first. | Decide |

## The type scale after this round

- **Countdown:** 64 (hero, detail) · 48 (show page, large widget) · 36 (small widget, Lock Screen Live Activity) · 32
  (medium widget) · 24 (rows, expanded island, rectangular widget) · 15 (compact rows, compact island). "Out now" at 0.7
  times, units at 0.5 times with an 11 pt floor. The app's countdowns scale with `.largeTitle`.
- **Serif:** `.largeTitle` (show titles, Welcome headline) · `.title` (spotlight, empty states) · `.title2` · `.title3`
  (row titles).
- **Sans:** `.body` medium (out line) · 15 (row out line, section headers semibold, actions) · 13 (info, delay) · 12
  (grid info).

The widgets and Live Activity keep fixed sizes: they draw on a fixed canvas.
