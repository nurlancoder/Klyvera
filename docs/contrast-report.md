# Contrast report

Generated from `design/tokens.json` by `design/generators/generate.py`. Do not edit by hand.

## Method

- Ratios use the WCAG 2.1 relative-luminance formula with sRGB channel
  linearisation.
- Normal text requires **4.5:1** (WCAG AA). Klyvera applies this to all
  body, label and caption text, not only to 16 px text.
- The focus ring is a non-text UI indicator and requires **3:1** against
  adjacent surfaces (WCAG 1.4.11).
- Disabled text is exempt from contrast requirements; its ratios are
  listed for information only.
- Borders are supplementary: Klyvera never relies on a low-contrast border
  as the only affordance, so border pairs are not enforced here.

## Dark (`dark`)

Required pairs: 47. Failures: 0.

| Foreground | Background | Foreground hex | Background hex | Ratio | Result |
| --- | --- | --- | --- | --- | --- |
| `textPrimary` | `background` | `#FAFAFA` | `#0A0B10` | 18.83:1 | PASS |
| `textPrimary` | `surface` | `#FAFAFA` | `#151720` | 17.12:1 | PASS |
| `textPrimary` | `surfaceRaised` | `#FAFAFA` | `#1A1D27` | 16.11:1 | PASS |
| `textPrimary` | `surfaceHover` | `#FAFAFA` | `#1B1E29` | 15.91:1 | PASS |
| `textSecondary` | `background` | `#9BA1AC` | `#0A0B10` | 7.57:1 | PASS |
| `textSecondary` | `surface` | `#9BA1AC` | `#151720` | 6.88:1 | PASS |
| `textSecondary` | `surfaceRaised` | `#9BA1AC` | `#1A1D27` | 6.48:1 | PASS |
| `textSecondary` | `surfaceHover` | `#9BA1AC` | `#1B1E29` | 6.40:1 | PASS |
| `accentPurple` | `background` | `#8B7CFF` | `#0A0B10` | 6.01:1 | PASS |
| `accentPurple` | `surface` | `#8B7CFF` | `#151720` | 5.47:1 | PASS |
| `accentPurple` | `surfaceRaised` | `#8B7CFF` | `#1A1D27` | 5.14:1 | PASS |
| `accentPurple` | `surfaceHover` | `#8B7CFF` | `#1B1E29` | 5.08:1 | PASS |
| `accentBlue` | `background` | `#3B82F6` | `#0A0B10` | 5.34:1 | PASS |
| `accentBlue` | `surface` | `#3B82F6` | `#151720` | 4.86:1 | PASS |
| `accentBlue` | `surfaceRaised` | `#3B82F6` | `#1A1D27` | 4.57:1 | PASS |
| `accentBlue` | `surfaceHover` | `#3B82F6` | `#1B1E29` | 4.52:1 | PASS |
| `accentMint` | `background` | `#5BE7D4` | `#0A0B10` | 12.94:1 | PASS |
| `accentMint` | `surface` | `#5BE7D4` | `#151720` | 11.76:1 | PASS |
| `accentMint` | `surfaceRaised` | `#5BE7D4` | `#1A1D27` | 11.07:1 | PASS |
| `accentMint` | `surfaceHover` | `#5BE7D4` | `#1B1E29` | 10.94:1 | PASS |
| `success` | `background` | `#5BE7D4` | `#0A0B10` | 12.94:1 | PASS |
| `success` | `surface` | `#5BE7D4` | `#151720` | 11.76:1 | PASS |
| `success` | `surfaceRaised` | `#5BE7D4` | `#1A1D27` | 11.07:1 | PASS |
| `success` | `surfaceHover` | `#5BE7D4` | `#1B1E29` | 10.94:1 | PASS |
| `danger` | `background` | `#FF6B6B` | `#0A0B10` | 7.08:1 | PASS |
| `danger` | `surface` | `#FF6B6B` | `#151720` | 6.44:1 | PASS |
| `danger` | `surfaceRaised` | `#FF6B6B` | `#1A1D27` | 6.06:1 | PASS |
| `danger` | `surfaceHover` | `#FF6B6B` | `#1B1E29` | 5.99:1 | PASS |
| `warning` | `background` | `#F5B84B` | `#0A0B10` | 11.08:1 | PASS |
| `warning` | `surface` | `#F5B84B` | `#151720` | 10.07:1 | PASS |
| `warning` | `surfaceRaised` | `#F5B84B` | `#1A1D27` | 9.48:1 | PASS |
| `warning` | `surfaceHover` | `#F5B84B` | `#1B1E29` | 9.36:1 | PASS |
| `info` | `background` | `#3B82F6` | `#0A0B10` | 5.34:1 | PASS |
| `info` | `surface` | `#3B82F6` | `#151720` | 4.86:1 | PASS |
| `info` | `surfaceRaised` | `#3B82F6` | `#1A1D27` | 4.57:1 | PASS |
| `info` | `surfaceHover` | `#3B82F6` | `#1B1E29` | 4.52:1 | PASS |
| `onAccent` | `accentPurple` | `#0A0B10` | `#8B7CFF` | 6.01:1 | PASS |
| `onAccent` | `accentBlue` | `#0A0B10` | `#3B82F6` | 5.34:1 | PASS |
| `onAccent` | `accentMint` | `#0A0B10` | `#5BE7D4` | 12.94:1 | PASS |
| `onAccent` | `success` | `#0A0B10` | `#5BE7D4` | 12.94:1 | PASS |
| `onAccent` | `danger` | `#0A0B10` | `#FF6B6B` | 7.08:1 | PASS |
| `onAccent` | `warning` | `#0A0B10` | `#F5B84B` | 11.08:1 | PASS |
| `onAccent` | `info` | `#0A0B10` | `#3B82F6` | 5.34:1 | PASS |
| `focusRing` | `background` | `#A99FFF` | `#0A0B10` | 8.51:1 | PASS |
| `focusRing` | `surface` | `#A99FFF` | `#151720` | 7.73:1 | PASS |
| `focusRing` | `surfaceRaised` | `#A99FFF` | `#1A1D27` | 7.28:1 | PASS |
| `focusRing` | `surfaceHover` | `#A99FFF` | `#1B1E29` | 7.19:1 | PASS |

