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


# ---------------------------------------------------------------- Phase 2
NURSERY_UP = ALL_LEVELS
LKG_UP = ["lkg", "ukg"]

# (id, English, Hindi, (fact EN, fact HI))
FRUITS = [
    ("apple", "Apple", "सेब",
     ("Apples are red and crunchy!", "सेब लाल और कुरकुरा होता है!")),
    ("banana", "Banana", "केला",
     ("A banana is yellow and soft!", "केला पीला और नरम होता है!")),
    ("mango", "Mango", "आम",
     ("Mango is the king of fruits!", "आम फलों का राजा है!")),
    ("orange", "Orange", "संतरा",
     ("An orange is round and juicy!", "संतरा गोल और रसीला होता है!")),
    ("grapes", "Grapes", "अंगूर",
     ("Grapes grow in bunches!", "अंगूर गुच्छों में लगते हैं!")),
    ("watermelon", "Watermelon", "तरबूज़",
     ("A watermelon is green outside and red inside!",
      "तरबूज़ बाहर से हरा और अंदर से लाल होता है!")),
    ("papaya", "Papaya", "पपीता",
     ("A papaya is orange inside!", "पपीता अंदर से नारंगी होता है!")),
    ("pineapple", "Pineapple", "अनानास",
     ("A pineapple has a spiky crown!", "अनानास के ऊपर काँटेदार ताज होता है!")),
    ("guava", "Guava", "अमरूद",
     ("A guava is green and sweet!", "अमरूद हरा और मीठा होता है!")),
    ("pomegranate", "Pomegranate", "अनार",
     ("A pomegranate is full of red seeds!", "अनार में लाल-लाल दाने होते हैं!")),
    ("strawberry", "Strawberry", "स्ट्रॉबेरी",
     ("A strawberry has tiny seeds outside!",
      "स्ट्रॉबेरी के बाहर छोटे-छोटे बीज होते हैं!")),
    ("coconut", "Coconut", "नारियल",
     ("A coconut has sweet water inside!", "नारियल के अंदर मीठा पानी होता है!")),
]

VEGETABLES = [
    ("potato", "Potato", "आलू",
     ("Potatoes grow under the ground!", "आलू ज़मीन के नीचे उगता है!")),
    ("tomato", "Tomato", "टमाटर",
     ("A tomato is red and juicy!", "टमाटर लाल और रसीला होता है!")),
    ("onion", "Onion", "प्याज़",
     ("Cutting an onion can make us cry!", "प्याज़ काटने पर आँसू आ जाते हैं!")),
    ("carrot", "Carrot", "गाजर",
     ("Carrots are good for our eyes!", "गाजर आँखों के लिए अच्छी होती है!")),
    ("cauliflower", "Cauliflower", "फूलगोभी",
     ("A cauliflower is white like a cloud!", "फूलगोभी बादल जैसी सफ़ेद होती है!")),
    ("cabbage", "Cabbage", "पत्तागोभी",
     ("A cabbage has many leaves!", "पत्तागोभी में बहुत सारे पत्ते होते हैं!")),
    ("brinjal", "Brinjal", "बैंगन",
     ("A brinjal is purple!", "बैंगन बैंगनी रंग का होता है!")),
    ("peas", "Peas", "मटर",
     ("Peas hide inside a pod!", "मटर फली के अंदर छिपे होते हैं!")),
    ("cucumber", "Cucumber", "खीरा",
     ("A cucumber is cool and green!", "खीरा ठंडा और हरा होता है!")),
    ("pumpkin", "Pumpkin", "कद्दू",
     ("A pumpkin is big and orange!", "कद्दू बड़ा और नारंगी होता है!")),
    ("spinach", "Spinach", "पालक",
     ("Spinach makes us strong!", "पालक हमें ताक़तवर बनाता है!")),
    ("lady_finger", "Lady Finger", "भिंडी",
     ("Lady finger is long and green!", "भिंडी लंबी और हरी होती है!")),
]

