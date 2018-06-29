import QtQuick 2.0
import QtQuick.Controls 2.2
import com.VideoPaintItem 1.0

Rectangle {
    id: previewToolBarItem
    width: 400; height: 300
    color: "white"
    radius: 20;
    z: 255
    visible: false;

    // 临时变量，鼠标点击位置
    property int pressX: 0
    property int pressY: 0

    // 当前页
    property int currentPage: 0

    // 所有输入通道
    property var channelList

    StandardToolBarItem {
        id: header
        width: parent.width+2; height: 50;
        bLeftToRight: false;
        bLock: true;
        mainTitle: "P";
        subTitle: "preview video signal realtime";

        MouseArea {
            anchors.fill: parent
            onPressed: {
                previewToolBarItem.pressX = mouseX
                previewToolBarItem.pressY = mouseY
            }
            onPositionChanged: {
                // 计算偏移量
                previewToolBarItem.x += mouseX-previewToolBarItem.pressX
                previewToolBarItem.y += mouseY-previewToolBarItem.pressY

                // 限定左上角
                previewToolBarItem.x = (previewToolBarItem.x < 0) ? 0 : previewToolBarItem.x;
                previewToolBarItem.y = (previewToolBarItem.y < 0) ? 0 : previewToolBarItem.y;

                // 限定右下角
                previewToolBarItem.x = (previewToolBarItem.x > operatorPage.width-previewToolBarItem.width) ? operatorPage.width-previewToolBarItem.width : previewToolBarItem.x;
                previewToolBarItem.y = (previewToolBarItem.y > operatorPage.height-previewToolBarItem.height-180) ? operatorPage.height-previewToolBarItem.height-180 : previewToolBarItem.y;
            }
            onReleased: {
                //
            }
        }
    }

    Grid {
        id: grid
        anchors.left: parent.left;
        anchors.top: header.bottom;
        rows: 2; columns: 2;
        rowSpacing: 1;
        columnSpacing: 2;

        flow: Grid.LeftToRight

        Repeater {
            model: 4

            Rectangle {
                width: 200; height: 110;
                color: "#5D778C";
                border.color: "white";
                border.width: 1;

                property alias txt: label.text
                property int chid: 0

                // 回显单元
                VideoPaintItem {
                    id: signalWindowVideo
                    anchors.fill: parent
                    //width: parent.width; height: 90;
                    //anchors.top: parent.top;
                }
                Rectangle {
                    width: parent.width; height: 20;
                    anchors.bottom: parent.bottom;
                    color: "#00000000";

                    Text {
                        id: label
                        text: qsTr("channel")
                        anchors.horizontalCenter: parent.horizontalCenter

                        color: "white"
                        font.family: "微软雅黑"
                        font.pixelSize: 14
                        font.bold: false
                        smooth: true
                        clip: true
                    }
                }

                function openPreview() {
                    signalWindowVideo.SetBaseInfo(mainMgr, -1, chid, chid);
                    signalWindowVideo.OpenPreview(240, 136);
                }
                function closePreview() {
                    signalWindowVideo.ClosePreview();
                }
            }
        }
    }

    Button {
        text: {
            if (0 == mainWindow.language) {
                text: qsTr("上一页");
            } else {
                qsTr("BACK");
            }
        }
        x: 75;
        width: 50; height: 25
        anchors.bottom: parent.bottom

        font.family: "微软雅黑";
        font.pixelSize: 14

        contentItem: Text {
            text: parent.text
            font: parent.font
            color: parent.down ? "#E8E8E8" : "#F8F8FF"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            border.width: 1
            border.color: "#F8F8FF"
            radius: 5
            color: "#5D778C"
        }

        onClicked: {if (null == channelList)
                channelList = mainMgr.getChannelList();

            // 向上取整
            var pageCount = Math.ceil(channelList.length/8);

            if (currentPage > 0) {
                currentPage -= 1;

                for (var i = 0; i < 4; i++) {
                    var item = grid.children[i];
                    if (null == item)
                        continue;

                    // 先关闭预监
                    item.closePreview();

                    var chIndex = currentPage*4+i;
                    if (chIndex < channelList.length/2) {
                        var chid = channelList[chIndex*2+0];
                        var chname = channelList[chIndex*2+1];

                        item.txt = chname;
                        item.chid = Number(chid);

                        // 打开回显
                        item.openPreview();
                    } else {
                        // 默认值
                        item.txt = "null";
                    }
                }
            }
        }
    }

    Button {
        text: {
            if (0 == mainWindow.language) {
                text: qsTr("下一页");
            } else {
                qsTr("NEXT");
            }
        }
        x: 275;
        width: 50; height: 25
        anchors.bottom: parent.bottom

        font.family: "微软雅黑"
        font.pixelSize: 14

        contentItem: Text {
            text: parent.text
            font: parent.font
            color: parent.down ? "#E8E8E8" : "#F8F8FF"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            border.width: 1
            border.color: "#F8F8FF"
            radius: 5
            color: "#5D778C"
        }

        onClicked: {
            if (null == channelList)
                channelList = mainMgr.getChannelList();

            // 向上取整
            var pageCount = Math.ceil(channelList.length/8);

            if (currentPage+1 < pageCount) {
                currentPage += 1;

                for (var i = 0; i < 4; i++) {
                    var item = grid.children[i];
                    if (null == item)
                        continue;

                    // 先关闭预监
                    item.closePreview();

                    var chIndex = currentPage*4+i;
                    if (chIndex < channelList.length/2) {
                        var chid = channelList[chIndex*2+0];
                        var chname = channelList[chIndex*2+1];

                        item.txt = chname;
                        item.chid = Number(chid);

                        // 打开回显
                        item.openPreview();
                    } else {
                        // 默认值
                        item.txt = "null";
                    }
                }
            }
        }
    }

    function setVisible( b ) {
        previewToolBarItem.visible = b;

        if (null == channelList)
            channelList = mainMgr.getChannelList();

        // 只要显示就默认显示前四个
        if ( b ) {
            currentPage = 0;
            for (var i = 0; i < 4; i++) {
                var item = grid.children[i];
                if (null == item)
                    continue;

                if (i < channelList.length/2) {
                    var chid = channelList[i*2+0];
                    var chname = channelList[i*2+1];

                    item.txt = chname;
                    item.chid = Number(chid);

                    // 打开回显
                    item.openPreview();
                } else {
                    // 默认值
                    item.label = "null";
                }
            }
        } else {
            for (i = 0; i < 4; i++) {
                item = grid.children[i];
                if (null == item)
                    continue;

                item.closePreview();
            }
        }
    }
}
