#!/usr/bin/env python3
"""Record TVmaze fixtures for the release-rule tests.

Each fixture pairs TVmaze's show and episode JSON with the release time confirmed
by an independent source, so tests check the resolver against reality, not against
itself. Usage: python3 scripts/record-fixtures.py  (writes MeridianTests/Fixtures/rules/)
"""
import json
import pathlib
import time
import urllib.parse
import urllib.request

API = "https://api.tvmaze.com"
OUT = pathlib.Path(__file__).resolve().parent.parent / "MeridianTests" / "Fixtures" / "rules"
DROP_KEYS = {"image", "summary", "_links", "_embedded", "rating", "weight", "updated", "dvdCountry", "officialSite"}

# (slug, show query, season, number, expected UTC instant or None, confidence, source URL, note)
CASES = [
    ("appletv-pluribus-s1e3", "pluribus", 1, 3, "2025-11-14T02:00:00Z", "estimated",
     "https://www.thewrap.com/?p=7880659", "Apple TV: 21:00 ET the day before the listed date"),
    ("appletv-severance-s2e10", "severance", 2, 10, "2025-03-21T01:00:00Z", "estimated",
     "https://www.techradar.com/streaming/apple-tv-plus/what-time-is-severance-season-2-episode-10-going-to-be-released-on-apple-tv",
     "Apple TV: Thu 20 Mar 2025 21:00 EDT"),
    ("netflix-wednesday-s2e1", "wednesday", 2, 1, "2025-08-06T07:00:00Z", "estimated",
     "https://www.thepinknews.com/2025/08/05/wednesday-season-two-netflix-release-time/",
     "Netflix: 00:00 PT on the listed date"),
    ("netflix-wednesday-s2e5", "wednesday", 2, 5, "2025-09-03T07:00:00Z", "estimated",
     "https://www.soapcentral.com/shows/when-will-wednesday-season-2-part-2-dropped-netflix-release-timings-different-regions-explored",
     "Netflix: Part 2, 00:00 PT"),
    ("prime-theboys-s5e1", "the boys", 5, 1, "2026-04-08T07:00:00Z", "estimated",
     "https://www.tomsguide.com/entertainment/prime-video/what-is-the-release-date-for-the-boys-season-5-episodes-1-and-2-on-prime-video", "Prime Video: 00:00 PT"),
    ("prime-reacher-s4e4", "reacher", 4, 4, "2026-08-19T07:00:00Z", "estimated",
     "https://techradar.com/streaming/amazon-prime-video/reacher-season-4-episode-4-release-date-time", "Prime Video: 00:00 PT"),
    ("paramount-landman-s2e1", "landman", 2, 1, "2025-11-16T08:00:00Z", "estimated",
     "https://bravo-www.soapcentral.com/shows/what-time-will-landman-season-2-premiere-paramount-release-streaming-details-explored",
     "Paramount+: 03:00 ET"),
    ("paramount-landman-s2e2", "landman", 2, 2, "2025-11-23T08:00:00Z", "estimated",
     "https://newsweek.com/entertainment/tv/landman-season-2-episode-2-release-date-how-to-watch-11064092", "Paramount+: 03:00 ET"),
    ("hbo-hotd-s3e1", "house of the dragon", 3, 1, "2026-06-22T01:00:00Z", "exact",
     "https://nc.inverse.com/entertainment/house-of-the-dragon-season-3-release-date-start-time-trailer-plot", "HBO: broadcast 21:00 ET"),
    ("hbo-knight-s1e2", "a knight of the seven kingdoms", 1, 2, "2026-01-26T03:00:00Z", "exact",
     "https://www.tomsguide.com/entertainment/hbo-max/a-knight-of-the-seven-kingdoms-episode-2-release-date-and-time-heres-when-its-streaming-on-hbo-max",
     "HBO: broadcast 22:00 ET"),
    ("override-strangerthings-s5e1", "stranger things", 5, 1, "2025-11-27T01:00:00Z", "exact",
     "https://www.nbcnewyork.com/entertainment/entertainment-news/what-time-stranger-things-season-5-netflix/6423120/",
     "Netflix event drop: 17:00 PT on 26 Nov 2025 (episode override)"),
    ("override-fallout-s2e1", "fallout", 2, 1, "2025-12-17T02:00:00Z", "exact",
     "https://bloody-disgusting.com/tv/3921877/fallout-season-2-delivers-holiday-surprise-with-early-release-date/",
     "Prime moved the premiere to 16 Dec 2025 18:00 PT (episode override)"),
    ("override-daredevil-s2e1", "daredevil: born again", 2, 1, "2026-03-25T01:00:00Z", "estimated",
     "https://www.thewrap.com/creative-content/tv-shows/daredevil-born-again-season-2-episodes-release-schedule/",
     "Disney+ Marvel: 18:00 PT (show override)"),
    ("override-wonderman-s1e1", "wonder man", 1, 1, "2026-01-28T02:00:00Z", "estimated",
     "https://www.dexerto.com/tv-movies/wonder-man-release-date-time-3310024/", "Disney+ Marvel: 18:00 PT (show override)"),
    ("disney-maul-s1e1", "maul shadow lord", 1, 1, None, "dateOnly",
     "https://www.tomsguide.com/entertainment/disney-plus/star-wars-maul-shadow-lord-episode-release-schedule-heres-when-new-episodes-stream-on-disney",
     "Disney+ has no default rule (D-36: Disney+ has no single rule); real time was 00:00 PT"),
]

