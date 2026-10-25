import QtQuick
import "../styles"

Item {
    id: root

    property string name: ""
    property color color: Theme.textPrimary
    property real level: 1.0
    property real size: Theme.scaled(Theme.icon.sizes.md)

    implicitWidth: size
    implicitHeight: size
    Accessible.ignored: true

    onColorChanged: canvas.requestPaint()
    onLevelChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    onSizeChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            const scale = width / 24
            ctx.save()
            ctx.scale(scale, scale)
            ctx.strokeStyle = root.color
            ctx.fillStyle = root.color
            ctx.lineWidth = Theme.icon.strokeWidth
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            function line(x1, y1, x2, y2) {
                ctx.beginPath()
                ctx.moveTo(x1, y1)
                ctx.lineTo(x2, y2)
                ctx.stroke()
            }

            switch (root.name) {
            case "search":
                ctx.beginPath()
                ctx.arc(10.5, 10.5, 6.5, 0, Math.PI * 2)
                ctx.stroke()
                line(15.2, 15.2, 20, 20)
                break
            case "close":
                line(6, 6, 18, 18)
                line(18, 6, 6, 18)
                break
            case "check":
                ctx.beginPath()
                ctx.moveTo(4, 12.5)
                ctx.lineTo(9.5, 18)
                ctx.lineTo(20, 6.5)
                ctx.stroke()
                break
            case "chevron-down":
                ctx.beginPath()
                ctx.moveTo(6, 9)
                ctx.lineTo(12, 15)
                ctx.lineTo(18, 9)
                ctx.stroke()
                break
            case "chevron-up":
                ctx.beginPath()
                ctx.moveTo(6, 15)
                ctx.lineTo(12, 9)
                ctx.lineTo(18, 15)
                ctx.stroke()
                break
            case "chevron-left":
                ctx.beginPath()
                ctx.moveTo(15, 6)
                ctx.lineTo(9, 12)
                ctx.lineTo(15, 18)
                ctx.stroke()
                break
            case "chevron-right":
                ctx.beginPath()
                ctx.moveTo(9, 6)
                ctx.lineTo(15, 12)
                ctx.lineTo(9, 18)
                ctx.stroke()
                break
            case "arrow-right":
                line(4, 12, 20, 12)
                ctx.beginPath()
                ctx.moveTo(14, 6)
                ctx.lineTo(20, 12)
                ctx.lineTo(14, 18)
                ctx.stroke()
                break
            case "plus":
                line(12, 5, 12, 19)
                line(5, 12, 19, 12)
                break
            case "minus":
                line(5, 12, 19, 12)
                break
            case "warning":
                ctx.beginPath()
                ctx.moveTo(12, 3.5)
                ctx.lineTo(21, 20)
                ctx.lineTo(3, 20)
                ctx.closePath()
                ctx.stroke()
                line(12, 9, 12, 14)
                ctx.beginPath()
                ctx.arc(12, 17.2, 0.9, 0, Math.PI * 2)
                ctx.fill()
                break
            case "info":
                ctx.beginPath()
                ctx.arc(12, 12, 8.5, 0, Math.PI * 2)
                ctx.stroke()
                line(12, 11, 12, 16.5)
                ctx.beginPath()
                ctx.arc(12, 7.8, 0.9, 0, Math.PI * 2)
                ctx.fill()
                break
            case "wifi":
                ctx.beginPath()
                ctx.arc(12, 18, 9, Math.PI * 1.25, Math.PI * 1.75)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(12, 18, 5.5, Math.PI * 1.25, Math.PI * 1.75)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(12, 18, 1.2, 0, Math.PI * 2)
                ctx.fill()
                break
            case "volume":
            case "volume-off":
                ctx.beginPath()
                ctx.moveTo(4, 9)
                ctx.lineTo(8, 9)
                ctx.lineTo(13, 5)
                ctx.lineTo(13, 19)
                ctx.lineTo(8, 15)
                ctx.lineTo(4, 15)
                ctx.closePath()
                ctx.stroke()
                if (root.name === "volume") {
                    ctx.beginPath()
                    ctx.arc(14, 12, 4, -Math.PI / 3, Math.PI / 3)
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.arc(14, 12, 7, -Math.PI / 3, Math.PI / 3)
                    ctx.stroke()
                } else {
                    line(16, 9, 21, 15)
                    line(21, 9, 16, 15)
                }
                break
            case "battery":
                ctx.beginPath()
                ctx.rect(2.5, 7, 17, 10)
                ctx.stroke()
                ctx.beginPath()
                ctx.rect(20.5, 10, 1.8, 4)
                ctx.fill()
                const fillWidth = Math.max(0, Math.min(1, root.level)) * 13
                if (fillWidth > 0) {
                    ctx.beginPath()
                    ctx.rect(4.5, 9, fillWidth, 6)
                    ctx.fill()
                }
                break
            case "sun":
                ctx.beginPath()
                ctx.arc(12, 12, 4, 0, Math.PI * 2)
                ctx.stroke()
                for (let i = 0; i < 8; i++) {
                    const angle = i * Math.PI / 4
                    ctx.beginPath()
                    ctx.moveTo(12 + Math.cos(angle) * 7, 12 + Math.sin(angle) * 7)
                    ctx.lineTo(12 + Math.cos(angle) * 9.2, 12 + Math.sin(angle) * 9.2)
                    ctx.stroke()
                }
                break
            case "moon":
                ctx.beginPath()
                ctx.arc(12, 12, 8, Math.PI * 0.35, Math.PI * 1.55)
                ctx.arc(15, 10, 7, Math.PI * 1.35, Math.PI * 0.45, true)
                ctx.stroke()
                break
            case "folder":
                ctx.beginPath()
                ctx.moveTo(3, 7)
                ctx.lineTo(9, 7)
                ctx.lineTo(11, 9.5)
                ctx.lineTo(21, 9.5)
                ctx.lineTo(21, 19)
                ctx.lineTo(3, 19)
                ctx.closePath()
                ctx.stroke()
                break
            case "trash":
                line(4, 7, 20, 7)
                line(9, 4, 15, 4)
                ctx.beginPath()
                ctx.moveTo(6, 7)
                ctx.lineTo(7, 20)
                ctx.lineTo(17, 20)
                ctx.lineTo(18, 7)
                ctx.stroke()
                line(10, 11, 10, 16)
                line(14, 11, 14, 16)
                break
            case "refresh":
                ctx.beginPath()
                ctx.arc(12, 12, 7.5, Math.PI * 0.2, Math.PI * 1.75)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(17.5, 4.5)
                ctx.lineTo(19.5, 8.5)
                ctx.lineTo(15.2, 8.8)
                ctx.stroke()
                break
            case "power":
                line(12, 3, 12, 11)
                ctx.beginPath()
                ctx.arc(12, 12.5, 7.5, Math.PI * 1.25, Math.PI * 1.75)
                ctx.stroke()
                break
            case "terminal":
                ctx.beginPath()
                ctx.rect(3, 4.5, 18, 15)
                ctx.stroke()
                line(7, 9.5, 10, 12)
                line(10, 12, 7, 14.5)
                line(12.5, 15, 17, 15)
                break
            case "code":
                line(8, 7, 3, 12)
                line(3, 12, 8, 17)
                line(16, 7, 21, 12)
                line(21, 12, 16, 17)
                line(14, 4, 10, 20)
                break
            case "grid":
                ctx.beginPath()
                ctx.rect(4, 4, 6, 6)
                ctx.rect(14, 4, 6, 6)
                ctx.rect(4, 14, 6, 6)
                ctx.rect(14, 14, 6, 6)
                ctx.stroke()
                break
            case "sliders":
                line(4, 7, 20, 7)
                line(4, 12, 20, 12)
                line(4, 17, 20, 17)
                ctx.beginPath()
                ctx.arc(9, 7, 2, 0, Math.PI * 2)
                ctx.arc(15, 12, 2, 0, Math.PI * 2)
                ctx.arc(7, 17, 2, 0, Math.PI * 2)
                ctx.fill()
                break
            case "bell":
                ctx.beginPath()
                ctx.moveTo(5, 17)
                ctx.lineTo(7, 14)
                ctx.lineTo(7, 10)
                ctx.arc(12, 10, 5, Math.PI, 0)
                ctx.lineTo(17, 14)
                ctx.lineTo(19, 17)
                ctx.closePath()
                ctx.stroke()
                line(10, 20, 14, 20)
                break
            case "clock":
                ctx.beginPath()
                ctx.arc(12, 12, 8.5, 0, Math.PI * 2)
                ctx.stroke()
                line(12, 7, 12, 12)
                line(12, 12, 15.5, 14)
                break
            default:
                ctx.beginPath()
                ctx.arc(12, 12, 8.5, 0, Math.PI * 2)
                ctx.stroke()
                break
            }

            ctx.restore()
        }
    }
}
