# Architecture and local rules

`main.dart` opens local storage with a retryable error screen. `app/app.dart`
contains theme application, a centered 480px maximum-width navigation shell and
detail routes. `features/` holds focused screens. `widgets/` holds reusable cards,
forms and the original animated `CustomPainter` character.

`PlantController` is the single shared `ChangeNotifier`. `PlantData` holds the
versioned document. All Lab and Weather changes update that document; care,
emotion, Home and chat context derive from it. Widgets do not cache alternate
sensor or recommendation state. Profile form drafts are committed explicitly.
All persistent edits capture a whole JSON document and enter an ordered write
queue. Writes cannot race and overwrite newer documents. A failed write leaves
in-memory state available, shows a warning, and can be retried. Do not close the
app while that warning is present. Shared preferences is adequate for a small
prototype, not a transactional database for large-scale or sensitive records.

LocalRepository keeps unreadable originals and writes a timestamped recovery
copy before presenting defaults. It does not silently drop malformed list entries.
Unknown schemas are treated as unreadable. No migration from an unavailable older
app format is claimed. Defaults are not saved until an explicit user action.
Sensor values are finite and clamped to demo ranges (0–100% moisture/humidity,
0–30,000 lux, 0–50°C, pH 0–14). Lists of sensor snapshots and activity events are
bounded at 100 and 200; the UI displays recent subsets. Memories, journal entries,
chat and posts remain until cleared. Do not use this prototype for sensitive data;
storage is not encrypted. Settings explains device-local storage and removal risks.

## Care rules

The local profiles contain illustrative min/max ranges for moisture, light,
temperature, air humidity and pH. These are demo heuristics, not referenced
horticultural science. Readings outside those ranges generate an explanation
with measured value, range and a concrete action. Priority is moisture (5),
temperature (4), light (3), humidity (2), pH (1). All normal yields one balanced-care
tip. Healthy Conditions uses the active species' range midpoints.

## Emotion rules (fictional, not biological claims)

Let W be the number of out-of-range sensor dimensions. Clamp scores to 0–100:

- Comfort = 100 − 18W.
- Vitality = 100 − 12W − 15 when temperature exceeds the upper range by over 5°C.
- Attachment = 20 + 4 × memory count + 5 × distinct check-in dates.
- Loneliness = 15 × whole days since last interaction (25 before any interaction).

Mood precedence: dry soil → Thirsty; vitality below 65 → Sleepy; loneliness above
55 → Missing you; comfort at least 90 → Thriving; otherwise Calm. The painter
switches mouth/eyes and a water-drop cue; subtle leaf sway can be disabled through
Settings and respects the system's reduce-animation preference. These rules are
stable for a given state and time; no random changes or real emotion detection.
Loneliness recalculates on rebuild/interaction, not through a background timer.

## Agent and earned progress

The local agent checks distress keywords first, then explicit `Remember [that] …`,
recall, care, supportive conversation, greetings and mood questions. Unknown input
gets a clear fallback. Safety responses are an illustrative keyword demonstration,
not reliable crisis detection or medical advice. There is no model, API call,
sentiment classifier, RAG, proactive agent or vector database.

Memories are captured only explicitly. Recall currently returns the latest saved
memory, not semantic search. Personality adds a deterministic tone. Profile,
current mood, sensors and care rules provide response context. Check-ins persist
one local calendar date per day. The local challenge needs three distinct care
dates and a deliberate join. Clock manipulation is not prevented. No XP, invented
streak, or fabricated earned reward is shown. Simulated interactions never claim
that a real plant has been watered or another person received a post/visit.


## Multi-plant collection

PlantController now owns a version-2 PlantCollection and exposes its selected
PlantData to the existing services/screens. Each record keeps its original data
format, and all record edits and selection changes share the ordered write queue.
The former single-plant document is accepted and preserved before migration.
Read `PLANT_COLLECTION.md` for schema, backup, preference scope and Home layout.
