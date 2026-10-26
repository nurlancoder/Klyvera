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
            PathSvg { path: "M 3 3 H 10 V 10 H 3 Z" }
        }
        ShapePath {
            strokeColor: root.color
            fillColor: "transparent"
            strokeWidth: Theme.icon.strokeWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M 14 3 H 21 V 10 H 14 Z" }
        }
        ShapePath {
            strokeColor: root.color
            fillColor: "transparent"
            strokeWidth: Theme.icon.strokeWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M 14 14 H 21 V 21 H 14 Z" }
        }
        ShapePath {
            strokeColor: root.color
            fillColor: "transparent"
            strokeWidth: Theme.icon.strokeWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M 3 14 H 10 V 21 H 3 Z" }
        }
    }
}
