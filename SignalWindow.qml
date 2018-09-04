import QtQuick 2.7
import QtQuick.Controls 2.2
import com.VideoPaintItem 1.0

Rectangle {
    id: signalWindow
    border.color: "#FFFFFF"
    border.width: 2
    radius: 10
    clip: true
    color: "#665D778C";

    // 是否穿透
    property bool bRemote: false

    // 服务器是否允许Resize
    property bool bResizeLiscene: false

    // 区分单击和双击事件
    property bool bMousePress: false

    // 点击时的起始位置
    property int pressX: 0
    property int pressY: 0

    // 信号窗的基本属性
    property int winid: 0
    property int chid: 0

    // 分割数
    property int segment: 1

    // 虚拟信号窗链表
    property Component signalWindowVirComponent: null
    property var signalWindowVirList: []

    // header
    Rectangle {
        id: signalWindowHeader
        y: 5
        width: parent.width-2; height: 30;
        anchors.horizontalCenter: parent.horizontalCenter
        color: "#00000000"
        clip: true

        // 如果屏组是归纳状态则不显示header
        visible: !groupDisplayItem.bFolder

        Rectangle {
            id: signalWindowTitleRect
            width: parent.width-10; height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#00000000"

            Text {
                id: signalWindowTitle
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                text: "WIN-"+winid

                color: "white"
                font.family: "微软雅黑"
                font.pixelSize: 14
                font.bold: true
                //smooth: true
                //clip: true
            }
        }
        // sub title
        Rectangle {
            width: signalWindowHeader.width-30; height: parent.height/3
            anchors.bottom: parent.bottom;
            anchors.horizontalCenter: signalWindowHeader.horizontalCenter
            color: "#4C5D778C";

            Text {
                id: signalWindowSubTitle
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                text: "signal-"+chid

                color: "white"
                font.family: "微软雅黑"
                font.pixelSize: 8
                font.bold: false
                //smooth: true
                //clip: true
            }
        }

        Button {
            id: signalWindowCloseBtn
            width: 26; height: 26
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: imageClose
                height: parent.height * 0.8
                width: parent.width * 0.8
                anchors.centerIn: parent
                source: "resource/closeSignalWindow1.png"
            }
            background: Rectangle {
                border.width: 1
                border.color: "#00000000"
                radius: 0
                color: "#00000000"
            }

            function customOnPressed() {
                imageClose.source = "resource/closeSignalWindow2.png";
            }
            function customOnReleased() {
                imageClose.source = "resource/closeSignalWindow1.png";
            }
            function customOnClicked() {
                debugArea.appendLog("signal window close onclicked.");

                if (0 === mainWindow.g_connectMode)
                    groupDisplayItem.removeSignalWindow(winid, true);
                else
                    mainMgr.gwinswitch(groupDisplayItem.groupID, winid);
            }
        }
        Button {
            id: signalWindowSegment
            width: 26; height: 26
            anchors.right: signalWindowCloseBtn.left
            anchors.verticalCenter: parent.verticalCenter
            visible: (9 == mainMgr.getTypeByID( chid ))

            Image {
                id: imageFull
                height: parent.height * 0.8
                width: parent.width * 0.8
                anchors.centerIn: parent
               // source: "resource/signalWindowFull.png"
            }
            background: Rectangle {
                border.width: 1
                border.color: "#00000000"
                radius: 0
                color: "#00000000"
            }

            function customOnPressed() {
                imageFull.opacity = 0.4;
            }
            function customOnReleased() {
                imageFull.opacity = 1.0;
            }
            function customOnClicked() {
                // menu
//                contextMenu.x = signalWindowSegment.x; // 菜单弹出位置
//                contextMenu.y = signalWindowSegment.y;
//                contextMenu.open();             // 显示菜单
            }
        }
        Menu {  // 自定义菜单
            id: contextMenu
            width: 100

            MenuItem {
                width: parent.width
                text: "整屏"
                onTriggered: {
                    signalWindowBody.setSegment( 1 );
                }
            }
            MenuItem {
                width: parent.width
                text: "4分屏"
                onTriggered: {
                    signalWindowBody.setSegment( 4 );
                }
            }
            MenuItem {
                width: parent.width
                text: "9分屏"
                onTriggered: {
                    signalWindowBody.setSegment( 9 );
                }
            }
            MenuItem {
                width: parent.width
                text: "36分屏"
                onTriggered: {
                    signalWindowBody.setSegment( 36 );
                }
            }
        }
        Button {
            id: signalWindowRemote
            width: 50; height: 26
            anchors.right: signalWindowSegment.left
            anchors.verticalCenter: parent.verticalCenter
            visible: true

            Text {
                text: {
                    if (0 == mainWindow.language) {
                        text: qsTr("穿透");
                    } else {
                        qsTr("Remote");
                    }
                }

                color: bRemote ? "red" : "white";
                anchors.centerIn: parent

                font.family: "微软雅黑"
                font.pixelSize: 14
                //smooth: true
                //clip: true
            }
            background: Rectangle {
                border.width: 1
                border.color: "#33000000"
                radius: 0
                color: "#00000000"
            }
            function customOnClicked() {
                bRemote = !bRemote;
            }
        }
    }

    // body
    Rectangle {
        id: signalWindowBody
        width: parent.width-10; height: parent.height-signalWindowHeader.height-10
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: signalWindowHeader.bottom
        color: "#00000000"

        // background
        Image {
            anchors.fill: parent

            fillMode: Image.Stretch
            source: "resource/background.png"
        }

        onWidthChanged: {
            setSegment(segment, false);
        }
        onHeightChanged: {
            setSegment(segment, false);
        }

        function setSegment(seg, bSendCmd) {
            var type = mainMgr.getTypeByID( chid );
            if (9 != type)
                return;

            segment = seg;
            initVirWindow();

            var i, j, row, col, virItem, ww, hh;
            for (i = 0; i < 36; i++) {
                virItem = signalWindowVirList[i];
                virItem.x = 0; virItem.y = 0;
                virItem.width = 0; virItem.height = 0;
            }
            if (0 == segment) {
                row = 1;
                col = 1;
            } else if (4 == segment) {
                row = 2;
                col = 2;
            } else if (9 == segment) {
                row = 3;
                col = 3;
            } else if (36 == segment) {
                row = 6;
                col = 6;
            }

            ww = signalWindowBody.width/row;
            hh = signalWindowBody.height/col;
            for (i = 0; i < row; i++) {
                for (j = 0; j < col; j++) {
                    virItem = signalWindowVirList[i*row+j];
                    virItem.x = i*ww;
                    virItem.y = j*hh;
                    virItem.width = ww;
                    virItem.height = hh;
                }
            }
        }

        function initVirWindow() {
            // 判断如果是IPV需要新建36个子窗体
            var type = mainMgr.getTypeByID( chid );
            if (9 == type) {
                if (0 != signalWindowVirList.length)
                    return;

                // 加载组件
                if (signalWindowVirComponent == null) {
                    signalWindowVirComponent = Qt.createComponent( "SignalWindowVirDisplay.qml" );
                }
                for (var i = 0; i < 36; i++) {
                    var virItem = signalWindowVirComponent.createObject(signalWindowBody, {"index": i, "x":0, "y":0, "width":0, "height": 0} );
                    signalWindowVirList.push( virItem );
                }
            }
        }
    }

    // 两点缩放
    PinchArea {
        anchors.fill: parent

        // 没有锁屏也没有穿透的情况下允许缩放
        enabled: !groupDisplayItem.bLock && !groupDisplayItem.bRemote && !groupDisplayItem.bFolder

        property int srcWidth: 0
        property int srcHeight: 0
        property int srcCenterX: 0
        property int srcCenterY: 0

        onPinchStarted: {
            srcWidth = parent.width;
            srcHeight = parent.height;
            srcCenterX = parent.x+(parent.width/2);
            srcCenterY = parent.y+(parent.height/2);

            // 两点时取消单点标示符，否则有冲突
            bMousePress = false;
            pinch.accepted = true;

            if (0 === mainWindow.g_connectMode)
                bResizeLiscene = true;
            else {
                bResizeLiscene = false;

                // 请求控制
                mainMgr.RequestControlBySignalWindow(groupDisplayItem.groupID, chid, 0, winid);
            }
        }

        onPinchUpdated: {
            // pinch.scale 缩放倍数
            // pinch.angle 角度，标准坐标系0~180  -180~0
            var newW = pinch.scale*srcWidth;
            var newH = pinch.scale*srcHeight;
            var bScaleWindow = 0;

            // 两点时取消单点标示符，否则有冲突
            bMousePress = false;
            if ( bResizeLiscene ) {
                var absAngle = Math.abs(pinch.angle);

                var resizeX = parent.x;
                var resizeY = parent.y;
                var resizeW = parent.width;
                var resizeH = parent.height;
                if ((absAngle < 20) || (absAngle > 160)) {
                    // 横向缩放
                    resizeW = newW;
                    resizeX = srcCenterX - (newW/2);

                    bScaleWindow = 1;
                } else if ((absAngle > 70) && (absAngle < 110)) {
                    // 纵向缩放
                    resizeH = newH;
                    resizeY = srcCenterY - (newH/2);

                    bScaleWindow = 1;
                } else {
                    // 横纵同时缩放
                    resizeW = newW;
                    resizeX = srcCenterX - (newW/2);

                    resizeH = newH;
                    resizeY = srcCenterY - (newH/2);

                    bScaleWindow = 1;
                }

                if (1 == bScaleWindow) {
                    // 限定最大值
                    resizeX = (resizeX < 0) ? 0 : resizeX;
                    resizeY = (resizeY < 0) ? 0 : resizeY;

                    // modify by 20180829，右下角两指缩放会出边界
                    var resizeR = resizeX+resizeW;
                    var resizeB = resizeY+resizeH;
                    resizeR = (resizeR > groupDisplayBody.width) ? groupDisplayBody.width : resizeR;
                    resizeB = (resizeB > groupDisplayBody.height) ? groupDisplayBody.height : resizeB;
                    resizeW = resizeR-resizeX;
                    resizeH = resizeB-resizeY;

                    // 限定最小值
                    resizeW = (resizeW < 100) ? 100 : resizeW;
                    resizeH = (resizeH < 50) ? 50 : resizeH;

                    if (0 === mainWindow.g_connectMode) {
                        // 单机直接修改尺寸
                        parent.x = resizeX;
                        parent.y = resizeY;
                        parent.width = resizeW;
                        parent.height = resizeH;
                    }

                    groupDisplayItem.gwinsize(winid, chid, resizeX, resizeY, resizeW, resizeH);
                }
            }
        }

        onPinchFinished: {
            if (1 === mainWindow.g_connectMode) {
                mainMgr.RequestOver( groupDisplayItem.groupID );
            }
        }

        DropArea {
            anchors.fill: parent

            property int chid: 0

            onEntered: {
                drag.accepted = roomTabView.isTopGroupDisplay( groupDisplayItem.groupID );
                chid = drag.getDataAsString("chid");
            }
            onPositionChanged: {
                drag.accepted = roomTabView.isTopGroupDisplay( groupDisplayItem.groupID );
            }
            onDropped: {
                if (drop.supportedActions == Qt.CopyAction) {
                }

                drop.acceptProposedAction();
                drop.accepted = roomTabView.isTopGroupDisplay( groupDisplayItem.groupID );
            }
        }
        MouseArea {
            anchors.fill: parent

            enabled: !groupDisplayItem.bLock && !groupDisplayItem.bFolder
            //hoverEnabled: true  // 悬停事件

            onPressed: {
                debugArea.appendLog("onPressed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
                bMousePress = true;
                if ( bRemote ) {
                    // 穿透
                    var dx = Math.round(10000*mouseX/signalWindowBody.width);
                    var dy = Math.round(10000*mouseY/signalWindowBody.height);
                    if ((dx == 0) && (dy == 0))
                        return;

                    var mouseFlag = 0x0000;
                    if (mouse.button == Qt.LeftButton) {
                        mouseFlag = 0x0002;
                    } else if (mouse.button == Qt.RightButton) {
                        mouseFlag = 0x0008;
                    }

                    if (0 != mouseFlag) {
                        var cmd = "M "+mouseFlag+" "+dx+" "+dy+"$$$$";

                        mainMgr.SendRemoteCmd(chid, cmd);
                    }
                } else {
                    signalWindow.pressX = mouseX
                    signalWindow.pressY = mouseY

                    if (0 === mainWindow.g_connectMode) {
                        bResizeLiscene = true;

                        // 置顶
                        groupDisplayItem.setSignalWindowTop( winid );
                    } else {
                        bResizeLiscene = false;

                        // 请求控制
                        mainMgr.RequestControlBySignalWindow(groupDisplayItem.groupID, chid, 0, winid);
                    }
                }

                if (signalWindowCloseBtn.contains(mapToItem(signalWindowCloseBtn, mouse.x, mouse.y))) {
                    signalWindowCloseBtn.customOnPressed();
                }
                if (signalWindowSegment.contains(mapToItem(signalWindowSegment, mouse.x, mouse.y))) {
                    signalWindowSegment.customOnPressed();
                }
            }
            onPositionChanged: {
                if (bRemote && bMousePress) {
                    // 穿透
                    // 转换坐标到ui->m_pGenaralBodyWidget
                    var dx = Math.round(10000*mouseX/signalWindowBody.width);
                    var dy = Math.round(10000*mouseY/signalWindowBody.height);

                    var mouseFlag = 0x0001;
                    if ((0 != mouseFlag) && (dx < 10000) && (dy < 10000)) {
                        var cmd = "M "+mouseFlag+" "+dx+" "+dy+"$$$$";

                        mainMgr.SendRemoteCmd(chid, cmd);
                    }
                }
                if (bResizeLiscene && bMousePress) {
                    // 横向缩放
                    var resizeX = signalWindow.x;
                    var resizeY = signalWindow.y;
                    var resizeW = signalWindow.width;
                    var resizeH = signalWindow.height;

                    // 计算偏移量
                    resizeX += mouseX-signalWindow.pressX
                    resizeY += mouseY-signalWindow.pressY

                    // 限定左上角
                    resizeX = (resizeX < 0) ? 0 : resizeX;
                    resizeY = (resizeY < 0) ? 0 : resizeY;

                    // 限定右下角
                    resizeX = (resizeX > groupDisplayBody.width-resizeW) ? groupDisplayBody.width-resizeW : resizeX;
                    resizeY = (resizeY > groupDisplayBody.height-resizeH) ? groupDisplayBody.height-resizeH : resizeY;

                    if (0 === mainWindow.g_connectMode) {
                        // 单机直接修改尺寸
                        signalWindow.x = resizeX;
                        signalWindow.y = resizeY;
                        signalWindow.width = resizeW;
                        signalWindow.height = resizeH;
                    }

                    // 发送指令
                    groupDisplayItem.gwinsize(winid, chid, resizeX, resizeY, resizeW, resizeH);
                }
            }
            onReleased: {
                debugArea.appendLog("onReleased~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
                if (signalWindowCloseBtn.contains(mapToItem(signalWindowCloseBtn, mouse.x, mouse.y))) {
                    signalWindowCloseBtn.customOnReleased();
                }
                if (signalWindowSegment.contains(mapToItem(signalWindowSegment, mouse.x, mouse.y))) {
                    signalWindowSegment.customOnReleased();
                }

                if (bRemote && bMousePress) {
                    // 穿透
                    var dx = Math.round(10000*mouseX/signalWindowBody.width);
                    var dy = Math.round(10000*mouseY/signalWindowBody.height);

                    var mouseFlag = 0x0000;
                    if (mouse.button == Qt.LeftButton) {
                        mouseFlag = 0x0004;
                    } else if (mouse.button == Qt.RightButton) {
                        mouseFlag = 0x0008;
                    }

                    if (0 != mouseFlag) {
                        var cmd = "M "+mouseFlag+" "+dx+" "+dy+"$$$$";

                        mainMgr.SendRemoteCmd(chid, cmd);
                    }

                    bMousePress = false;
                }
                if ( bMousePress ) {
                    bMousePress = false;
                    resizeByAdsorption();
                }

                if (1 === mainWindow.g_connectMode) {
                    mainMgr.RequestOver( groupDisplayItem.groupID );
                }
            }
            onClicked: {
                if (signalWindowCloseBtn.contains(mapToItem(signalWindowCloseBtn, mouse.x, mouse.y))) {
                    signalWindowCloseBtn.customOnClicked();
                }
                if (signalWindowSegment.contains(mapToItem(signalWindowSegment, mouse.x, mouse.y))) {
                    signalWindowSegment.customOnClicked();
                }
                if (signalWindowRemote.contains(mapToItem(signalWindowRemote, mouse.x, mouse.y))) {
                    signalWindowRemote.customOnClicked();
                }
            }
            onDoubleClicked: {
                if ( bRemote ) {
                    // 穿透
                } else {
                    bMousePress = false;
                    resizeToOverlapDisplay();
                }
            }
        }
    }

    // 回显单元
    VideoPaintItem {
        id: signalWindowVideo
        anchors.fill: signalWindowBody
        visible: false
    }

    function openPreview() {
        signalWindowVideo.SetBaseInfo(mainMgr, groupDisplayItem.groupID, winid, chid);
        signalWindowVideo.OpenPreview(parent.width, parent.height);
        signalWindowVideo.visible = true;
    }
    function closePreview() {
        signalWindowVideo.ClosePreview();
        signalWindowVideo.visible = false;
    }
    function updatePreview() {
        signalWindowVideo.UpdatePreview(parent.width, parent.height);
    }

    // 吸附
    function resizeByAdsorption() {
        var adsorptionPixel = 25;
        var singleWidth = 0.5*groupDisplayBody.width/groupDisplayItem.arrayX;
        var singleHeight = 0.5*groupDisplayBody.height/groupDisplayItem.arrayY;
        var resizeX = signalWindow.x;
        var resizeY = signalWindow.y;
        var resizeW = signalWindow.width;
        var resizeH = signalWindow.height;

        for (var i = 0; i < groupDisplayItem.arrayX*2+1; i++) {
            // 横向吸附
            if (Math.abs(i*singleWidth-resizeX) < adsorptionPixel) {
                resizeX = i*singleWidth;
            }
            if (Math.abs(i*singleWidth-(resizeX+resizeW)) < adsorptionPixel) {
                resizeW = i*singleWidth-resizeX;
            }
        }
        for (i = 0; i < groupDisplayItem.arrayY*2+1; i++) {
            // 纵向吸附
            if (Math.abs(i*singleHeight-resizeY) < adsorptionPixel) {
                resizeY = i*singleHeight;
            }
            if (Math.abs(i*singleHeight-(resizeY+resizeH)) < adsorptionPixel) {
                resizeH = i*singleHeight-resizeY;
            }
        }

        if (0 === mainWindow.g_connectMode) {
            // 单机直接修改尺寸
            signalWindow.x = resizeX;
            signalWindow.y = resizeY;
            signalWindow.width = resizeW;
            signalWindow.height = resizeH;
        }

        // 发送指令
        groupDisplayItem.gwinsize(winid, chid, resizeX, resizeY, resizeW, resizeH);
    }

    // 所占屏
    function resizeToOverlapDisplay() {
        var l = Number.MIN_VALUE;
        var r = Number.MAX_VALUE;
        var t = Number.MIN_VALUE;
        var b = Number.MAX_VALUE;
        var singleWidth = 0.5*groupDisplayBody.width/groupDisplayItem.arrayX;
        var singleHeight = 0.5*groupDisplayBody.height/groupDisplayItem.arrayY;

        for (var i = 0; i < groupDisplayItem.arrayX*2+1; i++) {
            if (i*singleWidth <= signalWindow.x)
                l = Math.max(l, i*singleWidth);
            if (i*singleWidth >= (signalWindow.x+signalWindow.width))
                r = Math.min(r, i*singleWidth);
        }
        for (i = 0; i < groupDisplayItem.arrayY*2+1; i++) {
            if (i*singleHeight <= signalWindow.y)
                t = Math.max(t, i*singleHeight);
            if (i*singleHeight >= (signalWindow.y+signalWindow.height))
                b = Math.min(b, i*singleHeight);
        }

        if (0 === mainWindow.g_connectMode) {
            signalWindow.x = l;
            signalWindow.y = t;
            signalWindow.width = r-l;
            signalWindow.height = b-t;
        }

        // 发送指令
        groupDisplayItem.gwinsize(winid, chid, l, t, r-l, b-t);
    }

    function resizeSignalWindowByAnimation(x, y, width, height, al, at, aw, ah) {
        resizeSignalWindowAnimation.setRange(x, y, width, height, al, at, aw, ah);
        resizeSignalWindowAnimation.start();
    }

    ParallelAnimation {
        id: resizeSignalWindowAnimation;

        function setRange(sx, sy, sw, sh, dx, dy, dw, dh) {
            rSXA.target = signalWindow; rSXA.from = sx; rSXA.to = dx;
            rSYA.target = signalWindow; rSYA.from = sy; rSYA.to = dy;
            rSWA.target = signalWindow; rSWA.from = sw; rSWA.to = dw;
            rSHA.target = signalWindow; rSHA.from = sh; rSHA.to = dh;
        }

        NumberAnimation { id: rSXA; property: "x"; duration: 200}
        NumberAnimation { id: rSYA; property: "y"; duration: 200}
        NumberAnimation { id: rSWA; property: "width"; duration: 200}
        NumberAnimation { id: rSHA; property: "height"; duration: 200}
    }
}
