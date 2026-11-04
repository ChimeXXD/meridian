# Skill prompts

Prompts for running Emil Kowalski's skills (github.com/emilkowalski/skills, installed in `~/.claude/skills/`) on
Meridian: five for the app and five for the design system site. Written 4 Nov 2026.

How to use them:

- **One skill per session.** Start a fresh Claude session for each prompt. Some skills pull in opposite directions
  (`remove-animations` against `find-animation-opportunities`, Emil's taste against recorded decisions).
- **Paste the shared preamble first**, then the prompt. For the site prompts, also paste the site rule.
- **Findings first, edits after Chime's OK.** The app is the source of truth and the site mirrors it (D-57), so a
  visual change in the app means new renders and a sync that Chime approves.
- Each prompt starts with the skill's slash command. `/review-animations` only runs when it's named.
- `apple-design` and `emil-design-eng` are written for the web. On the app, they're used for their principles only,
  rebuilt in SwiftUI.

## Order

- **Before going public (Day 6):** 1 `write-swift`, 2 `break-ui`, 6 `review-animations`.
- **Day 7:** 5 `animation-vocabulary`, since it feeds the case study and the demo video.
- **After launch:** 3, 4, 7, 8, then 9 and 10 in that order.

## Shared preamble (paste above every prompt)

```
Before anything: read CLAUDE.md, docs/HANDOFF.md, PROGRESS.md and docs/DECISIONS.md.
Ground rules for this session:
- Decisions in docs/DECISIONS.md win over the skill's advice. If the skill disagrees with one, list it as
  "conflicts with D-xx" and don't change it.
- The app is the source of truth; the design system site mirrors it (D-57). Anything that changes how the app
  looks goes into SwiftUI first. Widget and Live Activity pictures reach the site only through
  scripts/sync-design-system-renders.sh, after I approve the new renders.
- Work in two passes. Pass 1: findings only, ranked by impact, each with file:line, what's wrong in plain words,
  the fix, and what it would change on screen. Stop and wait for my picks. Pass 2: apply only what I picked.
- Never weaken a test to make it pass. Keep CLAUDE.md's rules 1–11 (timers without pauseTime, no .fixedSize on
  timers, ReleaseWording for every time, no artwork committed).
- One simulator job at a time; shut it down when done. Commit and push after each green step.
- I'm a designer: explain findings in plain words and show screenshots, not code, unless I ask.
```

## The app

### 1. `/write-swift`: the Swift review before going public

```
/write-swift
Meridian goes public tomorrow as open source. Review its Swift the way an experienced iOS engineer reading the
repo would. Focus, in order:
1. Swift 6 concurrency: actors, @MainActor, Sendable, nonisolated and TaskGroup use in Meridian/Services/ and
   Shared/. Flag anything that's racy, over-isolated, or uses @unchecked Sendable / nonisolated(unsafe)
   without a reason.
2. Value types and API design in Shared/Models/ and Shared/Time/: names, optionals, types that should be
   enums, logic duplicated between app and widget.
3. Swift Testing in MeridianTests/: weak assertions, tests that can't fail, missing parameterized cases for the
   time rules.
4. Performance: work on the main actor during refresh, artwork loading in Services/Artwork/, per-second
   redraws (TimelineView(.countdown)).
Skip style nits. Rank by "would a reviewer of a public repo notice this". Leave Shared/Time/ behaviour
unchanged: every fix there needs a test first.
```

### 2. `/break-ui`: worst-case data on widgets, Live Activity and rows

```
/break-ui
Stress-test the surfaces where Meridian's text has the least room: the widgets (MeridianWidgets/NextDropWidget.swift,
all six families), the Live Activity (Shared/LiveActivity/: lock, compact, minimal, expanded, small), and
DropRow / the Upcoming hero.
Worst cases to build from real shapes in LiveActivitySamples.swift and the widget previews: a 60-character
show name, a one-letter name, a non-Latin title (Japanese, Arabic), an emoji in a title, "S12E104", a
provider label like "Paramount+ with Showtime · US", five shows on the same night, zero followed shows,
every show date-only, a drop exactly at midnight, a drop 0:00:01 away, a 400-day countdown, and the largest
accessibility text size.
Don't build a web toggle. Add each worst case as a #Preview and, where it breaks, as a case in
WidgetRenderTests / LiveActivityLayoutTests, so it stays caught. Report each break with a render: what broke,
why, and the fix. Remember the device can differ from ImageRenderer renders (rule 4): mark anything I need to
check on the phone.
```

### 3. `/apple-design`: native feel of the app's screens and motion

```
/apple-design
Use this skill for its principles only; it's written for the web, and Meridian is SwiftUI on iOS 26. Review how
the app feels against Apple's own standard:
- Motion: every state change in Meridian/Features/ (Upcoming, ShowDetail, Search, Welcome's drifting wall,
  follow/unfollow). Are the springs interruptible? Does anything fade linearly or jump? Does Reduce Motion
  swap movement for a cross-fade everywhere?
- Gesture and sheets: presentation detents, dismissal, scroll edges.
- Type: the New York / SF pairing in Shared/Design/Tokens.swift: optical sizes, tracking at large sizes,
  leading in the countdown, Dynamic Type up to AX5.
- Depth and materials: where glass or material is used and where it shouldn't be.
- Feedback: haptics on follow, Live Activity switch, report sent. Present where they earn it, absent elsewhere.
For each finding, name the Apple principle, show the screen, and propose the SwiftUI change with exact values
(spring response/damping, or .snappy/.smooth).
```

### 4. `/emil-design-eng`: craft details in the app

```
/emil-design-eng
Apply Emil's taste to Meridian's app screens. Use his reasoning, not his CSS, and rebuild anything in SwiftUI.
Look at the small details that make it feel finished: how the countdown digits change (.contentTransition
(.numericText)?), press states on rows and the follow button, how artwork arrives (pop-in versus a calm
fade), empty and loading states, how "Out now" in gold arrives at the drop, and the spacing and alignment
between the hero, rows and section headers.
Take simulator screenshots of Upcoming, Show detail, Search, Settings and Welcome first, and critique from them.
Rank findings by what a design-literate visitor would notice in the first 10 seconds of the demo video.
```

### 5. `/animation-vocabulary`: words for the case study and video

```
/animation-vocabulary
For tomorrow's case study and demo video, I need the right names for Meridian's motion. Go through every
animated moment in the app, widgets and Live Activity (search Meridian/, MeridianWidgets/ and Shared/ for
withAnimation, .animation, .transition, .contentTransition, matchedGeometryEffect and sensoryFeedback), plus
the moments in docs/SHOT-LIST.md.
For each: its proper name, a one-line plain description, and the file:line it lives in. Then write a short
glossary paragraph I can put in docs/CASE-STUDY.md, describing Meridian's motion in precise terms. Don't
change any code.
```

## The design system site (`design-system/`)

### Site rule (paste after the shared preamble)

```
Site rule: you may restyle the site's own chrome (navigation, rail, tabs, layout, tables, page type, page
motion) directly in design-system/index.html, assets/site.css and assets/site.js. Anything that depicts the
app (phone mockups' contents, widget and Live Activity renders, tokens, component pictures) must match the
Swift: if it looks wrong, the fix is in the app, so list it and don't change it on the site. Check the site on
desktop and at 390 px wide in the browser after every change. The site deploys to Vercel from this folder;
don't deploy without my OK.
```

### 6. `/review-animations`: strict review of the site's motion

```
/review-animations
Review every animation and transition in design-system/assets/site.css and assets/site.js against your
standards: tab switches (widget, Live Activity and state tabs), hover states, the mobile drawer
(openDrawer/closeDrawer), the search, and anything in the @media (prefers-reduced-motion) block. Check
easing (no ease-in on UI), durations, transform origins, interruptibility, and that reduced motion really
removes movement. Flag by default; approval is earned. Give exact replacement values.
```

### 7. `/emil-design-eng`: polish of the site as a portfolio piece

```
/emil-design-eng
The design system site is linked from my README and portfolio. Recruiters and designers will judge it. Critique
the site's own craft: the hero phone, the showcase layouts (.showcase.home, .showcase.la), the iPhone
mockups' frame and shadow, the tabs, the token tables, the rail and search, type rhythm and spacing. Look for
borders that should be shadows, shadows that should be nothing, mismatched radii, weak hierarchy, and anything
that looks default. Screenshot each section before and after.
```

### 8. `/mobile-native`: the site on a phone

```
/mobile-native
Many people will open the design system site from the README on their phone. Check it at 390 × 844 and
430 × 932: hover states that stick on touch (phone mockups, tabs, links), tap highlight flashes, the 100vh
problem, content under the notch or home indicator, the mobile drawer, horizontal scroll from the wide tables
(.table-wrap) and the widget and Live Activity galleries, input zoom on the search field, and theme-color
and status bar colour. Fix the site's chrome only (see the site rule).
```

### 9. `/remove-animations`: clean up the site's motion (run before 10)

```
/remove-animations
Find motion on the design system site that doesn't earn its place: animation on keyboard or search actions,
on things people use over and over (tabs, rail links), decoration with no purpose, and delays that make the
site feel slow. Subtract only. List first; remove what I approve.
```

### 10. `/find-animation-opportunities`: motion that explains something (run after 9)

```
/find-animation-opportunities
After the clean-up, find the few places on the design system site where motion would genuinely explain
something: e.g. switching a widget state in the gallery (the countdown changing to "Out now"), or the island
going from compact to expanded. Prefer motion that mirrors how the app really moves. Read-only: propose each
with exact values and why. Reject everything decorative.
```
