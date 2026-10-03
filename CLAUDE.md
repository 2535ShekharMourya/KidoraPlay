# CLAUDE.md — Kidoraplay

This file is the single source of truth for building Kidoraplay. Read it fully before writing code. If a request conflicts with the **Non-negotiable rules** below, stop and tell the developer instead of implementing it.

---

## 1. Project overview

**Kidoraplay** is a playful, production-grade preschool learning app for Android (iOS later), built with Flutter.

- **Market:** India only (first release).
- **Users:** children aged 2–6 (Pre-nursery, Nursery, LKG, UKG). Parents install the app and control settings.
- **Languages:** English + Hindi (Devanagari). Every learning item has both.
- **Goal:** teach what Indian preschools teach (numbers, ABC, spellings, Hindi letters, animals, birds, etc.) in a way that feels like play.
- **Guide character:** **Kido**, a baby elephant who teaches, points with his trunk, spells along, and cheers.
- **Business model:** ads (AdMob, child-directed mode) + optional paid plans that remove ads and unlock everything.
- **Team:** two student developers. Repo: `https://github.com/2535ShekharMourya/KidoraPlay`.

### Current repo state
The repo currently contains only the default Flutter counter template (`lib/main.dart`), created with an older Flutter SDK (`sdk: '>=3.2.3 <4.0.0'`, `flutter_lints: ^2.0.0`, Java 1.8 in Gradle, release builds signed with debug keys). **First task:** upgrade to the current stable Flutter, regenerate platform folders (`flutter create .` after backing up), update lints, and replace the template with the architecture below.

### Open decisions (ask the developer, do not assume)
- Final Android `applicationId` (currently `com.kidoraplay.kidoraplay`; cannot change after first Play release).
- Trademark/Play Store availability of "Kidoraplay" and "Kido".
- Voice actor / TTS source for English and Hindi recordings.

---

## 2. Non-negotiable rules (child safety, Google Play Families, Indian law)

These rules protect the app from Play Store removal, AdMob account suspension, and violations of India's DPDP Act (children's provisions enforceable from May 2027) and CCPA dark-pattern guidelines. **Never violate them, even if asked to "increase engagement" or "increase ad revenue".**

