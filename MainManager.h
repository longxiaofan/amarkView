#ifndef MAINMANAGER_H
#define MAINMANAGER_H

#include <QRect>
#include <QObject>
#include <QVariantList>

// 临时使用
struct sSignalWindow {
    int gid;        // 屏组ID
    int chid;       // 通道ID
    int winid;      // 窗口ID
    QRect rect;     // 位置

    int sort;       // 屏组内排序，数字越小越靠上
};

// 缓存场景数据
struct sUnionScene
{
    int id;
    QString name;
    int shortcut;
    QList<sSignalWindow> lstWindow;
};

class SearchDeviceUdp;
class QTcpSocket;
class QUdpSocket;
class BCVedioManager;
class MainManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString welcomePageBaseInfo_user READ welcomePageBaseInfo_user WRITE setWelcomePageBaseInfo_user)
    Q_PROPERTY(QString welcomePageBaseInfo_password READ welcomePageBaseInfo_password WRITE setWelcomePageBaseInfo_password)
    Q_PROPERTY(QString welcomePageBaseInfo_ip READ welcomePageBaseInfo_ip WRITE setWelcomePageBaseInfo_ip)
    Q_PROPERTY(QString welcomePageBaseInfo_port READ welcomePageBaseInfo_port WRITE setWelcomePageBaseInfo_port)
    Q_PROPERTY(QString welcomePageBaseInfo_savePassword READ welcomePageBaseInfo_savePassword WRITE setWelcomePageBaseInfo_savePassword)
    Q_PROPERTY(QString welcomePageBaseInfo_unionControl READ welcomePageBaseInfo_unionControl WRITE setWelcomePageBaseInfo_unionControl)
    Q_PROPERTY(QString welcomePageBaseInfo_previewip READ welcomePageBaseInfo_previewip WRITE setWelcomePageBaseInfo_previewip)
    Q_PROPERTY(QString welcomePageBaseInfo_previewport READ welcomePageBaseInfo_previewport WRITE setWelcomePageBaseInfo_previewport)

public:
    MainManager();
    ~MainManager();

    BCVedioManager *GetPreviewMgr();

    void SetQMLRoot(QObject *root);                 // 保存QML内的根节点
    void AppendLog(const QString &log);             // 添加QML日志信息

    Q_INVOKABLE void SaveWelcomePageBaseInfo();     // 保存欢迎页的基础数据
    Q_INVOKABLE void LoginByServer();               // 服务器登录或用户鉴权
    Q_INVOKABLE void LoginByDemoMode();             // 根据演示模式进入软件
    Q_INVOKABLE void LoginByDirect();               // 直连设备
    Q_INVOKABLE void Authentication();              // 用户鉴权

    // 指令接口
    Q_INVOKABLE void gwinsize(int gid, int winid, int chid, int l, int t, int r, int b);
    Q_INVOKABLE void gwinswitch(int gid, int winid);
    Q_INVOKABLE void greset(int gid);
    Q_INVOKABLE void addscene(int gid, QVariantList lst);  // 场景ID需要在后端判断
    Q_INVOKABLE void updatescene(int gid, int sid, QVariantList lst);  // 场景ID需要在后端判断
    Q_INVOKABLE void delScene(int gid, int sid);
    Q_INVOKABLE void gload(int gid, int sid);

    Q_INVOKABLE int getTypeByID(int id);

    // 返回场景数据，场景内可能没有数据，所以需要分两个函数
    Q_INVOKABLE QVariantList getSceneList(int gid);
    Q_INVOKABLE QVariantList getSceneData(int gid, int sid);

    Q_INVOKABLE void RequestControlBySignalWindow(int groupid, int chid, int chtype, int winid);
    Q_INVOKABLE void RequestOver(int gid);

    Q_INVOKABLE QVariantList getChannelList();
    Q_INVOKABLE void addShortCutScene(int gid, int sid);
    Q_INVOKABLE QVariantList getShortCutScene(int gid);

    // 穿透
    Q_INVOKABLE void SendRemoteCmd(int chid, QString cmd);

    // 欢迎页接口
    QString welcomePageBaseInfo_user();
    QString welcomePageBaseInfo_password();
    QString welcomePageBaseInfo_ip();
    QString welcomePageBaseInfo_port();
    QString welcomePageBaseInfo_savePassword();
    QString welcomePageBaseInfo_unionControl();
    QString welcomePageBaseInfo_previewip();
    QString welcomePageBaseInfo_previewport();

    void setWelcomePageBaseInfo_user(const QString &text);
    void setWelcomePageBaseInfo_password(const QString &text);
    void setWelcomePageBaseInfo_ip(const QString &text);
    void setWelcomePageBaseInfo_port(const QString &text);
    void setWelcomePageBaseInfo_savePassword(const QString &text);
    void setWelcomePageBaseInfo_unionControl(const QString &text);
    void setWelcomePageBaseInfo_previewip(const QString &text);
    void setWelcomePageBaseInfo_previewport(const QString &text);

    // 搜索设备调用接口
    void AppendOnlineDevice(const QString &name, const QString &ip, int port, const QString &mask, const QString &gateway, const QString &mac);
    void AppendOnlinePreview(const QString &ip, int port, const QString &mac);

public slots:
    void onGWinsize(int gid, int winid, int chid, int l, int t, int r, int b);

private slots:
    void onRecvTcpMessage();
    void onGetFormatError();
    void onRequestFormat();
    void onCheckoutRequestFormat();