# Placeholder cases come from the live web schedule: an episode with an empty airtime on these channels.
PLACEHOLDER_CHANNELS = {"Peacock": "placeholder-peacock", "Hulu": "placeholder-hulu"}


def get(path, **params):
    url = f"{API}{path}" + (f"?{urllib.parse.urlencode(params)}" if params else "")
    for attempt in range(4):
        try:
            with urllib.request.urlopen(url, timeout=20) as r:
                time.sleep(0.6)  # stay well under 20 calls / 10 s
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code == 429:
                time.sleep(2 ** attempt)
                continue
            raise
    raise RuntimeError(f"rate limited: {url}")


def trim(obj):
    return {k: v for k, v in obj.items() if k not in DROP_KEYS}


def write(slug, show, episode, expected):
    OUT.mkdir(parents=True, exist_ok=True)
    data = {"show": trim(show), "episode": trim(episode), "expected": expected}
    (OUT / f"{slug}.json").write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    print(f"{slug}: airdate={episode['airdate']} airtime={episode['airtime']!r} airstamp={episode['airstamp']}")


def main():
    for slug, query, season, number, instant, confidence, source, note in CASES:
        show = get("/singlesearch/shows", q=query)
        episode = get(f"/shows/{show['id']}/episodebynumber", season=season, number=number)
        write(slug, show, episode, {"instant": instant, "confidence": confidence, "source": source, "note": note})

    found = set()
    for day in ("2026-10-28", "2026-10-29", "2026-10-30"):
        for item in get("/schedule/web", date=day):
            show = item.get("_embedded", {}).get("show", {})
            channel = (show.get("webChannel") or {}).get("name")
            slug = PLACEHOLDER_CHANNELS.get(channel)
            if slug and slug not in found and item.get("airtime") == "":
                write(slug, show, item, {"instant": None, "confidence": "dateOnly", "source": f"{API}/schedule/web?date={day}",
                                         "note": f"{channel} placeholder airstamp with empty airtime; no rule, so date only"})
                found.add(slug)
    missing = set(PLACEHOLDER_CHANNELS.values()) - found
    if missing:
        print("missing placeholder cases:", ", ".join(sorted(missing)))


def trim_show(show):
    show = trim(show)
    embedded = (show.get("_embedded") if "_embedded" in show else None)
    return show if embedded is None else {**show, "_embedded": {k: trim(v) for k, v in embedded.items()}}


def record_client():
    """Raw endpoint responses for TVmazeClient parser tests (MeridianTests/Fixtures/tvmaze/)."""
    out = OUT.parent / "tvmaze"
    out.mkdir(parents=True, exist_ok=True)

    def save(name, data):
        (out / f"{name}.json").write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
        print(f"{name}: {len(data) if isinstance(data, list) else 'object'}")

    for query in ("euphoria", "silo"):
        results = get("/search/shows", q=query)
        save(f"search-{query}", [{"score": r["score"], "show": trim(r["show"])} for r in results])
    silo = get("/singlesearch/shows", q="silo")
    url = f"{API}/shows/{silo['id']}?embed[]=nextepisode&embed[]=previousepisode"
    with urllib.request.urlopen(url, timeout=20) as r:
        show = json.load(r)
    embedded = show.get("_embedded", {})
    show = trim(show)
    show["_embedded"] = {k: trim(v) for k, v in embedded.items()}
    save("show-silo-embed", show)
    save("episodes-silo", [trim(e) for e in get(f"/shows/{silo['id']}/episodes")])


if __name__ == "__main__":
    import sys
    record_client() if sys.argv[1:] == ["client"] else main()
