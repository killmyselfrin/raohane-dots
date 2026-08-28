import QtQuick
import QtQuick.Shapes

Item {
    id: root

    enum Corner { TopLeft, TopRight, BottomLeft, BottomRight }

    property int corner: RaohaneRoundCorner.Corner.TopLeft
    property int implicitSize: 22
    property color color: "#000000"

    readonly property bool isTopLeft: corner === RaohaneRoundCorner.Corner.TopLeft
    readonly property bool isTopRight: corner === RaohaneRoundCorner.Corner.TopRight
    readonly property bool isBottomLeft: corner === RaohaneRoundCorner.Corner.BottomLeft
    readonly property bool isBottomRight: corner === RaohaneRoundCorner.Corner.BottomRight
    readonly property bool isTop: isTopLeft || isTopRight
    readonly property bool isBottom: isBottomLeft || isBottomRight
    readonly property bool isLeft: isTopLeft || isBottomLeft
    readonly property bool isRight: isTopRight || isBottomRight

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Shape {
        id: shape

        width: root.implicitSize
        height: root.implicitSize
        anchors {
            top: root.isTop ? parent.top : undefined
            bottom: root.isBottom ? parent.bottom : undefined
            left: root.isLeft ? parent.left : undefined
            right: root.isRight ? parent.right : undefined
        }
        layer.enabled: true
        layer.smooth: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: path
            strokeWidth: 0
            fillColor: root.color
            pathHints: ShapePath.PathSolid | ShapePath.PathNonIntersecting

            startX: root.isLeft ? 0 : root.implicitSize
            startY: root.isTop ? 0 : root.implicitSize

            PathAngleArc {
                moveToStart: false
                centerX: root.implicitSize - path.startX
                centerY: root.implicitSize - path.startY
                radiusX: root.implicitSize
                radiusY: root.implicitSize
                startAngle: {
                    if (root.isTopLeft)
                        return 180
                    if (root.isTopRight)
                        return -90
                    if (root.isBottomLeft)
                        return 90
                    return 0
                }
                sweepAngle: 90
            }

            PathLine {
                x: path.startX
                y: path.startY
            }
        }
    }
}
