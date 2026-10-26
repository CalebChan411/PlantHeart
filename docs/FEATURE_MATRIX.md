# Feature matrix

“Tested” below refers to the local Flutter implementation and the Linux-hosted
unit/widget suite. Native Windows execution is not claimed. No unavailable older
feature matrix existed in the empty checkout.

| Area | Delivered behavior | Evidence / boundary |
| --- | --- | --- |
| Onboarding | Saved name/species/personality, defaults and later editing | Widget first-run/reload; controller profile persistence |
| Mobile layout/navigation | Centered max 480px; Home, Community, Memoir, Care, More; separate test popups | All destinations/detail routes; narrow larger-text widget test; Chromium screenshots |
| Companion | Original painted leaves/pot/face, sway, thirsty and sleepy expressions, reduce motion | Reactive sensor widget test and visual inspection; fictional moods |
| Sensors | More sensor popup: five sliders, constrained values, four presets, 100 snapshots, latest 10 expanded readings | Range, preset, snapshot and reload tests; no hardware |
| Emotion | Comfort/vitality/attachment/loneliness and explainable deterministic moods | Bounds/time/propagation tests; simulator metrics only |
| Care | Species ranges, priority, values, reasons/actions, Home/Care access | Species and dry/healthy/weather tests; illustrative thresholds |
| Conversation testing | More popup with persistent replies, profile/tone/sensor context, prompts, typed simulated voice input and reply animation | Agent/controller/widget and browser checks; no LLM, microphone, audio or speech synchronization |
| Memoir / memory | Explicit capture, latest-entry recall, CRUD, confirmed deletion and timestamps | Unit/widget CRUD and restart tests; no vectors/semantic retrieval |
| Growth | Milestone CRUD, lifecycle transitions, care-event timeline, copyable text | Controller lifecycle/CRUD/reload tests; text photos only |
| Weather | More weather popup: four scenarios, three simulated locations, preview/apply, downstream update | Preview/apply controller test; no API or location permission |
| Community | Nearby schematic map, 5 searchable fictional PlantHearts, shared journals/readings, timed mutual peer reviews; existing local Feed | Search/range/filter, species-aware review, privacy, timer and persistence tests; no GPS, discovery, map API, accounts or social backend |
| Library | Pothos, Snake Plant, Spider Plant, selection and heuristic suitability | Species care/reload tests; demo data, not a verified plant database |
| Settings | Profile, larger text, reduce motion, check-in/sharing preferences, data summary | Settings round-trip; narrow text tests; clipboard depends on platform |
| Data management | Scoped clearing, confirmation and full reset to onboarding | Controller clear/reset tests and widget cancellation/deletion flows |
| Persistence/recovery | One ordered document, original-data recovery backups, save retry | Full round-trip, concurrent writes, corrupt-data and failed-write tests |
| Windows | Official runner, plugin registration, launch/build scripts | Generated and reviewed; compile/run still requires Windows |
| Web validation target | Local renderer assets and native browser storage | Release build and Chromium functional/reload smoke test |
| Pixel display preview | Eight feature-only 32×24 white-on-black expressions; manual/follow/tour modes, reply mouth animation, reference sheet, separate viewer window | Flutter UI and loopback transport tests; physical-screen integration and native Windows launch still unverified |
| Home sensor status bars | Five compact rows visible with the plant; three-band ring pointers and tappable five-zone/range details | Derived from active species; non-linear care-zone scale, no new sensor state |
| Plant collection | Add named plants; animated wrapping arrow selection; independent data and saved active selection; distinct species foliage | Isolation, full reload, legacy migration/backup, reset and accessibility layout tests; no family accounts or hardware pairing |
| Product build visibility | `PLANT_HEART_TEST_TOOLS=false` hides all More test entries; product destinations, library and settings remain | Widget check with the define disabled; visibility is not hardware integration |
| Demo growth memoir | Six illustrated fictional marigold checkpoints, date anchoring and removable per-plant sample story | Idempotence, isolation and reload checks; independent of personal memories, care days and real life stage |
| Bloom film | Embedded 18-second H.264 MP4 with play/pause/seek/replay/chapters and failure retry | Widget control checks and Chromium actual decoding; bundled pre-rendered demo, no runtime photo encoding; Windows plugin execution requires Windows |
