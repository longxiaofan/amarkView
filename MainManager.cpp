#include "MainManager.h"
#include "Player/BCVedioManager.h"
#include <QFile>
#include <QDomDocument>
#include <QTcpSocket>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonParseError>

// 需要定义命令结束标识，否则当命令发送过快的时候接收方会自动合并多个命令，造成解析错误
#define CMDOVERFLAG QString("$$$$")

// 测试代码
#define TEST

MainManager::MainManager()
{
    m_pRoot = NULL;
    m_pTcpSocket = NULL;
    m_pRemoteSocket = NULL;
    m_nRetryTimes = 0;
    m_nCacheTimes = 0;
    m_currentUserID = -1;

    // preview
    m_pVedioMgr = NULL;

//    // 初始化穿透IP
//    initRemoteIPList();

    // 初始化配置文件
    initConfigFile();

    if ( 1 )
        m_isPad = false;
    else
        m_isPad = true;
}

MainManager::~MainManager()
{
    m_pRoot = NULL;

    if (NULL != m_pVedioMgr) {
        delete m_pVedioMgr;
        m_pVedioMgr = NULL;
    }

    if (NULL != m_pTcpSocket) {
        m_pTcpSocket->disconnectFromHost();
        m_pTcpSocket->deleteLater();
    }
    if (NULL != m_pRemoteSocket) {
        m_pRemoteSocket->disconnectFromHost();
        m_pRemoteSocket->deleteLater();
    }
}

void MainManager::onRequestFormat()
{
    if (NULL == m_pTcpSocket)
        return;

    // 如果不是第一次断线重连，防止当前连接出现问题
    if (0 != m_nRetryTimes) {
        m_pTcpSocket->disconnectFromHost();
        m_pTcpSocket->connectToHost(QHostAddress(m_welcomePageBaseInfo_ip), m_welcomePageBaseInfo_port.toInt());
        m_pTcpSocket->waitForConnected( 5000 );
    }

    if ("0" == m_welcomePageBaseInfo_unionControl) {
        unsigned short code_id = 1234;

        char wStr[11];
        wStr[0] = 0x21;
        wStr[1] = 0x16;
        wStr[2] = 0x00;
        wStr[3] = 0x00;
        wStr[4] = 0x01;
        wStr[5] = code_id;
        wStr[6] = (code_id>>8);
        wStr[7] = 0x09;
        wStr[8] = 0x00;
        wStr[9] = 0xa4;
        wStr[10] = 0xa5;

        // 结束符
        char cEnd[32];
        for (int i = 0; i < 32; i++) {
            cEnd[i] = 0x00;
        }
        m_pTcpSocket->write((char *)wStr, 11);
        m_pTcpSocket->write((char *)cEnd, 32);

        m_pTcpSocket->flush();
        m_byteRecv.clear();
    } else {
        if (-1 == m_currentUserID)
            SendTcpData( EncodeStandardJson("Login", QString("%1 %2").arg(m_welcomePageBaseInfo_user).arg(m_welcomePageBaseInfo_password)) );
        else
            SendTcpData( EncodeStandardJson("GetFormat", QString::number(m_currentUserID)) );
    }

    // 2s后检查是否有收到数据
    QTimer::singleShot(2000, this, SLOT(onCheckoutRequestFormat()));

    // 日志
    AppendLog( QString("request format: %1 times, %2").arg(m_nRetryTimes).arg(m_pTcpSocket->state()) );
}
void MainManager::onCheckoutRequestFormat()
{
    if (m_byteRecv.isEmpty() && (m_nRetryTimes++ < 15) && m_bRequestFormat) {
        onRequestFormat();
    }
}
QString MainManager::EncodeStandardJson(const QString &k, const QString &v)
{
    QJsonObject json;
    json.insert("cmdKey", k);
    json.insert("cmdValue", v);

    QJsonDocument document;
    document.setObject(json);
    QByteArray byte_array = document.toJson(QJsonDocument::Compact);

    QString cmdValue = QString::fromLocal8Bit( byte_array ) + CMDOVERFLAG;
    return cmdValue;
}
QString MainManager::DecodeJsonKey(const QString &json) {
    QJsonParseError json_error;
    QJsonDocument parse_doucment = QJsonDocument::fromJson(json.toLocal8Bit(), &json_error);
    if(json_error.error != QJsonParseError::NoError) {
        qDebug() << json_error.errorString();
        return QString();
    }

    if( !parse_doucment.isObject() )
        return QString();

    QJsonObject obj = parse_doucment.object();
    if( !obj.contains("cmdKey") )
        return QString();

    QJsonValue cmdValue = obj.take("cmdKey");
    if( !cmdValue.isString() )
        return QString();

    return cmdValue.toString();
}

int MainManager::GetStandardJsonResult(const QString &json)
{
    QJsonParseError json_error;
    QJsonDocument parse_doucment = QJsonDocument::fromJson(json.toLocal8Bit(), &json_error);
    if(json_error.error != QJsonParseError::NoError)
        return 0;

    if( !parse_doucment.isObject() )
        return 0;

    QJsonObject obj = parse_doucment.object();
    if( !obj.contains("cmdResult") )
        return 0;

    QJsonValue cmdValue = obj.take("cmdResult");
    if( !cmdValue.isString() )
        return 0;

    return cmdValue.toString().toInt();
}

QString MainManager::GetJsonValueByKey(const QString &json, const QString &key, QString valueKey)
{
    QString qsValue;
    QJsonParseError json_error;
    QJsonDocument parse_doucment = QJsonDocument::fromJson(json.toLocal8Bit(), &json_error);
    if(json_error.error != QJsonParseError::NoError)
        return qsValue;

    if( !parse_doucment.isObject() )
        return qsValue;

    QJsonObject obj = parse_doucment.object();
    if( !obj.contains("cmdKey") )
        return qsValue;

    QJsonValue cmdValue = obj.take("cmdKey");
    if( !cmdValue.isString() )
        return qsValue;

    if (key != cmdValue.toString())
        return qsValue;

    cmdValue = obj.take( valueKey );
    if( !cmdValue.isString() )
        return qsValue;

    return cmdValue.toString();
}

void MainManager::ServerWinsize(int groupid, int chid, int /*chtype*/, int winid, int l, int t, int r, int b)
{
    if (NULL != m_pRoot) {
        QMetaObject::invokeMethod(m_pRoot, "serverWinsize", Q_ARG(QVariant, groupid),
                                  Q_ARG(QVariant, winid), Q_ARG(QVariant, chid),
                                  Q_ARG(QVariant, l), Q_ARG(QVariant, t), Q_ARG(QVariant, r-l), Q_ARG(QVariant, b-t));
    }
}

void MainManager::ServerWinswitch(int groupid, int /*channelid*/, int /*chtype*/, int windowid)
{
    if (NULL != m_pRoot) {
        QMetaObject::invokeMethod(m_pRoot, "serverWinswitch", Q_ARG(QVariant, groupid), Q_ARG(QVariant, windowid));
    }
}

void MainManager::ServerMoveSignalWindow(int groupid, int /*channelid*/, int /*chtype*/, int windowid)
{
    if (NULL != m_pRoot) {
        QMetaObject::invokeMethod(m_pRoot, "serverSignalWindowResizeLiscene", Q_ARG(QVariant, groupid), Q_ARG(QVariant, windowid));
    }
}

void MainManager::ServerReset(const QString &ids)
{
    if (NULL != m_pRoot) {
        QMetaObject::invokeMethod(m_pRoot, "serverReset", Q_ARG(QVariant, ids.toInt()));
    }
}