### Data
1. **Collect no personal data.** No login, no name, no age, no photos, no microphone, no location, no contacts.
2. **No analytics or tracking SDKs.** No Firebase (Analytics, Crashlytics, Remote Config), no Facebook SDK, no Mixpanel, no Adjust/AppsFlyer, nothing that creates user or device IDs. Use Play Console's Android vitals for crashes.
3. **All app state is stored locally only** (`shared_preferences` / local files): progress, stickers, settings, class level.
4. **Remove the advertising ID permission** in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove"/>
   ```
   (add `xmlns:tools="http://schemas.android.com/tools"` to the `<manifest>` tag).
5. **Bundle all fonts and assets locally.** Never fetch fonts or content at runtime from third-party servers (do not use `google_fonts` runtime fetching).

### Ads
6. **Only AdMob in child-directed mode**, configured before any ad request:
   ```dart
   await MobileAds.instance.updateRequestConfiguration(
     RequestConfiguration(
       tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
       maxAdContentRating: MaxAdContentRating.g,
     ),
   );
   await MobileAds.instance.initialize();
   ```
   Mediation partners only if they are on Google Play's Families self-certified ads SDK list. **Never** add Meta Audience Network, Taboola, AppNext, or similar.
7. **Interstitial ads only, only at natural breaks** (after a section, set, or quiz is completed). **Never** on app launch, **never** on app exit/back-to-home-screen, **never** mid-activity, **never** right after a child's tap.
8. **No banner ads, no native ads inside the play area, no app-open ads.** Toddlers tap everything; accidental clicks get AdMob accounts suspended.
9. **Frequency cap:** minimum 4 minutes between interstitials, and no ad in the first 3 minutes of a session.
10. **Ad-break screen:** before every interstitial, show a 2–3 second "Kido is taking a break 🐘" screen with no tappable elements, then show the ad.
11. **Rewarded ads** only inside the Parent Area, chosen by the parent (e.g. "Watch one ad to unlock a premium section for today").
12. **Premium users:** never initialize the Mobile Ads SDK at all.

### Parental gate
13. Everything that is not learning content goes **behind a parental gate**: settings, purchases, rewarded ads, any external link, share actions.
14. Gate design: a task a toddler cannot do, e.g. "Press and hold for 3 seconds", or "Tap the number **seven**" shown in words with digits as options. Randomize the challenge.

### No dark patterns (CCPA India guidelines + Play Families policy)
15. Kido **never** guilt-trips: no "Don't go!", no sad face when the child leaves, no "Kido will be lonely".
16. No nagging the child to buy, no fake countdown offers, no "watch an ad or lose progress".
17. Never disguise an ad as content. Never place purchase buttons in the child's play area.
18. No streak penalties, loot boxes, or random rewards designed to compel return visits.

---

## 3. Product scope

### Sections and phases

**Phase 1 (launch MVP, ~150 items)**
| Section | Content |
|---|---|
| Numbers | 1–100: numeral, number name, spelling (O-N-E), counting picture, place-value view (21 = 2 tens + 1) |
| ABC | A–Z: capital + small letter, "A for Apple", picture, word spelling |
| Animals | 15 animals: picture, real sound, English + Hindi name, spelling |
| Birds | 10 birds: picture, real sound, English + Hindi name, spelling |
| Parent Area | Class selector (Nursery/LKG/UKG), language (EN / HI / both), sound on/off, plans, restore purchase |

**Phase 2:** finger tracing (letters, numbers), Hindi swar + vyanjan (अ से अनार), fruits, vegetables, colours, shapes, vehicles (with sounds).

**Phase 3:** quiz mode, UKG 3-letter words and sight words, picture addition/subtraction to 20, before/after/between, days, months, opposites, Hindi matras.

### Curriculum reference
| Level | English | Maths | Hindi | General |
|---|---|---|---|---|
| Nursery (3–4) | A–Z recognition, A for Apple | 1–20, big/small | Swar | Animals, birds, fruits, colours, shapes, body parts |
| LKG (4–5) | Capital/small, phonics, spellings | 1–100, names 1–20, before/after | Vyanjan | Vegetables, vehicles, family, habits, days |
| UKG (5–6) | CVC words, sight words, sentences | Names to 100, +/− to 20 | Matras, 2–3 letter words | Months, seasons, opposites, helpers |

The class selected in the Parent Area filters which sections/items appear and their difficulty.

### Numbers 1–100: teaching pattern
1. 1–20 individually. 2. Tens: twenty … ninety, hundred. 3. Combinations: 21 = "twenty-one" = T-W-E-N-T-Y - O-N-E.
- Number grid is grouped into ten rows: 1–10, 11–20 … 91–100. Child taps a row, then a number.
- Each number name has its **own full voice recording** (do not stitch "twenty" + "one").

### Spelling mode (core feature, used by every word)
1. Child taps the picture → voice says the word ("Apple!").
2. Letter tiles appear one by one; each lights up and bounces as its letter is spoken (A … P … P … L … E), Kido taps each tile with his trunk.
3. Voice says the whole word again ("Apple!") + small celebration.
4. Child can tap any letter tile to hear it again.
- Spelling is **generated automatically from `word_en`**; never stored separately.
- Letter audio: 26 letter recordings, reused for all words. Hyphens/spaces are shown but silent.

---

## 4. Kido (guide character)

**Kido** is a cheerful, patient baby elephant. Never upset, never in a hurry.

### Teaching model: "I do, we do, you do"
1. **I do:** Kido shows and says it (points at 🍎, "This is an Apple!", spells it).
2. **We do:** "Let's spell it together!" Each tile glows; child taps it; Kido says the letter.
3. **You do:** "Can you find the Apple?" Child taps; Kido cheers.

### Hint escalation (when the child is idle)
| Idle time | Kido action |
|---|---|
| 5 s | Looks toward the target item |
| 10 s | Points with trunk + voice hint ("Tap the cow!") |
| 15 s | Target item glows and bounces |
Reset the timer on any tap. Hints never repeat more than twice in a row.

### Talk less over time
- First visit to a section: full guidance.
- Later visits: short greeting, hints only when idle.
- Track per-section "visited" flags locally.

### Animation states (Rive state machine `KidoMachine`)
Inputs (triggers unless noted): `idle` (default loop), `wave`, `point` (number input `pointAngle`), `talk` (bool), `spellTap`, `clap`, `trumpet`, `think`, `surprised`, `coverEars`.

### Placement
Bottom-left of the landscape screen, roughly 18–22% of screen height. Kido must **never overlap a tappable target**. On small screens he scales down; he never hides content.

### Voice lines
- Same voice actor for every line, in both languages.
- 5–6 variants for praise; pick randomly without immediate repeats.
- Lines live in `assets/content/kido_lines.json`, keyed by event + language.

| Event | English | Hindi |
|---|---|---|
| welcome_first | "Hi! I'm Kido! Let's learn!" | "नमस्ते! मैं किडो हूँ! चलो सीखें!" |
| welcome_back | "Hi again!" | "फिर से नमस्ते!" |
| hint_tap | "Tap the {item}!" | "{item} को छुओ!" |
| spell_together | "Let's spell it together!" | "चलो साथ में स्पेलिंग करें!" |
| praise | "Well done!" / "Super!" / "Wow!" | "शाबाश!" / "बहुत बढ़िया!" |
| try_again | "Oops! Try again!" | "ओह! फिर से कोशिश करो!" |
| section_done | "You learned {n} {section}!" | "तुमने {n} {section} सीखे!" |
| goodbye | "Bye bye! See you soon!" | "बाय बाय! फिर मिलेंगे!" |

For `{item}` placeholders, play pre-recorded segments in sequence (e.g. "Tap the" + "cow"), or record full lines for Phase 1 items if stitching sounds unnatural.

---

## 5. Playful UX and design system

**Every screen must feel alive and joyful.** If a screen is static or a tap does nothing, it is not done.

### Interaction rules
- **Landscape only.** Lock orientation.
- **Taps only** in child screens. No swipes, long-presses, double-taps, drag (tracing in Phase 2 is the only drag exception).
- **Tap targets ≥ 96 dp**, spacing ≥ 16 dp.
- **Every tap responds within 100 ms:** sound + visual (bounce/squash, sparkle) + light haptic (`HapticFeedback.lightImpact`, respects a "vibration off" setting).
- **No reading required.** Icons and pictures everywhere; Kido's voice explains.
- Back button: big, top-left, not flush against the edge, always visible.
- Debounce rapid repeated taps (toddler mashing): ignore taps within 250 ms on the same target; never queue more than one voice line.

### "Juice" (playfulness checklist for every screen)
- Entry animation: items pop in with a staggered spring (`Curves.elasticOut`, 60–80 ms stagger).
- Idle life: subtle floating/breathing on cards, clouds or leaves drifting in the background.
- Tap feedback: scale 1.0 → 1.15 → 1.0 with a spring, particle burst (stars/confetti), pop sound.
- Animal/bird/vehicle items: the picture reacts to its sound (cow tail swish, lion mane shake) via Rive or simple transforms.
- Completion: confetti + Kido `trumpet` + sticker reward flying into the sticker book.
- Transitions: playful page transitions (scale + fade, or a train-wipe), 300–400 ms.
- Respect `MediaQuery.disableAnimations` (reduce motion) by shortening/removing non-essential animation.

### Visual style
- Font: **Baloo 2** (bundled in `assets/fonts/`, OFL licence), supports Latin + Devanagari.
- Soft pastel backgrounds; bright saturated colours only on tappable items.
- Each section has its own colour + background theme (Numbers: sky blue, ABC: sunshine yellow, Animals: jungle green, Birds: sunset orange).
- Rounded corners everywhere (24 dp+ on cards), thick friendly outlines.
- Define all colours, radii, spacing, durations as tokens in `lib/core/theme/` — **no hardcoded colours or durations in widgets**.

### Audio
- Voice lines and SFX must never overlap messily: one voice channel (new line stops old), separate SFX channel with low latency, background music channel (soft, ducked to 30% while Kido speaks, off by default for 2–3-year-olds).
- Normalize all audio to consistent loudness. Format: `.ogg` or `.m4a`, mono, 44.1 kHz, short trimmed silence.

---

## 6. Technical architecture

### Stack
| Concern | Choice |
|---|---|
| Framework | Flutter (latest stable), Dart null-safety |
| State management | `flutter_riverpod` (with code generation optional) |
| Routing | `go_router` |
| Character animation | `rive` |
| Simple animations | Flutter implicit/explicit animations, `flutter_animate` |
| Voice audio | `just_audio` |
| Low-latency SFX | `audioplayers` (low-latency mode) or `flutter_soloud`; pick one after testing on a 2 GB RAM device |
| Local storage | `shared_preferences` (settings/progress) |
| Ads | `google_mobile_ads` |
| Payments | `in_app_purchase` (Google Play Billing) |
| Localization | `flutter_localizations` + `gen-l10n` with ARB files (`en`, `hi`) |
| Lints | `very_good_analysis` or latest `flutter_lints`, zero warnings |

Verify each package's latest version and changelog on pub.dev before adding it.

### Folder structure
```
lib/
  main.dart                    # bootstrap: orientation lock, ProviderScope, error handling
  app.dart                     # MaterialApp.router, theme, l10n
  core/
    theme/                     # colours, typography, spacing, durations, radii tokens
    audio/                     # AudioService (voice, sfx, music channels)
    router/                    # go_router config
    storage/                   # LocalStore wrapper over shared_preferences
    widgets/                   # BouncyButton, BigBackButton, ConfettiBurst, LetterTile, etc.
    haptics/
  features/
    splash/
    home/                      # section menu
    section_grid/              # reusable ItemGridScreen (any section)
    learn_card/                # reusable LearnCardScreen + SpellingStrip
    numbers/                   # NumberRowsScreen (1–10 … 91–100), place-value view
    kido/                      # KidoWidget (Rive), KidoController, hint timer, lines
    parent/                    # ParentGate, ParentAreaScreen, class selector, settings
    progress/                  # stickers, visited flags, section completion
    ads/                       # AdManager, AdBreakScreen, frequency rules
    billing/                   # BillingManager, entitlement cache, plans screen
  content/
    models/                    # LearningItem, Section, KidoLine (immutable, fromJson)
    repository/                # ContentRepository: loads/caches JSON from assets
  l10n/                        # app_en.arb, app_hi.arb
