import QtQuick 2.4
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

Rectangle {
    anchors.fill: parent

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
    }

    // 控制IP和端口
    Rectangle {
        y: mainWindow.mapToDeviceHeight(100)
        width: mainWindow.mapToDeviceWidth(1600); height: mainWindow.mapToDeviceHeight(80);
        anchors.horizontalCenter: parent.horizontalCenter
        color: "#00000000"

        // device ip
        Rectangle {
            width: mainWindow.mapToDeviceWidth(100); height: mainWindow.mapToDeviceHeight(80);
            color: "#00000000"

            Text {
                text: qsTr("设备IP")
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                font.family: "微软雅黑"
                font.pixelSize: 12
            }
        }
        TextField {
            id: deviceip
            x: mainWindow.mapToDeviceWidth(200)
            width: mainWindow.mapToDeviceWidth(500); height: mainWindow.mapToDeviceHeight(80);
            clip: true;

            placeholderText: "Device IP"
            font.family: "微软雅黑"
            font.pixelSize: 12
        }

        // device port
        Rectangle {
            x: mainWindow.mapToDeviceWidth(900)
            width: mainWindow.mapToDeviceWidth(100); height: mainWindow.mapToDeviceHeight(80);
            color: "#00000000"

            Text {
                text: qsTr("设备端口")
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                font.family: "微软雅黑"
                font.pixelSize: 12
            }
        }
        TextField {
            id: deviceport
            x: mainWindow.mapToDeviceWidth(1100)
            width: mainWindow.mapToDeviceWidth(500); height: mainWindow.mapToDeviceHeight(80);
            clip: true;

            placeholderText: "Device port"
            font.family: "微软雅黑"
            font.pixelSize: 12
        }
    }

    Rectangle {
        y: mainWindow.mapToDeviceHeight(200)
        width: mainWindow.mapToDeviceWidth(1600); height: mainWindow.mapToDeviceHeight(250)
        anchors.horizontalCenter: parent.horizontalCenter
        color: "#00000000"

        // background
        Image {
            anchors.fill: parent

            fillMode: Image.Stretch
            source: "resource/background.png"
        }

        TableView{  //定义table的显示，包括定制外观
            id: deviceTableView
            anchors.fill: parent
            TableViewColumn{role: "name"; title: "名称"; width: mainWindow.mapToDeviceWidth(200); elideMode: Text.ElideRight;}
            TableViewColumn{role: "ip"; title: "IP"; width: mainWindow.mapToDeviceWidth(300); elideMode: Text.ElideRight;}
            TableViewColumn{role: "port";title: "端口"; width: mainWindow.mapToDeviceWidth(200); elideMode: Text.ElideRight;}
            TableViewColumn{role: "mask";title: "子网掩码"; width: mainWindow.mapToDeviceWidth(300); elideMode: Text.ElideRight;}
            TableViewColumn{role: "gateway";title: "网关"; width: mainWindow.mapToDeviceWidth(300); elideMode: Text.ElideRight;}
            TableViewColumn{role: "mac";title: "Mac地址"; width: mainWindow.mapToDeviceWidth(300); elideMode: Text.ElideRight;}

            itemDelegate: Rectangle {
                anchors.fill: parent;
                anchors.margins: 3;
                border.color: "blue";
                radius:3;
                color: styleData.selected ? "#AA1A4275" : "#AA1A42AB";

                Text{
                    id: textID;
                    text:styleData.value;
                    font.family: "微软雅黑";
                    font.pixelSize: 12;
                    anchors.fill: parent;
                    color: "white";
                    elide: Text.ElideRight;
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            rowDelegate: Rectangle {
                height: mainWindow.mapToDeviceHeight(42);
                color: "transparent";
            }

            headerDelegate: Rectangle{
                border.color: "#AA84BFE7";
                color: "#AA1A42AB";
                height: 30;
                radius: 3;
                Text{
                    text: styleData.value
                    anchors.centerIn: parent
                    font.family: "微软雅黑";
                    font.pixelSize: 12;
                    color: "white";
                }
            }//header delegate is end

            model: ListModel{
                id: deviceModel
            }

            onClicked: {
                deviceip.text = deviceModel.get(row).ip;
                deviceport.text = deviceModel.get(row).port;
            }
        }
    }

    // 预监IP选择
    Rectangle {
        y: mainWindow.mapToDeviceHeight(500)
        width: mainWindow.mapToDeviceWidth(1600); height: mainWindow.mapToDeviceHeight(80);
        anchors.horizontalCenter: parent.horizontalCenter
        color: "#00000000"

        // preview ip
        Rectangle {
            width: mainWindow.mapToDeviceWidth(100); height: mainWindow.mapToDeviceHeight(80);
            color: "#00000000"

            Text {
                text: qsTr("预监IP")
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                font.family: "微软雅黑"
                font.pixelSize: 12
            }
        }
        TextField {
            id: previewip
            x: mainWindow.mapToDeviceWidth(200)
            width: mainWindow.mapToDeviceWidth(500); height: mainWindow.mapToDeviceHeight(80);
            clip: true;

            placeholderText: "Preview IP"
            font.family: "微软雅黑"
            font.pixelSize: 12
        }

        // preview port
        Rectangle {
            x: mainWindow.mapToDeviceWidth(900)
            width: mainWindow.mapToDeviceWidth(100); height: mainWindow.mapToDeviceHeight(80);
            color: "#00000000"

            Text {
                text: qsTr("预监端口")
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                font.family: "微软雅黑"
                font.pixelSize: 12
            }
        }
        TextField {
            id: preiviewport
            x: mainWindow.mapToDeviceWidth(1100)
            width: mainWindow.mapToDeviceWidth(500); height: mainWindow.mapToDeviceHeight(80);
            clip: true;

            placeholderText: "Preview port"
            font.family: "微软雅黑"
            font.pixelSize: 12
        }
    }

    Rectangle {
        x: mainWindow.mapToDeviceWidth(160); y: mainWindow.mapToDeviceHeight(600)
        width: mainWindow.mapToDeviceWidth(1000); height: mainWindow.mapToDeviceHeight(250)
        color: "#00000000"

        // background
        Image {
            anchors.fill: parent

            fillMode: Image.Stretch
            source: "resource/background.png"
        }

        TableView {  //定义table的显示，包括定制外观
            id: previewTableView
            anchors.fill: parent
            TableViewColumn{role: "ip"; title: "IP"; width: mainWindow.mapToDeviceWidth(400); elideMode: Text.ElideRight;}
            TableViewColumn{role: "port";title: "端口"; width: mainWindow.mapToDeviceWidth(200); elideMode: Text.ElideRight;}
            TableViewColumn{role: "mac";title: "Mac地址"; width: mainWindow.mapToDeviceWidth(400); elideMode: Text.ElideRight;}

            itemDelegate: Rectangle {
                anchors.fill: parent;
                anchors.margins: 3;
                border.color: "blue";
                radius:3;
                color: styleData.selected ? "#AA1A4275" : "#AA1A42AB";

                Text{
                    text:styleData.value;
                    font.family: "微软雅黑";
                    font.pixelSize: 12;
                    anchors.fill: parent;
                    color: "white";
                    elide: Text.ElideRight;
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            rowDelegate: Rectangle {
                height: mainWindow.mapToDeviceHeight(42);
                color: "transparent";
            }

            headerDelegate: Rectangle{
                border.color: "#AA84BFE7";
                color: "#AA1A42AB";
                height: 30;
                radius: 3;
                Text{
                    text: styleData.value
                    anchors.centerIn: parent
                    font.family: "微软雅黑";
                    font.pixelSize: 12;
                    color: "white";
                }
            }//header delegate is end

            model: ListModel{
                id: previewModel
            }

            onClicked: {
                previewip.text = previewModel.get(row).ip;
                preiviewport.text = previewModel.get(row).port;
            }
        }
    }

    Button {
        x: mainWindow.mapToDeviceWidth(160); y: mainWindow.mapToDeviceHeight(900);
        width: mainWindow.mapToDeviceWidth(150); height: mainWindow.mapToDeviceHeight(50);

        text: "返回首页"

        style: ButtonStyle {
            background: Rectangle {
                implicitWidth: 100
                implicitHeight: 25
                border.width: control.activeFocus ? 2 : 1
                border.color: "#888"
                radius: 4
                gradient: Gradient {
                    GradientStop { position: 0 ; color: control.pressed ? "#ccc" : "#eee" }
                    GradientStop { position: 1 ; color: control.pressed ? "#aaa" : "#ccc" }
                }
            }
        }

        onClicked: {
            pageIndex = 0;
        }
    }

    Button {
        x: mainWindow.mapToDeviceWidth(1450); y: mainWindow.mapToDeviceHeight(900);
        width: mainWindow.mapToDeviceWidth(150); height: mainWindow.mapToDeviceHeight(50);

        text: "演示模式"

        style: ButtonStyle {
            background: Rectangle {
                implicitWidth: 100
                implicitHeight: 25
                border.width: control.activeFocus ? 2 : 1
                border.color: "#888"
                radius: 4
                gradient: Gradient {
                    GradientStop { position: 0 ; color: control.pressed ? "#ccc" : "#eee" }
                    GradientStop { position: 1 ; color: control.pressed ? "#aaa" : "#ccc" }
                }
            }
        }

        onClicked: {
            mainMgr.LoginByDemoMode();
        }
    }

    Button {
        x: mainWindow.mapToDeviceWidth(1610); y: mainWindow.mapToDeviceHeight(900);
        width: mainWindow.mapToDeviceWidth(150); height: mainWindow.mapToDeviceHeight(50);

        text: "登  录"

        style: ButtonStyle {
            background: Rectangle {
                implicitWidth: 100
                implicitHeight: 25
                border.width: control.activeFocus ? 2 : 1
                border.color: "#888"
                radius: 4
                gradient: Gradient {
                    GradientStop { position: 0 ; color: control.pressed ? "#ccc" : "#eee" }
                    GradientStop { position: 1 ; color: control.pressed ? "#aaa" : "#ccc" }
                }
            }
        }

        onClicked: {
            mainMgr.welcomePageBaseInfo_ip = deviceip.text;
            mainMgr.welcomePageBaseInfo_port = deviceport.text;
            mainMgr.welcomePageBaseInfo_unionControl = "0";
            mainMgr.welcomePageBaseInfo_previewip = previewip.text;
            mainMgr.welcomePageBaseInfo_previewport = preiviewport.text;
            mainMgr.SaveWelcomePageBaseInfo();

            // login
            mainMgr.LoginByDirect();
        }
    }

    Component.onCompleted: {
        deviceip.text = mainMgr.welcomePageBaseInfo_ip;
        deviceport.text = mainMgr.welcomePageBaseInfo_port;
        previewip.text = mainMgr.welcomePageBaseInfo_previewip;
        preiviewport.text = mainMgr.welcomePageBaseInfo_previewport;
    }

    // 服务器搜索后出入数据
    function serverAppendOnlineDevice(name, ip, port, mask, gateway, mac) {
        deviceModel.append({"name":name,"ip":ip,"port":port,"mask":mask,"gateway":gateway,"mac":mac});
    }
    function serverAppendOnlinePreview(ip, port, mac) {
        previewModel.append({"ip":ip,"port":port,"mac":mac});
    }
}