void MainManager::ServerChangeLockState(int i, bool bLock)
{
    if (NULL != m_pRoot) {
        QMetaObject::invokeMethod(m_pRoot, "serverChangeLockState", Q_ARG(QVariant, i), Q_ARG(QVariant, bLock));
    }
}
void MainManager::onRecvTcpMessage()
{
    QByteArray byteRecv = m_pTcpSocket->readAll();

    if ("0" == m_welcomePageBaseInfo_unionControl) {
        if ( !m_bRequestFormat )
            return;

        m_byteRecv.append( byteRecv );
        AppendLog( QString("recv data: %1 bits").arg(m_byteRecv.length()) );

        if (m_byteRecv.length() == 12018) { // 4U
            if ((QChar(m_byteRecv.at(0)) == QChar(0xA6))
                    && (QChar(m_byteRecv.at(1)) == QChar(0xEC))
                    && (QChar(m_byteRecv.at(2)) == QChar(0xAA))
                    && (QChar(m_byteRecv.at(3)) == QChar(0x16))
                    && (QChar(m_byteRecv.at(4)) == QChar(0x55))
                    && (QChar(m_byteRecv.at(5)) == QChar(0xAA))
                    && (QChar(m_byteRecv.at(6)) == QChar(0x77))
                    && (QChar(m_byteRecv.at(7)) == QChar(0x66))) {

                QVariantList lstChannelData, lstGroupDisplayData, lstDefaultScene, lstChannelDataRes, lstGroupDisplayDataRes;
                QList<sSignalWindow> lstSignalWindow;   // 信号窗链表

                int k = 0;                  // 数组的起始值
                int n = 16;
                unsigned char cHighLow[2];  // 计算高低位的临时数组，串口数据需要两位进行组合，而且高低位是反向的

                // group count
                cHighLow[0] = m_byteRecv.at(21);
                cHighLow[1] = m_byteRecv.at(20);
                int nGroupCount= cHighLow[0]<<8|cHighLow[1];

                // group display data
                for (int i = 0; i < nGroupCount; i++) {
                    cHighLow[0] = m_byteRecv.at((n+i*16+0)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+i*16+0)*2);
                    int groupid = cHighLow[0]<<8|cHighLow[1]; // groupid
                    cHighLow[0] = m_byteRecv.at((n+i*16+3)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+i*16+3)*2);
                    int formatx = cHighLow[0]<<8|cHighLow[1]; // formatx
                    cHighLow[0] = m_byteRecv.at((n+i*16+4)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+i*16+4)*2);
                    int formaty = cHighLow[0]<<8|cHighLow[1]; // formaty
                    cHighLow[0] = m_byteRecv.at((n+i*16+5)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+i*16+5)*2);
                    unsigned int xsize = cHighLow[0]<<8|cHighLow[1]; // xsize
                    cHighLow[0] = m_byteRecv.at((n+i*16+6)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+i*16+6)*2);
                    int ysize = cHighLow[0]<<8|cHighLow[1]; // ysize
                    cHighLow[0] = m_byteRecv.at((n+i*16+7)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+i*16+7)*2);
                    int posx = cHighLow[0]<<8|cHighLow[1]; // posx
                    cHighLow[0] = m_byteRecv.at((n+i*16+8)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+i*16+8)*2);
                    int posy = cHighLow[0]<<8|cHighLow[1]; // posy

                    qDebug() << "group display: " << groupid << formatx << formaty << xsize << ysize << posx << posy;
                    if ((formatx == 0) || (formaty == 0) || (xsize == 0) || (ysize == 0)) {
                        continue;
                    }

                    lstGroupDisplayData.append( QString::number( groupid ) );
                    lstGroupDisplayData.append( QString::number( formatx ) );
                    lstGroupDisplayData.append( QString::number( formaty ) );
                    lstGroupDisplayData.append( QString::number( xsize ) );
                    lstGroupDisplayData.append( QString::number( ysize ) );
                    lstGroupDisplayData.append( QString::number( posx ) );
                    lstGroupDisplayData.append( QString::number( posy ) );
                }

                if ( lstGroupDisplayData.isEmpty() ) {
                    //emit sigDemoMode();
                    return;
                }

                k = n+nGroupCount*16+0;
                n = k+1;

                // channel count
                cHighLow[0] = m_byteRecv.at(17);
                cHighLow[1] = m_byteRecv.at(16);
                int nChannelCount= cHighLow[0]<<8|cHighLow[1];   // 全部通道，可用不可用在一起

                // temp memory for default scene
                QList<int> lstSort;     // 存放叠层链表
                for (int i = 0; i < nChannelCount; i++) {
                    cHighLow[0] = m_byteRecv.at((n+i+0)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+i+0)*2);
                    int sort = cHighLow[0]<<8|cHighLow[1];           // sort
                    lstSort.append( sort );
                }

                k = n+nChannelCount;
                n = k+1;

                // temp memory for default scene
                int nSignalWindow = n;

                k = n+nChannelCount*6;
                n = k+0;

                // channel valid count
                cHighLow[0] = m_byteRecv.at(23);
                cHighLow[1] = m_byteRecv.at(22);
                int nChannelValidCount= cHighLow[0]<<8|cHighLow[1];

                m_mapChannelIDType.clear();
                // channel data
                int tempBoardpos = 0;   // ??? 变量临时使用，硬件修改后删除
                for (int i = 0; i < nChannelValidCount; i++) {
                    cHighLow[0] = m_byteRecv.at((n+i*4+0)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+i*4+0)*2);
                    int xpixels = cHighLow[0]<<8|cHighLow[1];           // xpixels
                    cHighLow[0] = m_byteRecv.at((n+i*4+1)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+i*4+1)*2);
                    int ypixels = cHighLow[0]<<8|cHighLow[1];           // ypixels
                    cHighLow[0] = m_byteRecv.at((n+i*4+2)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+i*4+2)*2);
                    int chid = cHighLow[0]<<8|cHighLow[1];              // chid
                    cHighLow[0] = m_byteRecv.at((n+i*4+3)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+i*4+3)*2);
                    unsigned short type = cHighLow[0]<<8|cHighLow[1];   // type
                    unsigned short boardid = type & 0xFF;               // 板卡ID
                    unsigned short chtype = type>>12;                   // 0普清 3高清 9IPV 8Vedio
                    unsigned short boardpos = type<<4;
                    boardpos = boardpos>>12;                            // 板卡位置，如：0 1 2 3

                    // ??? 14U设备高清板卡位置不正确，如两块板卡回来的位置是4 6 0 2，应为0 1 0 1
                    if (3 == chtype) {
                        boardpos = tempBoardpos % 2;
                        tempBoardpos++;
                    }

                    m_mapChannelIDType.insert(chid, chtype);
                    lstChannelData.append( QString::number( chid ) );
                    lstChannelData.append( QString::number( chtype ) );
                    lstChannelData.append( QString::number( boardid ) );
                    lstChannelData.append( QString::number( boardpos ) );
                    lstChannelData.append( QString::number( xpixels ) );
                    lstChannelData.append( QString::number( ypixels ) );
                    qDebug() << "channel: " << chid << chtype  << boardid << boardpos << xpixels << ypixels;
                }

                k = n+4*nChannelValidCount;
                n = k+0;

                // ??? 暂时不知道数组是做什么用的
                for (int i = 0; i < 32; i++) {
                    cHighLow[0] = m_byteRecv.at((n+i*1+0)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+i*1+0)*2);
                    //int x = cHighLow[0]<<8|cHighLow[1];
                }

                k = n+32;
                n = k+0;

                // ??? 暂时不知道数组是做什么用的
                int j = 0;
                cHighLow[0] = m_byteRecv.at((n+j+0)*2+1);
                cHighLow[1] = m_byteRecv.at((n+j+0)*2);
                //int nInitBackBoardType = cHighLow[0]<<8|cHighLow[1];
                j++;
                cHighLow[0] = m_byteRecv.at((n+j+0)*2+1);
                cHighLow[1] = m_byteRecv.at((n+j+0)*2);
                int nMaxBoardLimit = cHighLow[0]<<8|cHighLow[1];
                for (int i = 0; i < nMaxBoardLimit; i++) {
                    cHighLow[0] = m_byteRecv.at((n+j+0)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+j+0)*2);
                    //int nMainBoardType = cHighLow[0]<<8|cHighLow[1];
                    j++;
                    cHighLow[0] = m_byteRecv.at((n+j+0)*2+1);
                    cHighLow[1] = m_byteRecv.at((n+j+0)*2);
                    //int nAuxMainBoardType = cHighLow[0]<<8|cHighLow[1];
                    j++;

                }

                // ??? 暂时不知道数组是做什么用的
                j++;
                cHighLow[0] = m_byteRecv.at((n+j+0)*2+1);
                cHighLow[1] = m_byteRecv.at((n+j+0)*2);
                //int nK = cHighLow[0]<<8|cHighLow[1] - 0xea00;

                // 取当前段的j
                cHighLow[0] = m_byteRecv.at(25);
                cHighLow[1] = m_byteRecv.at(24);
                j = cHighLow[0]<<8|cHighLow[1];

                k = n+j;
                n = k+0;

                // temp memory for default scene
                int nGroupIndex = n;

                n += nChannelCount;

                // temp memory for default scene
                int nGroupData = n;

                // default scene
                for (int i = 0; i < nChannelCount; i++) {
                    cHighLow[0] = m_byteRecv.at((nSignalWindow+i*6+1)*2+1);
                    cHighLow[1] = m_byteRecv.at((nSignalWindow+i*6+1)*2);
                    int enable = cHighLow[0]<<8|cHighLow[1];                    // enable, 1/65535
                    if (1 != enable)
                        continue;

                    cHighLow[0] = m_byteRecv.at((nSignalWindow+i*6+0)*2+1);
                    cHighLow[1] = m_byteRecv.at((nSignalWindow+i*6+0)*2);
                    int chid = cHighLow[0]<<8|cHighLow[1];                      // chid
                    cHighLow[0] = m_byteRecv.at((nSignalWindow+i*6+2)*2+1);
                    cHighLow[1] = m_byteRecv.at((nSignalWindow+i*6+2)*2);
                    int x0 = cHighLow[0]<<8|cHighLow[1];                        // left
                    cHighLow[0] = m_byteRecv.at((nSignalWindow+i*6+3)*2+1);
                    cHighLow[1] = m_byteRecv.at((nSignalWindow+i*6+3)*2);
                    int y0 = cHighLow[0]<<8|cHighLow[1];                        // top
                    cHighLow[0] = m_byteRecv.at((nSignalWindow+i*6+4)*2+1);
                    cHighLow[1] = m_byteRecv.at((nSignalWindow+i*6+4)*2);
                    int x1 = cHighLow[0]<<8|cHighLow[1];                        // right
                    cHighLow[0] = m_byteRecv.at((nSignalWindow+i*6+5)*2+1);
                    cHighLow[1] = m_byteRecv.at((nSignalWindow+i*6+5)*2);
                    int y1 = cHighLow[0]<<8|cHighLow[1];                        // bottom

                    cHighLow[0] = m_byteRecv.at((nGroupIndex+i+0)*2+1);
                    cHighLow[1] = m_byteRecv.at((nGroupIndex+i+0)*2);
                    unsigned short nMapGroupIndex = cHighLow[0]<<8|cHighLow[1]; // groupid
                    nMapGroupIndex -= 0xc000;
                    cHighLow[0] = m_byteRecv.at((nGroupData+i+0)*2+1);
                    cHighLow[1] = m_byteRecv.at((nGroupData+i+0)*2);
                    int nMapGroupData = cHighLow[0]<<8|cHighLow[1];             // wid

                    // 添加到链表，方便后面进行排序
                    sSignalWindow ssigWindow;
                    ssigWindow.gid = nMapGroupIndex;
                    ssigWindow.chid = chid;
                    ssigWindow.winid = nMapGroupData;
                    ssigWindow.rect = QRect(x0, y0, x1-x0, y1-y0);
                    ssigWindow.sort = lstSort.indexOf( i );
                    lstSignalWindow.append( ssigWindow );
                }

                // 排序；规则是屏组ID和叠放顺序倒序
                sortSignalWindow( &lstSignalWindow );

                // 添加到链表中
                for (int i = 0; i < lstSignalWindow.count(); i++) {
                    sSignalWindow ssigWindow = lstSignalWindow.at( i );

                    lstDefaultScene.append( QString::number( ssigWindow.gid ) );
                    lstDefaultScene.append( QString::number( ssigWindow.winid ) );
                    lstDefaultScene.append( QString::number( ssigWindow.chid ) );
                    lstDefaultScene.append( QString::number( ssigWindow.rect.left() ) );
                    lstDefaultScene.append( QString::number( ssigWindow.rect.top() ) );
                    lstDefaultScene.append( QString::number( ssigWindow.rect.width() ) );
                    lstDefaultScene.append( QString::number( ssigWindow.rect.height() ) );
                    qDebug() << "default signal window: " << ssigWindow.gid << ssigWindow.chid << ssigWindow.winid << ssigWindow.rect << ssigWindow.sort;
                }

                // change states
                m_bRequestFormat = false;

                // save file
                saveConfigFile(lstChannelData, lstGroupDisplayData, lstChannelDataRes, lstGroupDisplayDataRes);

                // call qml function
                if (NULL != m_pRoot) {
                    QMetaObject::invokeMethod(m_pRoot, "onVP4000Config",
                                              Q_ARG(QVariant, QVariant::fromValue(lstChannelDataRes)),
                                              Q_ARG(QVariant, QVariant::fromValue(lstGroupDisplayDataRes)),
                                              Q_ARG(QVariant, QVariant::fromValue(lstDefaultScene)));

                    // 初始化回显对象
                    if (NULL == m_pVedioMgr) {
#ifdef TEST
                        m_pVedioMgr = new BCVedioManager(this, "192.168.1.65", 8206);
#else
                        m_pVedioMgr = new BCVedioManager(this, m_welcomePageBaseInfo_ip, 8206);
#endif
                    }

                    // 初始化穿透socket
                    if (NULL == m_pRemoteSocket)
                        m_pRemoteSocket = new QUdpSocket();
                }
            } else {
                if ((m_nRetryTimes < 15) && m_bRequestFormat) {
                    QTimer::singleShot(10, this, SLOT(onRequestFormat()));
                }
            }
        } else if ((m_byteRecv.length() > 12018) && (m_nRetryTimes < 15) && m_bRequestFormat) {
            QTimer::singleShot(10, this, SLOT(onRequestFormat()));
        }
    } else {
        QString json( byteRecv );
        //qDebug() << "tcp recv: " << json;
        if ( !json.contains( CMDOVERFLAG ) ) {
           m_nCacheTimes++;
           m_qsCacheJson += json;

           AppendLog( QString("recv data: %1 times").arg( m_nCacheTimes ) );

           if (m_nCacheTimes >= 50) {
               // 清空缓存JSON
               m_nCacheTimes = 0;
               m_qsCacheJson = QString();
               return;
           }

           return;
        } else if (m_nCacheTimes != 0) {
            json = m_qsCacheJson + json;
        }

        // 经过分割后的指令
        QStringList lstCmds = json.split( CMDOVERFLAG );
        for (int i = 0; i < lstCmds.count(); i++) {
           // 处理单个指令函数
           RevSingleData( lstCmds.at(i) );
        }

        // 清空缓存JSON
        m_nCacheTimes = 0;
        m_qsCacheJson = QString();
    }
}

