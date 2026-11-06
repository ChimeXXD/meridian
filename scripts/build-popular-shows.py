#!/usr/bin/env python3
"""Write rules/popular-shows.json: the TV shows people read about most on English Wikipedia over the past 12 months
that aired in that year, with each show's TVmaze record and its latest season start (Chime, 6 Nov 2026; D-66).

Usage: python3 -I scripts/build-popular-shows.py [YYYY-MM-DD]   (the build day; today by default)

1. Candidates: every article in English Wikipedia's monthly top 1,000 for the last 12 complete months.
2. Wikidata keeps the articles that are a show (TVmaze series ID, P8600) or a season of one (P179 -> P8600).
3. Popularity: the show's own article's views over those 12 months, plus its season articles' top-list views.
4. TVmaze gives the show (network, poster URLs), its seasons and its last episode. Kept: scripted or animated shows
   whose last episode aired in the past year. Most viewed first, at most LIMIT shows.
5. A platform left with fewer than PER_SERVICE shows (US broadcast shows rarely reach a monthly top 1,000) gets more
   from Wikidata: its own shows (original broadcaster, P449) that haven't ended before the year, ranked by 60 days of
   views in one batched Wikipedia request per 50, the best checked as in steps 3 and 4 and on that platform in TVmaze.
Search reads it for Popular, New seasons and each service's "Popular on" row. Credits names Wikipedia and Wikidata.
"""
import datetime
import json
import pathlib
import sys
import time
import urllib.parse
import urllib.request

AGENT = "Meridian/0.1 (https://github.com/ChimeXXD/meridian; popular-shows build)"
LIMIT = 300
TYPES = {"Scripted", "Animation"}
PER_SERVICE = 15
# Each Search platform chip (PopularServices.swift): its TVmaze names and its Wikidata items, checked 6 Nov 2026.
SERVICES = {
    "Netflix": (["Netflix"], ["Q907311"]),
    "Prime Video": (["Prime Video"], ["Q4740856"]),
    "HBO Max": (["HBO Max", "HBO"], ["Q65359104", "Q23633"]),
    "Disney+": (["Disney+"], ["Q54958752"]),
    "Paramount+": (["Paramount+", "Paramount+ with Showtime"], ["Q27903045"]),
    "Hulu": (["Hulu"], ["Q1630304"]),
    "Peacock": (["Peacock"], ["Q67765302"]),
    "Apple TV": (["Apple TV", "Apple TV+"], ["Q62446736"]),
    "CBS": (["CBS"], ["Q43380"]),
    "NBC": (["NBC"], ["Q13974"]),
    "ABC": (["ABC"], ["Q169889"]),
    "FOX": (["FOX"], ["Q166419"]),
}
OUT = pathlib.Path(__file__).resolve().parent.parent / "rules" / "popular-shows.json"


def get(url, data=None, tries=4):
    for attempt in range(tries):
        try:
            request = urllib.request.Request(url, data=data, headers={"User-Agent": AGENT, "Accept": "application/json"})
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return None
            if attempt == tries - 1:
                raise
            time.sleep(2 * (attempt + 1) if error.code != 429 else 11)


def months(day):
    first = day.replace(day=1)
    out = []
    for _ in range(12):
        first = (first - datetime.timedelta(days=1)).replace(day=1)
        out.append(first)
    return sorted(out)


def top_articles(month_list):
    views = {}
    for month in month_list:
        url = (f"https://wikimedia.org/api/rest_v1/metrics/pageviews/top/en.wikipedia/all-access/"
               f"{month.year}/{month.month:02d}/all-days")
        for article in get(url)["items"][0]["articles"]:
            views[article["article"]] = views.get(article["article"], 0) + article["views"]
    return views


def tvmaze_ids(titles):
    """Wikipedia title -> (TVmaze ID, is a season article)."""
    found = {}
    titles = [t for t in titles if ":" not in t.split("_")[0] and not t.startswith("List_of")]
    for start in range(0, len(titles), 400):
        chunk = titles[start:start + 400]
        values = " ".join(json.dumps(t.replace("_", " ")) + "@en" for t in chunk)
        query = f"""SELECT ?title ?own ?parent WHERE {{
          VALUES ?title {{ {values} }}
          ?article schema:name ?title; schema:isPartOf <https://en.wikipedia.org/>; schema:about ?item.
          OPTIONAL {{ ?item wdt:P8600 ?own }}
          OPTIONAL {{ ?item wdt:P179 ?series. ?series wdt:P8600 ?parent }}
          FILTER(BOUND(?own) || BOUND(?parent))
        }}"""
        body = urllib.parse.urlencode({"query": query, "format": "json"}).encode()
        result = get("https://query.wikidata.org/sparql", data=body)
        for row in result["results"]["bindings"]:
            title = row["title"]["value"].replace(" ", "_")
            if "own" in row:
                found[title] = (int(row["own"]["value"]), False)
            elif title not in found:
                found[title] = (int(row["parent"]["value"]), True)
        time.sleep(1)
    return found


def article_views(title, month_list):
    first, last = month_list[0], month_list[-1]
    end = (last.replace(day=28) + datetime.timedelta(days=4)).replace(day=1) - datetime.timedelta(days=1)
    url = ("https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/en.wikipedia/all-access/user/"
           f"{urllib.parse.quote(title, safe='')}/monthly/{first:%Y%m%d}/{end:%Y%m%d}")
    result = get(url)
    return sum(item["views"] for item in result["items"]) if result else 0


