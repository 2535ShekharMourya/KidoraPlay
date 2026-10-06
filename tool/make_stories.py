"""Writes the picture stories: assets/content/stories.json and the page
pictures in assets/images/stories/.

Classic folk tales (public domain) retold in our own simple words, and a
few original Kido stories. Pictures are composed from Noto Emoji 3D art
(Apache 2.0 / OFL) on soft scene backgrounds. Voices come from
tool/make_voice.py (it reads stories.json).

    python tool/make_stories.py
"""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from make_pictures import emoji_toned, fit, save  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "assets" / "content"
W, H = 640, 480

# Scene backgrounds: (top colour, bottom colour, ground colour or None).
SCENES = {
    "day": ((186, 228, 255), (232, 247, 255), (153, 214, 126)),
    "jungle": ((172, 225, 175), (220, 244, 214), (110, 180, 90)),
    "water": ((186, 228, 255), (232, 247, 255), (94, 170, 230)),
    "night": ((40, 48, 96), (80, 90, 150), (60, 110, 80)),
    "home": ((255, 236, 214), (255, 247, 236), (230, 196, 150)),
}

# (id, levels, English title, Hindi title, cover [(emoji, x, y, size)],
#  pages: (scene, [(emoji, x, y, size)], English text, Hindi text))
# Positions are 0-1 of the picture; sizes are 0-1 of its height.
STORIES = [
    ("thirsty_crow", ["baby", "nursery", "lkg", "ukg"],
     "The Thirsty Crow", "प्यासा कौआ",
     [("1f426_200d_2b1b", .4, .45, .55), ("1f3fa", .72, .6, .5)],
     [
        ("day", [("1f426_200d_2b1b", .3, .35, .4), ("2600", .82, .18, .25)],
         "It was a hot, hot day. A crow was very thirsty.",
         "बहुत गरम दिन था। एक कौआ बहुत प्यासा था।"),
        ("day", [("1f426_200d_2b1b", .3, .5, .35), ("1f3fa", .65, .6, .45)],
         "He found a pot. But the water was at the very bottom!",
         "उसे एक मटका मिला। पर पानी बहुत नीचे था!"),
        ("day", [("1f426_200d_2b1b", .25, .5, .35), ("1faa8", .62, .72, .22),
                 ("1f914", .8, .25, .2)],
         "The crow thought and thought. Then he saw some pebbles.",
         "कौए ने सोचा, और सोचा। फिर उसे कुछ कंकड़ दिखे।"),
        ("day", [("1f426_200d_2b1b", .3, .4, .35), ("1f3fa", .65, .6, .45),
                 ("1faa8", .62, .3, .15)],
         "One by one, he dropped the pebbles into the pot. Plop! Plop!",
         "उसने एक-एक करके कंकड़ मटके में डाले। टप! टप!"),
        ("day", [("1f426_200d_2b1b", .45, .35, .38), ("1f4a7", .62, .62, .2),
                 ("1f3fa", .55, .65, .4)],
         "The water came up, up, up! The crow drank and said, thank you!",
         "पानी ऊपर आ गया! कौए ने पानी पिया, और खुश हो गया!"),
     ]),
    ("lion_mouse", ["nursery", "lkg", "ukg"],
     "The Lion and the Mouse", "शेर और चूहा",
     [("1f981", .35, .5, .6), ("1f42d", .75, .65, .3)],
     [
        ("jungle", [("1f981", .35, .55, .5), ("1f4a4", .55, .25, .18)],
         "A big lion was sleeping under a tree.",
         "एक बड़ा शेर पेड़ के नीचे सो रहा था।"),
        ("jungle", [("1f981", .3, .55, .45), ("1f42d", .62, .5, .2)],
         "A tiny mouse ran over his nose. The lion woke up. Grrr!",
         "एक छोटा चूहा उसकी नाक पर दौड़ गया। शेर जाग गया। ग्रर्र!"),
        ("jungle", [("1f981", .3, .55, .45), ("1f42d", .65, .55, .22),
                    ("1f64f", .82, .3, .18)],
         "Please let me go, said the mouse. One day I will help you!",
         "चूहे ने कहा, मुझे जाने दो। एक दिन मैं तुम्हारी मदद करूँगा!"),
        ("jungle", [("1f981", .4, .55, .45), ("1f578", .4, .45, .55)],
         "One day, the lion got stuck in a big net.",
         "एक दिन, शेर एक बड़े जाल में फँस गया।"),
        ("jungle", [("1f981", .35, .55, .45), ("1f42d", .68, .55, .22),
                    ("1f496", .55, .2, .18)],
         "The mouse cut the net with his little teeth. Now they were friends!",
         "चूहे ने अपने छोटे दाँतों से जाल काट दिया। अब वे दोस्त बन गए!"),
     ]),
    ("hare_tortoise", ["nursery", "lkg", "ukg"],
     "The Hare and the Tortoise", "खरगोश और कछुआ",
     [("1f407", .35, .5, .45), ("1f422", .72, .6, .4)],
     [
        ("day", [("1f407", .3, .55, .35), ("1f422", .7, .62, .33)],
         "The hare said, I am so fast! Let's have a race!",
         "खरगोश बोला, मैं बहुत तेज़ हूँ! चलो दौड़ लगाते हैं!"),
        ("day", [("1f407", .75, .5, .32), ("1f422", .2, .62, .3),
                 ("1f3c1", .9, .2, .18)],
         "Off they went! The hare ran far, far ahead.",
         "दौड़ शुरू हुई! खरगोश बहुत आगे निकल गया।"),
        ("day", [("1f407", .45, .6, .32), ("1f4a4", .6, .35, .15),
                 ("1f333", .3, .45, .45)],
         "The hare thought, I have time. He took a nap under a tree.",
         "खरगोश ने सोचा, अभी समय है। वह पेड़ के नीचे सो गया।"),
        ("day", [("1f422", .5, .6, .33), ("1f3c1", .85, .3, .2)],
         "The tortoise walked slowly, slowly. He never stopped.",
         "कछुआ धीरे-धीरे चलता रहा। वह कभी नहीं रुका।"),
        ("day", [("1f422", .55, .6, .33), ("1f3c6", .78, .3, .25),
                 ("1f407", .2, .6, .25)],
         "The tortoise won the race! Slow and steady wins!",
         "कछुआ जीत गया! धीरे-धीरे चलने वाला भी जीतता है!"),
     ]),
    ("monkey_crocodile", ["lkg", "ukg"],
     "The Monkey and the Crocodile", "बंदर और मगरमच्छ",
     [("1f412", .35, .4, .45), ("1f40a", .65, .7, .45)],
     [
        ("water", [("1f412", .3, .35, .35), ("1f333", .25, .45, .55),
                   ("1f352", .45, .3, .15)],
         "A monkey lived in a tree full of sweet fruits, near a river.",
         "नदी के पास एक पेड़ पर एक बंदर रहता था। पेड़ पर मीठे फल थे।"),
        ("water", [("1f412", .3, .35, .3), ("1f40a", .65, .7, .4),
                   ("1f352", .5, .5, .15)],
         "Every day, he gave fruits to his friend, the crocodile.",
         "वह रोज़ अपने दोस्त मगरमच्छ को फल देता था।"),
        ("water", [("1f412", .5, .5, .3), ("1f40a", .5, .72, .45)],
         "One day, the crocodile said, come for a ride on my back!",
         "एक दिन मगरमच्छ बोला, आओ, मेरी पीठ पर बैठकर घूमो!"),
        ("water", [("1f412", .45, .5, .3), ("1f40a", .5, .72, .45),
                   ("1f4a1", .7, .25, .18)],
         "In the river, the monkey thought fast. Let's go back to my tree!",
         "नदी में बंदर ने जल्दी सोचा। चलो, वापस मेरे पेड़ पर चलें!"),
        ("water", [("1f412", .3, .3, .3), ("1f333", .25, .45, .55),
                   ("1f60a", .7, .3, .2)],
         "He jumped back on his tree, safe and happy. Clever monkey!",
         "वह कूदकर अपने पेड़ पर पहुँच गया। होशियार बंदर!"),
     ]),
    ("ant_dove", ["nursery", "lkg", "ukg"],
     "The Ant and the Dove", "चींटी और कबूतर",
     [("1f41c", .35, .65, .3), ("1f54a", .65, .35, .45)],
     [
        ("water", [("1f41c", .45, .7, .2), ("1f4a7", .6, .6, .18)],
         "A little ant fell into the water. Help! Help!",
         "एक छोटी चींटी पानी में गिर गई। बचाओ! बचाओ!"),
        ("water", [("1f54a", .6, .25, .35), ("1f343", .45, .65, .2),
                   ("1f41c", .45, .62, .12)],
         "A kind dove dropped a leaf. The ant climbed on and was safe.",
         "एक दयालु कबूतर ने पत्ता गिराया। चींटी उस पर चढ़कर बच गई।"),
        ("day", [("1f54a", .45, .3, .33), ("1f408", .25, .65, .35)],
         "Later, a cat crept up to catch the dove.",
         "बाद में, एक बिल्ली कबूतर को पकड़ने चुपके से आई।"),
        ("day", [("1f408", .35, .6, .35), ("1f41c", .5, .52, .12),
                 ("1f4a8", .62, .45, .18)],
         "The ant tickled the cat's nose. Aaa-choo!",
         "चींटी ने बिल्ली की नाक में गुदगुदी की। आ-छू!"),
        ("day", [("1f54a", .6, .25, .33), ("1f41c", .35, .7, .15),
                 ("1f496", .5, .45, .15)],
         "The dove flew away safely. Friends help friends!",
         "कबूतर उड़कर बच गया। दोस्त, दोस्तों की मदद करते हैं!"),
     ]),
    ("kido_sneeze", ["baby", "nursery", "lkg", "ukg"],
     "Kido's Big Sneeze", "किडो की बड़ी छींक",
     [("1f418", .45, .55, .6), ("1f4a8", .78, .4, .25)],
     [
        ("day", [("1f418", .4, .55, .5), ("1f33c", .75, .7, .2)],
         "Kido the little elephant was smelling the flowers.",
         "छोटा हाथी किडो फूल सूँघ रहा था।"),
        ("day", [("1f418", .4, .55, .5), ("1f33c", .6, .45, .15)],
         "His trunk began to tickle. Aaa... aaa...",
         "उसकी सूँड में गुदगुदी होने लगी। आ... आ..."),
        ("day", [("1f418", .35, .55, .5), ("1f4a8", .7, .45, .3),
                 ("1f338", .85, .25, .15)],
         "AAA-CHOO! Flowers flew up into the sky!",
         "आ-छू! फूल उड़कर आसमान में चले गए!"),
        ("day", [("1f412", .25, .55, .3), ("1f407", .55, .65, .25),
                 ("1f602", .8, .3, .2)],
         "His friends laughed and laughed. Ha ha ha!",
         "उसके दोस्त खूब हँसे। हा हा हा!"),
        ("day", [("1f418", .4, .55, .45), ("1f338", .7, .3, .18),
                 ("1f60a", .7, .65, .18)],
         "Kido laughed too. What a funny sneeze!",
         "किडो भी हँसने लगा। कितनी मज़ेदार छींक थी!"),
     ]),
    ("kido_mangoes", ["baby", "nursery", "lkg", "ukg"],
     "Kido Shares Mangoes", "किडो ने आम बाँटे",
     [("1f418", .4, .55, .55), ("1f96d", .75, .55, .3)],
     [
        ("jungle", [("1f418", .4, .55, .5), ("1f96d", .7, .45, .18),
                    ("1f96d", .8, .6, .18)],
         "Kido found lots of sweet mangoes.",
         "किडो को बहुत सारे मीठे आम मिले।"),
        ("jungle", [("1f418", .3, .55, .45), ("1f412", .7, .55, .3)],
         "His friend the monkey looked hungry.",
         "उसका दोस्त बंदर भूखा लग रहा था।"),
        ("jungle", [("1f418", .3, .55, .45), ("1f96d", .55, .45, .15),
                    ("1f412", .75, .55, .3)],
         "Kido gave him a mango. Here you go, friend!",
         "किडो ने उसे एक आम दिया। यह लो, दोस्त!"),
        ("jungle", [("1f407", .25, .65, .25), ("1f43b", .5, .55, .35),
                    ("1f99c", .78, .35, .25)],
         "Then he shared with the rabbit, the bear and the parrot too.",
         "फिर उसने खरगोश, भालू और तोते के साथ भी आम बाँटे।"),
        ("jungle", [("1f418", .4, .55, .45), ("1f496", .7, .3, .2)],
         "Everyone was happy. Sharing is caring!",
         "सब खुश हो गए। बाँटने में ही खुशी है!"),
     ]),
    ("little_seed", ["baby", "nursery", "lkg", "ukg"],
     "The Little Seed", "छोटा सा बीज",
     [("1f331", .45, .6, .5), ("2600", .8, .2, .25)],
     [
        ("day", [("1f330", .5, .75, .15)],
         "A tiny seed was sleeping in the soil.",
         "मिट्टी में एक छोटा सा बीज सो रहा था।"),
        ("day", [("1f327", .5, .25, .35), ("1f330", .5, .78, .12)],
         "The rain said, drink, little seed! Pitter patter!",
         "बारिश बोली, पानी पियो, छोटे बीज! टप टप!"),
        ("day", [("2600", .8, .2, .25), ("1f331", .5, .65, .3)],
         "The sun said, grow, little seed! And a green shoot came up.",
         "सूरज बोला, बड़े हो जाओ, छोटे बीज! और एक हरा पौधा निकल आया।"),
        ("day", [("1f333", .5, .55, .6)],
         "It grew and grew into a big, tall tree.",
         "वह बढ़ता गया, और एक बड़ा, ऊँचा पेड़ बन गया।"),
        ("day", [("1f333", .45, .55, .6), ("1f34e", .4, .4, .12),
                 ("1f34e", .55, .35, .12), ("1f426", .8, .3, .18)],
         "Now it gives us fruits and shade, and birds sing in it!",
         "अब वह हमें फल और छाया देता है, और चिड़िया उसमें गाती हैं!"),
     ]),
    ("kido_brushes", ["baby", "nursery", "lkg", "ukg"],
     "Kido Brushes His Teeth", "किडो ब्रश करता है",
     [("1f418", .4, .55, .55), ("1faa5", .75, .5, .3)],
     [
        ("home", [("1f418", .4, .55, .5), ("1f305", .8, .2, .22)],
         "Good morning! Kido woke up with a big smile.",
         "सुप्रभात! किडो बड़ी सी मुस्कान के साथ उठा।"),
        ("home", [("1faa5", .4, .5, .3), ("1f9fc", .65, .55, .22)],
         "First, he took his toothbrush and toothpaste.",
         "पहले उसने अपना टूथब्रश और टूथपेस्ट लिया।"),
        ("home", [("1f418", .35, .55, .45), ("1faa5", .65, .45, .22),
                  ("1fae7", .75, .3, .15)],
         "Brush, brush, brush! Up and down, round and round.",
         "ब्रश, ब्रश, ब्रश! ऊपर-नीचे, गोल-गोल।"),
        ("home", [("1f418", .4, .55, .45), ("1f6b0", .72, .5, .25)],
         "Then he rinsed his mouth with clean water.",
         "फिर उसने साफ़ पानी से कुल्ला किया।"),
        ("home", [("1f418", .4, .55, .45), ("1f9b7", .72, .35, .22),
                  ("2728", .82, .2, .15)],
         "Shiny clean teeth! Brush in the morning and at night!",
         "चमकते साफ़ दाँत! सुबह और रात को ब्रश करो!"),
     ]),
    ("greedy_dog", ["lkg", "ukg"],
     "The Greedy Dog", "लालची कुत्ता",
     [("1f415", .45, .5, .5), ("1f9b4", .75, .6, .25)],
     [
        ("day", [("1f415", .4, .55, .45), ("1f9b4", .6, .5, .15)],
         "A dog found a big bone. Yummy!",
         "एक कुत्ते को एक बड़ी हड्डी मिली। वाह!"),
        ("water", [("1f415", .4, .5, .4), ("1f9b4", .55, .45, .12)],
         "He walked over a bridge across a river.",
         "वह नदी के ऊपर एक पुल से जा रहा था।"),
        ("water", [("1f415", .4, .42, .35), ("~1f415", .4, .76, .3)],
         "In the water, he saw another dog with a bone!",
         "पानी में उसे एक और कुत्ता दिखा, उसके पास भी हड्डी थी!"),
        ("water", [("1f415", .4, .45, .35), ("1f9b4", .5, .75, .12),
                   ("1f4a6", .6, .65, .18)],
         "He barked to take that bone too. Woof! His bone fell in. Splash!",
         "उसे भी लेने के लिए वह भौंका। भौं! उसकी हड्डी पानी में गिर गई। छपाक!"),
        ("water", [("1f415", .45, .5, .4), ("1f97a", .72, .3, .2)],
         "It was only his own picture in the water. Be happy with what you have!",
         "पानी में तो उसकी अपनी परछाईं थी। जो है, उसमें खुश रहो!"),
     ]),
]


