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
    "p_parrot": ("1f99c",), "q_queen": ("1f478",), "r_rabbit": ("1f407",),
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


def main():
    made = []
    for name in ("items_abc.json", "items_animals.json", "items_birds.json"):
        for it in json.loads((CONTENT / name).read_text(encoding="utf-8")):
            spec = PICTURES[it["id"]]
            img = (compose_abc(it["letter"], spec) if it["section"] == "abc"
                   else compose_plain(spec))
            made.append(save(img, it["image"]))
    for it in json.loads((CONTENT / "items_numbers.json").read_text("utf-8")):
        made.append(save(compose_number(it["number"]), it["image"]))
    for s in json.loads((CONTENT / "sections.json").read_text("utf-8")):
        made.append(save(compose_plain(PICTURES[f"sections/{s['id']}"]),
                         s["image"]))
    write_notice()

    # These pictures are no longer placeholders.
    if LIST_FILE.exists():
        remaining = [p for p in LIST_FILE.read_text("utf-8").split()
                     if p not in set(made)]
        LIST_FILE.write_text("\n".join(remaining) + "\n", encoding="utf-8")
    print(f"wrote {len(made)} pictures")


if __name__ == "__main__":
    main()