assets/
  content/                     # sections.json, items_numbers.json, items_abc.json, ... kido_lines.json
  images/{numbers,abc,animals,birds}/
  audio/en/  audio/hi/  audio/letters/  audio/sfx/  audio/animals/
  rive/kido.riv
  fonts/Baloo2-*.ttf
test/
```

### Data-driven content
Screens are templates. **Adding content = adding JSON + assets, never a new screen.**

`LearningItem` JSON:
```json
{
  "id": "apple",
  "section": "abc",
  "levels": ["nursery", "lkg"],
  "letter": "A",
  "number": null,
  "word_en": "Apple",
  "word_hi": "सेब",
  "image": "assets/images/abc/apple.webp",
  "voice_en": "assets/audio/en/apple.m4a",
  "voice_hi": "assets/audio/hi/apple.m4a",
  "sound": null,
  "rive_reaction": null
}
```
Rules:
- `id` is unique, lowercase snake_case, and matches asset file names.
- Spelling is derived from `word_en` at runtime (uppercase letters; hyphens/spaces rendered but not voiced).
- `ContentRepository` validates on load in debug builds: missing asset files, duplicate IDs, and empty fields throw clear errors.
- Images: `.webp`, sized for ~2x the largest display size, no image above 300 KB.

### Ads module (`features/ads/`)
- `AdManager` exposes `Future<void> maybeShowBreak({required String reason})`, called only at section/quiz completion.
- Enforces: premium check, session start grace (3 min), min interval (4 min), never on launch/exit, preload next interstitial after showing one, fail silently if no fill (child flow is never blocked or delayed waiting for an ad).
- Shows `AdBreakScreen` (2–3 s, non-interactive) before `InterstitialAd.show()`.
- Ad unit IDs come from build config; use Google test ad unit IDs in debug builds.

### Billing module (`features/billing/`)
Products (Google Play Console IDs, prices set in Console):
- `kidora_premium_monthly` subscription (~₹49)
- `kidora_premium_yearly` subscription (~₹299)
- `kidora_premium_lifetime` one-time non-consumable (~₹499)

Rules: plans screen only inside the Parent Area; "Restore purchase" button; cache entitlement locally so the app works offline; check entitlement **before** deciding to initialize ads.

### Startup sequence
1. Lock landscape, init error handlers.
2. Load settings + cached entitlement from local storage.
3. Preload content JSON and Kido Rive file.
4. If not premium: configure child-directed request configuration, then initialize Mobile Ads SDK in background (never block the UI).
5. Show splash (≤ 2 s), then Home with Kido `wave`.

### Performance targets (test on a budget 2 GB RAM Android phone)
- 60 fps in all screens; no jank on tap feedback.
- Cold start to Home ≤ 3 s.
- Base app download ≤ 50 MB; later sections via Play Asset Delivery if needed.
- Audio plays ≤ 100 ms after tap (preload current section's audio).
- Works fully offline (ads simply don't show offline).

---

## 7. Code quality standards (production grade)

- Small, composable widgets; `const` constructors wherever possible.
- No business logic in widgets; use Riverpod providers/notifiers.
- No hardcoded user-facing strings: all UI text in ARB files (en + hi).
- Immutable models with `fromJson`/`toJson` (`freezed` + `json_serializable` acceptable).
- Handle every async error; the child must never see an error dialog. Fall back gracefully (e.g. missing audio → show text + bounce).
- Accessibility: `Semantics` labels on all tappable items (for parents/testers using TalkBack).
- Tests required:
  - Unit: spelling generation, number-name mapping 1–100, content validation, AdManager frequency rules, parental gate logic, hint escalation timers.
  - Widget: home navigation, learn card tap → audio call, spelling strip sequence.
  - Golden tests for key screens (landscape phone size).
- Run `flutter analyze` and `flutter test` with zero failures before every commit.
- Commit messages: conventional commits (`feat:`, `fix:`, `chore:`, `test:`).
- Never commit signing keys, `key.properties`, or real ad unit IDs to the public repo.

---

## 8. Build order for Phase 1 (work through in sequence)

1. **Project reset:** upgrade Flutter, regenerate platforms, lints, folder structure, theme tokens, router, landscape lock. Remove counter template and its test.
2. **Content layer:** models, `ContentRepository`, JSON for 10 sample items per section with placeholder assets, validation.
3. **Core widgets:** `BouncyButton`, `BigBackButton`, `ConfettiBurst`, `LetterTile`, section-themed backgrounds.
4. **AudioService:** voice/SFX/music channels, preload, ducking, debounce.
5. **Screens:** Splash → Home → ItemGrid → LearnCard (with SpellingStrip) → NumberRows (1–100).
6. **Kido:** `KidoWidget` with placeholder Rive file, `KidoController`, hint escalation, I-do/we-do/you-do flow on LearnCard, talk-less-over-time flags.
7. **Progress:** stickers + section completion + celebration.
8. **Parent Area:** gate, class selector, language, sound/vibration toggles.
9. **Billing:** products, plans screen, restore, entitlement cache.
10. **Ads:** AdManager, AdBreakScreen, child-directed config, AD_ID removal, test IDs.
11. **Polish pass:** juice checklist on every screen, performance on low-end device, reduce-motion support.
12. **Release prep:** app icon, real signing config, Play Console Families declaration, Data Safety form ("no data collected"), privacy policy (EN + HI), store listing in EN + HI.

After each step: run analyze + tests, and summarize what changed and what to test manually on a phone.

---

## 9. When unsure
- Prefer the safer option for children (less data, fewer ads, no pressure).
- Ask the developer before adding any new dependency that makes network calls.
- If a feature request would break Section 2, explain why and propose a compliant alternative.
