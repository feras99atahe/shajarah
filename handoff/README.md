# Applying the Shajarah olive design to your Flutter app

Repo: `feras99atahe/shajarah` · Flutter + Supabase + Riverpod + go_router

## The one thing to understand
Your app already centralizes **all** styling in two files:

```
lib/core/theme/app_colors.dart   ← every color token
lib/core/theme/app_theme.dart    ← ThemeData (reads AppColors) + fonts
```

Every widget reads `AppColors.*` and the global `Theme`. So reskinning = replacing
these **two files**. Your Supabase calls, Riverpod providers, models
(`member.dart`, `family.dart`, `relationship.dart`), router, and l10n are **untouched**.

## Step 1 — Drop in the two files (the whole reskin)
Copy these over your originals (same class names, same token names):

```
handoff/core/theme/app_colors.dart  →  lib/core/theme/app_colors.dart
handoff/core/theme/app_theme.dart   →  lib/core/theme/app_theme.dart
```

`flutter pub get` (no new deps — you already have `google_fonts`), then run.
That's it — buttons, fields, cards, app bar, bottom nav, text, every screen
flips to olive + Reem Kufi / IBM Plex Sans Arabic. **Nothing else edited.**

### What changed, exactly
- **Colors:** forest-green `#2D6A4F` → olive `#515E37`; white surfaces → warm
  ivory/sand; gold accent → brass `#A9792F`. Only hex values changed.
- **Fonts:** Playfair Display → **Reem Kufi** (headings), Inter → **IBM Plex Sans
  Arabic** (UI/body), Cairo → IBM Plex Sans Arabic (`arabicStyle` helper).
- **Preserved on purpose:** your **gender** colors (male/female) and **deceased**
  state (`رحمه الله` badge) still carry meaning — I only re-tinted them to sit on
  the warm background. If you'd rather nodes be single-color (olive) with gold only
  for the selected/"you" node like the mockups, say so and I'll send that variant.

## Step 2 — RTL (you're bilingual, so this already works)
`app.dart` already wires `flutter_localizations` + `supportedLocales: [en, ar]`,
so Flutter flips direction from the active locale automatically. Two polish checks:
- Prefer `EdgeInsetsDirectional` / `AlignmentDirectional` over `left`/`right` in any
  custom widget (most of yours already inherit correctly).
- `member_node_widget.dart` shows `'${member.age} yrs'` — for Arabic, localize the
  unit (e.g. `'٣٤ سنة'`) via your `app_localizations`.

## Step 3 (optional) — adopt the new design extras
These are additions, not requirements — pull any you like from the mockups:
- **Hint leaf badge** on auto-linked members (your Supabase match → a small leaf on
  the avatar). Pure presentation on `app_avatar.dart` / `member_node_widget.dart`.
- **"You" node** emphasis (gold ring) for the signed-in member.
- **Four-part-name live preview** card on `profile_setup_screen` / `add_member_screen`.
- **Relationship chain** styling on `relationship_finder_screen`.

I can write any of these as widget-level diffs against your real files — just ask.

## What is NEVER touched
- `supabase/`, all provider/repository/service code, `*.fromJson/toJson`
- `features/**/models/*.dart`
- `core/router/app_router.dart`, auth logic
- Your business rules (name parsing, relationship detection)

## Reference
- `Shajarah Design System.html` — exact tokens, type scale, components
- `Shajarah App.html` — target layout for every screen
```
git checkout -b feature/olive-redesign   # so you can preview & revert freely
```

---

# Extras (mockup parity) — drop-in widgets

These match the HTML mockups. All new widget params are **optional** and default
to off, so existing call sites keep compiling. Copy each file to the mirrored path:

```
handoff/shared/widgets/hint_leaf.dart            → lib/shared/widgets/hint_leaf.dart        (new)
handoff/shared/widgets/app_avatar.dart           → lib/shared/widgets/app_avatar.dart       (replace)
handoff/shared/widgets/name_preview_card.dart    → lib/shared/widgets/name_preview_card.dart (new)
handoff/features/tree/widgets/member_node_widget.dart
                                                 → lib/features/tree/widgets/member_node_widget.dart (replace)
handoff/features/relationship/kinship.dart       → lib/features/relationship/kinship.dart    (new)
handoff/features/relationship/screens/relationship_finder_screen.dart
                                                 → lib/.../relationship_finder_screen.dart   (replace)
```

### 1. Calm olive nodes + "you" + hint leaf
`AppAvatar` and `MemberNodeWidget` now take:
- `isSelf` — the signed-in member: olive fill + gold ring + "أنت" label
- `isLineage` — a direct ancestor/descendant: olive border emphasis
- `showHint` — smart auto-link leaf badge
Gender is preserved as a small corner dot (so the data isn't lost) — pass
`showGenderDot: false` on `AppAvatar` if you want the pure-uniform mockup look.

Wire it where you build nodes in `tree_screen.dart`:
```dart
final selfId = ref.watch(currentMemberIdProvider); // your auth → member id
MemberNodeWidget(
  member: m,
  isArabic: isArabic,
  isSelf: m.id == selfId,
  isLineage: lineageIds.contains(m.id),   // optional: ids on the path to self
  showHint: autoLinkedIds.contains(m.id), // ids your Supabase match flagged
);
```
If you don't have a "self member id" yet, just omit `isSelf` — everything still
works, nodes simply render in the calm olive style.

### 2. Four-part-name live preview
Put `NamePreviewCard` above the name fields in `profile_setup_screen.dart` and
`add_member_screen.dart`. Rebuild it as the user types:
```dart
NamePreviewCard(
  name: _nameCtrl.text,
  father: _fatherCtrl.text,
  grandfather: _grandfatherCtrl.text,
  family: _familyCtrl.text,
  autoLinkHint: _matchedFather == null
      ? null
      : 'سيُربط تلقائيًا بـ ${_matchedFather!.displayName(true)}',
)
// add `onChanged: (_) => setState(() {})` to the four TextFields so it updates live
```

### 3. Relationship chain with Arabic kinship
`relationship_finder_screen.dart` is a full drop-in — **same BFS + providers**,
only the result is restyled into the horizontal chain with proper terms
(عمّتك، جدّك، ابن عمّك …). The logic lives in `kinship.dart`.

⚠️ **One direction check.** `kinship.dart` assumes each path edge reads
"next is `<edge>` of previous" (a `parent` edge ⇒ the next person is the previous
person's parent). If your `adjacencyProvider` builds edges the other way, the
terms will invert (you'll see ابنك where you expect أبوك). Fix in one line when
building hops — use `path[i].relationshipType!.inverse`:
```dart
KinHop(edge: path[i].relationshipType!.inverse, gender: path[i].member.gender)
```
Test with a known pair (you ↔ your father) and flip if needed.

> Note: I couldn't compile against your full project here (no Supabase creds /
> Flutter toolchain in this environment), so treat these as review-ready code —
> run `flutter analyze` after dropping them in. The logic mirrors your existing
> patterns 1:1; the only thing that may need the one-line flip is the kinship
> direction above.
