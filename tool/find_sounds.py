"""Lists candidate real animal/bird recordings on Wikimedia Commons whose
licence allows commercial use (public domain, CC0, CC BY, CC BY-SA).

    python tool/find_sounds.py [id ...]

Prints title, duration, licence and author so a person can choose; the
chosen files go into SOUNDS in tool/make_sounds.py.
"""

import json
import sys
import time
import urllib.parse
import urllib.request

API = "https://commons.wikimedia.org/w/api.php"
UA = "KidoraplayContentTool/1.0 (educational app; contact: dev team)"
OK_LICENCES = ("public domain", "pd", "cc0", "cc by", "cc-by")

QUERIES = {
    "cow": "cow moo", "dog": "dog barking", "cat": "cat meow",
    "lion": "Panthera leo roar", "tiger": "Panthera tigris", "elephant": "elephant trumpet",
    "monkey": "monkey calls", "horse": "horse neigh", "goat": "goat bleat",
    "sheep": "sheep bleat", "camel": "Camelus dromedarius", "deer": "deer call",
    "bear": "bear growl", "rabbit": "rabbit sound", "squirrel": "squirrel call",
    "crow": "Corvus splendens call", "parrot": "Psittacula krameri",
    "peacock": "Pavo cristatus call", "sparrow": "house sparrow chirp",
    "pigeon": "pigeon cooing", "duck": "duck quack", "hen": "chicken clucking",
    "owl": "owl hooting", "eagle": "eagle call", "koel": "Eudynamys scolopaceus",
}


def get(params):
    url = API + "?" + urllib.parse.urlencode({**params, "format": "json"})
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for attempt in range(6):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except Exception:
            time.sleep(2 ** attempt)
    raise RuntimeError(f"failed: {url}")


def candidates(query, limit=12):
    data = get({
        "action": "query", "generator": "search",
        "gsrsearch": f"{query} filetype:audio", "gsrnamespace": 6,
        "gsrlimit": limit, "prop": "imageinfo",
        "iiprop": "url|extmetadata|size|mime",
    })
    out = []
    for page in (data.get("query", {}).get("pages", {}) or {}).values():
        info = (page.get("imageinfo") or [{}])[0]
        meta = info.get("extmetadata", {})
        licence = meta.get("LicenseShortName", {}).get("value", "")
        if not any(licence.lower().startswith(l) for l in OK_LICENCES):
            continue
        if "nc" in licence.lower() or "nd" in licence.lower().split("-"):
            continue
        out.append({
            "title": page["title"],
            "duration": info.get("duration"),
            "licence": licence,
            "artist": meta.get("Artist", {}).get("value", ""),
            "url": info.get("url"),
            "page": info.get("descriptionurl"),
        })
    return out


def main():
    ids = sys.argv[1:] or list(QUERIES)
    for id_ in ids:
        print(f"== {id_}: {QUERIES[id_]}")
        for c in candidates(QUERIES[id_]):
            artist = c["artist"]
            if "<" in artist:  # strip HTML
                import re
                artist = re.sub("<[^>]+>", "", artist)
            print(f"  {c['title'][:70]:70} {c['licence'][:14]:14} "
                  f"{(c['duration'] or 0):6.1f}s  {artist[:30]}")


if __name__ == "__main__":
    main()