private:
    // 请求设备规模
    void RequestFormat();

    void initRemoteIPList();
    void initConfigFile();
    // 第三个参数依次内容为CHID CHTYPE CHNAME
    void saveConfigFile(QVariantList lstInputChannel, QVariantList lstGroupDisplay, QVariantList &lstInputChannelRes, QVariantList &lstGroupDisplayRes);

    // 排序功能函数
    void sortSignalWindow(QList<sSignalWindow> *pList);
    static bool compareSignalWindow(const sSignalWindow &win1, const sSignalWindow &win2);

    // 联控时接口
    void DealFormatFromServer(const QString &json);

    void RevSingleData(const QString &json);
    QString DecodeJsonKey(const QString &json);
    QString EncodeStandardJson(const QString &k, const QString &v);
    QString GetJsonValueByKey(const QString &json, const QString &key, QString valueKey = "cmdValue");
    int GetStandardJsonResult(const QString &json);
    sUnionScene DecodeSceneJson(const QString &json, int &gid);

    // 服务器通知
    void ServerWinsize(int groupid, int channelid, int chtype, int windowid, int l, int t, int r, int b);
    void ServerWinswitch(int groupid, int channelid, int chtype, int windowid);
    void ServerMoveSignalWindow(int groupid, int channelid, int chtype, int windowid);
    void ServerReset(const QString &ids);
    void ServerChangeLockState(int i, bool bLock);

    void SendTcpData(const QString &cmd);

    // 成员变量
    QObject         *m_pRoot;           // qml root
    BCVedioManager  *m_pVedioMgr;       // preview mgr

    // 欢迎页参数
    QString m_welcomePageBaseInfo_user;
    QString m_welcomePageBaseInfo_password;
    QString m_welcomePageBaseInfo_ip;
    QString m_welcomePageBaseInfo_port;
    QString m_welcomePageBaseInfo_savePassword;
    QString m_welcomePageBaseInfo_unionControl;
    QString m_welcomePageBaseInfo_previewip;
    QString m_welcomePageBaseInfo_previewport;

    // 系统用户
    struct sUser {
        int uid;
        QString uUser;
        QString uPassword;
        int uLevel;
    };
    QList<sUser>    m_lstSystemUser;    // system user
    int             m_currentUserID;

    QTcpSocket      *m_pTcpSocket;          // 通讯TCP
    SearchDeviceUdp *m_pSearchUdpSocket;    // 广播的通讯UDP

    // 联调时使用
    int             m_nCacheTimes;      // 通讯缓存次数，支持最大缓存数据为连续3次
    QString         m_qsCacheJson;      // 通讯的缓存JSON，因为大的数据可能一个JSON传不过来

    // 请求规模变量
    bool            m_bRequestFormat;   // 请求规模变量
    int             m_nRetryTimes;      // 重试次数
    QByteArray      m_byteRecv;         // 接收的数据

    // 缓存屏组的场景ID
    QMap<int, QList<int>>  m_mapGroupScene;

    // 缓存服务器的场景数据
    QMap<int, QList<sUnionScene>>   m_mapUnionGroupScene;

    // 缓存chid-chtype
    QMap<int, int>  m_mapChannelIDType;

    // 缓存通道数据，ID,NAME...
    QVariantList m_lstInputChannel;

    // 穿透IP链表
    QStringList m_lstRemoteIP;
    QUdpSocket  *m_pRemoteSocket;       // 远程控制的socket
};

inline void MainManager::SetQMLRoot(QObject *root)
{
    m_pRoot = root;
}

inline BCVedioManager *MainManager::GetPreviewMgr()
{
    return m_pVedioMgr;
}

inline QVariantList MainManager::getChannelList()
{
    return m_lstInputChannel;
}

inline QString MainManager::welcomePageBaseInfo_user()
{
    return m_welcomePageBaseInfo_user;
}
inline QString MainManager::welcomePageBaseInfo_password()
{
    return m_welcomePageBaseInfo_password;
}
inline QString MainManager::welcomePageBaseInfo_ip()
{
    return m_welcomePageBaseInfo_ip;
}
inline QString MainManager::welcomePageBaseInfo_port()
{
    return m_welcomePageBaseInfo_port;
}
inline QString MainManager::welcomePageBaseInfo_savePassword()
{
    return m_welcomePageBaseInfo_savePassword;
}
inline QString MainManager::welcomePageBaseInfo_unionControl()
{
    return m_welcomePageBaseInfo_unionControl;
}
inline QString MainManager::welcomePageBaseInfo_previewip()
{
    return m_welcomePageBaseInfo_previewip;
}
inline QString MainManager::welcomePageBaseInfo_previewport()
{
    return m_welcomePageBaseInfo_previewport;
}
inline void MainManager::setWelcomePageBaseInfo_user(const QString &text)
{
    m_welcomePageBaseInfo_user = text;
}
inline void MainManager::setWelcomePageBaseInfo_password(const QString &text)
{
    m_welcomePageBaseInfo_password = text;
}
inline void MainManager::setWelcomePageBaseInfo_ip(const QString &text)
{
    m_welcomePageBaseInfo_ip = text;
}
inline void MainManager::setWelcomePageBaseInfo_port(const QString &text)
{
    m_welcomePageBaseInfo_port = text;
}
inline void MainManager::setWelcomePageBaseInfo_savePassword(const QString &text)
{
    m_welcomePageBaseInfo_savePassword = text;
}
inline void MainManager::setWelcomePageBaseInfo_unionControl(const QString &text)
{
    m_welcomePageBaseInfo_unionControl = text;
}
inline void MainManager::setWelcomePageBaseInfo_previewip(const QString &text)
{
    m_welcomePageBaseInfo_previewip = text;
}
inline void MainManager::setWelcomePageBaseInfo_previewport(const QString &text)
{
    m_welcomePageBaseInfo_previewport = text;
}
#endif // MAINMANAGER_H
