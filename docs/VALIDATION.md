# Validation and delivery evidence

Validation performed on the Linux cloud host with **Flutter 3.47.8**, framework
`737ba8f885dc774b53b442759999a312c9461e4e`, **Dart 3.13.7**, and Chromium 154.
The initial repository was empty; this is a new local implementation, not a
verified upgrade of an older unavailable application.

| Check | Actual result |
| --- | --- |
| SDK installation and repeatable setup script | Passed; official pinned Git source and standard engine downloads; workspace-local caches |
| `flutter pub get --enforce-lockfile` | Passed; included lockfile resolves without changes |
| `flutter analyze` | Passed; no issues |
| `flutter test --reporter expanded` | **19 passed**, 0 failures, 0 skipped (13 controller/service tests, 6 widget tests) |
| `flutter build web --release --no-web-resources-cdn` | Passed; release output in `build/web`, local renderer assets; Wasm compatibility dry run also succeeded |
| Local HTTP HTML and `main.dart.js` | Passed; main script HTTP 200, 2,717,090 bytes |
| Chromium functional smoke | Passed; onboarding, dry-soil preset, chat explicit memory, Garden display, reload retaining memory and Thirsty mood |
| Browser runtime/network observation | 0 JavaScript page errors and 0 external network requests in the local smoke workflow |
| Visual inspection | Original onboarding, Home and Garden inspected at desktop and narrow widths; screenshots in `docs/screenshots` |
| `flutter run -d windows` | Attempted; unavailable: “No supported devices found with name or id matching 'windows'” on Linux |
| Native Windows compilation and plugin runtime | **Not executed**; requires Windows and Visual Studio C++ workload |
| `git diff --check` | Passed; checkout originally had no tracked files, so this alone does not validate newly created source |
| Reusable environment draft | `install_script`, `start_skill` and `storage.googleapis.com` custom network entry saved; no secrets required |

The web build emits an informational font-subset notice for Flutter's unused
Cupertino fallback font. All app icons use bundled Material Icons; the build exits
successfully. Newer dependency notices were not used to upgrade the locked graph.
Wasm compatibility output is not a claim of an executed Wasm build.

## Test coverage

Controller/service tests exercise dry/healthy and species-specific care, mood
propagation into chat, explicit memory capture/recall/edit/delete, distress and
unknown messages, weather preview versus apply, emotion score bounds and elapsed
time, distinct-date/idempotent check-ins and challenge completion, full JSON
round-trip (all modules/preferences), lifecycle and milestone CRUD, scoped clearing
and reset, corrupt-data recovery backups, constrained/non-finite sensors, ordered
concurrent saves and failed-save recovery.

Widget tests exercise first run and a simulated restarted controller, all five
destinations, all five detail modules and back navigation, keyboard chat submission,
memories across modules, memory creation/edit and cancelled/confirmed deletion,
weather apply, larger-text preference, clearing and cancelled/confirmed full reset,
and narrow layouts at 360×740 with larger text. These tests use mocked preferences;
the separate browser reload check exercises real browser local storage.

## Corrections made during validation

- Prevented an empty “Remember that” request from saving the word “that”.
- Made the header title flexible on narrow layouts.
- Added Material surfaces inside cards so interactive ListTiles show their ink
  feedback and pass Flutter 3.47's runtime assertions.
- Moved asynchronous save feedback behind mounted checks.
- Initialized the save queue lazily; widget tests drain writes within their test
  zone rather than awaiting zone-bound futures from an external teardown.

## Remaining limits

There are no known unresolved analyzer, test or web-build failures. A subsequent
user report identified repeated Windows accessibility-bridge AXTree errors; see
the follow-up below. Native Windows
build/run, clipboard behavior on Windows, real screen-reader acceptance and manual
Windows UX still require a Windows host. The official Windows runner was generated,
its title/starting size adjusted, and plugin files resolved; that does not establish
native build success. Mobile native targets are not included.

The prototype is not an encrypted database, medical service, scientific emotion
model, hardware integration or cloud product. Camera/photos, voice, videos, live
weather, LLM/RAG, family accounts, OS notifications and real social sharing remain
future work. Latest-memory recall is simple lookup. Calendar-based rewards trust
the device clock. No separate visual references were attached; visual checks use
the written brief. See `TRACEABILITY.md` for proposal scope.

Draft persistence does not publish an environment or validate restoration in a new
task. Review and save the changes in environment settings, then publish the
environment to make this setup reusable. Repository source is versioned separately in Git. Environment publication does
not itself commit or push source to GitHub, deploy the app or publish a website.


## Windows accessibility follow-up

The user successfully launched the app on Windows, then reported repeated
`accessibility_bridge.cc(114)` errors stating that nodes would not be in the AX
tree and were not the new root, across interactions (not just Lab).
The Linux tests do not execute Windows' native AXTree bridge.

The follow-up reduces app-wide semantics churn: MaterialApp/navigation are no
longer rebuilt on every data notification, successful saves do not notify again
unless clearing a storage error, the main content has an explicit stable semantics
container, and the animated character has its own semantics boundary. Slider
increase/decrease announcements now format the proposed value rather than always
announcing the current value. Accessibility is retained.

Validation: **20 tests passed** (13 controller/service, 7 widget); analyzer clean.
The added regression test enables semantics, repeats all tab transitions and
sensor presets, verifies a stable content boundary and checks actual slider
values and distinct increase/decrease announcements. These checks do not prove
the native Windows error is resolved. This change is a mitigation pending Windows
retest, not a confirmed diagnosis or engine fix. No Flutter SDK patch or downgrade
was applied. Capture the first error from a cold start if the problem persists.

## Pixel display simulation follow-up