# (id, English, Hindi, swatch RGB, example emoji, (fact EN, fact HI))
COLOURS = [
    ("colour_red", "Red", "लाल", (230, 57, 70), "1f34e",
     ("Apples are red!", "सेब लाल होता है!")),
    ("colour_blue", "Blue", "नीला", (46, 134, 222), "1fad0",
     ("The sky is blue!", "आसमान नीला होता है!")),
    ("colour_yellow", "Yellow", "पीला", (255, 209, 59), "1f34c",
     ("Bananas are yellow!", "केला पीला होता है!")),
    ("colour_green", "Green", "हरा", (62, 178, 75), "1f343",
     ("Leaves are green!", "पत्ते हरे होते हैं!")),
    ("colour_orange", "Orange", "नारंगी", (255, 138, 40), "1f34a",
     ("Oranges are orange!", "संतरा नारंगी होता है!")),
    ("colour_pink", "Pink", "गुलाबी", (255, 120, 180), "1f338",
     ("Some flowers are pink!", "कुछ फूल गुलाबी होते हैं!")),
    ("colour_purple", "Purple", "बैंगनी", (142, 68, 173), "1f347",
     ("Some grapes are purple!", "कुछ अंगूर बैंगनी होते हैं!")),
    ("colour_brown", "Brown", "भूरा", (141, 90, 60), "1f9f8",
     ("A teddy bear is brown!", "टेडी बियर भूरा होता है!")),
    ("colour_black", "Black", "काला", (40, 40, 48), "1f426_200d_2b1b",
     ("A crow is black!", "कौआ काला होता है!")),
    ("colour_white", "White", "सफ़ेद", (255, 255, 255), "2601",
     ("Clouds are white!", "बादल सफ़ेद होते हैं!")),
]

# (id, English, Hindi, (fact EN, fact HI))
SHAPES = [
    ("circle", "Circle", "गोला",
     ("A wheel is a circle!", "पहिया गोल होता है!")),
    ("square", "Square", "वर्ग",
     ("A square has four equal sides!", "वर्ग की चारों भुजाएँ बराबर होती हैं!")),
    ("triangle", "Triangle", "त्रिभुज",
     ("A triangle has three sides!", "त्रिभुज की तीन भुजाएँ होती हैं!")),
    ("rectangle", "Rectangle", "आयत",
     ("A door is a rectangle!", "दरवाज़ा आयत जैसा होता है!")),
    ("star", "Star", "तारा",
     ("Stars twinkle in the night sky!", "तारे रात के आसमान में टिमटिमाते हैं!")),
    ("heart", "Heart", "दिल",
     ("A heart means love!", "दिल का मतलब प्यार है!")),
    ("oval", "Oval", "अंडाकार",
     ("An egg is an oval!", "अंडा अंडाकार होता है!")),
    ("diamond", "Diamond", "हीरा",
     ("A kite looks like a diamond!", "पतंग हीरे जैसी दिखती है!")),
]


VEHICLES = [
    ("car", "Car", "कार",
     ("A car has four wheels!", "कार के चार पहिए होते हैं!")),
    ("bus", "Bus", "बस",
     ("A bus carries many people!", "बस में बहुत सारे लोग बैठते हैं!")),
    ("train", "Train", "रेलगाड़ी",
     ("A train runs on tracks!", "रेलगाड़ी पटरी पर चलती है!")),
    ("aeroplane", "Aeroplane", "हवाई जहाज़",
     ("An aeroplane flies in the sky!", "हवाई जहाज़ आसमान में उड़ता है!")),
    ("bicycle", "Bicycle", "साइकिल",
     ("A bicycle has two wheels!", "साइकिल के दो पहिए होते हैं!")),
    ("motorcycle", "Motorcycle", "मोटरसाइकिल",
     ("A motorcycle goes vroom vroom!", "मोटरसाइकिल चलती है, वूँ वूँ!")),
    ("auto_rickshaw", "Auto Rickshaw", "ऑटो रिक्शा",
     ("An auto rickshaw has three wheels!", "ऑटो रिक्शा के तीन पहिए होते हैं!")),
    ("truck", "Truck", "ट्रक",
     ("A truck carries heavy things!", "ट्रक भारी सामान ढोता है!")),
    ("tractor", "Tractor", "ट्रैक्टर",
     ("A tractor helps farmers!", "ट्रैक्टर किसानों की मदद करता है!")),
    ("boat", "Boat", "नाव",
     ("A boat floats on water!", "नाव पानी पर तैरती है!")),
    ("helicopter", "Helicopter", "हेलीकॉप्टर",
     ("A helicopter has spinning blades!", "हेलीकॉप्टर के पंखे घूमते हैं!")),
    ("ambulance", "Ambulance", "एम्बुलेंस",
     ("An ambulance takes people to hospital!", "एम्बुलेंस लोगों को अस्पताल ले जाती है!")),
]


