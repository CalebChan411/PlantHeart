# Feature matrix

“Tested” below refers to the local Flutter implementation and the Linux-hosted
unit/widget suite. Native Windows execution is not claimed. No unavailable older
feature matrix existed in the empty checkout.

| Area | Delivered behavior | Evidence / boundary |
| --- | --- | --- |
| Onboarding | Saved name/species/personality, defaults and later editing | Widget first-run/reload; controller profile persistence |
| Mobile layout/navigation | Centered max 480px, five destinations, scrollable tools | All destinations/detail routes; narrow larger-text widget test; Chromium screenshots |
| Companion | Original painted leaves/pot/face, sway, thirsty and sleepy expressions, reduce motion | Reactive sensor widget test and visual inspection; fictional moods |
| Sensors | All five sliders, constrained values, four presets, 100 snapshots, latest 10 expanded readings | Range, preset, snapshot and reload tests; no hardware |
| Emotion | Comfort/vitality/attachment/loneliness and explainable deterministic moods | Bounds/time/propagation tests; simulator metrics only |
| Care | Species ranges, priority, values, reasons/actions, Home/More access | Species and dry/healthy/weather tests; illustrative thresholds |
| Chat | Persistent conversation, profile/tone/sensor context, prompts and keyboard send | Agent unit tests and keyboard-send widget test; no LLM |
| Memory | Explicit capture, latest-entry recall, CRUD, confirmed deletion and timestamps | Unit/widget CRUD and restart tests; no vectors/semantic retrieval |
| Growth | Milestone CRUD, lifecycle transitions, care-event timeline, copyable text | Controller lifecycle/CRUD/reload tests; text photos only |
| Weather | Four scenarios, three simulated locations, preview/apply, downstream update | Preview/apply controller test; no API or location permission |
| Community | Sample/user posts, like toggle, virtual visit, joined/earned care challenge | Interactions/reload/idempotent distinct-day tests; all local |
| Library | Pothos, Snake Plant, Spider Plant, selection and heuristic suitability | Species care/reload tests; demo data, not a verified plant database |
| Settings | Profile, larger text, reduce motion, check-in/sharing preferences, data summary | Settings round-trip; narrow text tests; clipboard depends on platform |
| Data management | Scoped clearing, confirmation and full reset to onboarding | Controller clear/reset tests and widget cancellation/deletion flows |
| Persistence/recovery | One ordered document, original-data recovery backups, save retry | Full round-trip, concurrent writes, corrupt-data and failed-write tests |
| Windows | Official runner, plugin registration, launch/build scripts | Generated and reviewed; compile/run still requires Windows |
| Web validation target | Local renderer assets and native browser storage | Release build and Chromium functional/reload smoke test |
| Pixel display preview | Eight pixel expressions; manual/follow/tour modes, monochrome, reference sheet, separate viewer window | Flutter UI and loopback transport tests; physical-screen integration and native Windows launch still unverified |
