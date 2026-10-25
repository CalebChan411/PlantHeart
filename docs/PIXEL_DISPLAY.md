# Pixel Display Studio and reply animation

Open **More → Pixel Display Studio** for a closable tool popup. It contains a live
preview, **Open display window**, and **Compare all expressions**. The latter uses
the same painter for all eight designs. **More → Conversation simulator** also has
an inline face and an Open response display button.

The independent viewer is a separate software window. On Windows the executable
starts in `--expression-screen` mode; its entry point bypasses SharedPreferences
and never writes plant records. On web a separate browser popup/tab opens. Allow
popups for the app if blocked. The connected viewer shows only facial features on
black; a connection warning appears if the controller becomes unavailable.

## Face and modes

The old filled round head has been replaced by white pixel eyes, eyebrows and
mouth on black. There is no avatar ring or colored palette. `PixelFacePainter`
uses a **32×24 logical grid**, integer rectangle scaling and no antialiasing.
Eight distinct scenes remain: Happy, Calm, Thirsty, Sleepy, Too warm, Missing you,
Curious and Encouraged. Blinks and small gaze changes update on a 120ms timer.

- **Follow plant:** priority is too warm, dry soil, low light, missing you, then
  happy/calm. These cues are fictional companion states, not biological emotions.
- **Pick a scenario:** preview any scene without changing sensors or rewards.
- **Auto preview:** cycle scenes every three seconds; selecting another mode
  stops the tour. Mode state lasts for the app session, not across restart.
- **Pause face animation:** stop blinks/gaze/mouth motion. Auto preview is a
  separate mode, so stop it too if a completely fixed scene is needed. System and
  app reduced-motion preferences also stop facial motion.

## Conversation response

Sending typed simulated voice input produces the existing local deterministic
text reply and starts a six-shape mouth cycle. Both the inline face and independent
viewer respond. Duration is a text-length heuristic, clamped to 1.8–8 seconds;
this is visual reply simulation without speech, audio or lip synchronization.
The face returns to idle automatically. Replay restarts the animation without
adding another message or memory. A new response replaces the previous cycle;
changing plants cancels it so one plant does not inherit another's reply. Selecting
a manual scene or mode also cancels the reply. History does not autoplay on reopen.

The display session belongs to the application controller. Close a tool popup and
open Sensor simulator or Weather simulator to change readings while the separate
screen continues following them. Close both app and display before rebuilding on
Windows, because running executables can be locked by the OS.

## Display transport

`ExpressionFrame` version 2 contains expression, plant nickname, source,
reduced-motion flag and reply phase/ID/deadline. The monochrome field is always
serialized as true. It contains no conversation text, memories, sensor-edit
commands or profile editor. Version-1 frames remain readable with idle animation
defaults. This is an internal preview contract, not the hardware protocol.

Windows binds an ephemeral HTTP server to **127.0.0.1 only**, using a random
per-session URL path. The read-only child polls every 400ms. The server starts only
when the separate display is requested. No external destination or account is used.

Web uses a temporary same-origin localStorage channel with the frame and heartbeat,
separate from saved plant data. Heartbeats refresh every second; after five seconds
without one the viewer warns that it is showing the last frame. Browser suspension
can also appear stale. The reply deadline lets mouth movement stop even if the
final idle update is lost. Disposing the parent removes the channel; abrupt closure
can leave an expired entry. Private browser modes can restrict storage or popups.

## Hardware boundary

No OLED, LED matrix, SPI/I2C, serial or BLE driver is implemented. Agree the actual
resolution, orientation, refresh budget, transport, reconnect behavior and sensor
calibration before hardware integration. Native Windows launching of this viewer
still needs a Windows check; Linux/browser validation cannot prove it.
