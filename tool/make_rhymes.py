"""Writes the rhymes: assets/content/rhymes.json and a picture per rhyme.

Only rhymes that are safe to use: traditional English nursery rhymes
(public domain), traditional Hindi folk rhymes, and original Kido rhymes.
Never film songs or anyone's recordings. Each line has a xylophone tune
(notes from tool/make_notes.py) played before Kido says the line; sung
recordings by a voice artist can replace this later (a "song" file per
rhyme with line start times).

    python tool/make_rhymes.py
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from make_stories import compose  # noqa: E402
from make_pictures import save  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "assets" / "content"

# Tunes: "note:beats" separated by spaces (a beat is a short tap).
TWINKLE_A = "c5:1 c5:1 g5:1 g5:1 a5:1 a5:1 g5:2"
TWINKLE_B = "f5:1 f5:1 e5:1 e5:1 d5:1 d5:1 c5:2"
TWINKLE_C = "g5:1 g5:1 f5:1 f5:1 e5:1 e5:1 d5:2"

# (id, language, levels, title_en, title_hi, picture (scene, elements),
#  [(line, tune)])
RHYMES = [
    ("twinkle", "en", ["baby", "nursery", "lkg", "ukg"],
     "Twinkle Twinkle", "ट्विंकल ट्विंकल",
     ("night", [("2b50", .5, .35, .35), ("1f319", .8, .2, .2)]),
     [("Twinkle, twinkle, little star,", TWINKLE_A),
      ("How I wonder what you are!", TWINKLE_B),
      ("Up above the world so high,", TWINKLE_C),
      ("Like a diamond in the sky.", TWINKLE_C),
      ("Twinkle, twinkle, little star,", TWINKLE_A),
      ("How I wonder what you are!", TWINKLE_B)]),
    ("baa_baa", "en", ["baby", "nursery", "lkg", "ukg"],
     "Baa Baa", "बा बा ब्लैक शीप",
     ("day", [("*1f411", .4, .55, .45), ("1f9f6", .75, .6, .22)]),
     [("Baa, baa, black sheep, have you any wool?",
       "c5:1 c5:1 g5:1 g5:1 a5:1 a5:1 a5:1 a5:1 g5:2"),
      ("Yes sir, yes sir, three bags full!", TWINKLE_B),
      ("One for the master, one for the dame,",
       "g5:1 g5:1 g5:1 f5:1 f5:1 e5:1 e5:1 d5:2"),
      ("And one for the little boy who lives down the lane.",
       "g5:1 g5:1 f5:1 f5:1 f5:1 e5:1 e5:1 e5:1 d5:2")]),
    ("johny_johny", "en", ["nursery", "lkg", "ukg"],
     "Johny Johny", "जॉनी जॉनी",
     ("home", [("1f466_1f3fd", .35, .55, .45), ("1f36c", .7, .45, .2)]),
     [("Johny, Johny!", "g5:1 e5:1 g5:1 e5:1"),
      ("Yes, Papa?", "g5:1 g5:1 e5:2"),
      ("Eating sugar?", "f5:1 f5:1 d5:1 d5:1"),
      ("No, Papa!", "f5:1 f5:1 d5:2"),
      ("Telling lies?", "e5:1 e5:1 c5:2"),
      ("No, Papa!", "e5:1 e5:1 c5:2"),
      ("Open your mouth!", "g5:1 g5:1 g5:1 c6:1"),
      ("Ha! Ha! Ha!", "c6:1 g5:1 c5:2")]),
    ("rain_rain", "en", ["baby", "nursery", "lkg", "ukg"],
     "Rain Rain", "रेन रेन",
     ("day", [("1f327", .45, .3, .35), ("2602", .7, .62, .3)]),
     [("Rain, rain, go away,", "g5:1 e5:1 g5:1 g5:1 e5:2"),
      ("Come again another day.", "g5:1 g5:1 e5:1 a5:1 g5:1 g5:1 e5:2"),
      ("Little children want to play,", "g5:1 g5:1 e5:1 e5:1 g5:1 g5:1 e5:2"),
      ("Rain, rain, go away!", "g5:1 e5:1 g5:1 g5:1 c5:2")]),
    ("machhli", "hi", ["baby", "nursery", "lkg", "ukg"],
     "Machhli Jal Ki Rani", "मछली जल की रानी है",
     ("water", [("1f41f", .45, .7, .3), ("1f4a7", .7, .45, .15)]),
     [("मछली जल की रानी है,", "e5:1 g5:1 g5:1 e5:1 a5:2"),
      ("जीवन उसका पानी है।", "g5:1 g5:1 e5:1 d5:1 c5:2"),
      ("हाथ लगाओ, डर जाएगी,", "e5:1 g5:1 g5:1 e5:1 a5:2"),
      ("बाहर निकालो, मर जाएगी।", "g5:1 g5:1 e5:1 d5:1 c5:2")]),
    ("hathi_raja", "hi", ["baby", "nursery", "lkg", "ukg"],
     "Hathi Raja", "हाथी राजा कहाँ चले",
     ("jungle", [("1f418", .45, .55, .5), ("1f451", .45, .2, .15)]),
     [("हाथी राजा, कहाँ चले?", "c5:1 e5:1 g5:1 g5:1 e5:2"),
      ("सूँड हिलाकर, कहाँ चले?", "d5:1 f5:1 a5:1 a5:1 f5:2"),
      ("मेरे घर भी आओ ना,", "e5:1 e5:1 g5:1 g5:1 c6:2"),
      ("हलवा पूरी खाओ ना!", "a5:1 a5:1 g5:1 e5:1 c5:2")]),
    ("ginti_gaana", "hi", ["baby", "nursery", "lkg", "ukg"],
     "Kido's Counting Song", "किडो का गिनती गाना",
     ("day", [("1f418", .32, .55, .45), ("1f522", .72, .4, .3)]),
     [("एक, दो, तीन, चार,", "c5:1 d5:1 e5:1 f5:1"),
      ("किडो बोले, नमस्कार!", "g5:1 g5:1 a5:1 g5:2"),
      ("पाँच, छह, सात, आठ,", "c6:1 b5:1 a5:1 g5:1"),
      ("सीखो रोज़ नया पाठ!", "f5:1 f5:1 e5:1 d5:2"),
      ("नौ और दस,", "e5:1 e5:1 g5:2"),
      ("बस, बस, बस!", "c6:1 c6:1 c6:2")]),
]


def main():
    out = []
    for rid, lang, levels, en, hi, (scene, elements), lines in RHYMES:
        pic = f"assets/images/rhymes/{rid}.webp"
        save(compose(scene, elements), pic)
        out.append({
            "id": rid, "language": lang, "levels": levels,
            "title_en": en, "title_hi": hi, "image": pic,
            "lines": [
                {"text": text, "tune": tune,
                 "voice": f"assets/audio/{lang}/rhymes/{rid}_{i}.m4a"}
                for i, (text, tune) in enumerate(lines, 1)
            ],
        })
    p = CONTENT / "rhymes.json"
    p.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n",
                 encoding="utf-8")
    print(f"wrote {p.relative_to(ROOT)} ({len(out)} rhymes)")


if __name__ == "__main__":
    main()
