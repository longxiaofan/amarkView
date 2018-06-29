import QtQuick 2.0
import QtQuick.Controls 2.2

Button {
    property alias txt: label.text;
    property var image1: "resource/mainBtn1.png"
    property var image2: "resource/mainBtn2.png"

    height: 80
    width: 100

    Image {
        id: image
        height: parent.height * 0.8
        width: parent.width * 0.8
        anchors.centerIn: parent
        source: image1
    }
    Label{
        id: label
        color: "white"
        font.family: "微软雅黑"
        font.pixelSize: 18
        smooth: true
        clip: true
        renderType: Text.NativeRendering

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -8
    }

    background: Rectangle {
        border.width: 1
        border.color: "#00000000"
        radius: 5
        color: "#00000000"
    }
    onPressed: {
        image.source = image2
    }
    onReleased: {
        image.source = image1
    }
    onCanceled: {   // 可能取消点
        image.source = image2
    }
}
