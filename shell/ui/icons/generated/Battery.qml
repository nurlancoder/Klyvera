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
            PathSvg { path: "M 3 6 H 17 A 2 2 0 0 1 19 8 V 16 A 2 2 0 0 1 17 18 H 3 A 2 2 0 0 1 1 16 V 8 A 2 2 0 0 1 3 6 Z" }
        }
        ShapePath {
            strokeColor: root.color
            fillColor: "transparent"
            strokeWidth: Theme.icon.strokeWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M 23 13 L 23 11" }
        }
    }
}