A new **More → Pixel Display Studio** module provides eight pixel expressions,
an actual separate software viewer, manual/follow/auto modes, monochrome output,
reduced motion and a comparison sheet. The display session follows state while
navigating away from its controller page. It never edits sensor or reward data.
No new package dependency or lockfile change was required.

Final checks for this update:

- `flutter analyze`: no issues.
- `flutter test --reporter expanded`: **26 passed**, zero failures/skips
  (17 unit/transport tests and 9 widget tests).
- `flutter build web --release --no-web-resources-cdn`: passed; same informational
  Cupertino fallback-font subset notice as before.
- Chromium: opened a separate display popup; changed six manual expressions;
  toggled monochrome; returned to Lab and confirmed a live Thirsty cue; opened the
  eight-expression comparison sheet; closed the controller and confirmed stale-link
  feedback. Zero JavaScript page errors and zero external network requests in the
  final smoke run. An initial special-character font fallback was removed before
  the final run, restoring the offline check.
- Loopback transport test: a real local HTTP server/receiver exchange, frame
  updates, wrong-channel 404, endpoint restriction and shutdown passed. Process
  launch is injected in this test; it does not prove Windows process creation.
- Screenshots captured from the implemented Flutter UI, not mockup images:
  `docs/screenshots/pixel-display/expression-sheet.png` and the individual window
  images in the same folder.

Windows runner arguments/title/initial size are prepared for the display-only
process. Actual Windows native second-window creation remains **unverified on
this Linux host**, as does the earlier Windows AXTree issue. No physical screen,
firmware or display transport has been implemented. See `PIXEL_DISPLAY.md`.

Source publication is handled separately from environment publication and
requires explicit user approval. Consult Git history for the published revision.

## Home five-zone reading overview

The Home reading chips now form five centered, vertically ordered status cards.
Each shows units, a textual five-zone status, species-specific target range,
colored segments, current-position pointer and an interactive numeric-range
explanation. Each card is an independent scroll item. The Lab shortcut was tested
through normal pointer/scroll gestures. The ordinal display scale and its prototype
outer-zone thresholds are explained on the page and in `HOME_GAUGES.md`.

Checks for this update:

- `flutter analyze`: no issues; formatting check passed.
- `flutter test --reporter expanded`: **32 passed**, zero failed/skipped
  (21 unit/transport tests and 11 widget tests).
- Six new tests cover all five classifications, inclusive ideal endpoints,
  pointer ordering/clamping, species changes, precise numeric formatting,
  sequential Home card order, range details, Lab navigation and 320px width
  with 2x text scale and extreme readings.
- `flutter build web --release --no-web-resources-cdn`: passed.
- Chromium functional check: rendered all five readings, applied Hot Day in Lab,
  verified low soil moisture, high temperature and low humidity propagated to
  Home, opened the numeric-range dialog, and used Change readings in Lab.
  Zero JavaScript page errors or external network requests in this run.
- Actual UI screenshots: `docs/screenshots/home-gauges/ideal-readings.png` and
  `hot-day-readings.png`.

No sensor persistence schema, dependencies, care-engine thresholds or emotion
rules changed. The five-zone outside bands are display-only subdivisions.
Native Windows behavior of this update has not been retested on this Linux host;
the earlier AXTree report remains a separate Windows validation item.

Source publication requires explicit user approval and is separate from
environment publication. Consult Git history for the approved revision.

## Compact Home and independent plant collection

Home is now a fixed overview at standard text size rather than a long list of
large cards. Five compact three-band rows, values, plant illustration, arrows,
selected name/species/mood, check-in and care entry fit together. Row taps retain
exact ranges and detailed five-zone status. History and other modules remain in
the existing destinations. The three bands are explicitly ordinal care ranges.

The header Add plant dialog creates an independent record. Wrapping arrows select
records using a 320ms slide/fade; each species has different vector foliage.
Selection is persisted. Reduced motion resets the switcher so pending transitions
are stopped and subsequent motion uses the requested preference.

Validation of this update:

- `flutter analyze`: clean; format and whitespace checks passed.
- `flutter test --reporter expanded`: **43 passed**, zero failures/skips
  (28 unit/transport tests and 15 widget tests).
- `flutter build web --release --no-web-resources-cdn`: passed; same informational
  unused Cupertino font-subset notice as before.
- Standard-size widget checks at 360×740, 390×844, 440×900 and 480×960 confirm no
  Home scrollable and all five reading rows inside the visible area. The desktop
  larger-text preference is checked, as is non-clipping fallback for 2x text.
- Actual animation test observes both outgoing/incoming plant widgets during the
  transition and only the selected plant after completion.
- Seven collection tests cover lossless legacy conversion and backup, independent
  sensor/chat/memory/journal/community/check-in state, selected-record restoration,
  preference scope, wrapping selection, rapid queued writes, reset/scoped clearing
  and malformed collection recovery.
- Chromium workflow added Snake Plant and Spider Plant through the real dialog,
  switched arrows back to Milo, verified Milo's original 12% reading, refreshed
  and verified three saved companions. Mobile screenshots show the full overview.
  The completed smoke workflow had zero JavaScript page errors and zero external
  network requests. Final UI screenshots are in `docs/screenshots/plant-overview`.

The existing storage key now contains a version-2 collection of version-1 plant
documents; the original single-plant string is preserved before migration writes.
See `PLANT_COLLECTION.md` for schema, backup and rollback boundaries. Hardware
pairing, multi-user accounts and per-plant physical displays are not implemented.
Native Windows execution and the prior AXTree issue remain unverified here.

Source publication requires explicit user approval and is separate from
environment publication. Consult Git history for the approved revision.
