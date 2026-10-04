"""Replaces animal and bird pictures with real photographs.

Each item uses the lead photo of a Wikipedia article (hosted on Wikimedia
Commons), kept only if its licence allows commercial use (public domain,
CC0, CC BY, CC BY-SA). The photo is centre-cropped to a square, resized to
512 px and saved as .webp at the item's image path. Credits go to
assets/images/PHOTO_CREDITS.md (shown on the app's licences page).

Override a photo by putting "File:..." instead of an article title in
ARTICLES. A contact sheet is written to tool/.cache/photos/sheet.png for
review.

    python tool/make_photos.py
"""

import json
import re
import subprocess
import time
import urllib.parse
import urllib.request
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "assets" / "content"
CACHE = ROOT / "tool" / ".cache" / "photos"
CREDITS = ROOT / "assets" / "images" / "PHOTO_CREDITS.md"
WIKI = "https://en.wikipedia.org/w/api.php"
COMMONS = "https://commons.wikimedia.org/w/api.php"
UA = "KidoraplayContentTool/1.0 (educational app)"
OK_LICENCES = ("public domain", "pd", "cc0", "cc by", "cc-by")
SIZE = 512

# item id -> Wikipedia article (or "File:..." on Commons). Indian species
# where that is what children here see.
ARTICLES = {
    "cow": "Cattle", "dog": "Indian pariah dog", "cat": "Cat", "lion": "Lion",
    "tiger": "Bengal tiger", "elephant": "Indian elephant",
    "monkey": "Rhesus macaque", "horse": "Arabian horse", "goat": "Goat",
    "sheep": "Suffolk sheep", "camel": "Dromedary", "deer": "Chital",
    "bear": "Brown bear", "rabbit": "Domestic rabbit",
    "squirrel": "Indian palm squirrel",
    "crow": "House crow", "parrot": "Rose-ringed parakeet",
    "peacock": "Peafowl", "sparrow": "House sparrow",
    "pigeon": "Rock dove", "duck": "Mallard", "hen": "Chicken",
    "owl": "Barn owl", "eagle": "Golden eagle", "koel": "Asian koel",
    # Section tiles.
    "sections/animals": "Lion", "sections/birds": "Peafowl",
}


def api(url, params):
    full = url + "?" + urllib.parse.urlencode({**params, "format": "json"})
    req = urllib.request.Request(full, headers={"User-Agent": UA})
    for attempt in range(8):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except Exception:
            time.sleep(min(2 ** attempt, 30))
    raise RuntimeError(f"API failed: {params}")


def lead_file(article):
    if article.startswith("File:"):
        return article
    data = api(WIKI, {"action": "query", "titles": article,
                      "prop": "pageimages", "piprop": "name",
                      "redirects": 1})
    page = next(iter(data["query"]["pages"].values()))
    name = page.get("pageimage")
    if not name:
        raise RuntimeError(f"no lead image for {article}")
    return "File:" + name


def file_info(title):
    data = api(COMMONS, {"action": "query", "titles": title,
                         "prop": "imageinfo",
                         "iiprop": "url|extmetadata", "iiurlwidth": 1024})
    page = next(iter(data["query"]["pages"].values()))
    ii = page["imageinfo"][0]
    meta = ii["extmetadata"]

    def text(key):
        raw = meta.get(key, {}).get("value", "")
        return re.sub(r"\s+", " ", re.sub("<[^>]+>", "", raw)).strip()

    return {
        "title": title[5:],
        "thumb": ii.get("thumburl") or ii["url"],
        "page": ii["descriptionurl"],
        "licence": text("LicenseShortName"),
        "licence_url": meta.get("LicenseUrl", {}).get("value", ""),
        "artist": text("Artist") or "Unknown",
    }


def allowed(licence):
    low = licence.lower()
    return (any(low.startswith(l) for l in OK_LICENCES)
            and "nc" not in low.replace("-", " ").split()
            and "nd" not in low.replace("-", " ").split())


def download(url, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.stat().st_size > 1000:
        return
    part = path.with_suffix(".part")
    subprocess.run(["curl", "-sSL", "--retry", "10", "--retry-all-errors",
                    "--retry-delay", "3", "--max-time", "240", "-A", UA,
                    "-o", str(part), url], check=True)
    part.replace(path)


def square(img):
    """Centre crop, nudged up a little: subjects sit slightly high."""
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = max(0, min(h - side, int((h - side) * 0.4)))
    return img.crop((left, top, left + side, top + side))


def main():
    images = {}
    for name in ("items_animals.json", "items_birds.json"):
        for it in json.loads((CONTENT / name).read_text(encoding="utf-8")):
            images[it["id"]] = it["image"]
    for s in json.loads((CONTENT / "sections.json").read_text("utf-8")):
        images[f"sections/{s['id']}"] = s["image"]

    credits, sheet = [], []
    for key, article in ARTICLES.items():
        info = file_info(lead_file(article))
        if not allowed(info["licence"]):
            print(f"SKIP {key}: {info['title']} is {info['licence']}")
            continue
        src = CACHE / re.sub(r"[^\w.-]", "_", info["title"])
        download(info["thumb"], src)
        img = ImageOps.exif_transpose(Image.open(src)).convert("RGB")
        img = square(img).resize((SIZE, SIZE), Image.LANCZOS)
        out = ROOT / images[key]
        img.save(out, "WEBP", quality=80, method=6)
        sheet.append(img)
        credits.append({**info, "id": key})
        print(f"{key:18} {info['licence']:16} {info['title'][:50]}")

    lines = ["# Photo credits", "",
             "Animal and bird photographs from Wikimedia Commons, cropped and",
             "resized for Kidoraplay. Cropped versions of CC BY-SA photos are",
             "shared under the same licence.", ""]
    for c in credits:
        lines.append(f"- **{c['id']}**: \"{c['title']}\" by {c['artist']}, "
                     f"{c['licence']} ({c['licence_url'] or 'public domain'}),"
                     f" {c['page']}")
    CREDITS.write_text("\n".join(lines) + "\n", encoding="utf-8")

    cols = 7
    rows = (len(sheet) + cols - 1) // cols
    contact = Image.new("RGB", (cols * 170, rows * 170), "white")
    for i, im in enumerate(sheet):
        contact.paste(im.resize((165, 165)), ((i % cols) * 170, (i // cols) * 170))
    CACHE.mkdir(parents=True, exist_ok=True)
    contact.save(CACHE / "sheet.png")
    print(f"wrote {len(credits)} photos; sheet at {CACHE / 'sheet.png'}")


if __name__ == "__main__":
    main()
