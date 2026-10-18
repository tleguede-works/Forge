# Design review checklist

QA asks:
- Does every PRD business rule and edge case map to a screen or a state?
- Does every layout region appear in the `region-used` lines of one or more screens, or is it shared chrome declared in the layout itself?
- Does every screen define all six states?

Red team asks:
- For each screen, apply H3 to H8 and report any zone whose rank contradicts its stated reason.
- Does any screen file describe two screens, or does any zone belong to a different route?
- Does a navigation entry lead to a route that is missing from the screen map?
- Do two screens render the same component differently?
