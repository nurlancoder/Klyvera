import QtQuick
import QtQuick.Shapes
import "../../../styles"

Item {
    id: root

    property color color: Theme.textPrimary
    implicitWidth: 24
    implicitHeight: 24

    Shape {
        width: 24
        height: 24
        transform: Scale {
            origin.x: 0
            origin.y: 0
            xScale: root.width / 24
            yScale: root.height / 24
        }
        ShapePath {
            strokeColor: root.color
            fillColor: "transparent"
            strokeWidth: Theme.icon.strokeWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M 4 17 L 10 11 L 4 5" }
        }
        ShapePath {
            strokeColor: root.color
            fillColor: "transparent"
            strokeWidth: Theme.icon.strokeWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M 12 19 L 20 19" }
        }
    }
}