int MainManager::getTypeByID(int id)
{
    return m_mapChannelIDType.value(id, 0);
}
void MainManager::RevSingleData(const QString &json)
{
    if ( json.isEmpty() )
        return;

    qDebug() << "recv: " << json;

    // 解析json的cmdKey
    QString cmdKey = DecodeJsonKey( json );

    // 解析登录返回信息
    if ("LoginResult" == cmdKey) {
        QString qsLoginRes = GetJsonValueByKey(json, "LoginResult");
        QStringList lstPara = qsLoginRes.split(" ");
        if (2 == lstPara.count()) {
            m_currentUserID = lstPara.at(0).toInt();
            //int level = lstPara.at(1).toInt();

            SendTcpData( EncodeStandardJson("GetFormat", QString::number(m_currentUserID)) );
        }
    }

    // 解析房间配置返回值
    if ("GetFormatResult" == cmdKey) {
        DealFormatFromServer( json );
    }
    // 移动窗口请求控制
    if ("requestControlBySignalWindowResult" == cmdKey) {
        int nRes = GetStandardJsonResult( json );
        if (1 == nRes) {
            QString qsRes = GetJsonValueByKey(json, "requestControlBySignalWindowResult");
            QStringList lstPara = qsRes.split(" ");
            if (4 == lstPara.count()) {
                int groupid = lstPara.at(0).toInt();
                int chid    = lstPara.at(1).toInt();
                int chtype  = lstPara.at(2).toInt();
                int winid   = lstPara.at(3).toInt();

                ServerMoveSignalWindow(groupid, chid, chtype, winid);
            }
        }
    }
    // 解析请求开窗返回值
    if ("winsizeResult" == cmdKey) {
        int nRes = GetStandardJsonResult( json );
        if (1 == nRes) {
            QString qsRes = GetJsonValueByKey(json, "winsizeResult");
            QStringList lstPara = qsRes.split(" ");
            if (9 == lstPara.count()) {
                int groupid = lstPara.at(0).toInt();
                int chid    = lstPara.at(1).toInt();
                int winid   = lstPara.at(2).toInt();
                int l       = lstPara.at(3).toInt();
                int t       = lstPara.at(4).toInt();
                int r       = lstPara.at(5).toInt();
                int b       = lstPara.at(6).toInt();
                int type    = lstPara.at(7).toInt();

                ServerWinsize(groupid, chid, type, winid, l, t, r, b);
            }
        }
    }
    // 同步开窗，移动
    if ("winsize" == cmdKey) {
        QString qsRes = GetJsonValueByKey(json, "winsize");
        QStringList lstPara = qsRes.split(" ");
        if (9 == lstPara.count()) {
            int groupid = lstPara.at(0).toInt();
            int chid    = lstPara.at(1).toInt();
            int winid   = lstPara.at(2).toInt();
            int l       = lstPara.at(3).toInt();
            int t       = lstPara.at(4).toInt();
            int r       = lstPara.at(5).toInt();
            int b       = lstPara.at(6).toInt();
            int chtype  = lstPara.at(7).toInt();

            // 同步开窗
            ServerWinsize(groupid, chid, chtype, winid, l, t, r, b);
        }
    }
    // 同步关窗
    if ("winswitchResult" == cmdKey) {
        int nRes = GetStandardJsonResult( json );
        if (1 == nRes) {
            QString qsRes = GetJsonValueByKey(json, "winswitchResult");
            QStringList lstPara = qsRes.split(" ");
            if (5 == lstPara.count()) {
                int groupid = lstPara.at(0).toInt();
                int winid   = lstPara.at(1).toInt();
                int chid    = lstPara.at(2).toInt();
                int chtype  = lstPara.at(3).toInt();

                // 同步开窗
                ServerWinswitch(groupid, chid, chtype, winid);
            }
        }
    }
    // 关窗回复
    if ("winswitch" == cmdKey) {
        QString qsRes = GetJsonValueByKey(json, "winswitch");
        QStringList lstPara = qsRes.split(" ");
        if (5 == lstPara.count()) {
            int groupid = lstPara.at(0).toInt();
            int winid   = lstPara.at(1).toInt();
            int chid    = lstPara.at(2).toInt();
            int chtype  = lstPara.at(3).toInt();

            // 同步开窗
            ServerWinswitch(groupid, chid, chtype, winid);
        }
    }
    // 清屏回复
    if ("resetResult" == cmdKey) {
        int nRes = GetStandardJsonResult( json );
        if (1 == nRes) {
            QString qsRes = GetJsonValueByKey(json, "resetResult");

            ServerReset( qsRes );
        }
    }
    // 同步清屏
    if ("reset" == cmdKey) {
        QString qsRes = GetJsonValueByKey(json, "reset");

        ServerReset( qsRes );
    }
    // 锁屏
    if ("lockRoom" == cmdKey) {
        QString qsRes = GetJsonValueByKey(json, "lockRoom");

        ServerChangeLockState(qsRes.toInt(), true);
    }
    // 解锁
    if ("unLockRoom" == cmdKey) {
        QString qsRes = GetJsonValueByKey(json, "unLockRoom");

        ServerChangeLockState(qsRes.toInt(), false);
    }
    // 添加场景返回值
    if ("addSceneResult" == cmdKey) {
        int nRes = GetStandardJsonResult( json );
        if (1 == nRes) {
            int gid = -1;
            sUnionScene swindowscene = DecodeSceneJson(json, gid);
            if (-1 != gid) {
                // 1.添加内存
                QList<sUnionScene> lstScene = m_mapUnionGroupScene.value( gid );
                lstScene.append( swindowscene );
                m_mapUnionGroupScene.insert(gid, lstScene);

                // 2.添加UI
                if (NULL != m_pRoot) {
                    QMetaObject::invokeMethod(m_pRoot, "refreshCurrentSceneList");
                }
            }
        }
    }
    // 同步添加场景
    if ("addScene" == cmdKey) {
        int gid = -1;
        sUnionScene swindowscene = DecodeSceneJson(json, gid);
        if (-1 != swindowscene.id) {
            // 1.添加内存
            QList<sUnionScene> lstScene = m_mapUnionGroupScene.value( gid );
            lstScene.append( swindowscene );
            m_mapUnionGroupScene.insert(gid, lstScene);

            // 2.添加UI
            if (NULL != m_pRoot) {
                QMetaObject::invokeMethod(m_pRoot, "refreshCurrentSceneList");
            }
        }
    }
    // 删除场景返回值
    if ("deleteSceneResult" == cmdKey) {
        int nRes = GetStandardJsonResult( json );
        if (1 == nRes) {
            QString qsRes = GetJsonValueByKey(json, "deleteSceneResult");
            QStringList lstParas = qsRes.split(" ");
            if (3 == lstParas.count()) {
                int id = lstParas.at(0).toInt();
                int gid = lstParas.at(1).toInt();

                // 1.删除内存
                QList<sUnionScene> lstScene = m_mapUnionGroupScene.value( gid );
                for (int i = 0; i < lstScene.count(); i++) {
                    sUnionScene sscene = lstScene.at( i );
                    if (sscene.id == id) {
                        lstScene.removeAt( i );
                    }
                }
                m_mapUnionGroupScene.insert(gid, lstScene);

                // 2.添加UI
                if (NULL != m_pRoot) {
                    QMetaObject::invokeMethod(m_pRoot, "refreshCurrentSceneList");
                }
            }
        }
    }
    // 同步删除场景
    if ("deleteScene" == cmdKey) {
        QString qsRes = GetJsonValueByKey(json, "deleteScene");
        QStringList lstParas = qsRes.split(" ");
        if (3 == lstParas.count()) {
            int id = lstParas.at(0).toInt();
            int gid = lstParas.at(1).toInt();

            // 1.删除内存
            QList<sUnionScene> lstScene = m_mapUnionGroupScene.value( gid );
            for (int i = 0; i < lstScene.count(); i++) {
                sUnionScene sscene = lstScene.at( i );
                if (sscene.id == id) {
                    lstScene.removeAt( i );
                }
            }
            m_mapUnionGroupScene.insert(gid, lstScene);

            // 2.添加UI
            if (NULL != m_pRoot) {
                QMetaObject::invokeMethod(m_pRoot, "refreshCurrentSceneList");
            }
        }
    }
    // 刷新场景数据返回值
    if ("updateSceneDataResult" == cmdKey) {
        int nRes = GetStandardJsonResult( json );
        if (1 == nRes) {
            int gid = -1;
            sUnionScene swindowscene = DecodeSceneJson(json, gid);
            if (-1 != swindowscene.id) {
                // 1.添加内存
                QList<sUnionScene> lstScene = m_mapUnionGroupScene.value( gid );
                for (int i = 0; i < lstScene.count(); i++) {
                    sUnionScene sscene = lstScene.at( i );
                    if (sscene.id != swindowscene.id)
                        continue;

                    lstScene.replace(i, swindowscene);
                    m_mapUnionGroupScene.insert(gid, lstScene);
                    break;
                }

                // 2.添加UI
                if (NULL != m_pRoot) {
                    QMetaObject::invokeMethod(m_pRoot, "refreshCurrentSceneList");
                }
            }
        }
    }
    // 同步刷新场景数据
    if ("updateSceneData" == cmdKey) {
        int gid = -1;
        sUnionScene swindowscene = DecodeSceneJson(json, gid);
        if (-1 != swindowscene.id) {
            // 1.添加内存
            QList<sUnionScene> lstScene = m_mapUnionGroupScene.value( gid );
            for (int i = 0; i < lstScene.count(); i++) {
                sUnionScene sscene = lstScene.at( i );
                if (sscene.id != swindowscene.id)
                    continue;

                lstScene.replace(i, swindowscene);
                m_mapUnionGroupScene.insert(gid, lstScene);
                break;
            }

            // 2.添加UI
            if (NULL != m_pRoot) {
                QMetaObject::invokeMethod(m_pRoot, "refreshCurrentSceneList");
            }
        }
    }
    // 调用场景返回
    if ("gloadResult" == cmdKey) {
        QString qsRes = GetJsonValueByKey(json, "gloadResult");
        QStringList lstParas = qsRes.split(" ");
        if (2 == lstParas.count()) {
            if (NULL != m_pRoot) {
                QMetaObject::invokeMethod(m_pRoot, "serverLoadScene",
                                          Q_ARG(QVariant, QVariant::fromValue(lstParas.at(0).toInt())),
                                          Q_ARG(QVariant, QVariant::fromValue(lstParas.at(1).toInt())));
            }
        }
    }
    // 同步调用场景
    if ("gload" == cmdKey) {
        QString qsRes = GetJsonValueByKey(json, "gload");
        QStringList lstParas = qsRes.split(" ");
        if (2 == lstParas.count()) {
            if (NULL != m_pRoot) {
                QMetaObject::invokeMethod(m_pRoot, "serverLoadScene",
                                          Q_ARG(QVariant, QVariant::fromValue(lstParas.at(0).toInt())),
                                          Q_ARG(QVariant, QVariant::fromValue(lstParas.at(1).toInt())));
            }
        }
    }
//    // 刷新场景返回值
//    if ("updateSceneResult" == cmdKey) {
//        int nRes = GetStandardJsonResult( json );
//        if (1 == nRes) {
//            QString qsRes = GetJsonValueByKey(json, "updateSceneResult");
//            QStringList lstParas = qsRes.split(" ");
//            if (5 == lstParas.count()) {
//                int id = lstParas.at(0).toInt();
//                int nRoomID = lstParas.at(1).toInt();
//                int nGroupSceneID = lstParas.at(2).toInt();
//                int nCycle = lstParas.at(3).toInt();
//                QString name = lstParas.at(4);

//                ServerUpdateScene(nRoomID, nGroupSceneID, id, nCycle, name);
//                RefreshSceneWidget();
//            }
//        }
//    }
//    // 同步刷新场景
//    if ("updateScene" == cmdKey) {
//        QString qsRes = GetJsonValueByKey(json, "updateScene");
//        QStringList lstParas = qsRes.split(" ");
//        if (5 == lstParas.count()) {
//            int id = lstParas.at(0).toInt();
//            int nRoomID = lstParas.at(1).toInt();
//            int nGroupSceneID = lstParas.at(2).toInt();
//            int nCycle = lstParas.at(3).toInt();
//            QString name = lstParas.at(4);

//            ServerUpdateScene(nRoomID, nGroupSceneID, id, nCycle, name);
//            RefreshSceneWidget();
//        }
//    }
//    // 同步修改输入通道名称
//    if ("UpdateInputChannel" == cmdKey) {
//        QString qsRes = GetJsonValueByKey(json, "UpdateInputChannel");
//        QStringList lstParas = qsRes.split(" ");
//        if (4 == lstParas.count()) {
//            int userid = lstParas.at(0).toInt();
//            int chid = lstParas.at(1).toInt();
//            int chtype = lstParas.at(2).toInt();
//            QString text = lstParas.at(3);

//            ServerUpdateInputChannel(chid, chtype, text);
//        }
//    }
}

