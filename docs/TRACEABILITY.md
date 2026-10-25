# Proposal-to-prototype traceability

Authority: supplied *Plant Heart Project Proposal (AY26–27)*, six pages, and the
user's explicit local-software phase constraints. Proposal requirements are goals,
not a claim that hardware or cloud functionality exists. “Local simulation” means
working on-device behavior with deterministic/mock inputs, tested in this phase.

| Proposal area (pages) | Current status | Implementation and validation |
| --- | --- | --- |
| Emotional companionship (1–3) | Local simulation | Original companion, chat and local memories; agent, navigation, memory and restart tests |
| Four emotion dimensions (2) | Local simulation | `EmotionEngine`, explained on Home; deterministic bounds/time tests |
| Sensors/environmental awareness (2–3) | Local simulation | Five sensor values and snapshots in Lab; presets/ranges/propagation/reload tests |
| Personalized care and species profiles (2–3) | Local simulation | Three profiles, species-aware care priority, ranges and actions; cross-species/weather tests |
| Short/long memory and complementary dialogue (2) | Partial | Persistent chat and explicit text memories, tone selection and latest recall; no vector DB, sentiment analysis, RAG or evolving personality |
| Crisis keyword mechanism / non-medical boundaries (2–3) | Partial prototype | Keyword response with trusted-person/professional/emergency guidance; distress unit tests; not reliable detection |
| Mobile onboarding/dashboard/chat/care/community (2) | Implemented local UI | Five destinations and detail routes, English mobile presentation; first-run/navigation/keyboard/widget tests |
| Accessibility (2–3) | Partial | Larger text, labels, scrolling, touch/keyboard controls, reduced motion; narrow text tests; voice broadcast future |
| Offline operation (2–3) | Implemented for native local workflow | No service calls; preferences persistence and derived rules; browser smoke records no external requests after local asset build |
| Privacy/security (2–3) | Partial | Device-local records and explicit clearing; encryption, authentication, authorization and anonymization not implemented |
| Growth timeline/events/sensor curves (3) | Partial local implementation | Journal and care timeline, lifecycle state, moisture bars; snapshot and milestone CRUD/reload tests |
| Life cycle and memorial support (2–3) | Partial | Early/growing/mature/resting/remembered stages, text summary; camera, real health reports, photo albums and videos future |
| Weather/localized care (3) | Local simulation | Hong Kong-area labels, four weather scenarios and care reminders; preview/apply tests; no live weather, outdoor-gear feed or indoor/outdoor comparison |
| Virtual visits/community/light gamification (3) | Local simulation | Posts, likes, virtual visits, distinct-day care challenge; local interaction/reload tests; real social/cooperative network future |
| Similarity/crowdsourced plant database (2–3) | Partial / future | Local range-count suitability heuristic only; no cosine matching, crowd database or cloud recommendations |
| Expression library/animation (3) | Partial | Lightweight vector pot/leaf character with responsive face, sway and reduce motion; pixel display firmware/audio/music/TTS future |
| Proactive dialogue, emotion record/review (2) | Future / partial | Current mood explanation only; activity events stored; no background dialogue, historical emotion chart or dedicated mindfulness module |
| Family sharing and notifications (2–3) | Future | Clearly labelled local preferences and Home reminder card; no cross-device sharing or system notification service |
| Hardware/embedded/power/camera/voice (2,4–5) | Future | No device firmware, physical sensors, camera capture, solar/battery telemetry, speaker or embedded screen |
| Cloud/LLM/vector/TTS/weather APIs (2–5) | Future | No backend, paid services, API keys or network client; controller/services provide later integration boundaries |
| Android/iOS delivery (3–4) | Future native targets | Responsive Flutter UI prepared; only Windows and web runners included; mobile native build/deployment untested |
| Response time under 2s (3) | Partial evidence | Rule calculations synchronous and browser flows responsive; no formal benchmark or hardware/cloud performance claim |
| Documentation/testing/demo (4) | Implemented for local phase | README, audit, architecture/rules, feature matrix, validation and screenshots; hardware integration/user acceptance remains future |

See `VALIDATION.md` for actual executed checks and limitations. Screen presence
alone is not used as evidence for unimplemented proposal integrations.


Pixel-display follow-up: an original 32×32 expression renderer and standalone
software viewer now provide eight selectable scenes, follow-state behavior,
blinking, monochrome preview and a reference sheet. This advances the expression
library prototype; it does not implement firmware, a physical pixel screen or a
hardware communication protocol. See `PIXEL_DISPLAY.md` for the boundary.
