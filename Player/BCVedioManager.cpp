#include "BCVedioManager.h"
#include <QPainter>
#include <QNetworkInterface>
#include <QDebug>
#include "BCVedioDecodeThread.h"
#include "BCVedioPlayerThread.h"
#include "VideoPaintItem.h"
#include "MainManager.h"

BCVedioManager::BCVedioManager(MainManager *pMainMgr, const QString &ip, int port)
    :QObject(0)
{
    m_pMainMgr = pMainMgr;
    m_ip = ip;
    m_port = port;

    m_nHeartTimes = 0;
    m_nDelayPlayTimes = 0;

    // thread
    m_bStartThread = false;
    m_pDecodeThread1 = new BCVeioDecodeThread(m_ip, m_port, 0, this);
    m_pDecodeThread2 = new BCVeioDecodeThread(m_ip, m_port, 1, this);
    m_pDecodeThread3 = new BCVeioDecodeThread(m_ip, m_port, 2, this);
    m_pDecodeThread4 = new BCVeioDecodeThread(m_ip, m_port, 3, this);
    m_pPlayerThread = NULL;

    // connect and play
    m_pDecodeThread1->ConnectSocket();
    m_pDecodeThread2->ConnectSocket();
    m_pDecodeThread3->ConnectSocket();
    m_pDecodeThread4->ConnectSocket();
    StartPlayerThread();
}

BCVedioManager::~BCVedioManager()
{
    QMutexLocker locker(&m_mutexWindow);
    while ( !m_lstWindow.isEmpty() )
        delete m_lstWindow.takeFirst();

    // 停止线程
    StopPlayerThread();

    m_mutexFrame.lock();
    m_lstFrameOfDecodeThread1.clear();
    m_lstFrameOfDecodeThread2.clear();
    m_lstFrameOfDecodeThread3.clear();
    m_lstFrameOfDecodeThread4.clear();
    m_mutexFrame.unlock();
}

void BCVedioManager::Attach(VideoPaintItem *pWindow)
{
    QMutexLocker locker(&m_mutexWindow);
    if ( !m_lstWindow.contains( pWindow ) )
        m_lstWindow.append( pWindow );

    connect(m_pPlayerThread, SIGNAL(sigImage(int, int, QPixmap)), pWindow, SLOT(updateImage(int, int, QPixmap)));
}

void BCVedioManager::Detach(VideoPaintItem *pWindow)
{
    disconnect(m_pPlayerThread, SIGNAL(sigImage(int, int, QPixmap)), pWindow, SLOT(updateImage(int, int, QPixmap)));

    QMutexLocker locker(&m_mutexWindow);
    m_lstWindow.removeOne( pWindow );
}

bool BCVedioManager::IsConnected()
{
    return (m_pDecodeThread1->IsConnected() && m_pDecodeThread1->IsConnected() && m_pDecodeThread1->IsConnected() && m_pDecodeThread1->IsConnected());
}

void BCVedioManager::onAppendLog(const QString &log)
{
    if (NULL != m_pMainMgr)
        m_pMainMgr->AppendLog( log );
}

void BCVedioManager::onAppendVedioFrame(int id, const QByteArray &pY, const QByteArray &pU, const QByteArray &pV,
                        HI_U32 width, HI_U32 height, HI_U32 yStride, HI_U32 uvStride, const QByteArray &tmp_prew_pos_tab)
{
    QMutexLocker locker(&m_mutexFrame);

    BCVedioFrame frame;
    frame.pY.append( pY );
    frame.pU.append( pU );
    frame.pV.append( pV );
    frame.width = width;
    frame.height = height;
    frame.yStride = yStride;
    frame.uvStride = uvStride;
    frame.tmp_prew_pos_tab.append( tmp_prew_pos_tab );

    // 同时存放四个线程的帧数据
    int nFrameMaxCount = 5;    // 防止数据量大出现拷贝错误
    switch ( id ) {
    case 0: {
        if (m_lstFrameOfDecodeThread1.count() >= nFrameMaxCount)
            m_lstFrameOfDecodeThread1.takeFirst();

        m_lstFrameOfDecodeThread1.append( frame );
    }
        break;
    case 1: {
        if (m_lstFrameOfDecodeThread2.count() >= nFrameMaxCount)
            m_lstFrameOfDecodeThread2.takeFirst();

        m_lstFrameOfDecodeThread2.append( frame );
    }
        break;
    case 2: {
        if (m_lstFrameOfDecodeThread3.count() >= nFrameMaxCount)
            m_lstFrameOfDecodeThread3.takeFirst();

        m_lstFrameOfDecodeThread3.append( frame );
    }
        break;
    default: {
        if (m_lstFrameOfDecodeThread4.count() >= nFrameMaxCount)
            m_lstFrameOfDecodeThread4.takeFirst();

        m_lstFrameOfDecodeThread4.append( frame );
    }
        break;
    }
}

void BCVedioManager::StartPlayerThread()
{
    // 线程只打开一次
    if ( m_bStartThread )
        return;

    int nDelayTime = 100;
    if (NULL != m_pDecodeThread1) {
        QTimer::singleShot(nDelayTime*1, m_pDecodeThread1, SLOT(start()));
    }
    if (NULL != m_pDecodeThread2) {
        QTimer::singleShot(nDelayTime*2, m_pDecodeThread2, SLOT(start()));
    }
    if (NULL != m_pDecodeThread3) {
        QTimer::singleShot(nDelayTime*3, m_pDecodeThread3, SLOT(start()));
    }
    if (NULL != m_pDecodeThread4) {
        QTimer::singleShot(nDelayTime*4, m_pDecodeThread4, SLOT(start()));
    }
    if (NULL == m_pPlayerThread) {
        m_pPlayerThread = new BCVedioPlayerThread( this );
        QTimer::singleShot(nDelayTime*5, m_pPlayerThread, SLOT(start()));
    }

    m_bStartThread = true;
}

void BCVedioManager::StopPlayerThread()
{
    qDebug() << "BCVedioManager::StopPlayerThread";

    if (NULL != m_pDecodeThread1) {
        m_pDecodeThread1->ReadyQuit();
    }
    if (NULL != m_pDecodeThread2) {
        m_pDecodeThread2->ReadyQuit();
    }
    if (NULL != m_pDecodeThread3) {
        m_pDecodeThread3->ReadyQuit();
    }
    if (NULL != m_pDecodeThread4) {
        m_pDecodeThread4->ReadyQuit();
    }

    QThread::msleep( 200 );

    // 退出线程
    if (NULL != m_pDecodeThread1) {
        m_pDecodeThread1->Quit();
    }
    if (NULL != m_pDecodeThread2) {
        m_pDecodeThread2->Quit();
    }
    if (NULL != m_pDecodeThread3) {
        m_pDecodeThread3->Quit();
    }
    if (NULL != m_pDecodeThread4) {
        m_pDecodeThread4->Quit();
    }
    if (NULL != m_pPlayerThread) {
        m_pPlayerThread->Quit();
    }
}