// 处理服务器返回的房间json
void MainManager::DealFormatFromServer(const QString &json)
{
    QJsonParseError json_error;
    QJsonDocument parse_doucment = QJsonDocument::fromJson(json.toLocal8Bit(), &json_error);
    if(json_error.error != QJsonParseError::NoError)
        return;

    if( !parse_doucment.isObject() )
        return;

    QJsonObject obj = parse_doucment.object();
    if( !obj.contains("cmdValue") )
        return;

    QJsonValue cmdValue = obj.take("cmdValue");

    // 内部包含
    QJsonObject formatJsonObject = cmdValue.toObject();
    if ( formatJsonObject.isEmpty() )
        return;

    // 缓存场景数据
    m_mapUnionGroupScene.clear();

    // 临时排序使用
    struct sServerGroup
    {
        QString name;
        int formatx;
        int formaty;
        int xsize;
        int ysize;
    };
    QMap<int, sServerGroup> mapGroup;

    QVariantList lstChannelData, lstGroupDisplayData, lstDefaultScene;
    QJsonArray arrGroup = formatJsonObject.value("groups").toArray();
    for (int i = 0; i < arrGroup.count(); i++) {
        QJsonObject groupObj = arrGroup.at(i).toObject();

        int groupid = groupObj.value("groupid").toInt();

        // group
        sServerGroup sgroup;
        sgroup.name = groupObj.value("name").toString();
        sgroup.formatx = groupObj.value("formatx").toInt();
        sgroup.formaty = groupObj.value("formaty").toInt();
        sgroup.xsize = groupObj.value("xsize").toInt();
        sgroup.ysize = groupObj.value("ysize").toInt();
        mapGroup.insert(groupid, sgroup);

//        int groupid = groupObj.value("groupid").toInt();
//        lstGroupDisplayData << groupid
//                            << groupObj.value("name").toString()
//                            << groupObj.value("formatx").toInt()
//                            << groupObj.value("formaty").toInt()
//                            << groupObj.value("xsize").toInt()
//                            << groupObj.value("ysize").toInt();

        QList<sUnionScene> lstUnionScene;

        // scene
        QJsonArray arrScene = groupObj.value("scene").toArray();
        for (int j = 0; j < arrScene.count(); j++) {
            QJsonObject sceneObj = arrScene.at(j).toObject();

            sUnionScene sunionscene;
            sunionscene.id = sceneObj.value("sceneid").toInt();
            sunionscene.name = sceneObj.value("name").toString();

            QJsonArray arrSceneData = sceneObj.value("sceneDatas").toArray();
            for (int k = 0; k < arrSceneData.count(); k++) {
                QJsonObject sceneDataObj = arrSceneData.at(k).toObject();

                sSignalWindow swindow;
                swindow.chid = sceneDataObj.value("channelid").toInt();
                swindow.winid = sceneDataObj.value("winid").toInt();
                swindow.rect = QRect(sceneDataObj.value("left").toInt(),
                                     sceneDataObj.value("top").toInt(),
                                     sceneDataObj.value("width").toInt(),
                                     sceneDataObj.value("height").toInt());
                sunionscene.lstWindow.append( swindow );
            }

            lstUnionScene.append( sunionscene );
        }

        // 缓存组内场景
        m_mapUnionGroupScene.insert(groupid, lstUnionScene);

        // default scene
        QJsonArray arrDefaultScene = groupObj.value("defaultscene").toArray();
        for (int j = 0; j < arrDefaultScene.count(); j++) {
            QJsonObject sceneDataObj = arrDefaultScene.at(j).toObject();

            lstDefaultScene << groupid << sceneDataObj.value("winid").toInt()
                            << sceneDataObj.value("channelid").toInt()
                            << sceneDataObj.value("left").toInt()
                            << sceneDataObj.value("top").toInt()
                            << sceneDataObj.value("width").toInt()
                            << sceneDataObj.value("height").toInt();
        }
    }

    m_lstInputChannel.clear();
    QJsonArray arrChannel = formatJsonObject.value("channels").toArray();
    for (int i = 0; i < arrChannel.count(); i++) {
        QJsonObject channelObj = arrChannel.at(i).toObject();

        // channel
//        channelObj.value("boardcardid").toInt();
//        channelObj.value("boardcardpos").toInt();

        m_mapChannelIDType.insert(channelObj.value("id").toInt(), channelObj.value("signalSource").toInt());
        lstChannelData << channelObj.value("id").toInt()
                       << channelObj.value("signalSource").toInt()
                       << channelObj.value("name").toString();

        m_lstInputChannel << channelObj.value("id").toInt() << channelObj.value("name");
    }

    // change states
    m_bRequestFormat = false;

    // 按ID顺序取值
    QList<int> lstGroupID = mapGroup.keys();
    for (int i = 0; i < lstGroupID.count(); i++) {
        sServerGroup sgroup = mapGroup.value( i );

        lstGroupDisplayData << lstGroupID.at(i)
                            << sgroup.name
                            << sgroup.formatx
                            << sgroup.formaty
                            << sgroup.xsize
                            << sgroup.ysize;
    }

    // call qml function
    if (NULL != m_pRoot) {
        QMetaObject::invokeMethod(m_pRoot, "onVP4000Config",
                                  Q_ARG(QVariant, QVariant::fromValue(lstChannelData)),
                                  Q_ARG(QVariant, QVariant::fromValue(lstGroupDisplayData)),
                                  Q_ARG(QVariant, QVariant::fromValue(lstDefaultScene)));

        // 初始化回显对象
        if (NULL == m_pVedioMgr) {
#ifdef TEST
            m_pVedioMgr = new BCVedioManager(this, "192.168.1.65", 8206);
#else
            m_pVedioMgr = new BCVedioManager(this, m_welcomePageBaseInfo_ip, 8206);
#endif

            // 初始化穿透socket
            if (NULL == m_pRemoteSocket)
                m_pRemoteSocket = new QUdpSocket();
        }
    }
}

void MainManager::sortSignalWindow(QList<sSignalWindow> *pList)
{
    qSort(pList->begin(), pList->end(), compareSignalWindow);
}

bool MainManager::compareSignalWindow(const sSignalWindow &win1, const sSignalWindow &win2)
{
    if (win1.gid == win2.gid) {
        if (win1.sort > win2.sort) {
            return true;
        } else {
            return false;
        }
    } else if (win1.gid > win2.gid) {
        return false;
    } else {
        return true;
    }
}
void MainManager::SendRemoteCmd(int chid, QString cmd)
{
    QString qsRemoteIP = (m_lstRemoteIP.count() > chid) ? m_lstRemoteIP.at(chid) : "192.168.1.85";

    if (NULL != m_pRemoteSocket) {
        m_pRemoteSocket->writeDatagram(cmd.toLatin1(), QHostAddress(qsRemoteIP), 8811);
        m_pRemoteSocket->flush();
    }
}
void MainManager::AppendLog(const QString &log)
{
    if (NULL == m_pRoot)
        return;

    QObject *pctrlobj = m_pRoot->findChild<QObject*>("debugArea");
    if (NULL != pctrlobj) {
        QVariant msg = log;
        QMetaObject::invokeMethod(pctrlobj, "appendLog", Q_ARG(QVariant, msg));
    }
}

