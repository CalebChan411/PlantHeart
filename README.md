# Plant Heart

A friendly, offline Flutter plant companion for the AY 2026–2027 final-year
project. Meet **Milo**, explore simulated care conditions, keep memories and grow
a little routine. No hardware, keys, accounts, paid services or external AI needed.

![Plant Heart Home](docs/screenshots/product-tools/home-navigation.png)

## Run on Windows

1. Install **Flutter 3.47.8 / Dart 3.13.7** and Git; add Flutter's `bin` to PATH.
2. Install Visual Studio 2022 with **Desktop development with C++**, the Windows
   SDK and CMake tools. VS Code alone does not provide this native toolchain.
3. Extract/open the project root (the folder containing `pubspec.yaml`).
4. In PowerShell:

```powershell
flutter doctor -v
flutter config --enable-windows-desktop
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter run -d windows
```

Or run `powershell -ExecutionPolicy Bypass -File .\scripts\run-windows.ps1`.
The helper only runs dependency resolution and launch; no admin rights required.
For a release executable use `flutter build windows`. Ship the entire resulting
`build\windows\x64\runner\Release` folder, not just the exe. Windows platform
files are included, with a 540×960 starting window and a centered 480px app.
The UI also adapts to narrower screens. Android and iOS runners are future work.

Internet is needed for SDK/dependency installation. Normal installed-app use is
offline. There is no backend to start and no `.env` or secret configuration.

## What's inside

- **First run:** plant name, species and personality; optional defaults; locally saved.
- **Home:** animated plants with arrow switching, five compact readings visible
  together, direct care advice and earned daily care check-ins.
- **Community:** local posts, likes, virtual visits and an earned three-day challenge.
- **Memoir:** memories and growth journey; add/edit/confirmed delete, timestamps,
  lifecycle selection, activity timeline and copyable journey summary.
- **Care:** species-aware recommendations based on the selected plant's readings.
- **More:** plant library and settings, plus a separate **Prototype testing** area.
  Sensor, conversation, weather and pixel-display tools each open in a closable
  popup. Chat and Lab are no longer bottom-navigation destinations.
- **Conversation simulator:** typed input stands in for future voice input.
  Persistent deterministic replies, explicit `Remember that …` capture, latest
  recall and suggested prompts remain available. Replies trigger black-and-white
  pixel mouth/eye animation in both the popup and the separate display window.

To hide prototype test entries in a product build, run:

```powershell
flutter run -d windows --dart-define=PLANT_HEART_TEST_TOOLS=false
```

This controls entry visibility; physical sensors, voice input and real social
networking still need implementation. See [navigation and demo guide](docs/PRODUCT_NAVIGATION.md).

All UI is English. Care and emotion rules are illustrative; this app does not
measure real plant emotions or provide validated horticultural or medical advice.

## Architecture and storage

`lib/main.dart` handles boot; `lib/app/` owns the shell and shared controller;
`lib/models/` owns typed data and serialization; `lib/services/` owns care/emotion,
sensor/weather rules, local agent and storage; `lib/features/` owns screens;
`lib/widgets/` owns the design system and vector character.

One `ChangeNotifier` controls the selected plant and its collection. Sensor or species changes feed all
care, mood and chat views. Shared preferences stores a version-2 collection of version-1 plant documents
(`plant_heart_v1`) on this device. Writes are ordered, failures are visible and
retryable, and unreadable originals are preserved in recovery copies before
showing defaults. Storage is **unencrypted**, local-only and not cloud backed up.
Do not enter sensitive information. Uninstalling/clearing browser data can remove
records. A summary copied to the clipboard is not a full backup/import format.

See [architecture and rules](docs/ARCHITECTURE.md), [initial audit](docs/AUDIT.md),
[feature matrix](docs/FEATURE_MATRIX.md), [proposal traceability](docs/TRACEABILITY.md)
and [validation report](docs/VALIDATION.md).

## Validate

```powershell
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build windows
```

`scripts/verify.ps1` runs these commands and preserves failures. The Linux cloud
host can run analysis/tests and `flutter build web --release --no-web-resources-cdn`.
The built web version bundles renderer assets locally; serve `build/web` from a
static server. This does not claim an installable offline PWA: opening the web
app still needs access to its static host. The native Windows app requires no
network during operation.

## Boundaries

Sensors, weather and community are explicitly local simulations. Chat is a small
rule engine, memory recall is latest-entry lookup, and safety handling is only a
prototype keyword demonstration. Check-ins use the device calendar, not a server.
Sharing is an inert, clearly labelled future preference. Check-in reminders are
an in-app card, not operating-system notifications. Emotions recalculate on UI
updates; no background emotion scheduler or proactive dialogue is implemented.

Future scope: physical pot/firmware, BLE/device connection, battery/power, live
weather, cloud profiles, authenticated family sharing, encryption, LLM/RAG/vector
memory, voice/TTS, camera/photos, time-lapse/memorial video and native mobile builds.
Photo checkpoints currently use honest text milestones. Windows native execution
must still be verified on Windows; it cannot run on this Linux cloud host.


Windows follow-up: a user confirmed native launch, but reported repeated Flutter
AXTree accessibility errors during interaction. A previous change reduced global
semantics rebuilds; native Windows confirmation is still pending.
See the follow-up in `docs/VALIDATION.md`. Do not treat Linux/widget success as
proof of native Windows accessibility correctness.


## New local preview: Pixel Display Studio

Open **More → Pixel Display Studio → Open display window** for a separate pixel
face window. Preview eight expressions, follow the selected plant, cycle scenes
or open the comparison sheet. Output is white eyes, eyebrows and mouth on black,
without a head silhouette or avatar ring. The logical artwork is **32×24 pixels**.
Manual scenes never change plant data. Replies from **More → Conversation
simulator** animate the same display; replay does not add another message.
Animation respects system/app reduced motion and the studio's pause control.
See [pixel display details](docs/PIXEL_DISPLAY.md).

![Actual reply animation](docs/screenshots/product-tools/reply-animation.gif)

The second native window uses a temporary loopback-only connection (127.0.0.1);
the browser popup uses same-origin local storage. No external service is required.
This is a software screen simulator; no physical display driver is implemented.
Close all Plant Heart windows before rebuilding on Windows. Windows native launch
of the second process still requires testing on a Windows machine.

## Compact Home and multiple plants

Home now shows the plant and all five readings together, without scrolling at
normal desktop/phone sizes. Compact rows have three labelled care bands and a
ring pointer; tap for exact species ranges and detailed status. The scale is
ordinal, not a linear ruler. Very small windows or extreme text scaling retain
an accessibility scrolling fallback.

Use the header **+** to add a plant and the left/right arrows to switch with a
slide/fade transition. Each plant keeps its own readings, conversation, memories,
journey and care records; the selection survives restart. Three species have
distinct original vector foliage. Existing single-plant data is preserved and
backed up before the first version-2 collection write. Earlier app versions do
not read the new collection format. See [collection and migration details](docs/PLANT_COLLECTION.md).
