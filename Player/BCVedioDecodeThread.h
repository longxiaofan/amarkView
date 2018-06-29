/*********************************************************************************************************************************
* 作    者：liuwl
* 摘    要：移植并整合的VS2010 BRPlayer代码
*********************************************************************************************************************************/
#ifndef BCVeioDecodeThread_H
#define BCVeioDecodeThread_H

#include <QThread>
#include <QTcpSocket>
#include <QHostAddress>
#include <QMutex>
#include <QTimer>

extern "C"
{
    #include "libavcodec/avcodec.h"
    #include "libavcodec/avfft.h"
    #include "libavformat/avformat.h"
    #include "libavformat/avio.h"
    #include "libswscale/swscale.h"
    #include "libavutil/common.h"
    #include "libavutil/avstring.h"
    #include "libavutil/imgutils.h"
    #include "libavutil/time.h"
    //#include "libavdevice/avdevice.h"
    #include "libswresample/swresample.h"
}

typedef unsigned char   HI_U8;
typedef unsigned long   HI_U32;

// 解码线程
class BCVedioWindow;
class BCVedioManager;
class BCVeioDecodeThread : public QThread
{
    Q_OBJECT

public:
    BCVeioDecodeThread(const QString &ip, int port, int id, BCVedioManager *parent = NULL);
    ~BCVeioDecodeThread();

    void run();

    void SetConnectInfo(const QString &ip, int port);
    void DisConnectSocket();// disconnect socket
    void ConnectSocket();   // reconnect socket
    bool IsConnected();     // isconnected socket

    void ReadyQuit();   // disconnect slot, stop sokect
    void Quit();        // delete socket, quit thread

signals:
    void sigAppendVedioFrame(int id, const QByteArray &pY, const QByteArray &pU, const QByteArray &pV,
                            HI_U32 width, HI_U32 height, HI_U32 yStride, HI_U32 uvStride, const QByteArray &tmp_prew_pos_tab);

    void sigSocketState(const QString &state);

private slots:
    void onRecvTcpMessage();

    void onTimeout();

private:
    bool init_hi3531_h264_decode();

private:
    BCVedioManager *m_parent;
    QMutex m_mutex;

    QByteArray m_catchRecvArr;

    QTcpSocket *m_pSocket;

    QString m_ip;
    int m_port;
    int m_id;       // 编号
    bool m_bQuit;   // 退出标识
    int m_nDelayCount;  // 延时帧数

    AVFrame *m_pFrame;
    AVFrame *m_pFrameRGB;
    AVCodec *m_pCodec;
    AVCodecContext *m_pCodecCtx;
    AVCodecParserContext		*pCodecParserCtx;

    HI_U8			tmp_line_mask_id_ptr[2048];
    HI_U8			tmp_line_mask_id_ptr_a[2048];
    unsigned int	target_pos_tab[256][5];

    QTimer *m_pTimer;
};

#endif // BCVeioDecodeThread_H