SHOW_FIELDS = ("id", "name", "type", "language", "status", "premiered", "network", "webChannel", "weight", "image")


def tvmaze(show_id):
    time.sleep(0.55)  # TVmaze allows 20 calls every 10 seconds.
    return get(f"https://api.tvmaze.com/shows/{show_id}?embed[]=seasons&embed[]=previousepisode")


def service_candidates(items, cutoff):
    """Wikipedia title -> TVmaze ID for the shows a platform first aired that hadn't ended before `cutoff`."""
    values = " ".join(f"wd:{item}" for item in items)
    query = f"""SELECT ?title ?tvmaze WHERE {{
      VALUES ?net {{ {values} }}
      ?item wdt:P449 ?net; wdt:P8600 ?tvmaze.
      ?article schema:about ?item; schema:isPartOf <https://en.wikipedia.org/>; schema:name ?title.
      OPTIONAL {{ ?item wdt:P582 ?end }}
      FILTER(!BOUND(?end) || ?end >= "{cutoff}T00:00:00Z"^^xsd:dateTime)
    }}"""
    body = urllib.parse.urlencode({"query": query, "format": "json"}).encode()
    rows = get("https://query.wikidata.org/sparql", data=body)["results"]["bindings"]
    time.sleep(1)
    return {row["title"]["value"].replace(" ", "_"): int(row["tvmaze"]["value"]) for row in rows}


def recent_views(titles):
    """Title -> views over the last 60 days, 50 titles a request (Wikipedia's pageviews prop)."""
    views = {}
    for start in range(0, len(titles), 50):
        chunk = titles[start:start + 50]
        url = ("https://en.wikipedia.org/w/api.php?action=query&format=json&formatversion=2&prop=pageviews&titles="
               + urllib.parse.quote("|".join(chunk)))
        for page in (get(url) or {}).get("query", {}).get("pages", []):
            daily = page.get("pageviews") or {}
            views[page["title"].replace(" ", "_")] = sum(v or 0 for v in daily.values())
        time.sleep(0.2)
    return views


def entry(show_id, views, day, cutoff):
    """The list entry for a TVmaze show, or None when it isn't scripted or animated or didn't air in the year."""
    record = tvmaze(show_id)
    if not record or record.get("type") not in TYPES:
        return None
    embedded = record.get("_embedded", {})
    last = (embedded.get("previousepisode") or {}).get("airdate") or ""
    if last < cutoff or last > day.isoformat():
        return None
    started = [s for s in embedded.get("seasons", []) if s.get("premiereDate") and s["premiereDate"] <= day.isoformat()]
    latest = max(started, key=lambda s: s["premiereDate"], default=None)
    return {
        "views": views,
        "lastAired": last,
        "season": latest["number"] if latest else None,
        "seasonStart": latest["premiereDate"] if latest else None,
        "show": {key: record.get(key) for key in SHOW_FIELDS},
    }


def channel(show):
    return ((show.get("network") or show.get("webChannel")) or {}).get("name")


def main():
    day = datetime.date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else datetime.date.today()
    cutoff = (day - datetime.timedelta(days=365)).isoformat()
    month_list = months(day)
    top = top_articles(month_list)
    ids = tvmaze_ids(sorted(top))
    views = {}
    articles = {}
    for title, (show_id, is_season) in ids.items():
        if is_season:
            views[show_id] = views.get(show_id, 0) + top[title]
        else:
            articles[show_id] = title
    for show_id, title in articles.items():
        views[show_id] = views.get(show_id, 0) + article_views(title, month_list)
        time.sleep(0.05)
    shows = []
    for show_id in sorted(views, key=lambda i: -views[i]):
        if len(shows) == LIMIT:
            break
        kept = entry(show_id, views[show_id], day, cutoff)
        if kept:
            shows.append(kept)
    checked = set(views)
    for label, (names, items) in SERVICES.items():
        have = sum(channel(e["show"]) in names for e in shows)
        if have >= PER_SERVICE:
            continue
        candidates = {t: i for t, i in service_candidates(items, cutoff).items() if i not in checked}
        recent = recent_views(sorted(candidates))
        for title in sorted(recent, key=lambda t: -recent[t])[:3 * PER_SERVICE]:
            if have >= PER_SERVICE:
                break
            show_id = candidates.get(title)
            if show_id is None or show_id in checked:
                continue
            checked.add(show_id)
            kept = entry(show_id, article_views(title, month_list), day, cutoff)
            if kept and channel(kept["show"]) in names:
                shows.append(kept)
                have += 1
        print(f"{label}: {have} shows")
    shows.sort(key=lambda e: -e["views"])
    out = {"updated": day.isoformat(), "months": f"{month_list[0]:%Y-%m}..{month_list[-1]:%Y-%m}", "shows": shows}
    OUT.write_text(json.dumps(out, indent=1, ensure_ascii=False) + "\n")
    print(f"{len(top)} top articles, {len(ids)} shows or seasons, {len(shows)} kept -> {OUT.relative_to(OUT.parent.parent)}")


if __name__ == "__main__":
    main()