Disabled text (informational, WCAG-exempt):

| Foreground | Background | Ratio | Result |
| --- | --- | --- | --- |
| `textDisabled` | `background` | 4.02:1 | EXEMPT |
| `textDisabled` | `surface` | 3.66:1 | EXEMPT |

## Light (`light`)

Required pairs: 47. Failures: 0.

| Foreground | Background | Foreground hex | Background hex | Ratio | Result |
| --- | --- | --- | --- | --- | --- |
| `textPrimary` | `background` | `#111318` | `#F7F8FB` | 17.50:1 | PASS |
| `textPrimary` | `surface` | `#111318` | `#FFFFFF` | 18.58:1 | PASS |
| `textPrimary` | `surfaceRaised` | `#111318` | `#FFFFFF` | 18.58:1 | PASS |
| `textPrimary` | `surfaceHover` | `#111318` | `#F0F2F8` | 16.60:1 | PASS |
| `textSecondary` | `background` | `#4B5260` | `#F7F8FB` | 7.39:1 | PASS |
| `textSecondary` | `surface` | `#4B5260` | `#FFFFFF` | 7.85:1 | PASS |
| `textSecondary` | `surfaceRaised` | `#4B5260` | `#FFFFFF` | 7.85:1 | PASS |
| `textSecondary` | `surfaceHover` | `#4B5260` | `#F0F2F8` | 7.01:1 | PASS |
| `accentPurple` | `background` | `#5B4BE0` | `#F7F8FB` | 5.61:1 | PASS |
| `accentPurple` | `surface` | `#5B4BE0` | `#FFFFFF` | 5.95:1 | PASS |
| `accentPurple` | `surfaceRaised` | `#5B4BE0` | `#FFFFFF` | 5.95:1 | PASS |
| `accentPurple` | `surfaceHover` | `#5B4BE0` | `#F0F2F8` | 5.32:1 | PASS |
| `accentBlue` | `background` | `#1D4ED8` | `#F7F8FB` | 6.31:1 | PASS |
| `accentBlue` | `surface` | `#1D4ED8` | `#FFFFFF` | 6.70:1 | PASS |
| `accentBlue` | `surfaceRaised` | `#1D4ED8` | `#FFFFFF` | 6.70:1 | PASS |
| `accentBlue` | `surfaceHover` | `#1D4ED8` | `#F0F2F8` | 5.99:1 | PASS |
| `accentMint` | `background` | `#067568` | `#F7F8FB` | 5.27:1 | PASS |
| `accentMint` | `surface` | `#067568` | `#FFFFFF` | 5.60:1 | PASS |
| `accentMint` | `surfaceRaised` | `#067568` | `#FFFFFF` | 5.60:1 | PASS |
| `accentMint` | `surfaceHover` | `#067568` | `#F0F2F8` | 5.00:1 | PASS |
| `success` | `background` | `#067568` | `#F7F8FB` | 5.27:1 | PASS |
| `success` | `surface` | `#067568` | `#FFFFFF` | 5.60:1 | PASS |
| `success` | `surfaceRaised` | `#067568` | `#FFFFFF` | 5.60:1 | PASS |
| `success` | `surfaceHover` | `#067568` | `#F0F2F8` | 5.00:1 | PASS |
| `danger` | `background` | `#B42318` | `#F7F8FB` | 6.19:1 | PASS |
| `danger` | `surface` | `#B42318` | `#FFFFFF` | 6.57:1 | PASS |
| `danger` | `surfaceRaised` | `#B42318` | `#FFFFFF` | 6.57:1 | PASS |
| `danger` | `surfaceHover` | `#B42318` | `#F0F2F8` | 5.87:1 | PASS |
| `warning` | `background` | `#8A5A00` | `#F7F8FB` | 5.58:1 | PASS |
| `warning` | `surface` | `#8A5A00` | `#FFFFFF` | 5.93:1 | PASS |
| `warning` | `surfaceRaised` | `#8A5A00` | `#FFFFFF` | 5.93:1 | PASS |
| `warning` | `surfaceHover` | `#8A5A00` | `#F0F2F8` | 5.30:1 | PASS |
| `info` | `background` | `#1D4ED8` | `#F7F8FB` | 6.31:1 | PASS |
| `info` | `surface` | `#1D4ED8` | `#FFFFFF` | 6.70:1 | PASS |
| `info` | `surfaceRaised` | `#1D4ED8` | `#FFFFFF` | 6.70:1 | PASS |
| `info` | `surfaceHover` | `#1D4ED8` | `#F0F2F8` | 5.99:1 | PASS |
| `onAccent` | `accentPurple` | `#FFFFFF` | `#5B4BE0` | 5.95:1 | PASS |
| `onAccent` | `accentBlue` | `#FFFFFF` | `#1D4ED8` | 6.70:1 | PASS |
| `onAccent` | `accentMint` | `#FFFFFF` | `#067568` | 5.60:1 | PASS |
| `onAccent` | `success` | `#FFFFFF` | `#067568` | 5.60:1 | PASS |
| `onAccent` | `danger` | `#FFFFFF` | `#B42318` | 6.57:1 | PASS |
| `onAccent` | `warning` | `#FFFFFF` | `#8A5A00` | 5.93:1 | PASS |
| `onAccent` | `info` | `#FFFFFF` | `#1D4ED8` | 6.70:1 | PASS |
| `focusRing` | `background` | `#4A3ACB` | `#F7F8FB` | 7.17:1 | PASS |
| `focusRing` | `surface` | `#4A3ACB` | `#FFFFFF` | 7.61:1 | PASS |
| `focusRing` | `surfaceRaised` | `#4A3ACB` | `#FFFFFF` | 7.61:1 | PASS |
| `focusRing` | `surfaceHover` | `#4A3ACB` | `#F0F2F8` | 6.80:1 | PASS |

