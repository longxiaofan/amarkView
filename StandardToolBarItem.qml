import QtQuick 2.0
import QtGraphicalEffects 1.0

Rectangle {
    id: toolBarItem
    radius: 20
    color: "#00000000"
    width: 200; height: 70;
    clip: true

    // 加锁没有动画效果
    property bool bLock: false
    // 方向，true是头在右
    property bool bLeftToRight: false;
    // 颜色索引
    property int colorIndex: 0;
    // 文字
    property alias mainTitle: mainTitle.text;
    property alias subTitle: subTitle.text;
    // 状态值
    property bool bNormalShow: true
    // 颜色
    property var colorArr: ["#036EB8", "#28C3DD", "#4F778E", "#8C97A8", "#999999"]

    NumberAnimation { id: leftnormalShowAnimation; target: body; property: "width"; from: 20; to: 130; duration: 500}
    NumberAnimation { id: leftminShowAnimation; target: body; property: "width"; from: 130; to: 20; duration: 500}

    ParallelAnimation {     // 并行
        id: rightnormalShowAnimation;
        NumberAnimation { target: body; property: "x"; from: 20; to: 130; duration: 500}
        NumberAnimation { target: body; property: "width"; from: 130; to: 20; duration: 500}
    }
    ParallelAnimation {     // 并行
        id: rightminShowAnimation;
        NumberAnimation { target: body; property: "x"; from: 130; to:20 ; duration: 500}
        NumberAnimation { target: body; property: "width"; from: 20; to: 130; duration: 500}
    }

    function normalShow() {
        bNormalShow = true;
        if ( bLeftToRight )
            leftnormalShowAnimation.start();
        else
            rightnormalShowAnimation.start();
    }
    function minShow() {
        bNormalShow = false;
        if ( bLeftToRight )
            leftminShowAnimation.start();
        else
            rightminShowAnimation.start();
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if ( bLock )
                return;

            if ( bNormalShow ) {
                minShow();
            } else {
                normalShow();
            }
        }
    }

    Rectangle {
        id: body
        width: parent.width-header.width
        height: parent.height
        color: "white"

        Text {
            id: subTitle
            text: qsTr("person computer signal\ndouble clicked this")
            anchors.centerIn: parent

            color: "black"
            font.family: "微软雅黑"
            font.pixelSize: 12
            smooth: true
            clip: true
        }

        Component.onCompleted: {
            if ( toolBarItem.bLeftToRight ) {
                anchors.left = parent.left;
            } else {
                anchors.right = parent.right;
            }
        }
    }

    // 需要四个矩形
    Rectangle {
        id: header
        width: parent.height; height: width;
        radius: parent.radius
        color: toolBarItem.colorArr[toolBarItem.colorIndex]

        Rectangle {
            id: subheader
            width: parent.width/2; height: parent.height
            color: parent.color
        }
        Rectangle {
            width: parent.width; height: parent.height/2
            color: parent.color
            anchors.bottom: parent.bottom
        }

        layer.enabled: true
        layer.effect: DropShadow {
            id: shadow
            transparentBorder: true
            horizontalOffset: -3
            radius: 8.0
            samples: 16
            color: "#80000000"

            Component.onCompleted: {
                if ( !toolBarItem.bLeftToRight )
                    horizontalOffset = 3;
            }
        }

        Text {
            id: mainTitle
            text: qsTr("PC")
            anchors.centerIn: parent

            color: "white"
            font.family: "微软雅黑"
            font.pixelSize: 22
            font.bold: true
            smooth: true
            clip: true
        }

        Component.onCompleted: {
            if ( toolBarItem.bLeftToRight ) {
                anchors.left = body.right;
                subheader.anchors.left = header.left;
            } else {
                anchors.right = body.left;
                subheader.anchors.right = header.right;
            }
        }
    }
}