# Hindi letters (Devanagari). (letter, id, English meaning, Hindi word,
# picture source, levels). Picture source: "copy:<existing image>",
# "noto:<codepoint>", "photo:<Wikipedia article or File:...>" or
# "shape:<name>". ङ, ञ, ण and अः have no picture word on school charts.
HINDI = [
    # स्वर (vowels): Nursery and up.
    ("अ", "hi_anar", "Pomegranate", "अनार", "copy:fruits/pomegranate", NURSERY_UP),
    ("आ", "hi_aam", "Mango", "आम", "copy:fruits/mango", NURSERY_UP),
    ("इ", "hi_imli", "Tamarind", "इमली", "photo:Tamarind", NURSERY_UP),
    ("ई", "hi_eekh", "Sugarcane", "ईख", "photo:Sugarcane", NURSERY_UP),
    ("उ", "hi_ullu", "Owl", "उल्लू", "copy:birds/owl", NURSERY_UP),
    ("ऊ", "hi_oon", "Wool", "ऊन", "noto:1f9f6", NURSERY_UP),
    ("ऋ", "hi_rishi", "Sage", "ऋषि", "noto:1f9d8", NURSERY_UP),
    ("ए", "hi_edi", "Heel", "एड़ी", "noto:1f9b6", NURSERY_UP),
    ("ऐ", "hi_ainak", "Spectacles", "ऐनक", "noto:1f453", NURSERY_UP),
    ("ओ", "hi_okhli", "Mortar", "ओखली", "photo:Mortar and pestle", NURSERY_UP),
    ("औ", "hi_aurat", "Woman", "औरत", "noto:1f469", NURSERY_UP),
    ("अं", "hi_angoor", "Grapes", "अंगूर", "copy:fruits/grapes", NURSERY_UP),
    # व्यंजन (consonants): LKG and up.
    ("क", "hi_kabootar", "Pigeon", "कबूतर", "copy:birds/pigeon", LKG_UP),
    ("ख", "hi_khargosh", "Rabbit", "खरगोश", "copy:animals/rabbit", LKG_UP),
    ("ग", "hi_gamla", "Flowerpot", "गमला", "noto:1fab4", LKG_UP),
    ("घ", "hi_ghadi", "Clock", "घड़ी", "noto:23f0", LKG_UP),
    ("च", "hi_chammach", "Spoon", "चम्मच", "noto:1f944", LKG_UP),
    ("छ", "hi_chhatri", "Umbrella", "छतरी", "noto:2602", LKG_UP),
    ("ज", "hi_jahaaz", "Ship", "जहाज़", "noto:1f6a2", LKG_UP),
    ("झ", "hi_jhanda", "Flag", "झंडा", "noto:1f6a9", LKG_UP),
    ("ट", "hi_tamatar", "Tomato", "टमाटर", "copy:vegetables/tomato", LKG_UP),
    ("ठ", "hi_thela", "Cart", "ठेला", "noto:1f6d2", LKG_UP),
    ("ड", "hi_damru", "Drum", "डमरू", "noto:1fa98", LKG_UP),
    ("ढ", "hi_dhol", "Dhol", "ढोल", "noto:1f941", LKG_UP),
    ("त", "hi_tarbooz", "Watermelon", "तरबूज़", "copy:fruits/watermelon", LKG_UP),
    ("थ", "hi_tharmas", "Flask", "थरमस", "photo:Vacuum flask", LKG_UP),
    ("द", "hi_darwaza", "Door", "दरवाज़ा", "noto:1f6aa", LKG_UP),
    ("ध", "hi_dhanush", "Bow", "धनुष", "noto:1f3f9", LKG_UP),
    ("न", "hi_nal", "Tap", "नल", "noto:1f6b0", LKG_UP),
    ("प", "hi_patang", "Kite", "पतंग", "noto:1fa81", LKG_UP),
    ("फ", "hi_phal", "Fruits", "फल", "copy:sections/fruits", LKG_UP),
    ("ब", "hi_bakri", "Goat", "बकरी", "copy:animals/goat", LKG_UP),
    ("भ", "hi_bhalu", "Bear", "भालू", "copy:animals/bear", LKG_UP),
    ("म", "hi_machhli", "Fish", "मछली", "noto:1f41f", LKG_UP),
    ("य", "hi_yagya", "Holy Fire", "यज्ञ", "noto:1f525", LKG_UP),
    ("र", "hi_rath", "Chariot", "रथ", "photo:Ratha (Hinduism)", LKG_UP),
    ("ल", "hi_lattu", "Spinning Top", "लट्टू", "photo:Top", LKG_UP),
    ("व", "hi_van", "Forest", "वन", "noto:1f333", LKG_UP),
    ("श", "hi_sher", "Lion", "शेर", "copy:animals/lion", LKG_UP),
    ("ष", "hi_shatkon", "Hexagon", "षट्कोण", "shape:hexagon", LKG_UP),
    ("स", "hi_seb", "Apple", "सेब", "copy:fruits/apple", LKG_UP),
    ("ह", "hi_haathi", "Elephant", "हाथी", "copy:animals/elephant", LKG_UP),
    ("क्ष", "hi_kshitij", "Horizon", "क्षितिज", "noto:1f305", LKG_UP),
    ("त्र", "hi_trishul", "Trident", "त्रिशूल", "noto:1f531", LKG_UP),
    ("ज्ञ", "hi_gyan", "Knowledge", "ज्ञान", "noto:1f4da", LKG_UP),
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
    "car": "Beep beep!", "bus": "Honk honk!", "train": "Choo choo!",
    "aeroplane": "Whoooosh!", "bicycle": "Tring tring!",
    "motorcycle": "Vroom vroom!", "auto_rickshaw": "Pom pom!",
    "truck": "Honk!", "tractor": "Put put put!", "boat": "Toot toot!",
    "helicopter": "Chop chop chop!", "ambulance": "Nee-naw nee-naw!",
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

    write("items_fruits.json",
          [item("fruits", i, en, hi, fact=f, levels=NURSERY_UP)
           for i, en, hi, f in FRUITS])
    write("items_vegetables.json",
          [item("vegetables", i, en, hi, fact=f, levels=LKG_UP)
           for i, en, hi, f in VEGETABLES])
    write("items_colours.json",
          [item("colours", i, en, hi, fact=f, levels=NURSERY_UP)
           for i, en, hi, _rgb, _emoji, f in COLOURS])
    write("items_vehicles.json",
          [item("vehicles", i, en, hi, sound=True, fact=f, levels=LKG_UP)
           for i, en, hi, f in VEHICLES])
    hindi_items = []
    for letter, id_, en, hi, _src, levels in HINDI:
        it = item("hindi", id_, en, hi, letter=letter, levels=levels)
        it["letter_voice"] = f"assets/audio/hi/letters/{id_}.m4a"
        hindi_items.append(it)
    write("items_hindi.json", hindi_items)
    write("items_shapes.json",
          [item("shapes", i, en, hi, fact=f, levels=NURSERY_UP)
           for i, en, hi, f in SHAPES])


if __name__ == "__main__":
    main()