void MainManager::Login()
{
    if (NULL == m_pRoot)
        return;

    // new tcp socket
    if (NULL == m_pTcpSocket) {
        m_pTcpSocket = new QTcpSocket();
        connect(m_pTcpSocket, SIGNAL(readyRead()), this, SLOT(onRecvTcpMessage()));
    } else {
        m_pTcpSocket->disconnectFromHost();
    }

    // 直连设备
    if ("0" == m_welcomePageBaseInfo_unionControl) {
        // 1.验证用户
        bool bUserLisence = false;
        for (int i = 0; i < m_lstSystemUser.count(); i++) {
            sUser suser = m_lstSystemUser.at( i );
            if ((suser.uUser != m_welcomePageBaseInfo_user) || (suser.uPassword != m_welcomePageBaseInfo_password))
                continue;

            bUserLisence = true;
            break;
        }

        // 2.获取规模
        if ( !bUserLisence )
            return;

        m_nRetryTimes = 0;
        m_pTcpSocket->connectToHost(QHostAddress(m_welcomePageBaseInfo_ip), m_welcomePageBaseInfo_port.toInt());
        m_pTcpSocket->waitForConnected( 5000 );
    } else {
        // 联控
        m_currentUserID = -1;

        m_nRetryTimes = 0;
        m_pTcpSocket->connectToHost(QHostAddress(m_welcomePageBaseInfo_ip), m_welcomePageBaseInfo_port.toInt());
        m_pTcpSocket->waitForConnected( 5000 );
    }

    m_bRequestFormat = true;
    onRequestFormat();

    // 20秒钟没有结果反向通知前端
    QTimer::singleShot(20*1000, this, SLOT(onGetFormatError()));
}
void MainManager::SendTcpData(const QString &cmd)
{
    // 判断是否包含汉字
    if (NULL != m_pTcpSocket) {
        qDebug() << "tcp send: " << cmd;
        m_pTcpSocket->write(cmd.toLatin1(), cmd.length());
        m_pTcpSocket->flush();
    }
}
void MainManager::gwinsize(int gid, int winid, int chid, int l, int t, int r, int b)
{
    QString cmd;
    if ("0" == m_welcomePageBaseInfo_unionControl)
        cmd = QString("gwinsize %1 %2 %3 %4 %5 %6 %7\r\n")
                .arg(gid)
                .arg(winid)
                .arg(chid)
                .arg(l)
                .arg(t)
                .arg(r)
                .arg(b);
    else
        cmd = EncodeStandardJson("winsize", QString("%1 %2 %3 %4 %5 %6 %7 %8 %9")
                                                .arg(gid)
                                                .arg(chid)
                                                .arg(winid)
                                                .arg(l)
                                                .arg(t)
                                                .arg(r)
                                                .arg(b)
                                                .arg(0)
                                                .arg(0));

    SendTcpData( cmd );
}
void MainManager::gwinswitch(int gid, int winid)
{
    QString cmd;
    if ("0" == m_welcomePageBaseInfo_unionControl)
        cmd = QString("gwinswitch %1 %2\r\n")
            .arg(gid)
            .arg(winid);
    else
        cmd = EncodeStandardJson("winswitch", QString("%1 %2 %3 %4 %5").arg(gid).arg(winid).arg(0).arg(0).arg(0));

    SendTcpData( cmd );
}
void MainManager::greset(int gid)
{
    QString cmd;
    if ("0" == m_welcomePageBaseInfo_unionControl)
        cmd = QString("greset %1\r\n").arg(gid);
    else
        cmd = EncodeStandardJson("reset", QString::number(gid));

    SendTcpData( cmd );
}
void MainManager::gload(int gid, int sid)
{
    qDebug() << gid << sid << "~~~~~~~~`";
    QString cmd;
    if ("0" == m_welcomePageBaseInfo_unionControl)
        cmd = QString("gload %1 %2\r\n").arg(gid).arg(sid);
    else
        cmd = EncodeStandardJson("gload", QString("%1 %2").arg(gid).arg(sid));

    SendTcpData( cmd );
}
void MainManager::addShortCutScene(int gid, int sid)
{
    if ("0" == m_welcomePageBaseInfo_unionControl) {
        // 2.存文件
        QFile file("qMarkViewConfig.xml");
        if ( !file.exists() ) {
            file.setFileName(":/resource/config.xml");
        }
        if ( !file.open(QIODevice::ReadOnly) ) {
            return;
        }

        // 将文件内容读到QDomDocument中
        QDomDocument doc;
        bool bLoadFile = doc.setContent(&file);
        file.close();

        if ( !bLoadFile )
            return;

        // 二级链表
        QDomElement docElem = doc.documentElement();

        for (int i = 0; i < docElem.childNodes().count(); i++) {
            QDomNode node = docElem.childNodes().at(i);
            if ( !node.isElement() )
                continue;

            QDomElement ele = node.toElement();
            if (node.nodeName() == "Device") {
                QString ip = ele.attribute("ip");
                QString port = ele.attribute("port");

                if ((ip != m_welcomePageBaseInfo_ip) || (port != m_welcomePageBaseInfo_port))
                    continue;

                // IP和端口对不上则认为是新的设备，全部重新构造
                for (int j = 0; j < ele.childNodes().count(); j++) {
                    QDomNode groupNode = ele.childNodes().at(j);
                    if ( !groupNode.isElement() )
                        continue;

                    if (groupNode.nodeName() == "Group") {
                        QDomElement groupEle = groupNode.toElement();
                        if (gid != groupEle.attribute("id").toInt())
                            continue;

                        for (int k = 0; k < groupEle.childNodes().count(); k++) {
                            QDomNode sceneNode = groupEle.childNodes().at(k);
                            if ( !sceneNode.isElement() )
                                continue;

                            QDomElement sceneEle = sceneNode.toElement();
                            if (sid != sceneEle.attribute("id").toInt())
                                continue;

                            sceneEle.setAttribute("shortcut", 1);
                        }
                    }
                }
            }
        }

        // 写入文件
        file.setFileName("qMarkViewConfig.xml");
        if( !file.open(QIODevice::WriteOnly | QIODevice::Truncate) ) {
            return;
        }

        QTextStream out(&file);
        doc.save(out,4);
        file.close();
    } else {
        QList<sUnionScene> lstScene = m_mapUnionGroupScene.value( gid );
        for (int i = 0; i < lstScene.count(); i++) {
            sUnionScene sscene = lstScene.at( i );
            if (sid != sscene.id)
                continue;

            sscene.shortcut = 1;
            lstScene.replace(i, sscene);
            m_mapUnionGroupScene.insert(gid, lstScene);
            break;
        }
    }
}
QVariantList MainManager::getShortCutScene(int gid)
{
    QVariantList lstRes;
    if ("0" == m_welcomePageBaseInfo_unionControl) {
        // 2.存文件
        QFile file("qMarkViewConfig.xml");
        if ( !file.exists() ) {
            file.setFileName(":/resource/config.xml");
        }
        if ( !file.open(QIODevice::ReadOnly) ) {
            return lstRes;
        }

        // 将文件内容读到QDomDocument中
        QDomDocument doc;
        bool bLoadFile = doc.setContent(&file);
        file.close();

        if ( !bLoadFile )
            return lstRes;

        // 二级链表
        QDomElement docElem = doc.documentElement();

        for (int i = 0; i < docElem.childNodes().count(); i++) {
            QDomNode node = docElem.childNodes().at(i);
            if ( !node.isElement() )
                continue;

            QDomElement ele = node.toElement();
            if (node.nodeName() == "Device") {
                QString ip = ele.attribute("ip");
                QString port = ele.attribute("port");

                if ((ip != m_welcomePageBaseInfo_ip) || (port != m_welcomePageBaseInfo_port))
                    continue;

                // IP和端口对不上则认为是新的设备，全部重新构造
                for (int j = 0; j < ele.childNodes().count(); j++) {
                    QDomNode groupNode = ele.childNodes().at(j);
                    if ( !groupNode.isElement() )
                        continue;

                    if (groupNode.nodeName() == "Group") {
                        QDomElement groupEle = groupNode.toElement();
                        if (gid != groupEle.attribute("id").toInt())
                            continue;

                        for (int k = 0; k < groupEle.childNodes().count(); k++) {
                            QDomNode sceneNode = groupEle.childNodes().at(k);
                            if ( !sceneNode.isElement() )
                                continue;

                            QDomElement sceneEle = sceneNode.toElement();
                            if (1 != sceneEle.attribute("shortcut").toInt())
                                continue;

                            lstRes << sceneEle.attribute("id") << sceneEle.attribute("name");
                        }
                    }
                }
            }
        }

        // 写入文件
        file.setFileName("qMarkViewConfig.xml");
        if( !file.open(QIODevice::WriteOnly | QIODevice::Truncate) ) {
            return lstRes;
        }

        QTextStream out(&file);
        doc.save(out,4);
        file.close();
    } else {
        QList<sUnionScene> lstScene = m_mapUnionGroupScene.value( gid );
        for (int i = 0; i < lstScene.count(); i++) {
            sUnionScene sscene = lstScene.at( i );
            if (1 != sscene.shortcut)
                continue;

            lstRes << sscene.id << sscene.name;
        }
    }

    return lstRes;
}
void MainManager::addscene(int gid, QVariantList lst)
{
    if ("0" == m_welcomePageBaseInfo_unionControl) {
        // 单机
        QList<int> lstSceneID = m_mapGroupScene.value( gid );
        int sid = 0;
        for (int i = 0; i < lstSceneID.count()+1; i++) {
            if ( lstSceneID.contains(i) )
                continue;

            sid = i;
            break;
        }

        // 1.发送指令
        QString cmd = QString("gsave %1 %2\r\n").arg(gid).arg(sid);
        SendTcpData( cmd );

        // 2.存文件
        QFile file("qMarkViewConfig.xml");
        if ( !file.exists() ) {
            file.setFileName(":/resource/config.xml");
        }
        if ( !file.open(QIODevice::ReadOnly) ) {
            return;
        }

        // 将文件内容读到QDomDocument中
        QDomDocument doc;
        bool bLoadFile = doc.setContent(&file);
        file.close();

        if ( !bLoadFile )
            return;

        // 二级链表
        QDomElement docElem = doc.documentElement();

        for (int i = 0; i < docElem.childNodes().count(); i++) {
            QDomNode node = docElem.childNodes().at(i);
            if ( !node.isElement() )
                continue;

            QDomElement ele = node.toElement();
            if (node.nodeName() == "Device") {
                QString ip = ele.attribute("ip");
                QString port = ele.attribute("port");

                if ((ip != m_welcomePageBaseInfo_ip) || (port != m_welcomePageBaseInfo_port))
                    continue;

                // IP和端口对不上则认为是新的设备，全部重新构造
                for (int j = 0; j < ele.childNodes().count(); j++) {
                    QDomNode groupNode = ele.childNodes().at(j);
                    if ( !groupNode.isElement() )
                        continue;

                    if (groupNode.nodeName() == "Group") {
                        QDomElement groupEle = groupNode.toElement();
                        if (gid != groupEle.attribute("id").toInt())
                            continue;

                        bool bExistScene = false;
                        for (int k = 0; k < groupEle.childNodes().count(); k++) {
                            QDomNode sceneNode = groupEle.childNodes().at(k);
                            if ( !sceneNode.isElement() )
                                continue;

                            QDomElement sceneEle = sceneNode.toElement();
                            if (sid != sceneEle.attribute("id").toInt())
                                continue;

                            bExistScene = true;

                            // 清空链表不能使用childEle.clear();否则不能添加子node，原因未知
                            while (sceneEle.childNodes().count() != 0)
                                sceneEle.removeChild(sceneEle.childNodes().at(0));

                            for (int l = 0; l < lst.count()/6; l++) {
                                int chid = lst.at(l*6+0).toInt();
                                int winid = lst.at(l*6+1).toInt();
                                int ll = lst.at(l*6+2).toInt();
                                int t = lst.at(l*6+3).toInt();
                                int w = lst.at(l*6+4).toInt();
                                int h = lst.at(l*6+5).toInt();

                                QDomElement eleNode = doc.createElement(QString("Node"));
                                eleNode.setAttribute(QString("chid"), QString::number(chid));
                                eleNode.setAttribute(QString("winid"), QString::number(winid));
                                eleNode.setAttribute(QString("l"), QString::number(ll));
                                eleNode.setAttribute(QString("t"), QString::number(t));
                                eleNode.setAttribute(QString("w"), QString::number(w));
                                eleNode.setAttribute(QString("h"), QString::number(h));

                                sceneEle.appendChild( eleNode );
                            }
                        }

                        // 新建场景
                        if ( !bExistScene ) {
                            QDomElement sceneNode = doc.createElement(QString("Scene"));
                            sceneNode.setAttribute(QString("id"), QString::number(sid));
                            sceneNode.setAttribute(QString("name"), QString("scene%1").arg(sid+1));
                            sceneNode.setAttribute(QString("shortcut"), QString::number(0));
                            for (int l = 0; l < lst.count()/6; l++) {
                                int chid = lst.at(l*6+0).toInt();
                                int winid = lst.at(l*6+1).toInt();
                                int ll = lst.at(l*6+2).toInt();
                                int t = lst.at(l*6+3).toInt();
                                int w = lst.at(l*6+4).toInt();
                                int h = lst.at(l*6+5).toInt();

                                QDomElement eleNode = doc.createElement(QString("Node"));
                                eleNode.setAttribute(QString("chid"), QString::number(chid));
                                eleNode.setAttribute(QString("winid"), QString::number(winid));
                                eleNode.setAttribute(QString("l"), QString::number(ll));
                                eleNode.setAttribute(QString("t"), QString::number(t));
                                eleNode.setAttribute(QString("w"), QString::number(w));
                                eleNode.setAttribute(QString("h"), QString::number(h));

                                qDebug() << chid << winid << ll << t << w << h << "~~";
                                sceneNode.appendChild( eleNode );
                            }

                            groupEle.appendChild( sceneNode );
                        }
                    }
                }
            }
        }

        // 写入文件
        file.setFileName("qMarkViewConfig.xml");
        if( !file.open(QIODevice::WriteOnly | QIODevice::Truncate) ) {
            return;
        }

        QTextStream out(&file);
        doc.save(out,4);
        file.close();
    } else {
        QList<sUnionScene> lstScene = m_mapUnionGroupScene.value( gid );
        QList<int> lstSceneID;
        for (int i = 0; i < lstScene.count(); i++) {
            lstSceneID.append( lstScene.at(i).id );
        }
        int sid = 0;
        for (int i = 0; i < lstSceneID.count()+1; i++) {
            if ( lstSceneID.contains(i) )
                continue;

            sid = i;
            break;
        }

        QJsonObject json;
        json.insert("cmdKey", "addScene");

        QJsonObject jsonScene;
        jsonScene.insert("roomid", gid);
        jsonScene.insert("groupsceneid", 0);

        jsonScene.insert("id", sid);
        jsonScene.insert("iscycle", 0);
        jsonScene.insert("name", QString("Scene%1").arg(sid+1));

        // 添加场景数据
        QJsonArray arrSceneData;

        for (int i = 0; i < lst.count()/6; i++) {
            int chid = lst.at(i*6+0).toInt();
            int winid = lst.at(i*6+1).toInt();
            int l = lst.at(i*6+2).toInt();
            int t = lst.at(i*6+3).toInt();
            int w = lst.at(i*6+4).toInt();
            int h = lst.at(i*6+5).toInt();

            // 构造屏组对象
            QJsonObject jsonSceneData;
            jsonSceneData.insert("roomid", gid);
            jsonSceneData.insert("groupsceneid", 0);
            jsonSceneData.insert("sceneid", sid);
            jsonSceneData.insert("groupdisplayid", gid);
            jsonSceneData.insert("channelid", chid);
            jsonSceneData.insert("channeltype", 0);
            jsonSceneData.insert("copyindex", 0);
            jsonSceneData.insert("left", l);
            jsonSceneData.insert("top", t);
            jsonSceneData.insert("width", w);
            jsonSceneData.insert("height", h);
            jsonSceneData.insert("ipvsegmentation", 1);
            jsonSceneData.insert("ipvip1", "");
            jsonSceneData.insert("ipvip2", "");
            jsonSceneData.insert("ipvip3", "");
            jsonSceneData.insert("ipvip4", "");
            jsonSceneData.insert("ipvip5", "");
            jsonSceneData.insert("ipvip6", "");
            jsonSceneData.insert("ipvip7", "");
            jsonSceneData.insert("ipvip8", "");
            jsonSceneData.insert("ipvip9", "");
            jsonSceneData.insert("ipvip10", "");
            jsonSceneData.insert("ipvip11", "");
            jsonSceneData.insert("ipvip12", "");
            jsonSceneData.insert("ipvip13", "");
            jsonSceneData.insert("ipvip14", "");
            jsonSceneData.insert("ipvip15", "");
            jsonSceneData.insert("ipvip16", "");
            jsonSceneData.insert("winid", winid);

            arrSceneData.append( jsonSceneData );
        }

        // 在房间属性sceneDatas下添加场景
        jsonScene.insert("sceneDatas", arrSceneData);

        json.insert("cmdValue", jsonScene);

        QJsonDocument document;
        document.setObject(json);
        QByteArray byte_array = document.toJson(QJsonDocument::Compact);

        QString cmdValue = QString::fromLocal8Bit( byte_array ) + CMDOVERFLAG;

        SendTcpData( cmdValue );
    }
}
void MainManager::updatescene(int gid, int sid, QVariantList lst)
{
    if ("0" == m_welcomePageBaseInfo_unionControl) {
        // 单机
        // 1.发送指令
        QString cmd = QString("gsave %1 %2\r\n").arg(gid).arg(sid);
        SendTcpData( cmd );

        // 2.存文件
        QFile file("qMarkViewConfig.xml");
        if ( !file.exists() ) {
            file.setFileName(":/resource/config.xml");
        }
        if ( !file.open(QIODevice::ReadOnly) ) {
            return;
        }

        // 将文件内容读到QDomDocument中
        QDomDocument doc;
        bool bLoadFile = doc.setContent(&file);
        file.close();

        if ( !bLoadFile )
            return;

        // 二级链表
        QDomElement docElem = doc.documentElement();

        for (int i = 0; i < docElem.childNodes().count(); i++) {
            QDomNode node = docElem.childNodes().at(i);
            if ( !node.isElement() )
                continue;

            QDomElement ele = node.toElement();
            if (node.nodeName() == "Device") {
                QString ip = ele.attribute("ip");
                QString port = ele.attribute("port");

                if ((ip != m_welcomePageBaseInfo_ip) || (port != m_welcomePageBaseInfo_port))
                    continue;

                // IP和端口对不上则认为是新的设备，全部重新构造
                for (int j = 0; j < ele.childNodes().count(); j++) {
                    QDomNode groupNode = ele.childNodes().at(j);
                    if ( !groupNode.isElement() )
                        continue;

                    if (groupNode.nodeName() == "Group") {
                        QDomElement groupEle = groupNode.toElement();
                        if (gid != groupEle.attribute("id").toInt())
                            continue;

                        for (int k = 0; k < groupEle.childNodes().count(); k++) {
                            QDomNode sceneNode = groupEle.childNodes().at(k);
                            if ( !sceneNode.isElement() )
                                continue;

                            QDomElement sceneEle = sceneNode.toElement();
                            if (sid != sceneEle.attribute("id").toInt())
                                continue;

                            // 清空链表不能使用childEle.clear();否则不能添加子node，原因未知
                            while (sceneEle.childNodes().count() != 0)
                                sceneEle.removeChild(sceneEle.childNodes().at(0));

                            for (int l = 0; l < lst.count()/6; l++) {
                                int chid = lst.at(l*6+0).toInt();
                                int winid = lst.at(l*6+1).toInt();
                                int ll = lst.at(l*6+2).toInt();
                                int t = lst.at(l*6+3).toInt();
                                int w = lst.at(l*6+4).toInt();
                                int h = lst.at(l*6+5).toInt();

                                QDomElement eleNode = doc.createElement(QString("Node"));
                                eleNode.setAttribute(QString("chid"), QString::number(chid));
                                eleNode.setAttribute(QString("winid"), QString::number(winid));
                                eleNode.setAttribute(QString("l"), QString::number(ll));
                                eleNode.setAttribute(QString("t"), QString::number(t));
                                eleNode.setAttribute(QString("w"), QString::number(w));
                                eleNode.setAttribute(QString("h"), QString::number(h));

                                sceneEle.appendChild( eleNode );
                            }
                        }
                    }
                }
            }
        }

        // 写入文件
        file.setFileName("qMarkViewConfig.xml");
        if( !file.open(QIODevice::WriteOnly | QIODevice::Truncate) ) {
            return;
        }

        QTextStream out(&file);
        doc.save(out,4);
        file.close();
    } else {
        QJsonObject json;
        json.insert("cmdKey", "updateSceneData");

        QJsonObject jsonScene;
        jsonScene.insert("roomid", gid);
        jsonScene.insert("groupsceneid", 0);

        jsonScene.insert("id", sid);
        jsonScene.insert("iscycle", 0);
        jsonScene.insert("name", QString("Scene%1").arg(sid+1));

        // 添加场景数据
        QJsonArray arrSceneData;

        for (int i = 0; i < lst.count()/6; i++) {
            int chid = lst.at(i*6+0).toInt();
            int winid = lst.at(i*6+1).toInt();
            int l = lst.at(i*6+2).toInt();
            int t = lst.at(i*6+3).toInt();
            int w = lst.at(i*6+4).toInt();
            int h = lst.at(i*6+5).toInt();

            // 构造屏组对象
            QJsonObject jsonSceneData;
            jsonSceneData.insert("roomid", gid);
            jsonSceneData.insert("groupsceneid", 0);
            jsonSceneData.insert("sceneid", sid);
            jsonSceneData.insert("groupdisplayid", gid);
            jsonSceneData.insert("channelid", chid);
            jsonSceneData.insert("channeltype", 0);
            jsonSceneData.insert("copyindex", 0);
            jsonSceneData.insert("left", l);
            jsonSceneData.insert("top", t);
            jsonSceneData.insert("width", w);
            jsonSceneData.insert("height", h);
            jsonSceneData.insert("ipvsegmentation", 1);
            jsonSceneData.insert("ipvip1", "");
            jsonSceneData.insert("ipvip2", "");
            jsonSceneData.insert("ipvip3", "");
            jsonSceneData.insert("ipvip4", "");
            jsonSceneData.insert("ipvip5", "");
            jsonSceneData.insert("ipvip6", "");
            jsonSceneData.insert("ipvip7", "");
            jsonSceneData.insert("ipvip8", "");
            jsonSceneData.insert("ipvip9", "");
            jsonSceneData.insert("ipvip10", "");
            jsonSceneData.insert("ipvip11", "");
            jsonSceneData.insert("ipvip12", "");
            jsonSceneData.insert("ipvip13", "");
            jsonSceneData.insert("ipvip14", "");
            jsonSceneData.insert("ipvip15", "");
            jsonSceneData.insert("ipvip16", "");
            jsonSceneData.insert("winid", winid);

            arrSceneData.append( jsonSceneData );
        }

        // 在房间属性sceneDatas下添加场景
        jsonScene.insert("sceneDatas", arrSceneData);

        json.insert("cmdValue", jsonScene);

        QJsonDocument document;
        document.setObject(json);
        QByteArray byte_array = document.toJson(QJsonDocument::Compact);

        QString cmdValue = QString::fromLocal8Bit( byte_array ) + CMDOVERFLAG;

        SendTcpData( cmdValue );
    }
}
sUnionScene MainManager::DecodeSceneJson(const QString &json, int &gid)
{
    sUnionScene swindowscene;
    QJsonParseError json_error;
    QJsonDocument parse_doucment = QJsonDocument::fromJson(json.toLocal8Bit(), &json_error);
    if(json_error.error != QJsonParseError::NoError)
        return swindowscene;

    if( !parse_doucment.isObject() )
        return swindowscene;

    QJsonObject obj = parse_doucment.object();
    if( !obj.contains("cmdValue") )
        return swindowscene;

    // 这里的cmdValue是数组
    QJsonValue cmdValue = obj.take("cmdValue");
    if( !cmdValue.isObject() )
        return swindowscene;

    QJsonObject objScene = cmdValue.toObject();

    gid = objScene.value("roomid").toInt();
    swindowscene.id = objScene.value("id").toInt();
    swindowscene.name = objScene.value("name").toString();
    swindowscene.shortcut = 0;

    // 循环场景数据
    QJsonArray arrSceneDatas = objScene.value("sceneDatas").toArray();
    for (int l = 0; l < arrSceneDatas.count(); l++) {
        QJsonObject jsonSceneData = arrSceneDatas.at(l).toObject();
        if ( jsonSceneData.isEmpty() )
            continue;

        sSignalWindow swindowscenedata;

        swindowscenedata.chid = jsonSceneData.value("channelid").toInt();
        swindowscenedata.winid = jsonSceneData.value("winid").toInt();
        swindowscenedata.rect = QRect(jsonSceneData.value("left").toInt(),
                                      jsonSceneData.value("top").toInt(),
                                      jsonSceneData.value("width").toInt(),
                                      jsonSceneData.value("height").toInt());

        // 添加到场景
        swindowscene.lstWindow.append( swindowscenedata );
    }

    return swindowscene;
}
void MainManager::delScene(int gid, int sid)
{
    if ("0" == m_welcomePageBaseInfo_unionControl) {
        // 直接修改文件
        QFile file("qMarkViewConfig.xml");
        if ( !file.exists() ) {
            file.setFileName(":/resource/config.xml");
        }
        if ( !file.open(QIODevice::ReadOnly) ) {
            return;
        }

        // 将文件内容读到QDomDocument中
        QDomDocument doc;
        bool bLoadFile = doc.setContent(&file);
        file.close();

        if ( !bLoadFile )
            return;

        // 二级链表
        QDomElement docElem = doc.documentElement();

        for (int i = 0; i < docElem.childNodes().count(); i++) {
            QDomNode node = docElem.childNodes().at(i);
            if ( !node.isElement() )
                continue;

            QDomElement ele = node.toElement();
            if (node.nodeName() == "Device") {
                QString ip = ele.attribute("ip");
                QString port = ele.attribute("port");

                if ((ip != m_welcomePageBaseInfo_ip) || (port != m_welcomePageBaseInfo_port))
                    continue;

                // IP和端口对不上则认为是新的设备，全部重新构造
                for (int j = 0; j < ele.childNodes().count(); j++) {
                    QDomNode groupNode = ele.childNodes().at(j);
                    if ( !groupNode.isElement() )
                        continue;

                    if (groupNode.nodeName() == "Group") {
                        QDomElement groupEle = groupNode.toElement();
                        if (gid != groupEle.attribute("id").toInt())
                            continue;

                        for (int k = 0; k < groupEle.childNodes().count(); k++) {
                            QDomNode sceneNode = groupEle.childNodes().at(k);
                            if ( !sceneNode.isElement() )
                                continue;

                            QDomElement sceneEle = sceneNode.toElement();
                            if (sid != sceneEle.attribute("id").toInt())
                                continue;

                            // 1.删除文件
                            groupEle.removeChild( sceneEle );

                            // 2.修改内存
                            QList<int> lstSceneID = m_mapGroupScene.value( gid );
                            lstSceneID.removeOne( sid );
                            m_mapGroupScene.insert(gid, lstSceneID);
                        }
                    }
                }
            }
        }

        // 写入文件
        file.setFileName("qMarkViewConfig.xml");
        if( !file.open(QIODevice::WriteOnly | QIODevice::Truncate) ) {
            return;
        }

        QTextStream out(&file);
        doc.save(out,4);
        file.close();
    } else {
        // 发送指令给服务器
        SendTcpData( EncodeStandardJson("deleteScene", QString("%1 %2 0").arg(sid).arg(gid)) );
    }
}
QVariantList MainManager::getSceneList(int gid)
{
    QVariantList lstRes;
    if ("0" == m_welcomePageBaseInfo_unionControl) {
        // 如果系统内没有配置文件则直接使用系统内的配置文件
        QFile file("qMarkViewConfig.xml");
        if ( !file.exists() ) {
            file.setFileName(":/resource/config.xml");
        }
        if ( !file.open(QIODevice::ReadOnly) ) {
            return lstRes;
        }

        // 将文件内容读到QDomDocument中
        QDomDocument doc;
        bool bLoadFile = doc.setContent(&file);
        file.close();

        if ( !bLoadFile )
            return lstRes;

        // 二级链表
        QDomElement docElem = doc.documentElement();

        for (int i = 0; i < docElem.childNodes().count(); i++) {
            QDomNode node = docElem.childNodes().at(i);
            if ( !node.isElement() )
                continue;

            QDomElement ele = node.toElement();
            if (node.nodeName() == "Device") {
                QString ip = ele.attribute("ip");
                QString port = ele.attribute("port");

                if ((ip != m_welcomePageBaseInfo_ip) || (port != m_welcomePageBaseInfo_port))
                    continue;

                // IP和端口对不上则认为是新的设备，全部重新构造
                for (int j = 0; j < ele.childNodes().count(); j++) {
                    QDomNode groupNode = ele.childNodes().at(j);
                    if ( !groupNode.isElement() )
                        continue;

                    if (groupNode.nodeName() == "Group") {
                        QDomElement groupEle = groupNode.toElement();
                        if (gid != groupEle.attribute("id").toInt())
                            continue;

                        QList<int> lstSceneID;
                        for (int k = 0; k < groupEle.childNodes().count(); k++) {
                            QDomNode sceneNode = groupEle.childNodes().at(k);
                            if ( !sceneNode.isElement() )
                                continue;

                            QDomElement sceneEle = sceneNode.toElement();
                            int sid = sceneEle.attribute("id").toInt();
                            QString sname = sceneEle.attribute("name");

                            lstRes << sid << sname;
                            lstSceneID.append( sid );
                        }
                        // 保存sceneid list
                        if ( m_mapGroupScene.contains(gid) ) {
                            m_mapGroupScene.remove( gid );
                        }
                        m_mapGroupScene.insert(gid, lstSceneID);
                    }
                }
            }
        }
    } else {
        QList<sUnionScene> lstScene = m_mapUnionGroupScene.value( gid );
        for (int i = 0; i < lstScene.count(); i++) {
            sUnionScene sscene = lstScene.at( i );
            lstRes << sscene.id << sscene.name;
        }
    }

    return lstRes;
}
QVariantList MainManager::getSceneData(int gid, int ssid)
{
    QVariantList lstRes;

    if ("0" == m_welcomePageBaseInfo_unionControl) {
        // 如果系统内没有配置文件则直接使用系统内的配置文件
        QFile file("qMarkViewConfig.xml");
        if ( !file.exists() ) {
            file.setFileName(":/resource/config.xml");
        }
        if ( !file.open(QIODevice::ReadOnly) ) {
            return lstRes;
        }

        // 将文件内容读到QDomDocument中
        QDomDocument doc;
        bool bLoadFile = doc.setContent(&file);
        file.close();

        if ( !bLoadFile )
            return lstRes;

        // 二级链表
        QDomElement docElem = doc.documentElement();

        for (int i = 0; i < docElem.childNodes().count(); i++) {
            QDomNode node = docElem.childNodes().at(i);
            if ( !node.isElement() )
                continue;

            QDomElement ele = node.toElement();
            if (node.nodeName() == "Device") {
                QString ip = ele.attribute("ip");
                QString port = ele.attribute("port");

                if ((ip != m_welcomePageBaseInfo_ip) || (port != m_welcomePageBaseInfo_port))
                    continue;

                // IP和端口对不上则认为是新的设备，全部重新构造
                for (int j = 0; j < ele.childNodes().count(); j++) {
                    QDomNode groupNode = ele.childNodes().at(j);
                    if ( !groupNode.isElement() )
                        continue;

                    if (groupNode.nodeName() == "Group") {
                        QDomElement groupEle = groupNode.toElement();
                        if (gid != groupEle.attribute("id").toInt())
                            continue;

                        for (int k = 0; k < groupEle.childNodes().count(); k++) {
                            QDomNode sceneNode = groupEle.childNodes().at(k);
                            if ( !sceneNode.isElement() )
                                continue;

                            QDomElement sceneEle = sceneNode.toElement();
                            int sid = sceneEle.attribute("id").toInt();
                            if (sid != ssid)
                                continue;

                            for (int l = 0; l < sceneEle.childNodes().count(); l++) {
                                QDomNode sceneWinNode = sceneEle.childNodes().at(l);
                                if ( !sceneWinNode.isElement() )
                                    continue;

                                QDomElement sceneWinEle = sceneWinNode.toElement();
                                int chid = sceneWinEle.attribute("chid").toInt();
                                int winid = sceneWinEle.attribute("winid").toInt();
                                int ll = sceneWinEle.attribute("l").toInt();
                                int t = sceneWinEle.attribute("t").toInt();
                                int w = sceneWinEle.attribute("w").toInt();
                                int h = sceneWinEle.attribute("h").toInt();

                                lstRes << chid << winid << ll << t << w << h;
                            }
                        }
                    }
                }
            }
        }
    } else {
        QList<sUnionScene> lstScene = m_mapUnionGroupScene.value( gid );
        for (int i = 0; i < lstScene.count(); i++) {
            sUnionScene sscene = lstScene.at( i );
            if (ssid != sscene.id)
                continue;

            for (int j = 0; j < sscene.lstWindow.count(); j++) {
                sSignalWindow swindow = sscene.lstWindow.at( j );
                lstRes << swindow.chid << swindow.winid << swindow.rect.left() << swindow.rect.top() << swindow.rect.width() << swindow.rect.height();
            }
        }

    }

    return lstRes;
}

