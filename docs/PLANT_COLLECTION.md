# Compact Home and multiple plants

Home is now a fixed overview at standard desktop/phone sizes. The companion,
name/species/mood, both arrow controls, five readings, daily check-in and Care Guide
are visible together. Compact reading rows use three equal, labelled care bands
(Low / Ideal / High) and a white ring pointer. Tap a row for exact ranges and the
more detailed five-zone card. This is a care-zone scale, not a linear number line.
The original care thresholds have not changed.

The arrows select a different **plant record**, not just another illustration or
species setting. They wrap around the collection and are disabled when only one
plant exists. Add plants with the plus button in the header; name, species and
personality can be chosen. Edit the active profile using the pencil by its name.
Plants are not automatically created or given earned rewards. New plants start
with explicitly simulated healthy readings and empty conversations/records.

Each plant has independent sensors, snapshots, weather/location, chat, memories,
life stage, journal, activity, local community state and check-in dates. All other
modules use the selected plant. The existing pixel display follows that selection
in Follow plant mode. Larger text, reduced motion, check-in visibility and the
future sharing preference are application-wide preferences, synchronized when
switching plants. Removal of individual plants is not included in this update;
Reset all demo data removes the whole collection with confirmation. Scoped data
clearing applies only to the selected plant, as stated in Settings.

Plant changes use a 320ms slide/fade; reduced-motion settings make them immediate.
The original painter now draws different foliage for Golden Pothos, Snake Plant
and Spider Plant. These are local vector illustrations, not photographs of plants.

## Layout boundaries

No Home scrollable is created at default text size for tested 360×740, 390×844,
440×900 and 480×960 viewports. A desktop viewport with the app's larger-text
preference is also checked. Extremely small windows or very large accessibility
text use a natural-height scrolling fallback instead of clipping controls or
shrinking text to illegible sizes. History, chat, detailed advice and tools remain
accessible through their existing destinations; Home is the at-a-glance overview.

## Storage and migration

The storage **key stays `plant_heart_v1`** for continuity. Its document is now a
version-2 collection containing `activeId` and a list of `{id, data}` records. Each
record retains the existing version-1 per-plant format. The controller serializes
the full collection on its existing ordered write queue, including selection.

A valid legacy single-plant document is loaded as the first plant without losing
its name, readings or records. Loading does not write defaults. Before the first
version-2 write over a version-1 document, the repository preserves the original
string under `plant_heart_v1_before_multi_plant`. If that backup write fails, the
original is not overwritten; the existing storage warning/retry mechanism applies.

Malformed collection membership, duplicate IDs and unreadable plant documents
use the existing recovery-copy path instead of silently dropping records. Saved
backups remain unencrypted and device-local, like the rest of this prototype.
Earlier app versions do not understand the version-2 collection. Keep backups
before reverting to an earlier version; no automatic reverse migration is provided.
