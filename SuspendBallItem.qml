import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Window 2.2
import QtGraphicalEffects 1.0

Rectangle {
    id: suspendBall

    property int status: 0; // 0:初始化状态(不停靠)，1:停靠(显示半个圆球)，2:展开(显示一圈功能项)

    // 区分单击和双击事件
    property bool bMousePress: false

    // 点击时的起始位置
    property int pressX: 0
    property int pressY: 0

    // 展开后显示六边形，面积覆盖7个圆球，圆球半径30
    property double expendW: 180;
    property double expendH: 120;

    width: 60; height: width; radius: 30;

    border.color: "#0000CD"         // 边框颜色
    border.width: 0                 // 边框粗细
    color: "#00000000"              // 背景透明

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

    // 中间的主功能球
    Rectangle {
        id: mainBall
        width: 60; height: width; radius: 30; z: 2; // zvalue保证主功能球始终在上面
        anchors.centerIn: parent
        color: "#00000000"              // 背景透明

        // 背景图片
        Image {
            height: parent.height; width: height
            anchors.centerIn: parent

            fillMode: Image.Stretch
            source: "resource/ballmain.png"
        }

        Rectangle {
            id: mainBallLayer
            anchors.fill: parent
            radius: 30
            color: "#00000000"              // 背景透明
        }

        // 鼠标事件
        MouseArea
        {
            anchors.fill: parent
            onPressed: {
                suspendBall.bMousePress = true;
                suspendBall.pressX = mouseX;
                suspendBall.pressY = mouseY;

                mainBallLayer.color = "#22000000"
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
                mainBallLayer.color = "#00000000"
                // 只有初始状态可以隐藏
                if (suspendBall.status == 0 && suspendBall.bMousePress && !expandAnimation.running && !reduceAnimation.running) {
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

                suspendBall.bMousePress = false;
            }
            onDoubleClicked: {
                // 根据状态判断是否要变身
                if (suspendBall.status == 0 && !lAnimation.running && !rAnimation.running && !tAnimation.running && !bAnimation.running) {
                    // 计算占用的面积
                    var pl = suspendBall.x+(suspendBall.width/2)-(suspendBall.expendW/2);
                    var pr = suspendBall.x+(suspendBall.width/2)+(suspendBall.expendW/2);
                    var pt = suspendBall.y+(suspendBall.height/2)-(suspendBall.expendW/2);
                    var pb = suspendBall.y+(suspendBall.height/2)+(suspendBall.expendW/2);

                    // 位置纠错，不要超过边线
                    pl = (pl < 0) ? 0 : pl;
                    pt = (pt < 0) ? 0 : pt;
                    pl = (pr > suspendBall.parent.width) ? (suspendBall.parent.width-suspendBall.expendW) : pl;
                    pt = (pb > suspendBall.parent.height) ? (suspendBall.parent.height-suspendBall.expendW) : pt;

                    // 移动位置，修改尺寸
                    suspendBall.x = pl;
                    suspendBall.y = pt;
                    suspendBall.width = suspendBall.expendW;
                    suspendBall.height = suspendBall.expendW;

                    // 动画展开
                    expandAnimation.start();
                } else {
                    reduceAnimation.start();
                }
            }
        }
    }

    Rectangle {
        id: signalBall
        opacity: 0.0; z: 1;
        width: 60; height: width; radius: 30;
        color: "#00000000"              // 背景透明
        enabled: (mainWindow.pageIndex == 1)

        // 背景图片
        Image {
            height: parent.height-10; width: height
            anchors.centerIn: parent

            fillMode: Image.Stretch
            source: "resource/ballsignal.png"
        }

        Rectangle {
            id: signalBallLayer
            height: parent.height-10; width: height
            anchors.centerIn: parent
            radius: 30
            color: "#00000000";
        }

        MouseArea {
            anchors.fill: parent
            onPressed: {
                signalBallLayer.color = "#44000000"
            }
            onReleased: {
                signalBallLayer.color = "#00000000"
                operatePage.setSignalToolBarVisible();

                if (operatePage.bSignalViewShow)
                    signalBallLayer.color = "#44000000"
                else
                    signalBallLayer.color = "#00000000"
            }
        }
    }

    Rectangle {
        id: sceneBall
        opacity: 0.0; z: 1;
        width: 60; height: width; radius: 30;
        color: "#00000000"              // 背景透明
        enabled: (mainWindow.pageIndex == 1)

        // 背景图片
        Image {
            height: parent.height-10; width: height
            anchors.centerIn: parent

            fillMode: Image.Stretch
            source: "resource/ballscene.png"
        }

        Rectangle {
            id: sceneBallLayer
            height: parent.height-10; width: height
            anchors.centerIn: parent
            radius: 30
            color: "#00000000";
        }

        MouseArea {
            anchors.fill: parent
            onPressed: {
                sceneBallLayer.color = "#44000000"
            }
            onReleased: {
                sceneBallLayer.color = "#00000000"
                operatePage.setSceneToolBarVisible();
                if (operatePage.bSceneViewShow)
                    sceneBallLayer.color = "#44000000"
                else
                    sceneBallLayer.color = "#00000000"
            }
        }
    }

    Rectangle {
        id: echoBall
        opacity: 0.0; z: 1;
        width: 60; height: width; radius: 30;
        color: "#00000000"              // 背景透明
        enabled: (mainWindow.pageIndex == 1)

        // 背景图片
        Image {
            height: parent.height-10; width: height
            anchors.centerIn: parent

            fillMode: Image.Stretch
            source: "resource/ballecho.png"
        }

        Rectangle {
            id: echoBallLayer
            height: parent.height-10; width: height
            anchors.centerIn: parent
            radius: 30
            color: "#00000000";
        }

        MouseArea {
            anchors.fill: parent
            onPressed: {
                echoBallLayer.color = "#44000000"
            }
            onReleased: {
                echoBallLayer.color = "#00000000"
                operatePage.setEchoVisible();
                if (operatePage.bPreview)
                    echoBallLayer.color = "#44000000"
                else
                    echoBallLayer.color = "#00000000"
            }
        }
    }

    Rectangle {
        id: priviewBall
        opacity: 0.0; z: 1;
        width: 60; height: width; radius: 30;
        color: "#00000000"              // 背景透明
        enabled: (mainWindow.pageIndex == 1)

        // 背景图片
        Image {
            height: parent.height-10; width: height
            anchors.centerIn: parent

            fillMode: Image.Stretch
            source: "resource/ballpreview.png"
        }

        Rectangle {
            id: priviewBallLayer
            height: parent.height-10; width: height
            anchors.centerIn: parent
            radius: 30
            color: "#00000000";
        }

        MouseArea {
            anchors.fill: parent
            onPressed: {
                priviewBallLayer.color = "#44000000"
            }
            onReleased: {
                priviewBallLayer.color = "#00000000"
                operatePage.setPreviewVisible();
                if (operatePage.bPreviewShow)
                    priviewBallLayer.color = "#44000000"
                else
                    priviewBallLayer.color = "#00000000"
            }
        }
    }

    Rectangle {
        id: clearBall
        opacity: 0.0; z: 1;
        width: 60; height: width; radius: 30;
        color: "#00000000"              // 背景透明
        enabled: (mainWindow.pageIndex == 1)

        // 背景图片
        Image {
            height: parent.height-10; width: height
            anchors.centerIn: parent

            fillMode: Image.Stretch
            source: "resource/ballclear.png"
        }

        Rectangle {
            id: clearBallLayer
            height: parent.height-10; width: height
            anchors.centerIn: parent
            radius: 30
            color: "#00000000"              // 背景透明
        }

        MouseArea {
            anchors.fill: parent
            onPressed: {
                clearBallLayer.color = "#22000000"
                operatePage.resetGroupDislay();
            }
            onReleased: {
                clearBallLayer.color = "#00000000"
            }
        }
    }

    Rectangle {
        id: quitBall
        opacity: 0.0; z: 1;
        width: 60; height: width; radius: 30;
        color: "#00000000"              // 背景透明

        // 背景图片
        Image {
            height: parent.height-10; width: height
            anchors.centerIn: parent

            fillMode: Image.Stretch
            source: "resource/ballquit.png";
        }

        Rectangle {
            id: quitBallLayer
            height: parent.height-10; width: height
            anchors.centerIn: parent
            radius: 30
            color: "#00000000"              // 背景透明
        }

        MouseArea {
            anchors.fill: parent
            onPressed: {
                quitBallLayer.color = "#22000000"
                Qt.quit();
            }
            onReleased: {
                quitBallLayer.color = "#00000000"
            }
        }
    }

    ParallelAnimation {     // 展开
        id: expandAnimation;

        // 信号源
        NumberAnimation { target: signalBall; property: "x"; from: mainBall.x; to: mainBall.x+30-suspendBall.expendH/2; duration: 200}
        NumberAnimation { target: signalBall; property: "y"; from: mainBall.y; to: mainBall.y+30-suspendBall.expendW/2; duration: 200}
        NumberAnimation { target: signalBall; property: "opacity"; from: 0.0; to: 1.0; duration: 200}

        // 场景
        NumberAnimation { target: sceneBall; property: "x"; from: mainBall.x; to: mainBall.x-30+suspendBall.expendH/2; duration: 200}
        NumberAnimation { target: sceneBall; property: "y"; from: mainBall.y; to: mainBall.y+30-suspendBall.expendW/2; duration: 200}
        NumberAnimation { target: sceneBall; property: "opacity"; from: 0.0; to: 1.0; duration: 200}

        // 回显
        NumberAnimation { target: echoBall; property: "x"; from: mainBall.x; to: mainBall.x+30-suspendBall.expendW/2; duration: 200}
        NumberAnimation { target: echoBall; property: "y"; from: mainBall.y; to: mainBall.y; duration: 200}
        NumberAnimation { target: echoBall; property: "opacity"; from: 0.0; to: 1.0; duration: 200}

        // 预监
        NumberAnimation { target: priviewBall; property: "x"; from: mainBall.x; to: mainBall.x-30+suspendBall.expendW/2; duration: 200}
        NumberAnimation { target: priviewBall; property: "y"; from: mainBall.y; to: mainBall.y; duration: 200}
        NumberAnimation { target: priviewBall; property: "opacity"; from: 0.0; to: 1.0; duration: 200}

        // 清屏
        NumberAnimation { target: clearBall; property: "x"; from: mainBall.x; to: mainBall.x+30-suspendBall.expendH/2; duration: 200}
        NumberAnimation { target: clearBall; property: "y"; from: mainBall.y; to: mainBall.y-30+suspendBall.expendW/2; duration: 200}
        NumberAnimation { target: clearBall; property: "opacity"; from: 0.0; to: 1.0; duration: 200}

        // 备用
        NumberAnimation { target: quitBall; property: "x"; from: mainBall.x; to: mainBall.x-30+suspendBall.expendH/2; duration: 200}
        NumberAnimation { target: quitBall; property: "y"; from: mainBall.y; to: mainBall.y-30+suspendBall.expendW/2; duration: 200}
        NumberAnimation { target: quitBall; property: "opacity"; from: 0.0; to: 1.0; duration: 200}

        onStopped: {
            suspendBall.status = 2;
        }
    }

    ParallelAnimation {     // 缩小
        id: reduceAnimation;

        // 信号源
        NumberAnimation { target: signalBall; property: "x"; to: mainBall.x; duration: 200}
        NumberAnimation { target: signalBall; property: "y"; to: mainBall.y; duration: 200}
        NumberAnimation { target: signalBall; property: "opacity"; from: 1.0; to: 0.0; duration: 60}

        // 场景
        NumberAnimation { target: sceneBall; property: "x"; to: mainBall.x; duration: 200}
        NumberAnimation { target: sceneBall; property: "y"; to: mainBall.y; duration: 200}
        NumberAnimation { target: sceneBall; property: "opacity"; from: 1.0; to: 0.0; duration: 200}

        // 回显
        NumberAnimation { target: echoBall; property: "x"; to: mainBall.x; duration: 200}
        NumberAnimation { target: echoBall; property: "y"; to: mainBall.y; duration: 200}
        NumberAnimation { target: echoBall; property: "opacity"; from: 1.0; to: 0.0; duration: 200}

        // 预监
        NumberAnimation { target: priviewBall; property: "x"; to: mainBall.x; duration: 200}
        NumberAnimation { target: priviewBall; property: "y"; to: mainBall.y; duration: 200}
        NumberAnimation { target: priviewBall; property: "opacity"; from: 1.0; to: 0.0; duration: 200}

        // 清屏
        NumberAnimation { target: clearBall; property: "x"; to: mainBall.x; duration: 200}
        NumberAnimation { target: clearBall; property: "y"; to: mainBall.y; duration: 200}
        NumberAnimation { target: clearBall; property: "opacity"; from: 1.0; to: 0.0; duration: 200}

        // 备用
        NumberAnimation { target: quitBall; property: "x"; to: mainBall.x; duration: 200}
        NumberAnimation { target: quitBall; property: "y"; to: mainBall.y; duration: 200}
        NumberAnimation { target: quitBall; property: "opacity"; from: 1.0; to: 0.0; duration: 200}

        onStopped: {
            suspendBall.x = suspendBall.x+(suspendBall.width/2)-30;
            suspendBall.y = suspendBall.y+(suspendBall.height/2)-30;
            suspendBall.width = 60;
            suspendBall.height = 60;
            suspendBall.status = 0;
        }
    }

    // animation
    NumberAnimation { id: lAnimation; target: suspendBall; property: "x"; to: -30; duration: 200}
    NumberAnimation { id: rAnimation; target: suspendBall; property: "x"; to: suspendBall.parent.width-30; duration: 200}
    NumberAnimation { id: tAnimation; target: suspendBall; property: "y"; to: -30; duration: 200}
    NumberAnimation { id: bAnimation; target: suspendBall; property: "y"; to: suspendBall.parent.height-30; duration: 200}
}
