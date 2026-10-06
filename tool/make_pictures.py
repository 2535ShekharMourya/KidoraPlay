"""Builds item and section pictures from Google's Noto Emoji 3D artwork.

Downloads each source PNG once (cached in tool/.cache/noto) and composes
512x512 transparent .webp pictures:

- Animals / birds / section tiles: the picture, centred.
- ABC: the letter pair ("A a") on top, the picture below.
- Numbers 1-20: the numeral plus that many stars to count.
- Numbers 21-100: the numeral (the app shows place value separately).

Licence: Noto Emoji, (c) Google LLC, SIL Open Font License 1.1 / Apache
2.0 (see assets/images/NOTICE-noto-emoji.txt). These are good stand-ins
until custom Kidoraplay art exists; replace files freely.

    python tool/make_pictures.py
"""

import io
import json
import math
import urllib.request
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "assets" / "content"
CACHE = ROOT / "tool" / ".cache" / "noto"
FONT = ROOT / "assets" / "fonts" / "Baloo2-Variable.ttf"
NOTICE = ROOT / "assets" / "images" / "NOTICE-noto-emoji.txt"
LIST_FILE = ROOT / "tool" / "placeholder_assets.txt"
BASE = "https://raw.githubusercontent.com/googlefonts/noto-emoji/main"
SIZE = 512
INK = (46, 42, 71, 255)

# id -> (codepoint, optional recolour (dark, light))
PICTURES = {
    # ABC
    "a_apple": ("1f34e",), "b_ball": ("26bd",), "c_cat": ("1f408",),
    "d_dog": ("1f415",), "e_egg": ("1f95a",), "f_fish": ("1f41f",),
    "g_grapes": ("1f347",), "h_hat": ("1f452",), "i_ice_cream": ("1f366",),
    "j_jug": ("1f3fa",), "k_kite": ("1fa81",), "l_lion": ("1f981",),
    "m_mango": ("1f96d",), "n_nest": ("1faba",), "o_orange": ("1f34a",),
    "p_parrot": ("1f99c",), "q_quail": ("1f426",), "r_rabbit": ("1f407",),
    "s_sun": ("2600",), "t_tree": ("1f333",), "u_umbrella": ("2602",),
    "v_van": ("1f690",), "w_watch": ("231a",), "x_x_ray": ("1fa7b",),
    "y_yo_yo": ("1fa80",), "z_zebra": ("1f993",),
    # Animals
    "cow": ("1f404",), "dog": ("1f415",), "cat": ("1f408",),
    "lion": ("1f981",), "tiger": ("1f405",), "elephant": ("1f418",),
    "monkey": ("1f412",), "horse": ("1f40e",), "goat": ("1f410",),
    "sheep": ("1f411",), "camel": ("1f42a",), "deer": ("1f98c",),
    "bear": ("1f43b",), "rabbit": ("1f407",), "squirrel": ("1f43f",),
    # Birds (no sparrow/koel artwork: recolour the generic bird)
    "crow": ("1f426_200d_2b1b",), "parrot": ("1f99c",),
    "peacock": ("1f99a",), "sparrow": ("1f426", ((92, 60, 36), (222, 190, 150))),
    "pigeon": ("1f54a",), "duck": ("1f986",), "hen": ("1f414",),
    "owl": ("1f989",), "eagle": ("1f985",),
    "koel": ("1f426", ((18, 20, 38), (90, 96, 130))),
    # Section tiles
    "sections/numbers": ("1f522",), "sections/abc": ("1f524",),
    "sections/animals": ("1f981",), "sections/birds": ("1f99c",),
    # Games
    "games/games": ("1f9e9",), "games/find_it": ("1f50d",),
    "games/who_says": ("1f442",), "games/count_it": ("1f9ee",),
    "games/letters": ("1f524",),
    "games/tap_play": ("1f423",), "games/memory": ("1f0cf",),
    "games/music": ("1f3b9",),
}
STAR = "2b50"


def emoji(codepoint):
    CACHE.mkdir(parents=True, exist_ok=True)
    path = CACHE / f"{codepoint}.png"
    if not path.exists():
        url = f"{BASE}/3D/png/512/emoji_u{codepoint}.png"
        with urllib.request.urlopen(url, timeout=60) as r:
            path.write_bytes(r.read())
    return Image.open(path).convert("RGBA")


