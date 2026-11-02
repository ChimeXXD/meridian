# Privacy

Meridian collects no data about you. It has no account, no server, no analytics, no advertising and no tracking.
Nothing you do in the app is sent anywhere except the requests below, which any app needs to fetch show times.

## What leaves your phone

Meridian talks to these services directly from your phone. Each one sees an ordinary web request: your IP address,
the time, and what was asked for. None of them gets an identifier for you.

| Service | What Meridian asks for | Why |
| --- | --- | --- |
| TVmaze (`api.tvmaze.com`) | Show searches, a followed show's next episode, episode lists, schedules | Release dates and times |
| TVmaze images (`static.tvmaze.com`) | Posters and background art | Show artwork |
| AniList (`graphql.anilist.co` and its image host) | Anime searches, a followed anime's next episode, cover art | Anime schedules and artwork |
| Wikimedia (`thumb.wikimedia.org`) | Streaming service and network logos | The logos in Search |

Artwork requests carry a `User-Agent` naming the app and its GitHub page, as Wikimedia asks of apps.

**Report a wrong time** (on a show's page) opens an email in your own mail app (addressed to the developer, in the developer's builds) with the
show, episode, the time Meridian showed, where that time came from and your time zone filled in. Nothing is sent
unless you send it yourself. Without a mail app, the same text is copied for you to paste. Once the code is public,
it opens a prefilled GitHub issue instead.

## What stays on your phone

- **The shows you follow** and their settings (the Live Activity switch, an anime's time offset), in the app's own
  storage.
- **A small summary for the widgets** (the next episodes and their times) in the app group shared with Meridian's
  widgets.
- **Cached responses and artwork**, so the app works offline and asks less often. iOS may clear them at any time.
- **Your settings** (the Live Activity lead time, whether you've seen the welcome screen, when the times were last
  updated), in iOS's standard settings storage.

Live Activities are scheduled on your phone. Meridian uses no push notifications and no server to update them.

Deleting the app deletes all of it.

## Questions

Open an issue on [GitHub](https://github.com/ChimeXXD/meridian/issues).
