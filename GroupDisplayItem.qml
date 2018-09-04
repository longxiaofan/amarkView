import QtQuick 2.0
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

Rectangle {
    id: groupDisplayItem

    radius: 20
    color: "#33036EB8"
    border.color: "white"
    border.width: 2
    clip: true

    // 组ID
    property int groupID: 0
    property alias groupName: groupDisplayName.text;

    // 房间排列（虚拟分屏固定4分割，移动时起吸附作用）
    property int arrayX: 2
    property int arrayY: 2

    // 对应实际坐标
    property int actualWidth: 7680
    property int actualHeight: 2160

    // 信号窗的变量
    property Component signalWindowComponent: null
    property var signalWindowList: []

    // 点击时的起始位置
    property int pressX: 0
    property int pressY: 0

    property bool bPress: false

    // 房间是否锁定
    property bool bLock: false

    // 房间是否收入归纳区域
    property bool bFolder: false

    // 添加阴影
//    layer.enabled: true
//    layer.effect: DropShadow {
//        transparentBorder: true
//        horizontalOffset: 5
//        verticalOffset: 5
//        radius: 8.0
//        samples: 16
//        color: "#44000000"
//    }

    // header
    Rectangle {
        id: groupHeader
        x:mainWindow.mapToDeviceWidth(10); y:mainWindow.mapToDeviceHeight(10);
        width: parent.width-mainWindow.mapToDeviceWidth(20); height: mainWindow.mapToDeviceHeight(50)
        color: "#00000000";

        Rectangle {
            width: mainWindow.mapToDeviceWidth(44); height: width
            anchors.right: parent.right
            anchors.rightMargin: mainWindow.mapToDeviceWidth(55)
            anchors.verticalCenter: parent.verticalCenter
            radius: 5
            color: "#00000000";

            Image {
                anchors.fill: parent
                fillMode: Image.Stretch
                source: bLock ? "resource/roomLock.png" : "resource/roomUnLock.png"
            }
        }

        Text {
            id: groupDisplayName
            text: qsTr("GROUP"+groupID)
            anchors.verticalCenter: parent.verticalCenter

            color: "white"
            font.family: "微软雅黑"
            font.pixelSize: 20
            font.bold: true
            //smooth: true
            clip: true
        }

        Button {
            id: saveSceneBtn
            width: mainWindow.mapToDeviceWidth(44); height: mainWindow.mapToDeviceHeight(44)
            anchors.right: parent.right
            anchors.rightMargin: mainWindow.mapToDeviceWidth(5)
            anchors.verticalCenter: parent.verticalCenter

            background: Rectangle {
                border.width: 0
                border.color: "#00000000"
                radius: 0
                color: "#00000000"
            }

            Image {
                id: image
                height: parent.height
                width: parent.width
                anchors.centerIn: parent
                source: "resource/saveScene1.png"
            }

            SequentialAnimation {
                id: addSceneAnimation
                PropertyAnimation { target: image; property: "source"; from: "resource/saveScene1.png"; to: "resource/saveScene2.png"; duration: 100; }
                PropertyAnimation { target: image; property: "source"; from: "resource/saveScene2.png"; to: "resource/saveScene3.png"; duration: 100; }
                PropertyAnimation { target: image; property: "source"; from: "resource/saveScene3.png"; to: "resource/saveScene2.png"; duration: 100; }
                PropertyAnimation { target: image; property: "source"; from: "resource/saveScene2.png"; to: "resource/saveScene1.png"; duration: 100; }
            }

            function customOnClicked() {
                addSceneAnimation.start();
                // 保存场景
                addscene();
                // 刷新场景
                refreshSceneToolBar();
            }
        }

        // 两点缩放
        PinchArea {
            anchors.fill: parent

            enabled: !bFolder

            property int srcWidth: 0
            property int srcHeight: 0
            property int srcCenterX: 0
            property int srcCenterY: 0

            onPinchStarted: {
                srcWidth = groupDisplayItem.width;
                srcHeight = groupDisplayItem.height;
                srcCenterX = groupDisplayItem.x+(groupDisplayItem.width/2);
                srcCenterY = groupDisplayItem.y+(groupDisplayItem.height/2);

                pinch.accepted = true;
            }

            onPinchUpdated: {
                // pinch.scale 缩放倍数
                // pinch.angle 角度，标准坐标系0~180  -180~0
                var newW = pinch.scale*srcWidth;
                var newH = pinch.scale*srcHeight;
                var newX = srcCenterX - (newW/2);
                var newY = srcCenterY - (newH/2);

                // 限定最大值
                if (newW > roomTabView.width) {
                    newX = 0;
                    newW = roomTabView.width;
                } else if (newX+newW > roomTabView.width) {
                    newX = roomTabView.width - newW;
                }

                if (newH > roomTabView.height) {
                    newY = 0;
                    newH = roomTabView.height;
                } else if (newY+newH > roomTabView.height) {
                    newY = roomTabView.height - newH;
                }

                // 限定最小值
                newX = (newX < 0) ? 0 : newX;
                newY = (newY < 0) ? 0 : newY;

                newW = (newW < mainWindow.mapToDeviceWidth(200)) ? mainWindow.mapToDeviceWidth(200) : newW;
                newH = (newH < mainWindow.mapToDeviceHeight(100)) ? mainWindow.mapToDeviceHeight(100) : newH;

                // 需要修改内部信号窗的尺寸
                groupDisplayItem.resizeAllSignalWindow(newW-mainWindow.mapToDeviceWidth(20), newH-mainWindow.mapToDeviceHeight(80));

                groupDisplayItem.x = newX;
                groupDisplayItem.y = newY;

                groupDisplayItem.width = newW;
                groupDisplayItem.height = newH;
            }

            MouseArea {
                anchors.fill: parent

                onPressed: {
                    bPress = true;
                    // 置顶
                    roomTabView.setGroupDisplayTop(groupDisplayItem.groupID, groupDisplayItem.z);

                    groupDisplayItem.pressX = mouseX
                    groupDisplayItem.pressY = mouseY
                }
                onPositionChanged: {
                    if ( !bPress )
                        return;

                    // 计算偏移量
                    groupDisplayItem.x += mouseX-groupDisplayItem.pressX
                    groupDisplayItem.y += mouseY-groupDisplayItem.pressY

                    // 限定左上角
                    groupDisplayItem.x = (groupDisplayItem.x < 0) ? 0 : groupDisplayItem.x;
                    groupDisplayItem.y = (groupDisplayItem.y < 0) ? 0 : groupDisplayItem.y;

                    // 限定右下角
                    groupDisplayItem.x = (groupDisplayItem.x > roomTabView.width-groupDisplayItem.width) ? roomTabView.width-groupDisplayItem.width : groupDisplayItem.x;
                    groupDisplayItem.y = (groupDisplayItem.y > roomTabView.height-groupDisplayItem.height) ? roomTabView.height-groupDisplayItem.height : groupDisplayItem.y;

                    // 当尺寸同时小于父类尺寸的0.6时靠近右边框缩小锁定
                    var i, y, currentGItem;

                    // 当已经被归纳并且向左拖动超过一半归纳区域时放大
                    if (bFolder && (groupDisplayItem.x < roomTabView.width-mainWindow.mapToDeviceWidth(250))) {
                        bFolder = false;
                        bPress = false;

                        // 按比例放大里面的信号窗
                        resizeAllSignalWindow(mainWindow.mapToDeviceWidth(800-20), mainWindow.mapToDeviceHeight(400-80));

                        normalShow(roomTabView.width/2-mainWindow.mapToDeviceWidth(400), roomTabView.height/2-mainWindow.mapToDeviceHeight(200));

                        // 重新排序
                        y = mainWindow.mapToDeviceHeight(10);
                        for (i = 0; i < roomTabView.groupDisplayList.length; i++) {
                            currentGItem = roomTabView.groupDisplayList[i];
                            if (null == currentGItem)
                                continue;

                            // 判断排在上面的屏组
                            if ( !currentGItem.bFolder )
                                continue;

                            currentGItem.moveYByAnimation( y );
                            //currentGItem.y = y;
                            debugArea.appendLog(currentGItem.groupID+","+y+"~~~~~~~~~~");
                            y += mainWindow.mapToDeviceHeight(110);
                        }
                    }
                    if (!bFolder
                            && (groupDisplayItem.width < roomTabView.width*0.8) // 当尺寸大于整体界面的百分之八十时不归档
                            && (groupDisplayItem.height < roomTabView.height*0.8)
                            && (groupDisplayItem.x+groupDisplayItem.width == roomTabView.width)) {
                        bFolder = true;
                        bPress = false;

                        // 按比例缩小里面信号窗
                        resizeAllSignalWindow(mainWindow.mapToDeviceWidth(200-20), mainWindow.mapToDeviceHeight(100-80));

                        // 排列所有屏组
                        y = mainWindow.mapToDeviceHeight(10);
                        for (i = 0; i < roomTabView.groupDisplayList.length; i++) {
                            currentGItem = roomTabView.groupDisplayList[i];
                            if (null == currentGItem)
                                continue;

                            // 判断排在上面的屏组
                            if (currentGItem.groupID < groupDisplayItem.groupID) {
                                if ( currentGItem.bFolder )
                                    y += mainWindow.mapToDeviceHeight(110);
                            } else if (currentGItem.groupID > groupDisplayItem.groupID) {
                                if ( currentGItem.bFolder )
                                    currentGItem.y += mainWindow.mapToDeviceHeight(110);
                            }
                        }

                        folderShow( y );
                    }
                }
                onReleased: {
                    bPress = false;
                    if ( roomTabView.isTopGroupDisplay(groupDisplayItem.groupID) ) {
                        if (saveSceneBtn.contains(mapToItem(saveSceneBtn, mouse.x, mouse.y))) {
                            saveSceneBtn.customOnClicked();
                        }
                    }
                }
            }
        }
    }

    // body
    Rectangle {
        id: groupDisplayBody

        width: parent.width-mainWindow.mapToDeviceWidth(20); height: parent.height-mainWindow.mapToDeviceHeight(80)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: groupHeader.bottom

        // 实现拖放事件
        DropArea {
            anchors.fill: parent

            property int chid: 0

            onEntered: {
                debugArea.appendLog("drop onEntered.")
                drag.accepted = roomTabView.isTopGroupDisplay( groupDisplayItem.groupID );
                chid = drag.getDataAsString("chid");
                var chname = drag.getDataAsString("chname");
            }
            onPositionChanged: {
                drag.accepted = roomTabView.isTopGroupDisplay( groupDisplayItem.groupID );
            }
            onDropped: {
                if (drop.supportedActions == Qt.CopyAction) {
                    // 拖拽开单屏
                    var l, r, t, b;
                    var actualX = (groupDisplayItem.actualWidth/parent.width)*drop.x;
                    var actualY = (groupDisplayItem.actualHeight/parent.height)*drop.y;

                    var singleWidth = groupDisplayItem.actualWidth/groupDisplayItem.arrayX;
                    var singleHeight = groupDisplayItem.actualHeight/groupDisplayItem.arrayY;
                    for (var i = 0; i < groupDisplayItem.arrayX; i++) {
                        if ((actualX > i*singleWidth) && (actualX < (i+1)*singleWidth)) {
                            l = i*singleWidth;
                            r = (i+1)*singleWidth;
                            break;
                        }
                    }
                    for (i = 0; i < groupDisplayItem.arrayY; i++) {
                        if ((actualY > i*singleHeight) && (actualY < (i+1)*singleHeight)) {
                            t = i*singleHeight;
                            b = (i+1)*singleHeight;
                            break;
                        }
                    }

                    if (0 === mainWindow.g_connectMode) {
                        // 创建信号窗
                        var signalWindow = appendSignalWindow(chid, -1, l, t, r-l, b-t);

                        // 发送指令
                        gwinsize(signalWindow.winid, signalWindow.chid, signalWindow.x, signalWindow.y, signalWindow.width, signalWindow.height);
                    } else {
                        mainMgr.gwinsize(groupID, createWinID(), chid, l, t, r, b);
                    }
                }

                drop.acceptProposedAction();
                drop.accepted = roomTabView.isTopGroupDisplay( groupDisplayItem.groupID );
            }

            // 两点缩放
            PinchArea {
                anchors.fill: parent

                enabled: !bFolder

                property int srcWidth: 0
                property int srcHeight: 0
                property int srcCenterX: 0
                property int srcCenterY: 0

                onPinchStarted: {
                    srcWidth = groupDisplayItem.width;
                    srcHeight = groupDisplayItem.height;
                    srcCenterX = groupDisplayItem.x+(groupDisplayItem.width/2);
                    srcCenterY = groupDisplayItem.y+(groupDisplayItem.height/2);

                    pinch.accepted = true;
                }

                onPinchUpdated: {
                    // pinch.scale 缩放倍数
                    // pinch.angle 角度，标准坐标系0~180  -180~0
                    var newW = pinch.scale*srcWidth;
                    var newH = pinch.scale*srcHeight;
                    var newX = srcCenterX - (newW/2);
                    var newY = srcCenterY - (newH/2);

                    // 限定最大值
                    if (newW > roomTabView.width) {
                        newX = 0;
                        newW = roomTabView.width;
                    } else if (newX+newW > roomTabView.width) {
                        newX = roomTabView.width - newW;
                    }

                    if (newH > roomTabView.height) {
                        newY = 0;
                        newH = roomTabView.height;
                    } else if (newY+newH > roomTabView.height) {
                        newY = roomTabView.height - newH;
                    }

                    // 限定最小值
                    newX = (newX < 0) ? 0 : newX;
                    newY = (newY < 0) ? 0 : newY;

                    newW = (newW < mainWindow.mapToDeviceWidth(200)) ? mainWindow.mapToDeviceWidth(200) : newW;
                    newH = (newH < mainWindow.mapToDeviceHeight(100)) ? mainWindow.mapToDeviceHeight(100) : newH;

                    // 需要修改内部信号窗的尺寸
                    groupDisplayItem.resizeAllSignalWindow(newW-mainWindow.mapToDeviceWidth(20), newH-mainWindow.mapToDeviceHeight(80));

                    groupDisplayItem.x = newX;
                    groupDisplayItem.y = newY;

                    groupDisplayItem.width = newW;
                    groupDisplayItem.height = newH;
                }

                MouseArea {
                    anchors.fill: parent

                    onPressed: {
                        bPress = true;
                        // 置顶
                        roomTabView.setGroupDisplayTop(groupDisplayItem.groupID, groupDisplayItem.z);

                        groupDisplayItem.pressX = mouseX
                        groupDisplayItem.pressY = mouseY
                    }
                    onPositionChanged: {
                        if ( !bPress )
                            return;

                        // 计算偏移量
                        groupDisplayItem.x += mouseX-groupDisplayItem.pressX
                        groupDisplayItem.y += mouseY-groupDisplayItem.pressY

                        // 限定左上角
                        groupDisplayItem.x = (groupDisplayItem.x < 0) ? 0 : groupDisplayItem.x;
                        groupDisplayItem.y = (groupDisplayItem.y < 0) ? 0 : groupDisplayItem.y;

                        // 限定右下角
                        groupDisplayItem.x = (groupDisplayItem.x > roomTabView.width-groupDisplayItem.width) ? roomTabView.width-groupDisplayItem.width : groupDisplayItem.x;
                        groupDisplayItem.y = (groupDisplayItem.y > roomTabView.height-groupDisplayItem.height) ? roomTabView.height-groupDisplayItem.height : groupDisplayItem.y;

                    }
                    onReleased: {
                        bPress = false;
                        if ( roomTabView.isTopGroupDisplay(groupDisplayItem.groupID) ) {
                            if (saveSceneBtn.contains(mapToItem(saveSceneBtn, mouse.x, mouse.y))) {
                                saveSceneBtn.customOnClicked();
                            }
                        }

                        // 当尺寸同时小于父类尺寸的0.6时靠近右边框缩小锁定
                        var i, y, currentGItem;

                        // 当已经被归纳并且向左拖动超过一半归纳区域时放大
                        if (bFolder && (groupDisplayItem.x < roomTabView.width-mainWindow.mapToDeviceWidth(250))) {
                            bFolder = false;
                            bPress = false;

                            // 按比例放大里面的信号窗
                            resizeAllSignalWindow(mainWindow.mapToDeviceWidth(800-20), mainWindow.mapToDeviceHeight(400-80));

                            normalShow(roomTabView.width/2-mainWindow.mapToDeviceWidth(400), roomTabView.height/2-mainWindow.mapToDeviceHeight(200));

                            // 重新排序
                            y = mainWindow.mapToDeviceHeight(10);
                            for (i = 0; i < roomTabView.groupDisplayList.length; i++) {
                                currentGItem = roomTabView.groupDisplayList[i];
                                if (null == currentGItem)
                                    continue;

                                // 判断排在上面的屏组
                                if ( !currentGItem.bFolder )
                                    continue;

                                currentGItem.moveYByAnimation( y );
                                //currentGItem.y = y;
                                debugArea.appendLog(currentGItem.groupID+","+y+"~~~~~~~~~~");
                                y += mainWindow.mapToDeviceHeight(110);
                            }
                        }
                        if (!bFolder
                                && (groupDisplayItem.width < roomTabView.width*0.8) // 当尺寸大于整体界面的百分之八十时不归档
                                && (groupDisplayItem.height < roomTabView.height*0.8)
                                && (groupDisplayItem.x+groupDisplayItem.width == roomTabView.width)) {
                            bFolder = true;
                            bPress = false;

                            // 按比例缩小里面信号窗
                            resizeAllSignalWindow(mainWindow.mapToDeviceWidth(200-20), mainWindow.mapToDeviceHeight(100-80));

                            // 排列所有屏组
                            y = mainWindow.mapToDeviceHeight(10);
                            for (i = 0; i < roomTabView.groupDisplayList.length; i++) {
                                currentGItem = roomTabView.groupDisplayList[i];
                                if (null == currentGItem)
                                    continue;

                                // 判断排在上面的屏组
                                if (currentGItem.groupID < groupDisplayItem.groupID) {
                                    if ( currentGItem.bFolder )
                                        y += mainWindow.mapToDeviceHeight(110);
                                } else if (currentGItem.groupID > groupDisplayItem.groupID) {
                                    if ( currentGItem.bFolder )
                                        currentGItem.y += mainWindow.mapToDeviceHeight(110);
                                }
                            }

                            folderShow( y );
                        }
                    }
                }
            }
        }

        // background
        Image {
            anchors.fill: parent

            fillMode: Image.Stretch
            source: "resource/background.png"

//            Image {
//                height: parent.height/2; width: height
//                anchors.centerIn: parent

//                fillMode: Image.Stretch
//                source: "resource/backgroundcenter.png"
//            }
        }

        Canvas {
            id: groupPainter
            width: parent.width; height: parent.height;
            contextType: "2d";
            onPaint: {
                console.log("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
                var row = groupDisplayItem.arrayY;
                var col = groupDisplayItem.arrayX;
                var singleWidth = width/col;
                var singleHeight = height/row;
                context.beginPath();

                // 1.绘制虚线，4分屏
                context.lineWidth = 1;
                context.strokeStyle = "#66808080";
                // 绘制单屏横线
                for (var i = 0; i < row; i++) {
                    var beginYY = (i+0.5)*singleHeight;
                    drawDashLine(context, 0 ,beginYY, width , beginYY);
                }
                // 绘制单屏竖线
                for (i = 0; i < col; i++) {
                    var beginXX = (i+0.5)*singleWidth;
                    drawDashLine(context, beginXX ,0, beginXX , height);
                }
                context.stroke();
                context.closePath();
                context.beginPath();

                // 2.绘制屏组，示例4*2
                context.lineWidth = 1;
                context.strokeStyle = "99000000";
                // 绘制单屏横线
                for (i = 0; i < row+1; i++) {
                    var beginY = i*singleHeight;
                    context.moveTo(0 ,beginY);
                    context.lineTo(width , beginY);
                }
                // 绘制单屏竖线
                for (i = 0; i < col+1; i++) {
                    var beginX = i*singleWidth;
                    context.moveTo(beginX ,0);
                    context.lineTo(beginX , height);
                }

                context.stroke();
                context.closePath();
            }

            // 下面两个是绘制虚线的功能函数
            function getBeveling(x,y)
            {
                return Math.sqrt(Math.pow(x,2)+Math.pow(y,2));
            }

            function drawDashLine(context,x1,y1,x2,y2,dashLen)
            {
                dashLen = dashLen === undefined ? 5 : dashLen;
                //得到斜边的总长度
                var beveling = getBeveling(x2-x1,y2-y1);
                //计算有多少个线段
                var num = Math.floor(beveling/dashLen);

                for(var i = 0 ; i < num; i++)
                {
                    context[i%2 == 0 ? 'moveTo' : 'lineTo'](x1+(x2-x1)/num*i,y1+(y2-y1)/num*i);
                }
                context.stroke();
            }
        }
    }

    ParallelAnimation {     // 文件夹显示
        id: folderShowAnimation;

        function setPos( y ) {
            wAnimation.to = mainWindow.mapToDeviceWidth(200);
            hAnimation.to = mainWindow.mapToDeviceHeight(100);
            xAnimation.to = roomTabView.width-wAnimation.to-mainWindow.mapToDeviceWidth(10);
            yAnimation.to = y;
        }

        NumberAnimation { id: xAnimation; target: groupDisplayItem; property: "x"; duration: 200}
        NumberAnimation { id: yAnimation; target: groupDisplayItem; property: "y"; duration: 200}
        NumberAnimation { id: wAnimation; target: groupDisplayItem; property: "width"; duration: 200}
        NumberAnimation { id: hAnimation; target: groupDisplayItem; property: "height"; duration: 200}
    }

    ParallelAnimation {     // 常规显示
        id: normalShowAnimation;

        function setPos(x, y) {
            nxAnimation.to = x;
            nyAnimation.to = y;
        }

        NumberAnimation { id: nxAnimation; target: groupDisplayItem; property: "x"; duration: 200}
        NumberAnimation { id: nyAnimation; target: groupDisplayItem; property: "y"; duration: 200}
        NumberAnimation { target: groupDisplayItem; property: "width"; to: mainWindow.mapToDeviceWidth(800); duration: 200}
        NumberAnimation { target: groupDisplayItem; property: "height"; to: mainWindow.mapToDeviceHeight(400); duration: 200}
    }

    NumberAnimation { id: moveyAnimation; target: groupDisplayItem; property: "y"; duration: 200}

    function folderShow( ty ) {
        folderShowAnimation.setPos( ty );
        folderShowAnimation.start();
    }

    function normalShow(tx, ty) {
        normalShowAnimation.setPos(tx, ty);
        normalShowAnimation.start();
    }

    function moveYByAnimation( ty ) {
        moveyAnimation.to = ty;
        moveyAnimation.start();
    }

    function createWinID() {
        // 初始化数组作为哈希表
        var resArr = [];
        for (var i = 0; i < signalWindowList.length+1; i++) {
            resArr[i] = -1;
        }


        // 填充哈希表
        for (i = 0; i < signalWindowList.length; i++) {
            if (signalWindowList[i] != null) {
                resArr[signalWindowList[i].winid] = 1;
            }
        }

        // 返回没被赋值的位置
        for (i = 0; i < resArr.length; i++) {
            if (resArr[i] == -1)
                return i;
        }

        return 0;
    }

    function resizeAllSignalWindow(newW, newH) {
        for (var i = 0; i < signalWindowList.length; i++) {
            var signalWindow = signalWindowList[i];
            if (null == signalWindow)
                continue;

            // 获取实际坐标
            var al = (groupDisplayItem.actualWidth/groupDisplayBody.width)*signalWindow.x;
            var ar = (groupDisplayItem.actualWidth/groupDisplayBody.width)*(signalWindow.x+signalWindow.width);
            var at = (groupDisplayItem.actualHeight/groupDisplayBody.height)*signalWindow.y;
            var ab = (groupDisplayItem.actualHeight/groupDisplayBody.height)*(signalWindow.y+signalWindow.height);

            var vl = (newW/groupDisplayItem.actualWidth)*al;
            var vr = (newW/groupDisplayItem.actualWidth)*ar;
            var vt = (newH/groupDisplayItem.actualHeight)*at;
            var vb = (newH/groupDisplayItem.actualHeight)*ab;

            signalWindow.x = vl;
            signalWindow.y = vt;
            signalWindow.width = vr-vl;
            signalWindow.height = vb-vt;
        }
    }

    ParallelAnimation {
        id: resizeGroupDisplayAnimation;

        function setRange(sx, sy, sw, sh, dx, dy, dw, dh) {
            rGXA.from = sx; rGXA.to = dx;
            rGYA.from = sy; rGYA.to = dy;
            rGWA.from = sw; rGWA.to = dw;
            rGHA.from = sh; rGHA.to = dh;
        }

        NumberAnimation { id: rGXA; target: groupDisplayItem; property: "x"; duration: 200}
        NumberAnimation { id: rGYA; target: groupDisplayItem; property: "y"; duration: 200}
        NumberAnimation { id: rGWA; target: groupDisplayItem; property: "width"; duration: 200}
        NumberAnimation { id: rGHA; target: groupDisplayItem; property: "height"; duration: 200}
    }

    function resizeGroupDisplay(offsetW, offsetH) {
        // 计算新的组位置
        var gl = (roomTabView.width+offsetW)*groupDisplayItem.x/roomTabView.width;
        var gw = (roomTabView.width+offsetW)*groupDisplayItem.width/roomTabView.width;
        var gt = (roomTabView.height+offsetH)*groupDisplayItem.y/roomTabView.height;
        var gh = (roomTabView.height+offsetH)*groupDisplayItem.height/roomTabView.height;

        // 循环内部信号窗
        for (var i = 0; i < signalWindowList.length; i++) {
            var signalWindow = signalWindowList[i];
            if (null == signalWindow)
                continue;

            // 获取实际坐标
            var al = (gw-mainWindow.mapToDeviceWidth(20))*signalWindow.x/groupDisplayBody.width;
            var aw = (gw-mainWindow.mapToDeviceWidth(20))*signalWindow.width/groupDisplayBody.width;
            var at = (gh-mainWindow.mapToDeviceHeight(80))*signalWindow.y/groupDisplayBody.height;
            var ah = (gh-mainWindow.mapToDeviceHeight(80))*signalWindow.height/groupDisplayBody.height;

            signalWindow.resizeSignalWindowByAnimation(signalWindow.x, signalWindow.y, signalWindow.width, signalWindow.height,
                                                 al, at, aw, ah);
        }

        resizeGroupDisplayAnimation.setRange(groupDisplayItem.x, groupDisplayItem.y, groupDisplayItem.width, groupDisplayItem.height,
                                             gl, gt, gw, gh);
        resizeGroupDisplayAnimation.start();
    }

    // 置顶信号窗
    function setSignalWindowTop( winid ) {
        var currentSignalWindow;
        for (var i = 0; i < signalWindowList.length; i++) {
            var signalWindow = signalWindowList[i];
            if (null == signalWindow)
                continue;

            if (winid == signalWindow.winid) {
                currentSignalWindow = signalWindow;
                break;
            }
        }

        if (null == currentSignalWindow)
            return;

        for (i = 0; i < signalWindowList.length; i++) {
            signalWindow = signalWindowList[i];
            if (null == signalWindow)
                continue;

            if (signalWindow.z > currentSignalWindow.z) {
                signalWindow.z -= 1;
            }
        }
        currentSignalWindow.z = signalWindowList.length-1;
    }

    function greset( bSendCmd ) {
        // 置空链表
        for (var i = 0; i < signalWindowList.length; i++) {
            var signalWindow = signalWindowList[i];
            if (null != signalWindow) {
                signalWindow.destroy();
                signalWindowList[i] = null;
            }
        }

        if ( bSendCmd )
            mainMgr.greset( groupID );
    }

    function gwinsize(winid, chid, l, t, w, h) {
        var al = (groupDisplayItem.actualWidth/groupDisplayBody.width)*l;
        var ar = (groupDisplayItem.actualWidth/groupDisplayBody.width)*(l+w);
        var at = (groupDisplayItem.actualHeight/groupDisplayBody.height)*t;
        var ab = (groupDisplayItem.actualHeight/groupDisplayBody.height)*(t+h);

        mainWindow.sigGWinsize(groupID, winid, chid, al, at, ar, ab);
        //mainMgr.gwinsize(groupID, winid, chid, al, at, ar, ab);
    }

    function gwinswitch( winid ) {
        mainMgr.gwinswitch(groupID, winid);
    }

    function addscene() {
        // 按z-value排序的信号窗
        var lstSignalWindow = new Array;
        for (var i = 0; i < signalWindowList.length; i++) {
            var currentLength = lstSignalWindow.length;
            var preZ = (currentLength == 0) ? -1 : lstSignalWindow[currentLength-1].z;
            var currentZ = 255;
            var currentI = -1;

            for (var j = 0; j < signalWindowList.length; j++) {
                var signalWindow = signalWindowList[j];
                if (signalWindow == null)
                    continue;

                // 取最小Z值的索引
                if ((currentZ > signalWindow.z) && (preZ < signalWindow.z)){
                    currentZ = signalWindow.z;
                    currentI = j;
                }
            }

            if (-1 != currentI)
                lstSignalWindow.push( signalWindowList[currentI] );
        }

        var lst = new Array;
        for (i = 0; i < lstSignalWindow.length; i++) {
            signalWindow = lstSignalWindow[i];
            if (signalWindow != null) {
                var al = (groupDisplayItem.actualWidth/groupDisplayBody.width)*signalWindow.x;
                var ar = (groupDisplayItem.actualWidth/groupDisplayBody.width)*(signalWindow.x+signalWindow.width);
                var at = (groupDisplayItem.actualHeight/groupDisplayBody.height)*signalWindow.y;
                var ab = (groupDisplayItem.actualHeight/groupDisplayBody.height)*(signalWindow.y+signalWindow.height);

                lst.push( signalWindow.chid );
                lst.push( signalWindow.winid );
                lst.push( al );
                lst.push( at );
                lst.push( ar-al );
                lst.push( ab-at );
            }
        }

        mainMgr.addscene(groupID, lst);
    }

    function updateScene( sid ) {
        // 按z-value排序的信号窗
        var lstSignalWindow = new Array;
        for (var i = 0; i < signalWindowList.length; i++) {
            var currentLength = lstSignalWindow.length;
            var preZ = (currentLength == 0) ? -1 : lstSignalWindow[currentLength-1].z;
            var currentZ = 255;
            var currentI = -1;

            for (var j = 0; j < signalWindowList.length; j++) {
                var signalWindow = signalWindowList[j];
                if (signalWindow == null)
                    continue;

                // 取最小Z值的索引
                if ((currentZ > signalWindow.z) && (preZ < signalWindow.z)){
                    currentZ = signalWindow.z;
                    currentI = j;
                }
            }

            if (-1 != currentI)
                lstSignalWindow.push( signalWindowList[currentI] );
        }

        var lst = new Array;
        for (i = 0; i < lstSignalWindow.length; i++) {
            signalWindow = lstSignalWindow[i];
            if (signalWindow != null) {
                var al = (groupDisplayItem.actualWidth/groupDisplayBody.width)*signalWindow.x;
                var ar = (groupDisplayItem.actualWidth/groupDisplayBody.width)*(signalWindow.x+signalWindow.width);
                var at = (groupDisplayItem.actualHeight/groupDisplayBody.height)*signalWindow.y;
                var ab = (groupDisplayItem.actualHeight/groupDisplayBody.height)*(signalWindow.y+signalWindow.height);

                lst.push( signalWindow.chid );
                lst.push( signalWindow.winid );
                lst.push( al );
                lst.push( at );
                lst.push( ar-al );
                lst.push( ab-at );
            }
        }

        mainMgr.updatescene(groupID, sid, lst);
    }

    function gload( sid ) {
        mainMgr.gload(groupID, sid);
    }

    // 重新加载场景toolbar
    function refreshSceneToolBar() {
        operatorPage.refreshSceneToolBar();
    }

    function preview() {
        for (var i = 0; i < signalWindowList.length; i++) {
            var signalWindow = signalWindowList[i];
            if (null != signalWindow) {
                if ( operatorPage.bPreview ) {
                    signalWindow.openPreview();
                } else {
                    signalWindow.closePreview();
                }
            }
        }
    }

    // 在第一块单屏添加信号窗
    function appendDefaultWindow( chid ) {
        var singleDisplayWidth = groupDisplayItem.actualWidth/groupDisplayItem.arrayX;
        var singleDisplayHeight = groupDisplayItem.actualHeight/groupDisplayItem.arrayY;

        if (0 === mainWindow.g_connectMode) {
            // 创建信号窗
            var signalWindow = appendSignalWindow(chid, -1, 0, 0, singleDisplayWidth, singleDisplayHeight);

            // 发送指令
            gwinsize(signalWindow.winid, signalWindow.chid, signalWindow.x, signalWindow.y, signalWindow.width, signalWindow.height);
        } else {
            mainMgr.gwinsize(groupID, createWinID(), chid, 0, 0, singleDisplayWidth, singleDisplayHeight);
        }
    }

    function appendSignalWindow(chid, winid, cx, cy, cw, ch) {
        // 加载组件
        if (signalWindowComponent == null) {
            signalWindowComponent = Qt.createComponent( "SignalWindow.qml" );
        }

        var l = (cx/groupDisplayItem.actualWidth)*groupDisplayBody.width;
        var t = (cy/groupDisplayItem.actualHeight)*groupDisplayBody.height;
        var w = (cw/groupDisplayItem.actualWidth)*groupDisplayBody.width;
        var h = (ch/groupDisplayItem.actualHeight)*groupDisplayBody.height;
        var signalWindow = signalWindowComponent.createObject(groupDisplayBody, {"winid": (-1 == winid) ? createWinID() : winid, "chid": chid,
                                                                                                          "x":l, "y":t, "width":w, "height": h} );

        // 如果数组内元素被删除则直接替换
        var bReplaceNode = 0;
        for (var i = 0; i < signalWindowList.length; i++) {
            var tempSignalWindow = signalWindowList[i];
            if (tempSignalWindow == null) {
                signalWindowList[i] = signalWindow;
                bReplaceNode = 1;
                debugArea.appendLog( "add signal window by replace." );
                break;
            }
        }

        // 如果没有元素则直接push
        if (0 == bReplaceNode) {
            signalWindowList.push( signalWindow );
            signalWindow.z = signalWindowList.length-1;
            debugArea.appendLog( "add signal window by push." );
        }

        // 如果是打开的状态则打开预监回显
        if ( operatorPage.bPreview ) {
            signalWindow.openPreview();
        }

        return signalWindow;
    }

    function serverResizeSignalWindow(winid, cx, cy, cw, ch) {
        var l = (cx/groupDisplayItem.actualWidth)*groupDisplayBody.width;
        var t = (cy/groupDisplayItem.actualHeight)*groupDisplayBody.height;
        var w = (cw/groupDisplayItem.actualWidth)*groupDisplayBody.width;
        var h = (ch/groupDisplayItem.actualHeight)*groupDisplayBody.height;

        for (var i = 0; i < signalWindowList.length; i++) {
            var signalWindow = signalWindowList[i];
            if (signalWindow == null)
                continue;

            if (winid != signalWindow.winid)
                continue;

            signalWindow.x = l;
            signalWindow.y = t;
            signalWindow.width = w;
            signalWindow.height = h;
            break;
        }
    }

    function getSignalWindow( winid ) {
        for (var i = 0; i < signalWindowList.length; i++) {
            var signalWindow = signalWindowList[i];
            if (null == signalWindow)
                continue;

            if (winid == signalWindow.winid) {
                return signalWindow;
            }
        }

        return null;
    }

    function removeSignalWindow(winid, bSendCmd) {
        for (var i = 0; i < signalWindowList.length; i++) {
            var signalWindow = signalWindowList[i];
            if (null == signalWindow)
                continue;

            if (winid == signalWindow.winid) {
                signalWindow.destroy();

                // 发送指令给后端
                if ( bSendCmd ) {
                    gwinswitch( winid );
                }

                signalWindowList[i] = null;
                break;
            }
        }

        // 添加日志
        debugArea.appendLog( "remove signal window." );
    }
}