def recolour(img, dark, light):
    alpha = img.getchannel("A")
    tinted = ImageOps.colorize(ImageOps.grayscale(img), dark, light)
    tinted = tinted.convert("RGBA")
    tinted.putalpha(alpha)
    return tinted


def font(size):
    f = ImageFont.truetype(str(FONT), size)
    try:
        f.set_variation_by_axes([700])
    except Exception:
        pass
    return f


def fit(img, box):
    img = img.copy()
    img.thumbnail((box, box), Image.LANCZOS)
    return img


def canvas():
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def text_centered(draw, y, text, size):
    f = font(size)
    w = draw.textlength(text, font=f)
    draw.text(((SIZE - w) / 2, y), text, font=f, fill=INK)


def picture(spec):
    img = emoji(spec[0])
    if len(spec) > 1:
        img = recolour(img, *spec[1])
    return img


def compose_plain(spec):
    out = canvas()
    img = fit(picture(spec), 440)
    out.alpha_composite(img, ((SIZE - img.width) // 2, (SIZE - img.height) // 2))
    return out


def compose_abc(letter, spec):
    out = canvas()
    text_centered(ImageDraw.Draw(out), 0, f"{letter} {letter.lower()}", 150)
    img = fit(picture(spec), 300)
    out.alpha_composite(img, ((SIZE - img.width) // 2, SIZE - img.height - 10))
    return out


def compose_number(n):
    out = canvas()
    draw = ImageDraw.Draw(out)
    if n > 20:
        text_centered(draw, 40, str(n), 300)
        return out
    text_centered(draw, -10, str(n), 210)
    per_row = 5 if n <= 10 else 10
    step = 84 if n <= 10 else 48
    star = fit(emoji(STAR), step - 6)
    rows = (n + per_row - 1) // per_row
    top = 270 if rows == 1 else 260
    for k in range(n):
        row, col = divmod(k, per_row)
        count = min(per_row, n - row * per_row)
        x = int(SIZE / 2 - count * step / 2 + col * step + 3)
        y = int(top + row * (step + 8))
        out.alpha_composite(star, (x, y))
    return out


# ---------------------------------------------------------------- Phase 2
SHAPE_COLOURS = {
    "circle": (255, 99, 132), "square": (54, 162, 235),
    "triangle": (255, 193, 7), "rectangle": (76, 175, 80),
    "star": (255, 152, 0), "heart": (233, 30, 99),
    "oval": (156, 39, 176), "diamond": (0, 188, 212),
    "hexagon": (255, 112, 67),
}
OUTLINE = (59, 53, 97, 255)


def shape_points(name, box):
    """Polygon points for shapes drawn as polygons, inside box (l,t,r,b)."""
    l, t, r, b = box
    cx, cy = (l + r) / 2, (t + b) / 2
    w, h = r - l, b - t
    if name == "triangle":
        return [(cx, t), (r, b), (l, b)]
    if name == "hexagon":
        return [(cx + (w / 2) * math.cos(math.pi / 3 * i),
                 cy + (h / 2) * math.sin(math.pi / 3 * i)) for i in range(6)]
    if name == "diamond":
        return [(cx, t), (r, cy), (cx, b), (l, cy)]
    if name == "star":
        pts = []
        for i in range(10):
            rad = (w / 2) if i % 2 == 0 else (w / 2) * 0.42
            a = -math.pi / 2 + i * math.pi / 5
            pts.append((cx + rad * math.cos(a), cy + 0.05 * h + rad * math.sin(a)))
        return pts
    if name == "heart":
        pts = []
        for i in range(120):
            tt = i / 120 * 2 * math.pi
            x = 16 * math.sin(tt) ** 3
            y = -(13 * math.cos(tt) - 5 * math.cos(2 * tt)
                  - 2 * math.cos(3 * tt) - math.cos(4 * tt))
            pts.append((cx + x * w / 34, cy + y * h / 34))
        return pts
    return None


def compose_shape(name):
    # Draw large and downsample for smooth edges.
    big = 1024
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fill = SHAPE_COLOURS[name] + (255,)
    stroke = 28
    m = 150
    box = {
        "rectangle": (m - 40, 300, big - m + 40, big - 300),
        "oval": (90, 290, big - 90, big - 290),
    }.get(name, (m, m, big - m, big - m))
    if name in ("circle", "oval"):
        d.ellipse(box, fill=fill, outline=OUTLINE, width=stroke)
    elif name in ("square", "rectangle"):
        d.rounded_rectangle(box, radius=40, fill=fill, outline=OUTLINE,
                            width=stroke)
    else:
        pts = shape_points(name, box)
        d.polygon(pts, fill=fill)
        d.line(pts + [pts[0]], fill=OUTLINE, width=stroke, joint="curve")
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def compose_colour(rgb, emoji_code):
    out = canvas()
    d = ImageDraw.Draw(out)
    border = OUTLINE if rgb != (255, 255, 255) else (190, 190, 200, 255)
    # A big paint blob of the colour, with the example object in front.
    d.ellipse((40, 30, 400, 390), fill=rgb + (255,), outline=border, width=10)
    obj = fit(emoji(emoji_code), 270)
    out.alpha_composite(obj, (SIZE - obj.width - 20, SIZE - obj.height - 20))
    return out


def compose_shapes_tile():
    out = canvas()
    for name, (x, y) in {"circle": (20, 20), "triangle": (262, 20),
                         "square": (20, 262), "star": (262, 262)}.items():
        tile = compose_shape(name).resize((230, 230), Image.LANCZOS)
        out.alpha_composite(tile, (x, y))
    return out


def save(img, rel):
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "WEBP", quality=82, method=6)
    size = path.stat().st_size
    assert size < 300_000, f"{rel} is {size} bytes"
    return rel


def write_notice():
    with urllib.request.urlopen(f"{BASE}/LICENSE", timeout=60) as r:
        licence = r.read().decode("utf-8")
    NOTICE.write_text(
        "Item and section pictures are derived from Noto Emoji 3D artwork\n"
        "(https://github.com/googlefonts/noto-emoji), Copyright Google LLC.\n"
        "Per the project README, image resources are available under the\n"
        "Apache License 2.0; the repository LICENSE file is reproduced "
        "below.\n\n" + licence,
        encoding="utf-8",
    )


# ------------------------------------------------- general knowledge pictures

def emoji_toned(code):
    """A Noto emoji; skin-toned variants fall back to the default if the 3D
    set doesn't have them."""
    try:
        return emoji(code)
    except Exception:
        base = code.split("_")[0]
        if base == code:
            raise
        print(f"  no 3D art for {code}, using {base}")
        return emoji(base)


def compose_emoji(code, box=440):
    out = canvas()
    img = fit(emoji_toned(code), box)
    out.alpha_composite(img, ((SIZE - img.width) // 2, (SIZE - img.height) // 2))
    return out


def compose_india_flag():
    """Drawn, so it is always exact: saffron, white, green, navy chakra."""
    out = canvas()
    d = ImageDraw.Draw(out)
    x0, y0, x1, y1 = 36, 116, 476, 410
    h = (y1 - y0) / 3
    d.rounded_rectangle((x0, y0, x1, y1), 18, fill=(255, 255, 255, 255),
                        outline=OUTLINE, width=8)
    d.rectangle((x0 + 4, y0 + 4, x1 - 4, y0 + h), fill=(255, 153, 51, 255))
    d.rectangle((x0 + 4, y1 - h, x1 - 4, y1 - 4), fill=(19, 136, 8, 255))
    cx, cy, r = (x0 + x1) / 2, (y0 + y1) / 2, h * 0.42
    navy = (0, 0, 128, 255)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=navy, width=5)
    for i in range(24):
        a = math.pi * 2 * i / 24
        d.line((cx, cy, cx + r * math.cos(a), cy + r * math.sin(a)),
               fill=navy, width=2)
    d.rounded_rectangle((x0, y0, x1, y1), 18, outline=OUTLINE, width=8)
    return out


def compose_day(index, rgb):
    """A bright week card: the day's short name, and seven dots with this
    day's dot big (Monday first)."""
    out = canvas()
    d = ImageDraw.Draw(out)
    d.rounded_rectangle((26, 40, 486, 472), 48, fill=rgb + (255,),
                        outline=OUTLINE, width=10)
    # Calendar rings.
    for x in (150, 362):
        d.rounded_rectangle((x - 16, 16, x + 16, 92), 14,
                            fill=(255, 255, 255, 255), outline=OUTLINE, width=6)
    name = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"][index]
    f = font(170)
    w = d.textlength(name, font=f)
    d.text(((SIZE - w) / 2, 110), name, font=f, fill=(255, 255, 255, 255),
           stroke_width=6, stroke_fill=OUTLINE)
    step = 58
    x0 = SIZE / 2 - step * 3
    for i in range(7):
        r = 25 if i == index else 13
        x = x0 + i * step
        d.ellipse((x - r, 400 - r, x + r, 400 + r),
                  fill=(255, 255, 255, 255) if i == index else (255, 255, 255, 150),
                  outline=OUTLINE if i == index else None,
                  width=5 if i == index else 0)
    return out


def compose_glass(full):
    out = canvas()
    d = ImageDraw.Draw(out)
    top, bottom = 70, 450
    glass = [(130, top), (382, top), (350, bottom), (162, bottom)]
    if full:
        level = top + 40
        t = (level - top) / (bottom - top)
        lx0, lx1 = 130 + 32 * t, 382 - 32 * t
        d.polygon([(lx0, level), (lx1, level), (350, bottom), (162, bottom)],
                  fill=(84, 172, 255, 255))
        d.ellipse((lx0, level - 14, lx1, level + 14), fill=(140, 200, 255, 255))
    d.polygon(glass, fill=None, outline=OUTLINE, width=10)
    d.line((150, top + 30, 172, bottom - 40), fill=(255, 255, 255, 200), width=10)
    return out


def compose_opposite(spec):
    kind, _, code = spec.partition(":")
    if not code:  # a plain emoji
        return compose_emoji(kind)
    if kind == "glass":
        return compose_glass(code == "full")
    out = canvas()
    d = ImageDraw.Draw(out)
    if kind in ("day", "night"):
        sky = (135, 206, 250, 255) if kind == "day" else (25, 32, 72, 255)
        d.ellipse((16, 16, 496, 496), fill=sky, outline=OUTLINE, width=10)
        if kind == "night":
            for x, y in ((120, 150), (370, 120), (330, 380), (150, 360), (250, 90)):
                d.ellipse((x - 7, y - 7, x + 7, y + 7), fill=(255, 241, 150, 255))
        img = fit(emoji(code), 290)
        out.alpha_composite(img, ((SIZE - img.width) // 2, (SIZE - img.height) // 2))
        return out
    if kind in ("big", "small"):
        img = fit(emoji(code), 470 if kind == "big" else 150)
        out.alpha_composite(img, ((SIZE - img.width) // 2, (SIZE - img.height) // 2))
        return out
    # Up / down: the ground line shows where "down" is.
    d.rounded_rectangle((30, 470, 482, 490), 10, fill=(143, 210, 124, 255))
    img = fit(emoji(code), 230 if kind == "up" else 190)
    y = 10 if kind == "up" else 470 - img.height
    out.alpha_composite(img, ((SIZE - img.width) // 2, y))
    arrow_y0, arrow_y1 = (440, 310) if kind == "up" else (90, 190)
    d.line((SIZE / 2, arrow_y0, SIZE / 2, arrow_y1), fill=OUTLINE, width=14)
    tip = arrow_y1 + (-30 if kind == "up" else 30)
    d.polygon([(SIZE / 2 - 34, arrow_y1), (SIZE / 2 + 34, arrow_y1),
               (SIZE / 2, tip)], fill=OUTLINE)
    return out


def compose_pair(left, right):
    """Two pictures side by side (section tile for opposites)."""
    out = canvas()
    a = fit(emoji(left), 300)
    b = fit(emoji(right), 150)
    out.alpha_composite(a, (20, (SIZE - a.height) // 2))
    out.alpha_composite(b, (SIZE - b.width - 30, SIZE - b.height - 90))
    return out


def compose_family():
    """Mother, father and baby together (the emoji "family" sign is an
    icon, not people)."""
    out = canvas()
    mum = fit(emoji("1f469_1f3fd"), 270)
    dad = fit(emoji("1f468_1f3fd"), 270)
    baby = fit(emoji("1f476_1f3fd"), 210)
    out.alpha_composite(mum, (10, 40))
    out.alpha_composite(dad, (SIZE - dad.width - 10, 40))
    out.alpha_composite(baby, ((SIZE - baby.width) // 2, SIZE - baby.height - 10))
    return out


def general_knowledge():
    from make_items import BODY, DAYS, FAMILY, MONTHS, OPPOSITES
    made = []
    for id_, _en, _hi, code, _f in BODY:
        made.append(save(compose_emoji(code), f"assets/images/body/{id_}.webp"))
    for id_, _en, _hi, code, _f in FAMILY:
        img = compose_family() if code == "1f46a" else compose_emoji(code)
        made.append(save(img, f"assets/images/family/{id_}.webp"))
    for i, (id_, _en, _hi, rgb, _f) in enumerate(DAYS):
        made.append(save(compose_day(i, rgb), f"assets/images/days/{id_}.webp"))
    for id_, _en, _hi, code, _f in MONTHS:
        img = compose_india_flag() if code == "1f1ee_1f1f3" else compose_emoji(code)
        made.append(save(img, f"assets/images/months/{id_}.webp"))
    for pair in OPPOSITES:
        for id_, _en, _hi, spec in pair:
            made.append(save(compose_opposite(spec),
                             f"assets/images/opposites/{id_}.webp"))
    tiles = {
        "body": compose_emoji("1f440"),
        "family": compose_family(),
        "days": compose_day(0, (231, 76, 60)),
        "months": compose_emoji("1f5d3"),
        "opposites": compose_pair("1f418", "1f42d"),
    }
    for id_, img in tiles.items():
        made.append(save(img, f"assets/images/sections/{id_}.webp"))
    return made


def main():
    # Real photographs (tool/make_photos.py) win over illustrations.
    import sys
    sys.path.insert(0, str(Path(__file__).parent))
    from make_photos import ARTICLES as PHOTOS

    made = []
    for name in ("items_abc.json", "items_animals.json", "items_birds.json",
                 "items_fruits.json", "items_vegetables.json"):
        for it in json.loads((CONTENT / name).read_text(encoding="utf-8")):
            if it["id"] in PHOTOS or it["id"] not in PICTURES:
                continue
            spec = PICTURES[it["id"]]
            img = (compose_abc(it["letter"], spec) if it["section"] == "abc"
                   else compose_plain(spec))
            made.append(save(img, it["image"]))
    for it in json.loads((CONTENT / "items_numbers.json").read_text("utf-8")):
        made.append(save(compose_number(it["number"]), it["image"]))
    sys.path.insert(0, str(Path(__file__).parent))
    from make_items import COLOURS, SHAPES
    for id_, _en, _hi, rgb, code, _fact in COLOURS:
        made.append(save(compose_colour(rgb, code),
                         f"assets/images/colours/{id_}.webp"))
    for id_, *_ in SHAPES:
        made.append(save(compose_shape(id_), f"assets/images/shapes/{id_}.webp"))
    made.append(save(compose_plain(("1f3a8",)), "assets/images/sections/colours.webp"))
    made.append(save(compose_shapes_tile(), "assets/images/sections/shapes.webp"))
    from make_items import HINDI
    import shutil
    for _letter, id_, _en, _hi, src, _lv in HINDI:
        out = f"assets/images/hindi/{id_}.webp"
        kind, _, ref = src.partition(":")
        if kind == "copy":
            (ROOT / out).parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / f"assets/images/{ref}.webp", ROOT / out)
            made.append(out)
        elif kind == "noto":
            made.append(save(compose_plain((ref,)), out))
        elif kind == "shape":
            made.append(save(compose_shape(ref), out))
        # "photo:" items come from tool/make_photos.py.
    # Hindi tile: the first vowels drawn in Baloo 2 (single code points,
    # so no Devanagari shaping is needed).
    tile = canvas()
    text_centered(ImageDraw.Draw(tile), 90, "अ आ", 250)
    made.append(save(tile, "assets/images/sections/hindi.webp"))
    for game in ("games", "find_it", "who_says", "count_it", "letters",
                 "tap_play", "memory", "music"):
        made.append(save(compose_plain(PICTURES[f"games/{game}"]),
                         f"assets/images/games/{game}.webp"))
    for s in json.loads((CONTENT / "sections.json").read_text("utf-8")):
        if (f"sections/{s['id']}" in PHOTOS
                or f"sections/{s['id']}" not in PICTURES):
            continue
        made.append(save(compose_plain(PICTURES[f"sections/{s['id']}"]),
                         s["image"]))
    made += general_knowledge()
    write_notice()

    # These pictures are no longer placeholders.
    if LIST_FILE.exists():
        remaining = [p for p in LIST_FILE.read_text("utf-8").split()
                     if p not in set(made)]
        LIST_FILE.write_text("\n".join(remaining) + "\n", encoding="utf-8")
    print(f"wrote {len(made)} pictures")


if __name__ == "__main__":
    main()
