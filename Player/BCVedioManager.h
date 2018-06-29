/*********************************************************************************************************************************
* 作    者：liuwl
* 摘    要：管理预监回显等视频显示类
*********************************************************************************************************************************/
#ifndef BCVedioMANAGER_H
#define BCVedioMANAGER_H

#include <QUdpSocket>
#include <QTimer>
#include <QRect>
#include <QMutex>

typedef unsigned long   HI_U32;

// 视频帧
struct BCVedioFrame
{
    QByteArray pY;
    QByteArray pU;
    QByteArray pV;
    HI_U32 width;
    HI_U32 height;
    HI_U32 yStride;
    HI_U32 uvStride;

    QByteArray tmp_prew_pos_tab;
};

class VideoPaintItem;
class BCVeioDecodeThread;
class BCVedioPlayerThread;
class MainManager;
class BCVedioManager : public QObject
{
    Q_OBJECT

public:
    BCVedioManager(MainManager *pMainMgr, const QString &ip, int port);
    ~BCVedioManager();

    bool IsConnected();

    void Attach(VideoPaintItem *pWindow);
    void Detach(VideoPaintItem *pWindow);

    QList<VideoPaintItem *> m_lstWindow;

    void StartPlayerThread();
    void StopPlayerThread();

    QMutex m_mutexWindow;     // 链表的线程锁

    // 视频帧数据链表
    QList<BCVedioFrame> m_lstFrameOfDecodeThread1;
    QList<BCVedioFrame> m_lstFrameOfDecodeThread2;
    QList<BCVedioFrame> m_lstFrameOfDecodeThread3;
    QList<BCVedioFrame> m_lstFrameOfDecodeThread4;
    QMutex m_mutexFrame;

public slots:
    void onAppendVedioFrame(int id, const QByteArray &pY, const QByteArray &pU, const QByteArray &pV,
                            HI_U32 width, HI_U32 height, HI_U32 yStride, HI_U32 uvStride, const QByteArray &tmp_prew_pos_tab);

    void onAppendLog(const QString &log);

private:
    MainManager *m_pMainMgr;                // main manager

    QString m_ip;
    int m_port;

    int         m_nDelayPlayTimes;
    int         m_nHeartTimes;              // 心跳包的次数

    bool        m_bStartThread;             // 是否开启了解码和播放线程
    BCVeioDecodeThread *m_pDecodeThread1;
    BCVeioDecodeThread *m_pDecodeThread2;
    BCVeioDecodeThread *m_pDecodeThread3;
    BCVeioDecodeThread *m_pDecodeThread4;

    BCVedioPlayerThread *m_pPlayerThread;
};

#endif // BCVedioMANAGER_H
