# Design system: <project name>

## 1. Colors {#colors}
Every token has a value. A token with no value is a defect. `On token` names the background
the colour is used on, and `Contrast` states the measured ratio. `forge design check` computes
the ratio from the two hex values and refuses a text colour below 4.5:1 (3:1 when the row
says `large`), and refuses a stated ratio that the values do not produce.
| Token | Value | On token | Use | Contrast |
|---|---|---|---|---|
| color-bg | #FFFFFF | color-bg | page background, non-text | n/a |
| color-text | #111111 | color-bg | body text | 18.9:1 |

## 2. Typography {#typography}
| Token | Typeface | Size | Weight | Line height | Where it is used |
|---|---|---|---|---|---|
| text-body | <typeface> | 16px | 400 | 24px | body copy |

## 3. Spacing and radius {#spacing-and-radius}
| Token | Value | Use |
|---|---|---|
| space-1 | 4px | gap between icon and label |

## 4. Primitive components {#primitive-components}
| Component | States | Tokens used | Behavior |
|---|---|---|---|
| Button | default, hover, pressed, focus, disabled, error | color-primary, space-2, radius-1 | <behavior> |

## 5. Navigation {#navigation}
Order of entries, the active state, and the behavior on small and large screens.

## 6. Motion and feedback {#motion-and-feedback}
| Event | Animation | Duration | Reduced-motion behavior |
|---|---|---|---|
| <event> | <animation> | <ms> | <behavior> |
