import QtQuick 2.0

Rectangle {
    property int index: 0

    border.width: 1
    border.color: "black"
    clip: true
    color: (txt.text != "") ? "#FF69B4FF" : "#00000000"

    Text {
        id: txt
        anchors.centerIn: parent
        //visible: bExistIP
    }
}
