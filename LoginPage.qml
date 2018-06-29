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

        MouseArea {
            anchors.fill: parent
            onDoubleClicked: {
                debugArea.visible = !debugArea.visible;
            }
        }
    }

    // login
    Rectangle {
        id: loginArea
        y: parent.height-200;
        width: 200; height: 180;
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
            y: 40
            width: 180; height: 30;
            anchors.horizontalCenter: loginArea.horizontalCenter

            visible: (pageIndex == 0) ? true : false;
            color: "#00000000"

            // 内部偏移像素值没有规律，只是为了样式调整
            Rectangle {
                id: userIcon
                x: 5; y: 4
                width: 22; height: 22

                color: "#00000000"

                Image {
                    anchors.fill: parent
                    fillMode: Image.Stretch
                    source: "resource/loginUsr.png"
                }
            }
            TextField {
                id: user
                x: 40
                width: 130; height: 30

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
            y: 75
            width: 180; height: 30
            anchors.horizontalCenter: loginArea.horizontalCenter

            visible: (pageIndex == 0) ? true : false;
            color: "#00000000"

            // 内部偏移像素值没有规律，只是为了样式调整
            Rectangle {
                id: passwordIcon
                x: 5; y: 4
                width: 22; height: 22

                color: "#00000000"

                Image {
                    anchors.fill: parent
                    fillMode: Image.Stretch
                    source: "resource/loginPsw.png"
                }
            }

            TextField {
                id: password
                x: 40
                width: 130; height: 30

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
            y: 40
            width: 180; height: 30;
            anchors.horizontalCenter: loginArea.horizontalCenter

            visible: (pageIndex == 1) ? true : false;
            color: "#00000000"

            // 内部偏移像素值没有规律，只是为了样式调整
            Rectangle {
                width: 35; height: 30;
                color: "#00000000"

                Text {
                    text: qsTr("IP")
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            TextField {
                id: ip
                x: 40
                width: 130; height: 30

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
            y: 75
            width: 180; height: 30
            anchors.horizontalCenter: loginArea.horizontalCenter

            visible: (pageIndex == 1) ? true : false;
            color: "#00000000"

            // 内部偏移像素值没有规律，只是为了样式调整
            Rectangle {
                width: 35; height: 30;
                color: "#00000000"

                Text {
                    text: qsTr("PORT")
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            TextField {
                id: port
                x: 40
                width: 130; height: 30

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
            x: 20; y: 113
            width: 180; height: 15

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
            x: 20; y: 113
            width: 180; height: 15

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
            x: 25; y: 135
            width: 70; height: 30

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
                    // 首先保存变量
                    mainMgr.welcomePageBaseInfo_user = user.text;
                    mainMgr.welcomePageBaseInfo_password = password.text;
                    mainMgr.welcomePageBaseInfo_savePassword = savePswCheckBox.checked ? "1" : "0";
                    mainMgr.welcomePageBaseInfo_ip = ip.text;
                    mainMgr.welcomePageBaseInfo_port = port.text;
                    mainMgr.welcomePageBaseInfo_unionControl = unionCtrlCheckBox.checked ? "1" : "0";
                    mainMgr.SaveWelcomePageBaseInfo();

                    // login
                    mainMgr.Login();
                } else {
                    // 如果是设置页则直接返回到登录界面
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
            x: 105; y: 135
            width: 70; height: 30

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
