---
name: flutter-icon
description: Generates or updates Flutter app icons correctly for Android adaptive icons and iOS full-bleed. Use when changing, creating, or redesigning a Flutter app icon, updating launcher icons, or fixing the "icon inside icon" double-border bug on Android.
argument-hint: "[icon design description]"
allowed-tools:
  - Bash(python3 *)
  - Bash(pip3 *)
  - Bash(flutter pub get)
  - Bash(dart run flutter_launcher_icons)
  - Bash(mkdir -p assets/icon)
  - Edit
  - Write
---

# Flutter App Icon Generator

Generate or update the app icon for a Flutter project correctly across Android (adaptive) and iOS (full-bleed).

## Arguments
`$ARGUMENTS` — Optional description of the desired icon design. If empty, redesign the existing icon or use a sensible default for the project.

## Rules — read before touching any file

### Why these rules exist
- **Android API 26+** uses adaptive icons: the OS composites a *foreground layer* (PNG with transparent bg) over a *background layer* (solid color or image) and then clips both with a shape mask (squircle, circle, etc.). If you bake rounded corners into the source image, Android clips it again → "icon inside icon."
- **iOS** applies its own squircle mask to a full-bleed square. Pre-baked rounded corners leave visible corner padding inside the squircle → same inset problem.

### Correct approach
| Asset | Background | Rounded corners | Notes |
|---|---|---|---|
| `app_icon_ios.png` | Full-bleed solid color | ❌ None | iOS adds its own mask |
| `app_icon_foreground.png` | Transparent (RGBA) | ❌ None | Android foreground layer; content must fit inside safe zone |

**Android safe zone:** the center 72/108 = **66.7%** of the canvas is always visible regardless of mask shape. Keep all meaningful content (outer_r, etc.) within that region. For a 1024 px canvas: safe = 683 px, so `outer_r ≤ 340`.

## Steps

### 1. Check prerequisites

```bash
python3 -c "from PIL import Image; print('ok')" 2>/dev/null || pip3 install Pillow
```

Check `pubspec.yaml` for `flutter_launcher_icons` in dev_dependencies. If absent, add it:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.1
```

### 2. Create icon assets directory

```bash
mkdir -p assets/icon
```

### 3. Generate icon PNGs with Python/Pillow

Write and run a Python script that produces **two files**:

#### `assets/icon/app_icon_ios.png` — 1024×1024, full-bleed square
```python
from PIL import Image, ImageDraw
size = 1024
img = Image.new('RGBA', (size, size), BACKGROUND_COLOR)  # solid fill, no rounded_rectangle
draw = ImageDraw.Draw(img)
# ... draw design centered on canvas ...
img.save('assets/icon/app_icon_ios.png')
```
- Use `Image.new('RGBA', (size, size), bg_color)` for the background — **not** `draw.rounded_rectangle`.
- Design fills edge-to-edge; iOS clips to squircle automatically.

#### `assets/icon/app_icon_foreground.png` — 1024×1024, transparent background
```python
fg = Image.new('RGBA', (size, size), (0, 0, 0, 0))  # fully transparent
draw = ImageDraw.Draw(fg)
# ... draw design centered, scaled so outer_r ≤ 340 for 1024px canvas ...
# When cutting out a center hole in a donut, fill with (0,0,0,0) not the bg color
fg.save('assets/icon/app_icon_foreground.png')
```
- Background **must be transparent** — `(0, 0, 0, 0)`.
- Any "hole" in the design (donut center, gaps) must also be `(0, 0, 0, 0)`.
- Scale all radii/sizes proportionally so content stays inside the 683 px safe zone.

### 4. Update `pubspec.yaml`

Set the `flutter_launcher_icons` section to:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path_android: "assets/icon/app_icon_ios.png"   # legacy Android (API < 26)
  image_path_ios: "assets/icon/app_icon_ios.png"
  adaptive_icon_background: "#RRGGBB"                  # match the bg color used in app_icon_ios.png
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
  min_sdk_android: 21
  remove_alpha_ios: true
```

- `image_path_android` (legacy) and `image_path_ios` must both be present — the tool errors if either is missing when using the split-path form.
- `adaptive_icon_background` is a hex color string matching the background of `app_icon_ios.png`.
- Do **not** use the single `image_path` key when you also set adaptive icon keys.

### 5. Run the generator

```bash
flutter pub get && dart run flutter_launcher_icons
```

Expected output includes:
- `• Creating adaptive icons Android`
- `• Creating mipmap xml file Android`
- `✓ Successfully generated launcher icons`

Verify that `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` was created — this is the adaptive icon XML. If it's missing, the Android "icon inside icon" bug is not fixed.

### 6. Verify

After running, confirm:
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` exists and references `@color/ic_launcher_background` + `@drawable/ic_launcher_foreground`
- `android/app/src/main/res/values/colors.xml` contains the `ic_launcher_background` color
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` contains updated PNGs

## Common mistakes to avoid

- ❌ Drawing the background with `draw.rounded_rectangle(...)` — causes double-rounding on both platforms
- ❌ Filling the donut center hole with the background color in the foreground PNG — should be `(0,0,0,0)`
- ❌ Omitting `image_path_android` when using `image_path_ios` — tool will error
- ❌ Making `outer_r > 340` on a 1024px foreground — content gets clipped by aggressive masks (circle)
- ❌ Using a single `image_path` for both platforms — loses adaptive icon support on Android
