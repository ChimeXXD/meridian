# Test fixtures

Recorded API responses that the tests read instead of the network.

- `tvmaze/`, `rules/` and `audit/` hold JSON from the [TVmaze API](https://www.tvmaze.com/api), licensed under
  [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). They're trimmed (no images, summaries or links)
  and, in `rules/` and `audit/`, paired with the release time an independent source confirmed (the source URL is in
  each file). Recorded by `scripts/record-fixtures.py`.
- `anilist/` holds responses from the [AniList API](https://anilist.co), under AniList's terms of use.
- `logos/` holds a sample of `rules/network-logos.json`: image URLs only, no image files.

No artwork is stored here (CLAUDE.md rule 9).
