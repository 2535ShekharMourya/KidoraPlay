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


ONES = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight",
        "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen",
        "Sixteen", "Seventeen", "Eighteen", "Nineteen"]
TENS = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy",
        "Eighty", "Ninety"]

# Hindi number names 1–100 (index 0 unused). Please have a native speaker
# review spellings before release.
HINDI_NUMBERS = """
- एक दो तीन चार पाँच छह सात आठ नौ दस
ग्यारह बारह तेरह चौदह पंद्रह सोलह सत्रह अठारह उन्नीस बीस
इक्कीस बाईस तेईस चौबीस पच्चीस छब्बीस सत्ताईस अट्ठाईस उनतीस तीस
इकतीस बत्तीस तैंतीस चौंतीस पैंतीस छत्तीस सैंतीस अड़तीस उनतालीस चालीस
इकतालीस बयालीस तैंतालीस चवालीस पैंतालीस छियालीस सैंतालीस अड़तालीस उनचास पचास
इक्यावन बावन तिरपन चौवन पचपन छप्पन सत्तावन अट्ठावन उनसठ साठ
इकसठ बासठ तिरसठ चौंसठ पैंसठ छियासठ सड़सठ अड़सठ उनहत्तर सत्तर
इकहत्तर बहत्तर तिहत्तर चौहत्तर पचहत्तर छिहत्तर सतहत्तर अठहत्तर उन्यासी अस्सी
इक्यासी बयासी तिरासी चौरासी पचासी छियासी सत्तासी अट्ठासी नवासी नब्बे
इक्यानवे बानवे तिरानवे चौरानवे पंचानवे छियानवे सत्तानवे अट्ठानवे निन्यानवे सौ
""".split()


def number_name_en(n):
    """Must match lib/content/number_names.dart."""
    if n == 100:
        return "One Hundred"
    if n < 20:
        return ONES[n]
    tens, ones = divmod(n, 10)
    return TENS[tens] if ones == 0 else f"{TENS[tens]}-{ONES[ones].lower()}"


def number_id(n):
    return number_name_en(n).lower().replace("-", "_").replace(" ", "_")


# Curriculum: Nursery learns 1–20; LKG and UKG learn 1–100.
NUMBERS = [
    (n, number_id(n), number_name_en(n), HINDI_NUMBERS[n],
     ALL_LEVELS if n <= 20 else ["lkg", "ukg"])
    for n in range(1, 101)
]
assert len(HINDI_NUMBERS) == 101, len(HINDI_NUMBERS)

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
          [item("numbers", i, en, hi, number=n, levels=lv)
           for n, i, en, hi, lv in NUMBERS])
    write("items_abc.json",
          [item("abc", i, en, hi, letter=l) for l, i, en, hi in ABC])
    write("items_animals.json",
          [item("animals", i, en, hi, sound=True) for i, en, hi in ANIMALS])
    write("items_birds.json",
          [item("birds", i, en, hi, sound=True) for i, en, hi in BIRDS])


if __name__ == "__main__":
    main()
