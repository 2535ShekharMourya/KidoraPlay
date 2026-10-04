"""Writes the Phase 1 items_*.json files from compact tables.

Phase 1 content: Numbers 1-100, ABC A-Z, 15 animals, 10 birds. Each word
item has a short, child-level fun fact in English and Hindi. The tables
here are the source; re-run after editing them:

    python tool/make_items.py

Hindi text should be reviewed by a native speaker before release.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "assets" / "content"
ALL_LEVELS = ["nursery", "lkg", "ukg"]


def item(section, id_, word_en, word_hi, *, letter=None, number=None,
         sound=False, levels=ALL_LEVELS, fact=None):
    fact_en, fact_hi = fact if fact else (None, None)
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
        "fact_en": fact_en,
        "fact_hi": fact_hi,
        "voice_fact_en": f"assets/audio/en/{id_}_fact.m4a" if fact else None,
        "voice_fact_hi": f"assets/audio/hi/{id_}_fact.m4a" if fact else None,
        "rive_reaction": None,
    }


# ---------------------------------------------------------------- numbers

ONES = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight",
        "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen",
        "Sixteen", "Seventeen", "Eighteen", "Nineteen"]
TENS = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy",
        "Eighty", "Ninety"]

# Hindi number names 1–100 (index 0 unused).
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
assert len(HINDI_NUMBERS) == 101, len(HINDI_NUMBERS)


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

# ---------------------------------------------------------------- ABC
# (letter, id, English, Hindi, (fact EN, fact HI)) — words Indian
# preschools use on their alphabet charts.
ABC = [
    ("A", "a_apple", "Apple", "सेब",
     ("An apple is red and yummy!", "सेब लाल और मीठा होता है!")),
    ("B", "b_ball", "Ball", "गेंद",
     ("A ball is round. Let's play!", "गेंद गोल होती है। चलो खेलें!")),
    ("C", "c_cat", "Cat", "बिल्ली",
     ("A cat says meow!", "बिल्ली म्याऊँ करती है!")),
    ("D", "d_dog", "Dog", "कुत्ता",
     ("A dog says woof woof!", "कुत्ता भौं भौं करता है!")),
    ("E", "e_egg", "Egg", "अंडा",
     ("A baby bird comes out of an egg!", "अंडे से छोटा सा चूज़ा निकलता है!")),
    ("F", "f_fish", "Fish", "मछली",
     ("A fish swims in the water.", "मछली पानी में तैरती है।")),
    ("G", "g_grapes", "Grapes", "अंगूर",
     ("Grapes are small and sweet!", "अंगूर छोटे और मीठे होते हैं!")),
    ("H", "h_hat", "Hat", "टोपी",
     ("A hat goes on your head.", "टोपी सिर पर पहनते हैं।")),
    ("I", "i_ice_cream", "Ice Cream", "आइसक्रीम",
     ("Ice cream is cold and yummy!", "आइसक्रीम ठंडी और मज़ेदार होती है!")),
    ("J", "j_jug", "Jug", "जग",
     ("We keep water in a jug.", "जग में पानी रखते हैं।")),
    ("K", "k_kite", "Kite", "पतंग",
     ("A kite flies high in the sky!", "पतंग आसमान में ऊँची उड़ती है!")),
    ("L", "l_lion", "Lion", "शेर",
     ("The lion is the king of the jungle!", "शेर जंगल का राजा है!")),
    ("M", "m_mango", "Mango", "आम",
     ("Mango is the king of fruits!", "आम फलों का राजा है!")),
    ("N", "n_nest", "Nest", "घोंसला",
     ("Birds live in a nest.", "चिड़िया घोंसले में रहती है।")),
    ("O", "o_orange", "Orange", "संतरा",
     ("An orange is round and juicy!", "संतरा गोल और रसीला होता है!")),
    ("P", "p_parrot", "Parrot", "तोता",
     ("A parrot is green and can talk!", "तोता हरा होता है और बोल सकता है!")),
    ("Q", "q_queen", "Queen", "रानी",
     ("A queen wears a crown.", "रानी मुकुट पहनती है।")),
    ("R", "r_rabbit", "Rabbit", "खरगोश",
     ("A rabbit has long ears and loves carrots!",
      "खरगोश के लंबे कान होते हैं और उसे गाजर पसंद है!")),
    ("S", "s_sun", "Sun", "सूरज",
     ("The sun gives us light!", "सूरज हमें रोशनी देता है!")),
    ("T", "t_tree", "Tree", "पेड़",
     ("A tree gives us fruits and shade.", "पेड़ हमें फल और छाया देता है।")),
    ("U", "u_umbrella", "Umbrella", "छाता",
     ("An umbrella keeps us dry in the rain!",
      "छाता हमें बारिश से बचाता है!")),
    ("V", "v_van", "Van", "वैन",
     ("A van goes vroom vroom!", "वैन चलती है, वूँ वूँ!")),
    ("W", "w_watch", "Watch", "घड़ी",
     ("A watch tells us the time. Tick tock!",
      "घड़ी हमें समय बताती है। टिक टिक!")),
    ("X", "x_x_ray", "X-ray", "एक्स-रे",
     ("An X-ray shows the bones inside us!",
      "एक्स-रे हमारे अंदर की हड्डियाँ दिखाता है!")),
    ("Y", "y_yo_yo", "Yo-yo", "यो-यो",
     ("A yo-yo goes up and down!", "यो-यो ऊपर नीचे जाता है!")),
    ("Z", "z_zebra", "Zebra", "ज़ेबरा",
     ("A zebra has black and white stripes!",
      "ज़ेबरा पर काली और सफ़ेद धारियाँ होती हैं!")),
]

# ---------------------------------------------------------------- animals
# (id, English, Hindi, (fact EN, fact HI))
ANIMALS = [
    ("cow", "Cow", "गाय", ("The cow gives us milk!", "गाय हमें दूध देती है!")),
    ("dog", "Dog", "कुत्ता",
     ("A dog is a good friend!", "कुत्ता हमारा अच्छा दोस्त है!")),
    ("cat", "Cat", "बिल्ली",
     ("A cat loves to drink milk!", "बिल्ली को दूध पीना पसंद है!")),
    ("lion", "Lion", "शेर",
     ("The lion is the king of the jungle!", "शेर जंगल का राजा है!")),
    ("tiger", "Tiger", "बाघ",
     ("The tiger has orange and black stripes!",
      "बाघ पर नारंगी और काली धारियाँ होती हैं!")),
    ("elephant", "Elephant", "हाथी",
     ("An elephant has a long trunk, just like me!",
      "हाथी की लंबी सूँड होती है, बिल्कुल मेरी तरह!")),
    ("monkey", "Monkey", "बंदर",
     ("A monkey loves bananas!", "बंदर को केला बहुत पसंद है!")),
    ("horse", "Horse", "घोड़ा",
     ("A horse can run very fast!", "घोड़ा बहुत तेज़ दौड़ता है!")),
    ("goat", "Goat", "बकरी",
     ("A goat likes to eat leaves.", "बकरी को पत्ते खाना पसंद है।")),
    ("sheep", "Sheep", "भेड़",
     ("A sheep has soft, woolly fur.", "भेड़ के बाल मुलायम ऊन जैसे होते हैं।")),
    ("camel", "Camel", "ऊँट",
     ("A camel walks in the desert.", "ऊँट रेगिस्तान में चलता है।")),
    ("deer", "Deer", "हिरण",
     ("A deer can jump very high!", "हिरण बहुत ऊँचा कूद सकता है!")),
    ("bear", "Bear", "भालू",
     ("A bear loves to eat honey!", "भालू को शहद खाना पसंद है!")),
    ("rabbit", "Rabbit", "खरगोश",
     ("A rabbit hops, hop hop hop!", "खरगोश फुदकता है, फुदक फुदक!")),
    ("squirrel", "Squirrel", "गिलहरी",
     ("A squirrel has a fluffy tail!", "गिलहरी की पूँछ झबरीली होती है!")),
]

BIRDS = [
    ("crow", "Crow", "कौआ", ("A crow is black and clever!", "कौआ काला और चतुर होता है!")),
    ("parrot", "Parrot", "तोता",
     ("A parrot is green and can talk!", "तोता हरा होता है और बोल सकता है!")),
    ("peacock", "Peacock", "मोर",
     ("The peacock is India's national bird!", "मोर भारत का राष्ट्रीय पक्षी है!")),
    ("sparrow", "Sparrow", "गौरैया",
     ("A sparrow is a tiny brown bird.", "गौरैया छोटी सी भूरी चिड़िया है।")),
    ("pigeon", "Pigeon", "कबूतर",
     ("A pigeon says coo coo!", "कबूतर गुटर गूँ करता है!")),
    ("duck", "Duck", "बत्तख",
     ("A duck swims in the pond!", "बत्तख तालाब में तैरती है!")),
    ("hen", "Hen", "मुर्गी",
     ("A hen lays eggs.", "मुर्गी अंडे देती है।")),
    ("owl", "Owl", "उल्लू",
     ("An owl is awake at night!", "उल्लू रात को जागता है!")),
    ("eagle", "Eagle", "चील",
     ("An eagle flies very high!", "चील बहुत ऊँचा उड़ती है!")),
    ("koel", "Koel", "कोयल",
     ("The koel sings a sweet song!", "कोयल मीठा गाना गाती है!")),
]

# What Kido says for each animal/bird sound until real recordings exist.
SOUND_TEXT = {
    "cow": "Mooo! Mooo!", "dog": "Woof woof!", "cat": "Meow! Meow!",
    "lion": "Roarrr!", "tiger": "Grrrr! Grrrr!", "elephant": "Pawooo!",
    "monkey": "Ooh ooh, aah aah!", "horse": "Neighhh!",
    "goat": "Meh-eh-eh!", "sheep": "Baa baa!", "camel": "Grumble grumble!",
    "deer": "Bleat bleat!", "bear": "Grrr!", "rabbit": "Sniff sniff!",
    "squirrel": "Chit chit chit!",
    "crow": "Caw caw!", "parrot": "Squawk! Hello!", "peacock": "Mayaow!",
    "sparrow": "Chirp chirp!", "pigeon": "Coo coo!", "duck": "Quack quack!",
    "hen": "Cluck cluck!", "owl": "Hoo hoo!", "eagle": "Screech!",
    "koel": "Koo-hoo! Koo-hoo!",
}


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
          [item("abc", i, en, hi, letter=l, fact=f)
           for l, i, en, hi, f in ABC])
    write("items_animals.json",
          [item("animals", i, en, hi, sound=True, fact=f)
           for i, en, hi, f in ANIMALS])
    write("items_birds.json",
          [item("birds", i, en, hi, sound=True, fact=f)
           for i, en, hi, f in BIRDS])


if __name__ == "__main__":
    main()
