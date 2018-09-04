import QtQuick 2.0
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

Rectangle {
    anchors.fill: parent

    // 页标识，0：用户名&密码，1：IP&Port
    property int pageIndex: 0

    // background
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

//        MouseArea {
//            anchors.fill: parent
//            onDoubleClicked: {
//                debugArea.visible = !debugArea.visible;
//            }
//        }
    }

    // login
    Rectangle {
        id: loginArea
        y: parent.height-mainWindow.mapToDeviceHeight(260);
        width: mainWindow.mapToDeviceWidth(400); height: mainWindow.mapToDeviceHeight(240);
        anchors.horizontalCenter: parent.horizontalCenter

        color: "#00000000"

        // 添加阴影
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 3
            verticalOffset: 3
            radius: 8.0
            samples: 16
            color: "#44000000"
        }

        Image {
            anchors.fill: parent
            fillMode: Image.Stretch
            source: "resource/loginGroup.png"
        }

        // user
        Rectangle {
            y: mainWindow.mapToDeviceHeight(45)
            width: mainWindow.mapToDeviceWidth(360); height: mainWindow.mapToDeviceHeight(50);
            anchors.horizontalCenter: loginArea.horizontalCenter

            visible: (pageIndex == 0) ? true : false;
            color: "#00000000"

            // 内部偏移像素值没有规律，只是为了样式调整
            Rectangle {
                id: userIcon
                x: mainWindow.mapToDeviceWidth(5); y: mainWindow.mapToDeviceHeight(5)
                width: mainWindow.mapToDeviceWidth(40); height: mainWindow.mapToDeviceHeight(40)

                color: "#00000000"

                Image {
                    anchors.fill: parent
                    fillMode: Image.Stretch
                    source: "resource/loginUsr.png"
                }
            }
            TextField {
                id: user
                x: mainWindow.mapToDeviceWidth(80)
                width: mainWindow.mapToDeviceWidth(280); height: mainWindow.mapToDeviceHeight(50)

                placeholderText: "user"

                background: Rectangle{
                    color: "#F0F8FF"
                    border.color: "gray"
                    radius: 5
                }
            }
        }
        // password
        Rectangle {
            y: mainWindow.mapToDeviceHeight(100)
            width: mainWindow.mapToDeviceWidth(360); height: mainWindow.mapToDeviceHeight(50);
            anchors.horizontalCenter: loginArea.horizontalCenter

            visible: (pageIndex == 0) ? true : false;
            color: "#00000000"

            // 内部偏移像素值没有规律，只是为了样式调整
            Rectangle {
                id: passwordIcon
                x: mainWindow.mapToDeviceWidth(5); y: mainWindow.mapToDeviceHeight(5);
                width: mainWindow.mapToDeviceWidth(40); height: mainWindow.mapToDeviceHeight(40);

                color: "#00000000"

                Image {
                    anchors.fill: parent
                    fillMode: Image.Stretch
                    source: "resource/loginPsw.png"
                }
            }

            TextField {
                id: password
                x: mainWindow.mapToDeviceWidth(80)
                width: mainWindow.mapToDeviceWidth(280); height: mainWindow.mapToDeviceHeight(50);

                placeholderText: "password"

                background: Rectangle{
                    color: "#F0F8FF"
                    border.color: "gray"
                    radius: 5
                }
            }
        }

        // ip
        Rectangle {
            y: mainWindow.mapToDeviceHeight(45)
            width: mainWindow.mapToDeviceWidth(360); height: mainWindow.mapToDeviceHeight(50);
            anchors.horizontalCenter: loginArea.horizontalCenter

            visible: (pageIndex == 1) ? true : false;
            color: "#00000000"

            // 内部偏移像素值没有规律，只是为了样式调整
            Rectangle {
                x: mainWindow.mapToDeviceWidth(5);
                width: mainWindow.mapToDeviceWidth(65); height: mainWindow.mapToDeviceHeight(50);
                color: "#00000000"

                Text {
                    text: qsTr("IP")
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "微软雅黑"
                    font.pixelSize: 12
                }
            }
            TextField {
                id: ip
                x: mainWindow.mapToDeviceWidth(80)
                width: mainWindow.mapToDeviceWidth(280); height: mainWindow.mapToDeviceHeight(50);
                clip: true;

                placeholderText: "IP"

                background: Rectangle{
                    color: "#F0F8FF"
                    border.color: "gray"
                    radius: 5
                }
            }
        }
        // port
        Rectangle {
            y: mainWindow.mapToDeviceHeight(100);
            width: mainWindow.mapToDeviceWidth(360); height: mainWindow.mapToDeviceHeight(50);
            anchors.horizontalCenter: loginArea.horizontalCenter

            visible: (pageIndex == 1) ? true : false;
            color: "#00000000"

            // 内部偏移像素值没有规律，只是为了样式调整
            Rectangle {
                x: mainWindow.mapToDeviceWidth(5);
                width: mainWindow.mapToDeviceWidth(65); height: mainWindow.mapToDeviceHeight(50);
                color: "#00000000";
                clip: true;

                Text {
                    text: qsTr("PORT")
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "微软雅黑"
                    font.pixelSize: 12
                }
            }

            TextField {
                id: port
                x: mainWindow.mapToDeviceWidth(80);
                width: mainWindow.mapToDeviceWidth(280); height: mainWindow.mapToDeviceHeight(50);

                placeholderText: "PORT"

                background: Rectangle{
                    color: "#F0F8FF"
                    border.color: "gray"
                    radius: 5
                }
            }
        }
        // save password or sync
        Rectangle {
            x: mainWindow.mapToDeviceWidth(30); y: mainWindow.mapToDeviceHeight(155);
            width: mainWindow.mapToDeviceWidth(360); height: mainWindow.mapToDeviceHeight(30);

            visible: (pageIndex == 0) ? true : false;
            color: "#00000000"
            CheckBox {
                id: savePswCheckBox
                anchors.fill: parent
                text: {
                    if (0 == mainWindow.language) {
                        text: qsTr("记住密码");
                    } else {
                        qsTr("save password");
                    }
                }

                indicator: Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 15
                    implicitHeight: 15
                    radius: 1
                    border.width: 1
                    border.color: "#00000000"

                    Image {
                        anchors.fill: parent
                        fillMode: Image.Stretch
                        source: savePswCheckBox.checked ? "resource/checked.png" : "resource/unchecked.png";
                    }
                }
            }
        }
        // union control
        Rectangle {
            x: mainWindow.mapToDeviceWidth(30); y: mainWindow.mapToDeviceHeight(155);
            width: mainWindow.mapToDeviceWidth(360); height: mainWindow.mapToDeviceHeight(30);

            visible: (pageIndex == 0) ? false : true;
            color: "#00000000"
            CheckBox {
                id: unionCtrlCheckBox
                anchors.fill: parent
                text: {
                    if (0 == mainWindow.language) {
                        qsTr("联控");
                    } else {
                        qsTr("union control");
                    }
                }

                indicator: Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 15
                    implicitHeight: 15
                    radius: 1
                    border.width: 1
                    border.color: "#00000000"

                    Image {
                        anchors.fill: parent
                        fillMode: Image.Stretch
                        source: unionCtrlCheckBox.checked ? "resource/checked.png" : "resource/unchecked.png";
                    }
                }
            }
        }

        // button-login
        Button {
            text: {
                if (0 == mainWindow.language) {
                    (pageIndex == 0) ? qsTr("登  录") : qsTr("确  定")
                } else {
                    (pageIndex == 0) ? qsTr("Login") : qsTr("Sure")
                }
            }
            x: mainWindow.mapToDeviceWidth(30); y: mainWindow.mapToDeviceHeight(190);
            width: mainWindow.mapToDeviceWidth(160); height: mainWindow.mapToDeviceHeight(40);

            font.family: "微软雅黑"
            font.pixelSize: 14
            //font.bold: true

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
                color: "#00A4FF"
            }

            onClicked: {
                if (pageIndex == 0) {
                    // 如果是服务器则直接登录
                    if ( unionCtrlCheckBox.checked ) {
                        mainWindow.g_connectMode = 1;
                        mainMgr.welcomePageBaseInfo_user = user.text;
                        mainMgr.welcomePageBaseInfo_password = password.text;
                        mainMgr.welcomePageBaseInfo_savePassword = savePswCheckBox.checked ? "1" : "0";
                        mainMgr.welcomePageBaseInfo_ip = ip.text;
                        mainMgr.welcomePageBaseInfo_port = port.text;
                        mainMgr.welcomePageBaseInfo_unionControl = "1";
                        mainMgr.welcomePageBaseInfo_previewip = ip.text;
                        mainMgr.welcomePageBaseInfo_previewport = port.text;
                        mainMgr.SaveWelcomePageBaseInfo();

                        // login
                        mainMgr.LoginByServer();
                    } else {
                        mainWindow.g_connectMode = 0;
                        mainMgr.welcomePageBaseInfo_user = user.text;
                        mainMgr.welcomePageBaseInfo_password = password.text;
                        mainMgr.welcomePageBaseInfo_savePassword = savePswCheckBox.checked ? "1" : "0";
                        mainMgr.welcomePageBaseInfo_unionControl = "0";
                        mainMgr.SaveWelcomePageBaseInfo();

                        mainMgr.Authentication();
                    }
                } else {
                    pageIndex = 0;
                }
            }
        }

        // button-set
        Button {
            text: {
                if (0 == mainWindow.language) {
                    (pageIndex == 0) ? qsTr("设  置") : qsTr("返  回");
                } else {
                    (pageIndex == 0) ? qsTr("Set") : qsTr("Back");
                }
            }
            x: mainWindow.mapToDeviceWidth(220); y: mainWindow.mapToDeviceHeight(190);
            width: mainWindow.mapToDeviceWidth(160); height: mainWindow.mapToDeviceHeight(40);

            font.family: "微软雅黑"
            font.pixelSize: 14
            //font.bold: true

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
                color: "#00A4FF"
            }

            onClicked: {
                // 只负责切换界面
                pageIndex = (0 == pageIndex) ? 1 : 0;
            }
        }
    }

    Component.onCompleted: {
        // 初始化欢迎页
        user.text = mainMgr.welcomePageBaseInfo_user;
        password.text = mainMgr.welcomePageBaseInfo_password;
        savePswCheckBox.checked = (1 == mainMgr.welcomePageBaseInfo_savePassword) ? true : false;
        ip.text = mainMgr.welcomePageBaseInfo_ip;
        port.text = mainMgr.welcomePageBaseInfo_port;
        unionCtrlCheckBox.checked = (1 == mainMgr.welcomePageBaseInfo_unionControl) ? true : false;
    }
}
