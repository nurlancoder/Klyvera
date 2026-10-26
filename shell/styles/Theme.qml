pragma Singleton
import QtQuick

QtObject {
    readonly property string productName: "klyvera"
    readonly property string tokenVersion: "2"
    readonly property var availableThemes: ["dark","light","high-contrast"]

    property string themeName: "dark"
    property real scale: 1.0
    property bool reduceMotion: false

    readonly property var palettes: ({
        "dark": {
            "background": "#07080D",
            "surface": "#10121A",
            "surfaceRaised": "#161926",
            "surfaceHover": "#1C2031",
            "surfaceActive": "#242A3E",
            "surfaceSunken": "#0B0C12",
            "overlay": "#07080D",
            "textPrimary": "#F4F6FB",
            "textSecondary": "#B9C0D6",
            "textDisabled": "#7C849C",
            "accentPurple": "#9B8BFF",
            "accentBlue": "#4FC3F7",
            "accentMint": "#4DFFCC",
            "success": "#4DFFCC",
            "danger": "#FF7B95",
            "warning": "#FFC857",
            "info": "#7CC4FF",
            "onAccent": "#05050A",
            "borderSubtle": "#14FFFFFF",
            "borderStrong": "#29FFFFFF",
            "focusRing": "#B9A6FF",
            "selection": "#669B8BFF",
            "shadow": "#8C000000"
        },
        "light": {
            "background": "#F6F7FB",
            "surface": "#FFFFFF",
            "surfaceRaised": "#FFFFFF",
            "surfaceHover": "#F1F3FA",
            "surfaceActive": "#E7EAF6",
            "surfaceSunken": "#ECEEF6",
            "overlay": "#F6F7FB",
            "textPrimary": "#0F1220",
            "textSecondary": "#2F354A",
            "textDisabled": "#6B728E",
            "accentPurple": "#5B3FE0",
            "accentBlue": "#005FB8",
            "accentMint": "#006B5C",
            "success": "#006B5C",
            "danger": "#B4233D",
            "warning": "#92400E",
            "info": "#1D4ED8",
            "onAccent": "#FFFFFF",
            "borderSubtle": "#0F0F1220",
            "borderStrong": "#290F1220",
            "focusRing": "#5B3FE0",
            "selection": "#405B3FE0",
            "shadow": "#2E0F1220"
        },
        "high-contrast": {
            "background": "#000000",
            "surface": "#000000",
            "surfaceRaised": "#000000",
            "surfaceHover": "#101010",
            "surfaceActive": "#1A1A1A",
            "surfaceSunken": "#000000",
            "overlay": "#000000",
            "textPrimary": "#FFFFFF",
            "textSecondary": "#FFFFFF",
            "textDisabled": "#BFBFBF",
            "accentPurple": "#D7CCFF",
            "accentBlue": "#9DDEFF",
            "accentMint": "#9DFFEC",
            "success": "#9DFFEC",
            "danger": "#FFB3C6",
            "warning": "#FFE0A3",
            "info": "#C9E6FF",
            "onAccent": "#000000",
            "borderSubtle": "#FFFFFF",
            "borderStrong": "#FFFFFF",
            "focusRing": "#FFFFFF",
            "selection": "#66D7CCFF",
            "shadow": "#1FFFFFFF"
        }
    })
    readonly property var palette: palettes[themeName] ? palettes[themeName] : palettes["dark"]

    readonly property color background: palette["background"]
    readonly property color surface: palette["surface"]
    readonly property color surfaceRaised: palette["surfaceRaised"]
    readonly property color surfaceHover: palette["surfaceHover"]
    readonly property color surfaceActive: palette["surfaceActive"]
    readonly property color surfaceSunken: palette["surfaceSunken"]
    readonly property color overlay: palette["overlay"]
    readonly property color textPrimary: palette["textPrimary"]
    readonly property color textSecondary: palette["textSecondary"]
    readonly property color textDisabled: palette["textDisabled"]
    readonly property color accentPurple: palette["accentPurple"]
    readonly property color accentBlue: palette["accentBlue"]
    readonly property color accentMint: palette["accentMint"]
    readonly property color success: palette["success"]
    readonly property color danger: palette["danger"]
    readonly property color warning: palette["warning"]
    readonly property color info: palette["info"]
    readonly property color onAccent: palette["onAccent"]
    readonly property color borderSubtle: palette["borderSubtle"]
    readonly property color borderStrong: palette["borderStrong"]
    readonly property color focusRing: palette["focusRing"]
    readonly property color selection: palette["selection"]
    readonly property color shadow: palette["shadow"]

    readonly property QtObject spacing: QtObject {
        readonly property int base: 4
        readonly property int xxs: 2
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 20
        readonly property int size2xl: 24
        readonly property int xxl: 24
        readonly property int size3xl: 32
        readonly property int size4xl: 40
        readonly property int size5xl: 48
        readonly property int size6xl: 64
        readonly property int xxxl: 80
        readonly property int huge: 96
    }
    readonly property QtObject radius: QtObject {
        readonly property int xs: 6
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 20
        readonly property int pill: 9999
    }
    readonly property QtObject borders: QtObject {
        readonly property int hairline: 1
        readonly property int thick: 2
        readonly property int focus: 3
        readonly property int strong: 2
    }
    readonly property QtObject typography: QtObject {
        readonly property string fontHeading: "Manrope"
        readonly property string fontBody: "Inter"
        readonly property string fontMono: "JetBrains Mono"
        readonly property string uiFamily: "Inter"
        readonly property string headingFamily: "Manrope"
        readonly property string monoFamily: "JetBrains Mono"
        readonly property QtObject scale: QtObject {
            readonly property int xs: 11
            readonly property int sm: 12
            readonly property int base: 14
            readonly property int md: 15
            readonly property int lg: 16
            readonly property int xl: 18
            readonly property int size2xl: 20
            readonly property int size3xl: 24
            readonly property int size4xl: 28
            readonly property int size5xl: 32
            readonly property int size6xl: 40
            readonly property int display: 48
            readonly property int heading1: 36
            readonly property int heading3: 24
            readonly property int bodyStrong: 15
            readonly property int caption: 12
            readonly property int label: 14
            readonly property int title: 18
            readonly property int body: 14
        }
        readonly property QtObject weight: QtObject {
            readonly property int regular: 400
            readonly property int medium: 500
            readonly property int semibold: 600
            readonly property int bold: 700
            readonly property int extrabold: 800
            readonly property int label: 500
            readonly property int title: 600
            readonly property int caption: 400
        }
        readonly property QtObject lineHeight: QtObject {
            readonly property real tight: 1.1
            readonly property real snug: 1.2
            readonly property real normal: 1.5
            readonly property real relaxed: 1.7
            readonly property real body: 1.5
            readonly property real caption: 1.4
        }
        readonly property QtObject tracking: QtObject {
            readonly property string tight: "-0.02em"
            readonly property string normal: "0em"
            readonly property string wide: "0.02em"
            readonly property string letterSpacing: "0em"
        }
        readonly property QtObject body: QtObject {
            readonly property int size: 14
            readonly property real lineHeight: 1.5
        }
        readonly property QtObject caption: QtObject {
            readonly property int size: 12
            readonly property int weight: 400
            readonly property real lineHeight: 1.4
        }
        readonly property QtObject display: QtObject {
            readonly property int size: 48
            readonly property int weight: 700
            readonly property string letterSpacing: "-0.02em"
        }
        readonly property QtObject heading1: QtObject {
            readonly property int size: 36
            readonly property int weight: 700
            readonly property string letterSpacing: "-0.02em"
        }
        readonly property QtObject heading2: QtObject {
            readonly property int size: 20
            readonly property int weight: 600
        }
        readonly property QtObject heading3: QtObject {
            readonly property int size: 24
            readonly property int weight: 600
        }
        readonly property QtObject label: QtObject {
            readonly property int size: 14
            readonly property int weight: 500
        }
        readonly property QtObject title: QtObject {
            readonly property int size: 18
            readonly property int weight: 600
        }
        readonly property QtObject bodyStrong: QtObject {
            readonly property int size: 15
            readonly property int weight: 500
        }
        readonly property int weightSemibold: 600
        readonly property int weightMedium: 500
        readonly property int weightBold: 700
    }
    readonly property QtObject motion: QtObject {
        readonly property QtObject duration: QtObject {
            readonly property int fast: 120
            readonly property int base: 200
            readonly property int slow: 320
            readonly property int normal: 200
            readonly property int durationFast: 120
            readonly property int durationNormal: 200
            readonly property int durationSlow: 320
        }
        readonly property QtObject easing: QtObject {
            readonly property string standard: "cubic-bezier(0.25,0.8,0.25,1)"
            readonly property string emphasized: "cubic-bezier(0.2,0.8,0.2,1)"
            readonly property string spring: "cubic-bezier(0.16,1,0.3,1)"
        }
        readonly property bool reduceMotion: true
        readonly property int durationFast: 120
        readonly property int durationNormal: 200
        readonly property int durationSlow: 320
    }
    readonly property QtObject icon: QtObject {
        readonly property int xs: 16
        readonly property int sm: 18
        readonly property int md: 20
        readonly property int lg: 22
        readonly property int xl: 24
        readonly property int size2xl: 28
        readonly property QtObject sizes: QtObject {
            readonly property int sm: 18
            readonly property int md: 20
            readonly property int lg: 22
        }
        readonly property real stroke: 1.75
        readonly property real strokeWidth: 1.75
    }
    readonly property QtObject layout: QtObject {
        readonly property int touchTarget: 40
        readonly property QtObject panel: QtObject {
            readonly property int height: 44
            readonly property int iconSpacing: 8
            readonly property int gap: 8
            readonly property int iconButtonSize: 32
            readonly property int padding: 8
        }
        readonly property QtObject spaces: QtObject {
            readonly property int sidebarWidth: 280
            readonly property int cardMinWidth: 320
            readonly property int wizardMaxWidth: 600
            readonly property int gridGap: 16
        }
        readonly property QtObject launcher: QtObject {
            readonly property int widthCompact: 600
            readonly property int widthRegular: 800
            readonly property int widthWide: 1000
            readonly property int widthUltrawide: 1200
            readonly property int height: 500
            readonly property int gutter: 16
            readonly property real maxHeightRatio: 0.85
            readonly property real maxHeightRatioValue: 0.85
        }
        readonly property QtObject controlCenter: QtObject {
            readonly property int widthRegular: 360
            readonly property int widthWide: 400
        }
        readonly property QtObject classes: QtObject {
            readonly property QtObject compact: QtObject {
                readonly property int maxWidth: 1279
                readonly property int gutter: 16
                readonly property int panelHeight: 40
            }
            readonly property QtObject regular: QtObject {
                readonly property int minWidth: 1280
                readonly property int maxWidth: 1919
                readonly property int gutter: 20
                readonly property int panelHeight: 44
            }
            readonly property QtObject wide: QtObject {
                readonly property int minWidth: 1920
                readonly property int maxWidth: 2559
                readonly property int gutter: 24
                readonly property int panelHeight: 48
            }
            readonly property QtObject ultrawide: QtObject {
                readonly property int minWidth: 2560
                readonly property int gutter: 32
                readonly property int panelHeight: 52
            }
        }
    }
    readonly property QtObject accessibility: QtObject {
        readonly property real minContrast: 4.5
        readonly property real minContrastLarge: 3.0
        readonly property real focusWidth: 2
        readonly property real focusRingOffset: 2
        readonly property real minimumTargetSize: 40
        readonly property real preferredTargetSize: 40
    }

    function scaled(value) { return Math.round(value * scale) }
    function scaledInt(value) { return Math.round(value * scale) }
    function motionDuration(ms) { return reduceMotion ? 0 : ms; }
    function layoutClass(width) { if (width < 1280) return 'compact'; if (width < 1920) return 'regular'; if (width < 2560) return 'wide'; return 'ultrawide'; }
}
