# Home sensor status bars

The Home environmental reading chips are replaced with a centered vertical list
of five cards: soil moisture, light intensity, temperature, air humidity and soil
pH. Each card shows its value/unit, a textual status, its species-specific ideal
range, five labelled color zones and a high-contrast pointer. Readings are still
simulated. Use **Change readings in Lab** to edit the shared state; the Home
pointer is a read-only indicator. Each info button opens the numeric range details.

The five labels are **Very low / Low / Ideal / High / Very high**. The ideal
minimum/maximum come directly from the selected `PlantProfile`, including both
endpoints, matching the Care Guide. The two outside regions are each divided at
their midpoint to distinguish low from very low, and high from very high. These
extra divisions are visual prototype rules, not validated severity thresholds.
Changing the selected plant species changes the card ranges and pointer position.

## How the pointer works

The five color regions have equal display width so every label remains legible.
This is an **ordinal care-zone scale, not a linear numerical ruler**; the UI states
that explicitly. Within each region the pointer moves proportionally with the
reading. Values at the ideal minimum and maximum are still labelled Ideal. Values
outside the displayed domain clamp the pointer to the end, without wrapping.

For example, Golden Pothos moisture uses a 0–100% domain and a 30–65% ideal range:

| Status | Illustrative range |
| --- | --- |
| Very low | Below 15% |
| Low | 15% to below 30% |
| Ideal | 30–65%, inclusive |
| High | Above 65% to below 82.5% |
| Very high | 82.5% and above |

The ranges used for CareEngine and EmotionEngine are unchanged. No additional
sensor values or conflicting per-page state are stored. SensorGauge only derives
labels and display positions; sensor edits and persistence remain in the existing
shared controller. The existing pixel display window is unaffected.

The cards are individual Home scroll items, keeping the long page accessible and
avoiding an oversized item in the lazy list. Labels, units and an accessible
summary accompany color. The layout supports narrow screens and larger text;
the range dialog scrolls and the Lab shortcut remains actionable.