Disabled text (informational, WCAG-exempt):

| Foreground | Background | Ratio | Result |
| --- | --- | --- | --- |
| `textDisabled` | `background` | 3.02:1 | EXEMPT |
| `textDisabled` | `surface` | 3.21:1 | EXEMPT |

## High contrast (`highContrast`)

Required pairs: 47. Failures: 0.

| Foreground | Background | Foreground hex | Background hex | Ratio | Result |
| --- | --- | --- | --- | --- | --- |
| `textPrimary` | `background` | `#FFFFFF` | `#000000` | 21.00:1 | PASS |
| `textPrimary` | `surface` | `#FFFFFF` | `#0A0A0A` | 19.80:1 | PASS |
| `textPrimary` | `surfaceRaised` | `#FFFFFF` | `#141414` | 18.42:1 | PASS |
| `textPrimary` | `surfaceHover` | `#FFFFFF` | `#1F1F1F` | 16.48:1 | PASS |
| `textSecondary` | `background` | `#D6D6D6` | `#000000` | 14.45:1 | PASS |
| `textSecondary` | `surface` | `#D6D6D6` | `#0A0A0A` | 13.62:1 | PASS |
| `textSecondary` | `surfaceRaised` | `#D6D6D6` | `#141414` | 12.68:1 | PASS |
| `textSecondary` | `surfaceHover` | `#D6D6D6` | `#1F1F1F` | 11.34:1 | PASS |
| `accentPurple` | `background` | `#C9BFFF` | `#000000` | 12.38:1 | PASS |
| `accentPurple` | `surface` | `#C9BFFF` | `#0A0A0A` | 11.67:1 | PASS |
| `accentPurple` | `surfaceRaised` | `#C9BFFF` | `#141414` | 10.86:1 | PASS |
| `accentPurple` | `surfaceHover` | `#C9BFFF` | `#1F1F1F` | 9.72:1 | PASS |
| `accentBlue` | `background` | `#8AB4FF` | `#000000` | 10.05:1 | PASS |
| `accentBlue` | `surface` | `#8AB4FF` | `#0A0A0A` | 9.48:1 | PASS |
| `accentBlue` | `surfaceRaised` | `#8AB4FF` | `#141414` | 8.82:1 | PASS |
| `accentBlue` | `surfaceHover` | `#8AB4FF` | `#1F1F1F` | 7.89:1 | PASS |
| `accentMint` | `background` | `#7CF5E4` | `#000000` | 16.04:1 | PASS |
| `accentMint` | `surface` | `#7CF5E4` | `#0A0A0A` | 15.12:1 | PASS |
| `accentMint` | `surfaceRaised` | `#7CF5E4` | `#141414` | 14.07:1 | PASS |
| `accentMint` | `surfaceHover` | `#7CF5E4` | `#1F1F1F` | 12.59:1 | PASS |
| `success` | `background` | `#7CF5E4` | `#000000` | 16.04:1 | PASS |
| `success` | `surface` | `#7CF5E4` | `#0A0A0A` | 15.12:1 | PASS |
| `success` | `surfaceRaised` | `#7CF5E4` | `#141414` | 14.07:1 | PASS |
| `success` | `surfaceHover` | `#7CF5E4` | `#1F1F1F` | 12.59:1 | PASS |
| `danger` | `background` | `#FF9B9B` | `#000000` | 10.41:1 | PASS |
| `danger` | `surface` | `#FF9B9B` | `#0A0A0A` | 9.82:1 | PASS |
| `danger` | `surfaceRaised` | `#FF9B9B` | `#141414` | 9.14:1 | PASS |
| `danger` | `surfaceHover` | `#FF9B9B` | `#1F1F1F` | 8.17:1 | PASS |
| `warning` | `background` | `#FFD166` | `#000000` | 14.56:1 | PASS |
| `warning` | `surface` | `#FFD166` | `#0A0A0A` | 13.73:1 | PASS |
| `warning` | `surfaceRaised` | `#FFD166` | `#141414` | 12.78:1 | PASS |
| `warning` | `surfaceHover` | `#FFD166` | `#1F1F1F` | 11.43:1 | PASS |
| `info` | `background` | `#8AB4FF` | `#000000` | 10.05:1 | PASS |
| `info` | `surface` | `#8AB4FF` | `#0A0A0A` | 9.48:1 | PASS |
| `info` | `surfaceRaised` | `#8AB4FF` | `#141414` | 8.82:1 | PASS |
| `info` | `surfaceHover` | `#8AB4FF` | `#1F1F1F` | 7.89:1 | PASS |
| `onAccent` | `accentPurple` | `#000000` | `#C9BFFF` | 12.38:1 | PASS |
| `onAccent` | `accentBlue` | `#000000` | `#8AB4FF` | 10.05:1 | PASS |
| `onAccent` | `accentMint` | `#000000` | `#7CF5E4` | 16.04:1 | PASS |
| `onAccent` | `success` | `#000000` | `#7CF5E4` | 16.04:1 | PASS |
| `onAccent` | `danger` | `#000000` | `#FF9B9B` | 10.41:1 | PASS |
| `onAccent` | `warning` | `#000000` | `#FFD166` | 14.56:1 | PASS |
| `onAccent` | `info` | `#000000` | `#8AB4FF` | 10.05:1 | PASS |
| `focusRing` | `background` | `#FFD166` | `#000000` | 14.56:1 | PASS |
| `focusRing` | `surface` | `#FFD166` | `#0A0A0A` | 13.73:1 | PASS |
| `focusRing` | `surfaceRaised` | `#FFD166` | `#141414` | 12.78:1 | PASS |
| `focusRing` | `surfaceHover` | `#FFD166` | `#1F1F1F` | 11.43:1 | PASS |

Disabled text (informational, WCAG-exempt):

| Foreground | Background | Ratio | Result |
| --- | --- | --- | --- |
| `textDisabled` | `background` | 8.33:1 | PASS |
| `textDisabled` | `surface` | 7.85:1 | PASS |

## Summary

All required text and focus-indicator pairs pass WCAG AA in all
three themes. See the tables above for measured ratios.
