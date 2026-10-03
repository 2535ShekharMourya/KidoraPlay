"""Writes the sample items_*.json files from compact tables.

Run once to (re)create the Phase 1 sample content. After that the JSON files
are the source of truth and can be edited by hand.

    python tool/make_items.py
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "assets" / "content"
ALL_LEVELS = ["nursery", "lkg", "ukg"]


def item(section, id_, word_en, word_hi, *, letter=None, number=None,
         sound=False, levels=ALL_LEVELS):
    return {
        "id": id_,
        "section": section,
        "levels": levels,
        "letter": letter,
        "number": number,
        "word_en": word_en,
        "word_hi": word_hi,
        "image": f"assets/images/{section}/{id_}.webp",
        "voice_en": f"assets/audio/en/{id_}.m4a",
        "voice_hi": f"assets/audio/hi/{id_}.m4a",
        "sound": f"assets/audio/{section}/{id_}.m4a" if sound else None,
        "rive_reaction": None,
    }


NUMBERS = [
    (1, "one", "One", "एक"), (2, "two", "Two", "दो"),
    (3, "three", "Three", "तीन"), (4, "four", "Four", "चार"),
    (5, "five", "Five", "पाँच"), (6, "six", "Six", "छह"),
    (7, "seven", "Seven", "सात"), (8, "eight", "Eight", "आठ"),
    (9, "nine", "Nine", "नौ"), (10, "ten", "Ten", "दस"),
]

ABC = [
    ("A", "a_apple", "Apple", "सेब"), ("B", "b_ball", "Ball", "गेंद"),
    ("C", "c_cat", "Cat", "बिल्ली"), ("D", "d_dog", "Dog", "कुत्ता"),
    ("E", "e_egg", "Egg", "अंडा"), ("F", "f_fish", "Fish", "मछली"),
    ("G", "g_grapes", "Grapes", "अंगूर"), ("H", "h_hat", "Hat", "टोपी"),
    ("I", "i_ice_cream", "Ice Cream", "आइसक्रीम"), ("J", "j_jug", "Jug", "जग"),
]

ANIMALS = [
    ("cow", "Cow", "गाय"), ("dog", "Dog", "कुत्ता"), ("cat", "Cat", "बिल्ली"),
    ("lion", "Lion", "शेर"), ("tiger", "Tiger", "बाघ"),
    ("elephant", "Elephant", "हाथी"), ("monkey", "Monkey", "बंदर"),
    ("horse", "Horse", "घोड़ा"), ("goat", "Goat", "बकरी"),
    ("sheep", "Sheep", "भेड़"),
]

BIRDS = [
    ("crow", "Crow", "कौआ"), ("parrot", "Parrot", "तोता"),
    ("peacock", "Peacock", "मोर"), ("sparrow", "Sparrow", "गौरैया"),
    ("pigeon", "Pigeon", "कबूतर"), ("duck", "Duck", "बत्तख"),
    ("hen", "Hen", "मुर्गी"), ("owl", "Owl", "उल्लू"),
    ("eagle", "Eagle", "चील"), ("koel", "Koel", "कोयल"),
]


def write(name, items):
    path = CONTENT / name
    path.write_text(
        json.dumps(items, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {path.relative_to(ROOT)} ({len(items)} items)")


def main():
    CONTENT.mkdir(parents=True, exist_ok=True)
    write("items_numbers.json",
          [item("numbers", i, en, hi, number=n) for n, i, en, hi in NUMBERS])
    write("items_abc.json",
          [item("abc", i, en, hi, letter=l) for l, i, en, hi in ABC])
    write("items_animals.json",
          [item("animals", i, en, hi, sound=True) for i, en, hi in ANIMALS])
    write("items_birds.json",
          [item("birds", i, en, hi, sound=True) for i, en, hi in BIRDS])


if __name__ == "__main__":
    main()
