# Pixel Display Studio

Open **More → Pixel Display Studio**. The studio contains a live preview,
**Open display window**, and **Compare all expressions**. The latter is a reference
sheet of all eight designs; it uses the same Flutter painter as the live screen.

The new screen is an actual separate software window, rather than an image or
another bottom-navigation tab. On Windows the existing executable is started in
`--expression-screen` mode, with a separate title and initial 640×680 size. The
viewer entry point bypasses SharedPreferences and never writes plant records.
On web a separate browser popup/tab is opened; allow popups for the app if blocked.

## Preview modes

- **Follow plant:** display cues derive from the shared plant state. Priority is
  too warm, dry soil, low light, missing you, then happy/calm. A temperature/light
  cue is a display rule, separate from the existing four-dimensional emotion score.
- **Pick a scenario:** manually preview Happy, Calm, Thirsty, Sleepy, Too warm,
  Missing you, Curious or Encouraged. This does not change sensors or earn care days.
- **Auto preview:** cycle through those eight expressions every three seconds.
  Selecting a scenario or Follow plant stops the cycle. The studio's mode survives
  navigation but is not saved across an application restart.
- **Monochrome display:** white/black raster instead of the color palette.
- **Pause face animation:** stop blinking and accent movement; the separate auto
  preview mode still changes scenarios until stopped. System reduced motion and
  the app's reduce-motion preference are also respected.

Open the display, leave the studio, and use Lab or Weather to change simulated
readings. The display session belongs to the application controller, so it keeps
following changes while another page is open. Child windows may be closed without
closing the main application. Close both main and display windows before rebuilding
Windows, because running executables can be locked by the OS.

## Rendering and transport

`PixelFacePainter` draws a 32×32 logical grid using integer rectangle scaling and
no antialiasing. There are no downloaded expression images or animation packages.
The window only scales the drawing; actual hardware dimensions, colors and refresh
rates are not selected yet. Blinks run on a small local timer; the expression's
accessible description is separate from the painting.

`ExpressionFrame` is a version-1, display-only message: expression, plant nickname,
source label, monochrome and reduced-motion flags. It contains no chat, memories,
commands or profile-edit interface. This is an internal preview contract, not the
future hardware protocol.

On Windows a controller binds an ephemeral HTTP server to **127.0.0.1 only**, using
a per-session random URL path. The child polls every 400ms, with timeout and failed
connection handling. The server starts only when Open display window is requested;
no external destination, API, backend service or account is needed.

Web uses a temporary same-origin localStorage channel containing only the frame
and a heartbeat timestamp. It is separate from the application's persisted JSON.
The controller refreshes the heartbeat every second. After five seconds without a
heartbeat, the viewer marks the last frame as disconnected. This is best-effort
preview liveness; browser timer throttling/suspension can also mark a paused parent
as stale. The viewer keeps the last frame with an explicit warning. Channel storage
is removed when the owning controller is disposed; abrupt browser closure can
leave an expired entry. Private browser modes can restrict storage or popups.

## Hardware boundary

This does not drive an OLED, LED matrix, SPI/I2C screen, serial device or BLE device.
Before hardware integration, agree the display resolution, color/monochrome format,
frame orientation, refresh budget, transport, reconnect behavior and how sensors
are calibrated. These are fictional companion expressions, not measurements of
biological plant emotions. Positive-feedback/curiosity scenes are explicit manual
previews; no earned achievement is fabricated.
