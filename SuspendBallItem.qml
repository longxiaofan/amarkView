import QtQuick 2.0
import QtGraphicalEffects 1.0

Rectangle {
    id: suspendBall

    property int status: 0; // 0:初始化状态(不停靠)，1:停靠(显示半个圆球)，2:展开(显示一圈功能项)

    // 区分单击和双击事件
    property bool bMousePress: false

    // 点击时的起始位置
    property int pressX: 0
    property int pressY: 0

    width: (2 == status) ? 140 : 50; height: width; radius: 25;

    border.color: "#0000CD"         // 边框颜色
    border.width: 1                 // 边框粗细
    color: "#00000000"              // 背景透明

    // 背景图片
    Image {
        height: parent.height-1; width: height
        anchors.centerIn: parent

        fillMode: Image.Stretch
        source: "resource/backgroundcenter.png"
    }

    // 添加阴影
    layer.enabled: true
    layer.effect: DropShadow {
        transparentBorder: true
        horizontalOffset: 5
        verticalOffset: 5
        radius: 8.0
        samples: 16
        color: "#44000000"
    }

    // 鼠标事件
    MouseArea
    {
        anchors.fill: parent
        onPressed: {
            suspendBall.bMousePress = true;
            suspendBall.pressX = mouseX;
            suspendBall.pressY = mouseY;
        }
        onPositionChanged: {
            if ( suspendBall.bMousePress ) {
                var resizeX = suspendBall.x;
                var resizeY = suspendBall.y;

                // 计算偏移量
                resizeX += mouseX-suspendBall.pressX
                resizeY += mouseY-suspendBall.pressY

                // 限定左上角
                resizeX = (resizeX < 0) ? 0 : resizeX;
                resizeY = (resizeY < 0) ? 0 : resizeY;

                // 限定右下角
                resizeX = (resizeX > suspendBall.parent.width-suspendBall.width) ? suspendBall.parent.width-suspendBall.width : resizeX;
                resizeY = (resizeY > suspendBall.parent.height-suspendBall.height) ? suspendBall.parent.height-suspendBall.height : resizeY;

                // 单机直接修改尺寸
                suspendBall.x = resizeX;
                suspendBall.y = resizeY;
            }
        }
        onReleased: {
            suspendBall.bMousePress = false;

            // 判断是否需要隐藏
            var bAnimationH = false;
            if (0 == suspendBall.x) {
                bAnimationH = true;
                lAnimation.start();
            }
            if ((suspendBall.parent.width-suspendBall.width) == suspendBall.x) {
                bAnimationH = true;
                rAnimation.start();
            }

            if ( !bAnimationH ) {
                if (0 == suspendBall.y) {
                    tAnimation.start();
                }
                if ((suspendBall.parent.height-suspendBall.height) == suspendBall.y) {
                    bAnimation.start();
                }
            }
        }
        onDoubleClicked: {
            // 根据状态判断是否要变身
        }
    }

    // animation
    NumberAnimation { id: lAnimation; target: suspendBall; property: "x"; to: -25; duration: 200}
    NumberAnimation { id: rAnimation; target: suspendBall; property: "x"; to: suspendBall.parent.width-25; duration: 200}
    NumberAnimation { id: tAnimation; target: suspendBall; property: "y"; to: -25; duration: 200}
    NumberAnimation { id: bAnimation; target: suspendBall; property: "y"; to: suspendBall.parent.height-25; duration: 200}
}
