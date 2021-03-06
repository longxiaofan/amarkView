import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import QtQml.Models 2.3
import QtQml 2.2
//import QtGraphicalEffects 1.0

import com.MainManager 1.0

Rectangle {
    id: operatorPage
    anchors.fill: parent

    // 场景和定位是否显示
    property bool bPreview: false

    // 几个区域是否显示标示符
    property bool bSignalViewShow: false
    property bool bSceneViewShow: false
    property bool bPreviewShow: false

    // background image
    Image {
        anchors.fill: parent

        fillMode: Image.Stretch
        source: "resource/background.png"

        Image {
            height: parent.height/2; width: height
            anchors.centerIn: parent

            fillMode: Image.Stretch
            source: "resource/backgroundcenter.png"
        }
    }

    // signal animation
    NumberAnimation { id: showSignalSrcAnimation; target: signalSource; property: "width"; from: 0; to: mainWindow.mapToDeviceWidth(250); duration: 300; }
    NumberAnimation { id: hideSignalSrcAnimation; target: signalSource; property: "width"; from: mainWindow.mapToDeviceWidth(250); to: 0; duration: 300; }
    NumberAnimation { id: showSceneViewAnimation; target: sceneView; property: "width"; from: 0; to: mainWindow.mapToDeviceWidth(250); duration: 300; }
    NumberAnimation { id: hideSceneViewAnimation; target: sceneView; property: "width"; from: mainWindow.mapToDeviceWidth(250); to: 0; duration: 300; }

    // 信号源工具栏
    Rectangle {
        id: signalSource
        x: 0; y: 0; width: 0; height: parent.height;
        anchors.left: parent.left
//        anchors.leftMargin: -20     // 只要两个圆角
//        radius: 20
        clip: true

        color: "#3383A3AA"

//        // 添加阴影
//        layer.enabled: true
//        layer.effect: DropShadow {
//            transparentBorder: true
//            horizontalOffset: 5
//            verticalOffset: 5
//            radius: 8.0
//            samples: 16
//            color: "#44000000"
//        }

        ListModel {
            id: channelModel
        }

        Component {                   // 自定义代理
            id: signalSourceDelegate;

            Column {
                // 这里用来控制信号组内成员是否显示
                visible: {
                    if (group == 0) {
                        true;
                    } else if (0 == chType)
                        !signalSourceView.minPCGroup;
                    else if (3 == chType) {
                        !signalSourceView.minHDGroup;
                    } else if (8 == chType)
                        !signalSourceView.minVideoGroup;
                    else if (9 == chType)
                        !signalSourceView.minIPVGroup;
                }

                Row {
                    width: mainWindow.mapToDeviceWidth(300); height: (group == 0)?mainWindow.mapToDeviceHeight(80):mainWindow.mapToDeviceHeight(40);

                    visible: {
                        // 分组的标题控制，如果里面没有输入信号则隐藏
                        if (group == 0) {
                            if (chType == 0)
                                (signalSourceView.pccount != 0) ? true : false;
                            else if (chType == 3) {
                                (signalSourceView.hdcount != 0) ? true : false;
                            } else if (chType == 8)
                                (signalSourceView.videocount != 0) ? true : false;
                            else if (chType == 9)
                                (signalSourceView.ipvcount != 0) ? true : false;
                        } else
                            true;
                    }

                    Rectangle {
                        width: parent.width; height: (group == 0)?mainWindow.mapToDeviceHeight(60):mainWindow.mapToDeviceHeight(40);
                        anchors.verticalCenter: parent.verticalCenter

                        property int dragLisence: 0         // 是否允许拖拽
                        color: "#00000000"

                        // group
                        StandardToolBarItem {
                            id: channelGroupItem
                            anchors.fill: parent
                            anchors.left: parent.left

                            visible: (group == 0)

                            bLeftToRight: true;
                            colorIndex: {
                                if (0 == chType) 0;
                                else if (3 == chType) 1;
                                else if (8 == chType) 2;
                                else if (9 == chType) 3;
                            }
                            mainTitle: {
                                if (0 == chType) "P";
                                else if (3 == chType) "H";
                                else if (8 == chType) "V";
                                else if (9 == chType) "I";
                            }
                            subTitle: "signal list"

                            Component.onCompleted: {
                                minShow();
                            }
                        }

                        // channel
                        Rectangle {
                            width: parent.width-mainWindow.mapToDeviceWidth(50); height: mainWindow.mapToDeviceHeight(40);
                            anchors.horizontalCenter: parent.horizontalCenter;
                            color: ((signalSourceView.currentChID == chID) && (signalSourceView.currentChType == chType)) ? "#8C97A8" : "#5D778C";
                            border.width: 1
                            border.color: "white"
                            visible: (group == 1)

                            Text {
                                text: name
                                anchors.centerIn: parent

                                color: "white"
                                font.family: "微软雅黑"
                                font.pixelSize: 14
                                font.bold: false
                                smooth: true
                                clip: true
                            }
                        }

                        // 拖拽事件
                        Drag.active: (1 == dragLisence) && (1 == group)
                        Drag.supportedActions: Qt.CopyAction
                        Drag.dragType: Drag.Automatic
                        Drag.mimeData: {"chid":chID, "chname":name}
                        Drag.imageSource: "resource/channelDragIcon.png"  // 全屏不显示

                        MouseArea {                         // 设置鼠标区域
                            id: mouseMA
                            acceptedButtons: Qt.LeftButton // 只接收右键
                            anchors.fill: parent
                            enabled: true

                            onPressAndHold: {
                                debugArea.appendLog( "channel onPressAndHold" )
                                if (group == 1)
                                    parent.dragLisence = 1;
                            }
                            onReleased: {
                                if (group == 1)
                                    parent.dragLisence = 0;
                            }
                            onPressed: {
                                // 记录当前信号源
                                if (1 == group) {
                                    signalSourceView.currentChID = chID;
                                    signalSourceView.currentChType = chType;
                                } else if (0 == group) {
                                    if ( channelGroupItem.bNormalShow )
                                        channelGroupItem.minShow();
                                    else
                                        channelGroupItem.normalShow();
                                }

                                // 控制组是否展开
                                if (0 == group) {
                                    if (0 == chType)
                                        signalSourceView.minPCGroup = (1 == signalSourceView.minPCGroup) ? 0 : 1;
                                    else if (3 == chType)
                                        signalSourceView.minHDGroup = (1 == signalSourceView.minHDGroup) ? 0 : 1;
                                    else if (8 == chType)
                                        signalSourceView.minVideoGroup = (1 == signalSourceView.minVideoGroup) ? 0 : 1;
                                    else if (9 == chType)
                                        signalSourceView.minIPVGroup = (1 == signalSourceView.minIPVGroup) ? 0 : 1;
                                }
                            }
                            onDoubleClicked: {
                                if (1 == group) {
                                    var gItem = roomTabView.getCurrentGroupDisplay();
                                    if (null != gItem) {
                                        gItem.appendDefaultWindow( chID );
                                    }
                                }
                            }
                        }
                    }
                }

                // 加载子对象
                Repeater {
                   model: subNode
                   delegate: signalSourceDelegate
                }
            }
        }

        ListView {  // 定义ListView
            id: signalSourceView
            width: mainWindow.mapToDeviceWidth(300)
            height: mainWindow.mapToDeviceHeight(600)
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            // 记录当前选中信号
            property int currentChID: 0;
            property int currentChType: 0;

            // 记录信号组的状态
            property int minPCGroup: 1
            property int minHDGroup: 1
            property int minVideoGroup: 1
            property int minIPVGroup: 1

            property int pccount: 0
            property int hdcount: 0
            property int videocount: 0
            property int ipvcount: 0

            model: channelModel
            delegate: signalSourceDelegate
        }
    }

    // 场景工具栏
    Rectangle {
        id: sceneView
        x: parent.width; y: 0; width: 0; height: parent.height;
        anchors.right: parent.right
//        anchors.rightMargin: -20     // 只要两个圆角
//        radius: 20
        clip: true

        color: "#3383A3AA"

//        // 添加阴影
//        layer.enabled: true
//        layer.effect: DropShadow {
//            transparentBorder: true
//            horizontalOffset: 5
//            verticalOffset: 5
//            radius: 8.0
//            samples: 16
//            color: "#44000000"
//        }

        // 当前显示场景的屏组ID
        property int gid: 0

        ListModel {
            id: sceneModel
        }

        Component {                   // 自定义代理
            id: sceneDelegate;

            Row {
                spacing: 20

                Rectangle {
                    color: "#00000000"
                    width: mainWindow.mapToDeviceWidth(300); height: mainWindow.mapToDeviceHeight(120);

                    // 场景按照屏组模式显示
                    Rectangle {
                        radius: 10
                        color: "#9EADB7";
                        clip: true
                        border.color: "white"
                        border.width: 2
                        width: parent.width; height: mainWindow.mapToDeviceHeight(100)
                        anchors.verticalCenter: parent.verticalCenter

                        // header
                        Rectangle {
                            id: sceneHeader
                            width: parent.width; height: mainWindow.mapToDeviceHeight(30)
                            color: "#00000000"
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: name
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter

                                color: "white"
                                font.family: "微软雅黑"
                                font.pixelSize: 15
                                font.bold: true
                                smooth: true
                                clip: true
                            }

                            MainToolBarButton {
                                id: delSceneBtn
                                image1: "resource/deleteScene1.png"
                                image2: "resource/deleteScene2.png"
                                x: parent.width-30; y: 1;
                                width: mainWindow.mapToDeviceWidth(28); height: mainWindow.mapToDeviceHeight(28)

                                onClicked: {
                                    // 删除场景
                                    sceneView.delScene( sid );
                                }
                            }
                            MainToolBarButton {
                                id: updateSceneBtn
                                image1: "resource/updateScene1.png"
                                image2: "resource/updateScene2.png"
                                x: parent.width-60; y: 1;
                                width: mainWindow.mapToDeviceWidth(28); height: mainWindow.mapToDeviceHeight(28)

                                onClicked: {
                                    // 更新场景
                                    var gItem = roomTabView.getCurrentGroupDisplay();
                                    if (null != gItem) {
                                        gItem.updateScene( sid );
                                    }
                                }
                            }
                        }

                        // body
                        Rectangle {
                            radius: 10
                            width: sceneHeader.width; height: parent.height-sceneHeader.height
                            anchors.top: sceneHeader.bottom
                            anchors.horizontalCenter: parent.horizontalCenter

                            property int dragLisence: 0         // 是否允许拖拽

                            Canvas {
                                width: parent.width; height: parent.height;
                                contextType: "2d";
                                onPaint: {
                                    var gItem = roomTabView.getCurrentGroupDisplay();
                                    for (var i = 0; i < sceneData.count; i++) {
                                        var chid = sceneData.get(i).chid;
                                        var winid = sceneData.get(i).winid;
                                        var l = sceneData.get(i).l;
                                        var t = sceneData.get(i).t;
                                        var w = sceneData.get(i).w;
                                        var h = sceneData.get(i).h;

                                        var vl = (l/gItem.actualWidth)*parent.width;
                                        var vr = ((l+w)/gItem.actualWidth)*parent.width;
                                        var vt = (t/gItem.actualHeight)*parent.height;
                                        var vb = ((t+h)/gItem.actualHeight)*parent.height;

                                        context.beginPath();

                                        // 1.绘制虚线，4分屏
                                        context.lineWidth = 1;
                                        context.strokeStyle = "gray";

                                        context.moveTo(vl, vt);
                                        context.lineTo(vr, vt);
                                        context.lineTo(vr, vb);
                                        context.lineTo(vl, vb);
                                        context.lineTo(vl, vt);

                                        context.stroke();
                                        context.closePath();
                                    }
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

                            // 拖拽事件
                            Drag.active: (1 == dragLisence) ? true : false;
                            Drag.supportedActions: Qt.CopyAction
                            Drag.dragType: Drag.Automatic
                            Drag.mimeData: {"sid":sid, "sname": name}
                            //Drag.imageSource: "resource/channelDragIcon.png"  // 全屏不显示

                            MouseArea {
                                anchors.fill: parent
                                onPressAndHold: {
                                    debugArea.appendLog( "scene onPressAndHold" )
                                    parent.dragLisence = 1;
                                }
                                onReleased: {
                                    parent.dragLisence = 0;
                                }
                                onDoubleClicked: {
                                    sceneView.gloadScene( sceneModel.get(index).sid );
                                }
                            }
                        }
                    }
                }
            }
        }

        ListView {  // 定义ListView
            id: sceneListView
            width: mainWindow.mapToDeviceWidth(300); height: mainWindow.mapToDeviceHeight(600)
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            clip: true

            model: sceneModel
            delegate: sceneDelegate
        }

        // 加载场景数据
        function loadScene() {
            var gItem = roomTabView.getCurrentGroupDisplay();
            if (gItem == null)
                return;

            sceneModel.clear();
            var sceneArr = mainMgr.getSceneList( gItem.groupID );
            for (var i = 0; i < sceneArr.length/2; i++) {
                var sceneid = sceneArr[i*2+0];
                var scenename = sceneArr[i*2+1];

                var sceneDataArr = mainMgr.getSceneData(gItem.groupID, sceneid);
                var lst = new Array;
                for (var j = 0; j < sceneDataArr.length/6; j++) {
                    var chid = sceneDataArr[j*6+0];
                    var winid = sceneDataArr[j*6+1];
                    var l = sceneDataArr[j*6+2];
                    var t = sceneDataArr[j*6+3];
                    var w = sceneDataArr[j*6+4];
                    var h = sceneDataArr[j*6+5];

                    lst.push({'chid':chid, 'winid':winid, 'l':l, 't':t, 'w':w, 'h':h});
                }

                // 添加场景
                appendScene(sceneid, scenename, lst);
            }
        }

        // 调用场景并显示UI
        function gloadScene( sid ) {
            debugArea.appendLog("gload "+sid)
            var gItem = roomTabView.getCurrentGroupDisplay();
            if (gItem == null)
                return;

            // 1.调用指令
            gItem.gload( sid );

            // 2.清屏，不发送指令
            gItem.greset( false );

            // 3.循环添加场景
            for (var i = 0; i < sceneModel.count; i++) {
                if (sceneModel.get(i).sid != sid)
                    continue;

                for (var j = 0; j < sceneModel.get(i).sceneData.count; j++) {
                    var chid = sceneModel.get(i).sceneData.get(j).chid;
                    var winid = sceneModel.get(i).sceneData.get(j).winid;
                    var l = sceneModel.get(i).sceneData.get(j).l;
                    var t = sceneModel.get(i).sceneData.get(j).t;
                    var w = sceneModel.get(i).sceneData.get(j).w;
                    var h = sceneModel.get(i).sceneData.get(j).h;

                    gItem.appendSignalWindow(chid, winid, l, t, w, h);
                }
            }
        }

        // 添加场景
        function appendScene(sid, sname, lst) {
            var data = {'sid':sid,'name':sname,'sceneData':lst};
            sceneModel.append( data );
        }

        // 删除场景
        function delScene( sid ) {
            var gItem = roomTabView.getCurrentGroupDisplay();
            if (gItem == null)
                return;

            if (0 === mainWindow.g_connectMode) {
                for (var i = 0; i < sceneModel.count; i++) {
                    if (sceneModel.get(i).sid == sid) {
                        sceneModel.remove( sceneModel.get(i).index );   // ??? 索引取法可能不对
                    }
                }
            }

            // 通知后端
            mainMgr.delScene(gItem.groupID, sid);
        }
    }

    // 主操作界面
    Rectangle {
        id: roomTabView
        x: 0; y: 0; width: parent.width; height: parent.height;

        color: "#2283A3AA"

//        // 添加阴影
//        layer.enabled: true
//        layer.effect: DropShadow {
//            transparentBorder: true
//            horizontalOffset: 5
//            verticalOffset: 5
//            radius: 8.0
//            samples: 16
//            color: "#44000000"
//        }

        property var groupDisplayList: []
        property Component groupComponent: null

        // 屏组管理文件夹
        Rectangle {
            id: roomFolder
            color: "#3383A3AA"
            radius: 10
            width: mainWindow.mapToDeviceWidth(220)
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }

        // 清屏
        function greset() {
            var groupItem = getCurrentGroupDisplay();
            groupItem.greset( true );
        }
        // 回显
        function preview() {
            bPreview = !bPreview;

            for (var i = 0; i < roomTabView.groupDisplayList.length; i++) {
                var groupDisplay = roomTabView.groupDisplayList[ i ];
                if (null == groupDisplay)
                    continue;

                groupDisplay.preview();
            }
        }
        // 置顶gid的屏组，当前z为cz
        function setGroupDisplayTop(gid, cz) {
            var maxZ = 0;
            for (var i = 0; i < roomTabView.groupDisplayList.length; i++) {
                var groupDisplay = roomTabView.groupDisplayList[ i ];
                if (null == groupDisplay)
                    continue;

                maxZ = Math.max(maxZ, groupDisplay.z);
            }

            for (i = 0; i < roomTabView.groupDisplayList.length; i++) {
                groupDisplay = roomTabView.groupDisplayList[ i ];
                if (groupDisplay.groupID == gid) {
                    // 置顶
                    groupDisplay.z = maxZ;
                } else if (groupDisplay.z == maxZ) {
                    groupDisplay.z = cz;
                }
            }
            // 切换场景
            if (maxZ != cz) {
                sceneView.loadScene();
            }
        }
        // 是否是最顶层
        function isTopGroupDisplay( gid ) {
            var maxZ = 0;
            for (var i = 0; i < roomTabView.groupDisplayList.length; i++) {
                var groupDisplay = roomTabView.groupDisplayList[ i ];
                if (null == groupDisplay)
                    continue;

                maxZ = Math.max(maxZ, groupDisplay.z);
            }

            for (i = 0; i < roomTabView.groupDisplayList.length; i++) {
                groupDisplay = roomTabView.groupDisplayList[ i ];
                if (groupDisplay.groupID == gid) {
                    return (groupDisplay.z == maxZ);
                }
            }

            return false;
        }
        // 返回当前groupDisplay
        function getCurrentGroupDisplay() {
            var maxZ = 0;
            for (var i = 0; i < roomTabView.groupDisplayList.length; i++) {
                var groupDisplay = roomTabView.groupDisplayList[ i ];
                if (null == groupDisplay)
                    continue;

                maxZ = Math.max(maxZ, groupDisplay.z);
            }

            for (var i = 0; i < roomTabView.groupDisplayList.length; i++) {
                groupDisplay = roomTabView.groupDisplayList[ i ];
                if (groupDisplay.z == maxZ) {
                    return groupDisplay;
                }
            }
        }
        // 返回id的屏组
        function getGroupDisplay( gid ) {
            for (var i = 0; i < roomTabView.groupDisplayList.length; i++) {
                var groupDisplay = roomTabView.groupDisplayList[ i ];
                if (groupDisplay.groupID == gid) {
                    return groupDisplay;
                }
            }

            return null;
        }
    }

    // 预监窗口
    PreviewToolBarItem {
        id: priviewToolBar
        visible: false
    }

    // 信号源工具条动画
    ParallelAnimation {
        id: showSignalAnimation;

        NumberAnimation { target: signalSource; property: "width"; from: 0; to: mainWindow.mapToDeviceWidth(300); duration: 200}
        NumberAnimation { target: roomTabView; property: "x"; from: 0; to: mainWindow.mapToDeviceWidth(300); duration: 200}
        NumberAnimation { target: roomTabView; property: "width"; from: roomTabView.width; to: roomTabView.width-mainWindow.mapToDeviceWidth(300); duration: 200}
    }
    ParallelAnimation {
        id: hideSignalAnimation;

        NumberAnimation { target: signalSource; property: "width"; from: mainWindow.mapToDeviceWidth(300); to: 0; duration: 200}
        NumberAnimation { target: roomTabView; property: "x"; from: mainWindow.mapToDeviceWidth(300); to: 0; duration: 200}
        NumberAnimation { target: roomTabView; property: "width"; from: roomTabView.width; to: roomTabView.width+mainWindow.mapToDeviceWidth(300); duration: 200}
    }

    function setSignalToolBarVisible() {
        bSignalViewShow = !bSignalViewShow;

        // resize group first 因为函数内对roomTabView进行取值了，后执行可能有偏差
        for (var i = 0; i < roomTabView.groupDisplayList.length; i++) {
            var groupDisplay = roomTabView.groupDisplayList[ i ];
            var tWidth = mainWindow.mapToDeviceWidth(300);
            groupDisplay.resizeGroupDisplay(bSignalViewShow ? -1*tWidth : tWidth, 0);
        }

        // resize roomTabView
        if ( bSignalViewShow )
            showSignalAnimation.start();
        else
            hideSignalAnimation.start();
    }

    // 场景工具条动画
    ParallelAnimation {
        id: showSceneAnimation;

        NumberAnimation { target: sceneView; property: "width"; from: 0; to: mainWindow.mapToDeviceWidth(300); duration: 200}
        NumberAnimation { target: roomTabView; property: "width"; from: roomTabView.width; to: roomTabView.width-mainWindow.mapToDeviceWidth(300); duration: 200}
    }
    ParallelAnimation {
        id: hideSceneAnimation;

        NumberAnimation { target: sceneView; property: "width"; from: mainWindow.mapToDeviceWidth(300); to: 0; duration: 200}
        NumberAnimation { target: roomTabView; property: "width"; from: roomTabView.width; to: roomTabView.width+mainWindow.mapToDeviceWidth(300); duration: 200}
    }
    function setSceneToolBarVisible() {
        bSceneViewShow = !bSceneViewShow;

        // resize group first 因为函数内对roomTabView进行取值了，后执行可能有偏差
        for (var i = 0; i < roomTabView.groupDisplayList.length; i++) {
            var groupDisplay = roomTabView.groupDisplayList[ i ];
            var fWidth = mainWindow.mapToDeviceWidth(300);
            groupDisplay.resizeGroupDisplay(bSceneViewShow ? -1*fWidth : fWidth, 0);
        }

        // resize roomTabView
        if ( bSceneViewShow )
            showSceneAnimation.start();
        else
            hideSceneAnimation.start();
    }

    function setEchoVisible() {
        roomTabView.preview();
    }

    function setPreviewVisible() {
        bPreviewShow = !bPreviewShow;
        priviewToolBar.setVisible( bPreviewShow );
    }

    function resetGroupDislay() {
        roomTabView.greset();
    }

    // 初始化输入通道
    function appendRoot() {
        channelModel.append({"name":"电脑","chID":"-1","chType":"0","group":0,"subNode":[]})
        channelModel.append({"name":"高清","chID":"-1","chType":"3","group":0,"subNode":[]})
        channelModel.append({"name":"Video","chID":"-1","chType":"8","group":0,"subNode":[]})
        channelModel.append({"name":"IPVideo","chID":"-1","chType":"9","group":0,"subNode":[]})
    }

    function appendChannel(chid, chtype, chname) {
        var rootIndex = 0;
        if (chtype == 0) {
            signalSourceView.pccount++;
        } else if (chtype == 3) {
            rootIndex = 1;
            signalSourceView.hdcount++;
        } else if (chtype == 8) {
            rootIndex = 2;
            signalSourceView.videocount++;
        } else if (chtype == 9) {
            rootIndex = 3;
            signalSourceView.ipvcount++;
        }

        channelModel.get(rootIndex).subNode.append({"name":chname,"chID":chid,"chType":chtype,"group":1,"subNode":[]})
    }

    // 添加房间布局
    function appendRoom(gid, gname, arrX, arrY, sizeX, sizeY) {
        // 加载组件
        if (roomTabView.groupComponent == null) {
            roomTabView.groupComponent = Qt.createComponent( "GroupDisplayItem.qml" );
        }

        var groupDisplay = roomTabView.groupComponent.createObject(roomTabView, {"groupID": gid, "groupName": gname, "actualWidth": sizeX,
                                                                       "actualHeight":sizeY, "arrayX":arrX, "arrayY":arrY,
                                                                       "x": gid*mainWindow.mapToDeviceWidth(50),
                                                                       "y": gid*mainWindow.mapToDeviceHeight(50), "z": gid,
                                                                       "width": mainWindow.mapToDeviceWidth(800),
                                                                       "height": mainWindow.mapToDeviceHeight(400)} );

        // 将新加房间添加到链表
        roomTabView.groupDisplayList.push( groupDisplay );
    }

    function appendSignalWindow(gid, chid, winid, cx, cy, cw, ch) {
        for (var i = 0; i < roomTabView.groupDisplayList.length; i++) {
            var groupDisplay = roomTabView.groupDisplayList[ i ];
            if (null == groupDisplay)
                continue;

            if (groupDisplay.groupID == gid) {
                groupDisplay.appendSignalWindow(chid, winid, cx, cy, cw, ch);
            }
        }
    }

    function serverSignalWindowResizeLiscene(gid, winid) {
        var gItem = roomTabView.getGroupDisplay( gid );
        if (null == gItem)
            return;

        var sigItem = gItem.getSignalWindow( winid );
        if (null == sigItem)
            return;

        sigItem.bResizeLiscene = true;
    }

    function serverWinsize(gid, winid, chid, l, t, w, h) {
        var gItem = roomTabView.getGroupDisplay( gid );
        if (null == gItem)
            return;

        var sigItem = gItem.getSignalWindow( winid );
        if (null == sigItem) {
            // 新建不发送指令
            gItem.appendSignalWindow(chid, winid, l, t, w, h);
        } else {
            // ??? 如果chid有变化则需要修改标题

            // 移动不发送指令
            gItem.serverResizeSignalWindow(winid, l, t, w, h);
            // 置顶
            gItem.setSignalWindowTop( winid );
        }
    }

    function serverWinswitch(gid, winid) {
        var gItem = roomTabView.getGroupDisplay( gid );
        if (null == gItem)
            return;

        gItem.removeSignalWindow(winid, false);
    }

    function serverReset( gid ) {
        var gItem = roomTabView.getGroupDisplay( gid );
        if (null == gItem)
            return;

        gItem.greset( false );
    }

    // 调用场景并显示UI
    function serverLoadScene(gid, sid) {
        var gItem = roomTabView.getGroupDisplay( gid );
        if (gItem == null)
            return;

        // 1.清屏，不发送指令
        gItem.greset( false );

        // 2.循环添加场景
        for (var i = 0; i < sceneModel.count; i++) {
            if (sceneModel.get(i).sid != sid)
                continue;

            for (var j = 0; j < sceneModel.get(i).sceneData.count; j++) {
                var chid = sceneModel.get(i).sceneData.get(j).chid;
                var winid = sceneModel.get(i).sceneData.get(j).winid;
                var l = sceneModel.get(i).sceneData.get(j).l;
                var t = sceneModel.get(i).sceneData.get(j).t;
                var w = sceneModel.get(i).sceneData.get(j).w;
                var h = sceneModel.get(i).sceneData.get(j).h;

                gItem.appendSignalWindow(chid, winid, l, t, w, h);
            }
        }
    }

    function serverChangeLockState(gid, bLock) {
        var gItem = roomTabView.getGroupDisplay( gid );
        if (null == gItem)
            return;

        gItem.bLock = bLock;
    }

    function refreshCurrentSceneList() {
        sceneView.loadScene();
    }

    function refreshSceneToolBar() {
        if ( bSceneViewShow ) {
            sceneView.loadScene();
        }
    }
}
