import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Window 2.2

import com.MainManager 1.0

ApplicationWindow {
    id: mainWindow
    visible: true
    title: qsTr("拼控软件")
    visibility: Window.FullScreen

    // 页面索引,0:欢迎界面，1:操作界面，2:选择设备界面
    property int pageIndex: 0

    // 语言索引，0：中文；1：英文
    property int language: 1

    // 连接模式，0：单机(演示)；1：联控
    property int g_connectMode: 0

    signal sigGWinsize(int gid, int winid, int chid, int l, int t, int r, int b);

    // 功能球
    SuspendBallItem {
        id: suspendBall
        x: parent.width-100; y: parent.height/2
        z: 255

        visible: true
    }

    // 登录界面
    LoginPage {
        id: loginPage

        visible: mainWindow.pageIndex == 0
    }

    // 搜索设备界面
    SearchDevicePage {
        id: searchPage

        visible: mainWindow.pageIndex == 2
    }

    // 主操作界面
    OperatePage {
        id: operatePage

        visible: mainWindow.pageIndex == 1
    }

    // debug输出
    TextEdit {
        id: debugArea
        objectName: "debugArea"                 // c++ 外部调用

        visible: false;

        y: 100                  // 和主工具条一样高
        width: 200
        height: 400
        anchors.right: parent.right

        color: "#32CD32";
        clip: true;

        readOnly: true
        wrapMode: TextEdit.WrapAnywhere

        enabled: false

        function appendLog( text ) {
            // 如果日志超出clip范围直接清除，可考虑修改成滚动条式显示
            if (debugArea.implicitHeight > parent.height)
                debugArea.clear();

            debugArea.append( text )
        }
    }

    // 错误提醒
    Rectangle {
        id: errorMessageBox
        visible: false

        width: 120; height: 50;
        anchors.centerIn: parent
        color: "#3B3B3B"
        radius: 5
        border.width: 1
        border.color: "#FCFCFC"

        Rectangle {
            width: height; height: parent.height/2;
            anchors.top: parent.top;
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#00000000"

            Image {
                anchors.fill: parent
                fillMode: Image.Stretch
                source: "resource/errorMessageBox.png"
            }
        }

        Rectangle {
            width: parent.width; height: parent.height/2;
            anchors.bottom: parent.bottom;
            color: "#00000000"

            Text {
                id: errorMessageBoxText
                text: qsTr("网络连接中断")
                anchors.centerIn: parent

                color: "#FCFCFC"
            }
        }

        PropertyAnimation {
            id: errorMessageBoxAnimation
            target: errorMessageBox
            properties: "opacity"
            from: 1.0;
            to: 0.0;
            duration: 1200;
        }
    }

    function showErrorMessageBox( type ) {
        if (1 == type) {
            errorMessageBoxText.text = "获取规模失败."
        } else if (2 == type) {
            errorMessageBoxText.text = "用户鉴权失败."
        }

        errorMessageBox.visible = true;
        errorMessageBox.opacity = 1.0;
        errorMessageBoxAnimation.start();
    }

    function onVP4000Config(lstInputChannel, lstGroupDisplay, lstDefaultScene) {
        debugArea.appendLog( lstGroupDisplay );
        console.log(lstGroupDisplay)
        // 1.输入通道
        var pcIndex = 1;
        var ipvIndex = 1;
        operatePage.appendRoot();
        for (var i = 0; i < lstInputChannel.length/3; i++) {
            var chid = lstInputChannel[i*3+0];
            var chtype = lstInputChannel[i*3+1];
            var chname = lstInputChannel[i*3+2];
            if (0 == chtype)
                chname = "PC"+(pcIndex++);
            else
                chname = "IPV"+(ipvIndex++);
            operatePage.appendChannel(chid, chtype, chname);
        }

        // 2.屏组信息
        for (i = 0; i < lstGroupDisplay.length/6; i++) {
            var groupid = lstGroupDisplay[i*6+0];
            //var groupname = "GROUP"+(groupid+1);//lstGroupDisplay[i*6+1];
            var groupname = "GROUP";
            if (1 === groupid)
                groupname = "55\"LCD 4x3 - VP 4800";
            if (2 === groupid)
                groupname = "P1.25LED 1920x1080";
            if (3 === groupid)
                groupname = "VP6000";
            if (4 === groupid)
                groupname = "Agent Controllor";
            if (5 === groupid)
                groupname = "4K Output";
            //var groupname = lstGroupDisplay[i*6+1];
            var formatx = lstGroupDisplay[i*6+2];
            var formaty = lstGroupDisplay[i*6+3];
            var xsize = lstGroupDisplay[i*6+4];
            var ysize = lstGroupDisplay[i*6+5];
            operatePage.appendRoom(groupid, groupname, formatx, formaty, xsize, ysize);
        }

        // 3.添加信号窗
        for (i = 0; i < lstDefaultScene.length/7; i++) {
            var nGroupDisplayID = lstDefaultScene[7*i+0];
            var winid = lstDefaultScene[7*i+1];
            chid = lstDefaultScene[7*i+2];
            var left = lstDefaultScene[7*i+3];
            var top = lstDefaultScene[7*i+4];
            var width = lstDefaultScene[7*i+5];
            var height = lstDefaultScene[7*i+6];

            // 循环添加窗口
            operatePage.appendSignalWindow(nGroupDisplayID, chid, winid, left, top, width, height);
        }

        // 4.翻页
        mainWindow.pageIndex = 1;
    }
    function serverAppendOnlineDevice(name, ip, port, mask, gateway, mac) {
        searchPage.serverAppendOnlineDevice(name, ip, port, mask, gateway, mac);
    }
    function serverAppendOnlinePreview(ip, port, mac) {
        searchPage.serverAppendOnlinePreview(ip, port, mac);
    }

    function serverChangePage(i) {
        mainWindow.pageIndex = i;
    }

    function serverSignalWindowResizeLiscene(gid, winid) {
        operatePage.serverSignalWindowResizeLiscene(gid, winid);
    }

    function serverWinsize(gid, winid, chid, l, t, w, h) {
        operatePage.serverWinsize(gid, winid, chid, l, t, w, h);
    }

    function serverWinswitch(gid, winid) {
        operatePage.serverWinswitch(gid, winid);
    }

    function serverReset( gid ) {
        operatePage.serverReset( gid );
    }

    function serverLoadScene(gid, sid) {
        operatePage.serverLoadScene(gid, sid);
    }

    function refreshCurrentSceneList() {
        operatePage.refreshCurrentSceneList();
    }

    function serverChangeLockState(gid, bLock) {
        operatePage.serverChangeLockState(gid, bLock);
    }

    // 所有尺寸按照1920*1080标准转换
    function mapToDeviceWidth( w ) {
        return Screen.width*w/1920;
    }
    function mapToDeviceHeight( h ) {
        return Screen.height*h/1080;
    }

    Component.onCompleted: {    // 加载完成后调用
        var result

        debugArea.appendLog( "UI completed, w:"+Screen.width+",h:"+Screen.height );
        console.log(Screen.width, Screen.height)
    }
}