def background(scene):
    top, bottom, ground = SCENES[scene]
    img = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        d.line([(0, y), (W, y)], fill=c + (255,))
    if ground:
        d.ellipse((-W * 0.3, H * 0.72, W * 1.3, H * 1.6), fill=ground + (255,))
    if scene == "night":
        for x, y in ((80, 60), (220, 110), (420, 50), (560, 120), (330, 30)):
            d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(255, 241, 150, 255))
    return img


def compose(scene, elements):
    img = background(scene)
    for code, x, y, size in elements:
        # "~code": a reflection in water (upside down, faint).
        mirror = code.startswith("~")
        e = fit(emoji_toned(code.lstrip("~")), int(H * size))
        if mirror:
            e = e.transpose(Image.FLIP_TOP_BOTTOM)
            e.putalpha(e.getchannel("A").point(lambda a: a * 55 // 100))
        img.alpha_composite(e, (int(W * x - e.width / 2), int(H * y - e.height / 2)))
    return img


def main():
    stories = []
    for sid, levels, en, hi, cover, pages in STORIES:
        cover_path = f"assets/images/stories/{sid}_cover.webp"
        save(compose("day", cover), cover_path)
        story = {
            "id": sid, "levels": levels, "title_en": en, "title_hi": hi,
            "cover": cover_path,
            "voice_title_en": f"assets/audio/en/stories/{sid}_title.m4a",
            "voice_title_hi": f"assets/audio/hi/stories/{sid}_title.m4a",
            "pages": [],
        }
        for i, (scene, elements, text_en, text_hi) in enumerate(pages, 1):
            pic = f"assets/images/stories/{sid}_{i}.webp"
            save(compose(scene, elements), pic)
            story["pages"].append({
                "image": pic, "text_en": text_en, "text_hi": text_hi,
                "voice_en": f"assets/audio/en/stories/{sid}_{i}.m4a",
                "voice_hi": f"assets/audio/hi/stories/{sid}_{i}.m4a",
            })
        stories.append(story)
    out = CONTENT / "stories.json"
    out.write_text(json.dumps(stories, ensure_ascii=False, indent=2) + "\n",
                   encoding="utf-8")
    print(f"wrote {out.relative_to(ROOT)} ({len(stories)} stories)")


if __name__ == "__main__":
    main()