void MainManager::RequestControlBySignalWindow(int groupid, int chid, int chtype, int winid)
{
    SendTcpData( EncodeStandardJson("requestControlBySignalWindow", QString("%1 %2 %3 %4").arg(groupid).arg(chid).arg(chtype).arg(winid)) );
}

void MainManager::RequestOver(int gid)
{
    SendTcpData( EncodeStandardJson("over", QString::number(gid)) );
}

void MainManager::onGetFormatError()
{
    if ((NULL != m_pRoot) && m_bRequestFormat) {
        m_bRequestFormat = false;
        QVariant msg = 1;
        QMetaObject::invokeMethod(m_pRoot, "showErrorMessageBox", Q_ARG(QVariant, msg));
    }
}
// 配置文件格式如下，如不存在则创建qMarkviewConfig.xml
//<BR>
//	<SystemUser>
//		<User user="admin" password="" level="0"/>
//	</SystemUser>
//	<WelcomeBaseInfo user="" password="" savePassword="0" ip="" port="" unionControl="0"/>
//	<Device ip="" port="">
//		<Channel pCount="" hCount="" iCount="" vCount="" pName="PC1;PC2;;;" hName="" iName="" vName=""/>
//		<Group id="0" arrX="3" arrY="3" width="5760" height="3240">
//			<Scene id="1" name="scene1">
//			</Scene>
//		</Group>
//		<Group id="1" arrX="2" arrY="2" width="3840" height="2160">
//		</Group>
//	</Device>
//</BR>
void MainManager::initConfigFile()
{
    // 初始化基础数据
    m_welcomePageBaseInfo_user = "";
    m_welcomePageBaseInfo_password = "";
    m_welcomePageBaseInfo_savePassword = "0";
    m_welcomePageBaseInfo_ip = "";
    m_welcomePageBaseInfo_port = "";
    m_welcomePageBaseInfo_unionControl = "0";

    // 如果系统内没有配置文件则直接使用系统内的配置文件
    QFile file("qMarkViewConfig.xml");
    if ( !file.exists() ) {
        file.setFileName(":/resource/config.xml");
    }
    if ( !file.open(QIODevice::ReadOnly) ) {
        return;
    }

    // 将文件内容读到QDomDocument中
    QDomDocument doc;
    bool bLoadFile = doc.setContent(&file);
    file.close();

    if ( !bLoadFile )
        return;

    // 二级链表
    QDomElement docElem = doc.documentElement();

    // 循环添加用户
    for (int i = 0; i < docElem.childNodes().count(); i++) {
        QDomNode node = docElem.childNodes().at(i);
        if ( !node.isElement() )
            continue;

        QDomElement ele = node.toElement();
        if (node.nodeName() == "WelcomeBaseInfo") {
            m_welcomePageBaseInfo_user = ele.attribute(QString("user"));
            m_welcomePageBaseInfo_password = ele.attribute(QString("password"));
            m_welcomePageBaseInfo_savePassword = ele.attribute(QString("savePassword"));
            m_welcomePageBaseInfo_ip = ele.attribute(QString("ip"));
            m_welcomePageBaseInfo_port = ele.attribute(QString("port"));
            m_welcomePageBaseInfo_unionControl = ele.attribute(QString("unionControl"));
        }

        if (node.nodeName() == "SystemUser") {
            for (int j = 0; j < ele.childNodes().count(); j++) {
                QDomNode nodeUser = ele.childNodes().at(i);
                if ( !nodeUser.isElement() )
                    continue;

                QDomElement eleUser = nodeUser.toElement();
                sUser suser;
                suser.uid = eleUser.attribute("id").toInt();
                suser.uUser = eleUser.attribute("user");
                suser.uPassword = eleUser.attribute("password");
                suser.uLevel = eleUser.attribute("level").toInt();
                m_lstSystemUser.append( suser );
            }
        }
    }
}
void MainManager::initRemoteIPList()
{
    QFile file("remoteConfig.txt");
    if ( !file.exists() )
        return;
    if ( !file.open(QIODevice::ReadOnly) )
        return;

    while ( !file.atEnd() )
        m_lstRemoteIP.append( QString( file.readLine() ).trimmed() );
}
void MainManager::SaveWelcomePageBaseInfo()
{
    QFile file("qMarkViewConfig.xml");
    if ( !file.exists() ) {
        file.setFileName(":/resource/config.xml");
    }
    if ( !file.open(QIODevice::ReadOnly) ) {
        return;
    }

    // 将文件内容读到QDomDocument中
    QDomDocument doc;
    bool bLoadFile = doc.setContent(&file);
    file.close();

    if ( !bLoadFile )
        return;

    // 二级链表
    QDomElement docElem = doc.documentElement();

    // 循环添加用户
    for (int i = 0; i < docElem.childNodes().count(); i++) {
        QDomNode node = docElem.childNodes().at(i);
        if ( !node.isElement() )
            continue;

        if (node.nodeName() != "WelcomeBaseInfo")
            continue;

        QDomElement ele = node.toElement();
        ele.setAttribute(QString("user"), m_welcomePageBaseInfo_user);
        ele.setAttribute(QString("password"), m_welcomePageBaseInfo_password);
        ele.setAttribute(QString("savePassword"), m_welcomePageBaseInfo_savePassword);
        ele.setAttribute(QString("ip"), m_welcomePageBaseInfo_ip);
        ele.setAttribute(QString("port"), m_welcomePageBaseInfo_port);
        ele.setAttribute(QString("unionControl"), m_welcomePageBaseInfo_unionControl);
    }

    // 写入文件
    file.setFileName("qMarkViewConfig.xml");
    if( !file.open(QIODevice::WriteOnly | QIODevice::Truncate) ) {
        return;
    }

    QTextStream out(&file);
    doc.save(out,4);
    file.close();
}
void MainManager::saveConfigFile(QVariantList lstInputChannel, QVariantList lstGroupDisplay, QVariantList &lstInputChannelRes, QVariantList &lstGroupDisplayRes)
{
    QFile file("qMarkViewConfig.xml");
    if ( !file.exists() ) {
        file.setFileName(":/resource/config.xml");
    }
    if ( !file.open(QIODevice::ReadOnly) ) {
        return;
    }

    // 将文件内容读到QDomDocument中
    QDomDocument doc;
    bool bLoadFile = doc.setContent(&file);
    file.close();

    if ( !bLoadFile )
        return;

    // 二级链表
    QDomElement docElem = doc.documentElement();

    for (int i = 0; i < docElem.childNodes().count(); i++) {
        QDomNode node = docElem.childNodes().at(i);
        if ( !node.isElement() )
            continue;

        QDomElement ele = node.toElement();
        if (node.nodeName() == "Device") {
            QString ip = ele.attribute("ip");
            QString port = ele.attribute("port");

            // IP和端口对不上则认为是新的设备，全部重新构造
            for (int j = 0; j < ele.childNodes().count(); j++) {
                QDomNode childNode = ele.childNodes().at(j);
                if ( !childNode.isElement() )
                    continue;

                QDomElement childEle = childNode.toElement();
                if (childNode.nodeName() == "Channel") {
                    bool bRebuildChannel = false;
                    if ((ip != m_welcomePageBaseInfo_ip) || (port != m_welcomePageBaseInfo_port)) {
                        bRebuildChannel = true;

                        // 保存设备的IP和端口
                        ele.setAttribute("ip", m_welcomePageBaseInfo_ip);
                        ele.setAttribute("port", m_welcomePageBaseInfo_port);
                    } else {
                        // 已经存在的设备
                        // 1.判断通道数量和名字个数能否对应上
                        if (ele.childNodes().count() != (lstInputChannel.count()/6)) {
                            bRebuildChannel = true;
                        }
                    }

                    // 重新构建通道
                    m_lstInputChannel.clear();
                    if ( bRebuildChannel ) {
                        // 清空链表不能使用childEle.clear();否则不能添加子node，原因未知
                        while (childEle.childNodes().count() != 0)
                            childEle.removeChild(childEle.childNodes().at(0));

                        // 添加节点
                        int pCount = 0, iCount = 0, hCount = 0, vCount = 0;
                        for (int k = 0; k < lstInputChannel.count()/6; k++) {
                            int id = lstInputChannel.at(k*6 + 0).toInt();
                            int type = lstInputChannel.at(k*6 + 1).toInt();
                            QString qsCurrentName;
                            if (type == 0) {
                                qsCurrentName.append(QString("PC%1").arg(++pCount));
                            }
                            if (type == 9) {
                                qsCurrentName.append(QString("IPV%1").arg(++iCount));
                            }
                            if (type == 3) {
                                qsCurrentName.append(QString("HD%1").arg(++hCount));
                            }
                            if (type == 8) {
                                qsCurrentName.append(QString("VIDEO%1").arg(++vCount));
                            }

                            QDomElement eleNode = doc.createElement(QString("Node"));
                            eleNode.setAttribute(QString("id"), QString::number(id));
                            eleNode.setAttribute(QString("type"), QString::number(type));
                            eleNode.setAttribute(QString("name"), qsCurrentName);

                            childEle.appendChild( eleNode );

                            // 构造QML中使用的channel
                            lstInputChannelRes << QString::number(id) << QString::number(type) << qsCurrentName;

                            m_lstInputChannel << id << qsCurrentName;
                        }
                    } else {
                        for (int k = 0; j < childEle.childNodes().count(); k++) {
                            QDomNode channelNode = childEle.childNodes().at(k);
                            if ( !channelNode.isElement() )
                                continue;

                            QDomElement channelEle = channelNode.toElement();

                            // 构造QML中使用的channel
                            lstInputChannelRes << channelEle.attribute("id")
                                               << channelEle.attribute("type")
                                               << channelEle.attribute("name");

                            m_lstInputChannel << channelEle.attribute("id").toInt() << channelEle.attribute("name");
                        }
                    }
                }

                if (childNode.nodeName() == "Group") {
                    int id = childEle.attribute("id").toInt();
                    QString groupName = childEle.attribute("name");
                    int arrX = childEle.attribute("arrX").toInt();
                    int arrY = childEle.attribute("arrY").toInt();
                    int width = childEle.attribute("width").toInt();
                    int height = childEle.attribute("height").toInt();

                    // 判断是否存在
                    bool bExistGroup = false;
                    for (int k = 0; k < lstGroupDisplay.count() / 7; k++) {
                        int groupid = lstGroupDisplay.at(k*7+0).toInt();
                        int formatx = lstGroupDisplay.at(k*7+1).toInt();
                        int formaty = lstGroupDisplay.at(k*7+2).toInt();
                        int xsize = lstGroupDisplay.at(k*7+3).toInt();
                        int ysize = lstGroupDisplay.at(k*7+4).toInt();

                        if ((id != groupid) || (arrX != formatx) || (arrY != formaty) || (width != xsize) || (height != ysize))
                            continue;

                        lstGroupDisplayRes << groupid << groupName << formatx << formaty << xsize << ysize;

                        bExistGroup = true;
                        for (int l = 0; l < 7; l++) {
                            lstGroupDisplay.removeAt(k*7+0);
                        }

                        break;
                    }

                    if ( !bExistGroup ) {
                        ele.removeChild( childNode );
                    }
                }
            }

            // group
            for (int j = 0; j < lstGroupDisplay.count() / 7; j++) {
                int groupid = lstGroupDisplay.at(j*7+0).toInt();
                int formatx = lstGroupDisplay.at(j*7+1).toInt();
                int formaty = lstGroupDisplay.at(j*7+2).toInt();
                int xsize = lstGroupDisplay.at(j*7+3).toInt();
                int ysize = lstGroupDisplay.at(j*7+4).toInt();

                QDomElement eleGroup = doc.createElement(QString("Group"));
                eleGroup.setAttribute(QString("id"), QString::number(groupid));
                eleGroup.setAttribute(QString("arrX"), QString::number(formatx));
                eleGroup.setAttribute(QString("arrY"), QString::number(formaty));
                eleGroup.setAttribute(QString("width"), QString::number(xsize));
                eleGroup.setAttribute(QString("height"), QString::number(ysize));

                lstGroupDisplayRes << groupid << QString("GROUP%1").arg(groupid+1) << formatx << formaty << xsize << ysize;
                ele.appendChild( eleGroup );
            }
        }
    }

    // 写入文件
    file.setFileName("qMarkViewConfig.xml");
    if( !file.open(QIODevice::WriteOnly | QIODevice::Truncate) ) {
        return;
    }

    QTextStream out(&file);
    doc.save(out,4);
    file.close();
}
