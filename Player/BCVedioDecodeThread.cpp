#include "BCVedioDecodeThread.h"
#include <QPixmap>
#include <QThread>
#include <QBuffer>
#include <QTime>
#include "BCVedioManager.h"

#define DelayCount 4000
#define DelayCountByServer 0

BCVeioDecodeThread::BCVeioDecodeThread(const QString &ip, int port, int id, BCVedioManager *parent)
    :QThread( NULL )
{
    m_parent = parent;
    m_ip = ip;
    m_port = port;
    m_id = id;
    m_bQuit = false;
    m_nDelayCount = DelayCount+1;

    // init 3531
    init_hi3531_h264_decode();

    // init tcp socket
    m_pSocket = new QTcpSocket(this);
    connect(m_pSocket, SIGNAL(readyRead()), this, SLOT(onRecvTcpMessage()));

    // frame signal slot
    connect(this, SIGNAL(sigAppendVedioFrame(int,QByteArray,QByteArray,QByteArray,HI_U32,HI_U32,HI_U32,HI_U32,QByteArray)),
            m_parent, SLOT(onAppendVedioFrame(int,QByteArray,QByteArray,QByteArray,HI_U32,HI_U32,HI_U32,HI_U32,QByteArray)), Qt::DirectConnection);

    // socket connect state
    connect(this, SIGNAL(sigSocketState(QString)), m_parent, SLOT(onAppendLog(QString)));

    m_pTimer = new QTimer();
    m_pTimer->setInterval( 2*1000 );
    connect(m_pTimer, SIGNAL(timeout()), this, SLOT(onTimeout()));
}

BCVeioDecodeThread::~BCVeioDecodeThread()
{
    m_pTimer->deleteLater();
    qDebug() << "BCVeioDecodeThread::~BCVeioDecodeThread() ~~" << m_id;
}

void BCVeioDecodeThread::SetConnectInfo(const QString &ip, int port)
{
    if ((m_ip == ip) && (m_port == port))
        return;

    m_ip = ip;
    m_port = port;

    QAbstractSocket::SocketState state = m_pSocket->state();
    if ((state == QAbstractSocket::ConnectedState) || (state == QAbstractSocket::ConnectingState)) {
        m_pSocket->disconnectFromHost();
        m_pSocket->waitForDisconnected( 500 );
        m_pSocket->connectToHost(QHostAddress(m_ip), m_port+m_id);
    }
}

void BCVeioDecodeThread::ReadyQuit()
{
    // socket
    disconnect(m_pSocket, SIGNAL(readyRead()), this, SLOT(onRecvTcpMessage()));
    disconnect(this, SIGNAL(sigAppendVedioFrame(int,QByteArray,QByteArray,QByteArray,HI_U32,HI_U32,HI_U32,HI_U32,QByteArray)),
            m_parent, SLOT(onAppendVedioFrame(int,QByteArray,QByteArray,QByteArray,HI_U32,HI_U32,HI_U32,HI_U32,QByteArray)));

    // clear socket recv list
    m_mutex.lock();
    m_catchRecvArr.clear();
    m_mutex.unlock();

    m_bQuit = true;
}

void BCVeioDecodeThread::Quit()
{
    if ( m_pSocket->state() == QAbstractSocket::ConnectedState ) {
        m_pSocket->disconnectFromHost();
        m_pSocket->waitForDisconnected( 50 );
    }
    m_pSocket->deleteLater();

    // thread
    this->requestInterruption();
    this->quit();
    this->wait(50);
    this->deleteLater();
}

void BCVeioDecodeThread::onRecvTcpMessage()
{
    if ( m_bQuit )
        return;

    QByteArray byteTcpRecv = m_pSocket->readAll();

    //qDebug() << IsConnected() << m_id << m_catchRecvArr.length();
    if (byteTcpRecv.length() == 5) {
        if (QString(byteTcpRecv) == "false") {
            this->DisConnectSocket();
        }
    }

    m_nDelayCount++;

    int nDelayCount = DelayCountByServer;
    if (m_nDelayCount < nDelayCount) {
        //
        qDebug() << "delay frame " << m_nDelayCount;
    } else {
        QMutexLocker locker(&m_mutex);
        if (m_catchRecvArr.length() > 8*1024*1024)
            m_catchRecvArr.clear();

        m_catchRecvArr.append( byteTcpRecv );

        m_nDelayCount = DelayCount+1;
    }
}

void BCVeioDecodeThread::DisConnectSocket()
{
    if ( m_pSocket->state() == QAbstractSocket::ConnectedState ) {
        m_pSocket->disconnectFromHost();
    }
    m_nDelayCount = 0;
}

void BCVeioDecodeThread::onTimeout()
{
    if ( !IsConnected() ) {
        m_pSocket->connectToHost(QHostAddress(m_ip), m_port+m_id);
        m_pSocket->waitForConnected( 50 );
        emit sigSocketState( QString("PREVIEW:%1:%2, STATE: %3").arg(m_ip).arg(m_port+m_id).arg(IsConnected()?"CONNECTED":"DISCONNECT") );
    }
}

void BCVeioDecodeThread::ConnectSocket()
{
    if ( m_ip.isEmpty() )
        return;

    m_pSocket->connectToHost(QHostAddress(m_ip), m_port+m_id);
    m_pSocket->waitForConnected( 50 );

    m_pTimer->start();
}

bool BCVeioDecodeThread::IsConnected()
{
    return (m_pSocket->state() == QAbstractSocket::ConnectedState) ? true : false;
}

void BCVeioDecodeThread::run()
{
    while ( !this->isInterruptionRequested() ) {
        if ( m_bQuit )
            return;

        m_mutex.lock();
        QByteArray recvByte( m_catchRecvArr );
        m_mutex.unlock();

        if ( !recvByte.isEmpty() ) {
            int nRevLen = recvByte.size();

            AVPacket		tmp_packet;
            av_init_packet(&tmp_packet);

            if (nRevLen < (8*1024*1024)) {
                int len = av_parser_parse2(pCodecParserCtx, m_pCodecCtx, &tmp_packet.data, &tmp_packet.size, (const uint8_t*)recvByte.data(), nRevLen, AV_NOPTS_VALUE, AV_NOPTS_VALUE, AV_NOPTS_VALUE);

                m_mutex.lock();
                m_catchRecvArr.remove(0, len);
                m_mutex.unlock();

                if (0 == tmp_packet.size) {
                    QThread::msleep( 20 );
                    continue;
                }

                int got_picture = 0;
                int ret = avcodec_decode_video2(m_pCodecCtx, m_pFrame, &got_picture, &tmp_packet);
                if (ret < 0) {
                    QThread::msleep( 20 );
                    continue;
                }

                if (1 == got_picture) {
                    HI_U8 *pY = m_pFrame->data[0];
                    HI_U8 *pU = m_pFrame->data[1];
                    HI_U8 *pV = m_pFrame->data[2];
                    HI_U32 width    = m_pFrame->linesize[0];
                    HI_U32 height   = m_pFrame->height;
                    HI_U32 yStride  = m_pFrame->linesize[0];
                    HI_U32 uvStride = m_pFrame->linesize[1];
                    HI_U32 frame_yuv_size = height* yStride;

                    unsigned char tmp_prew_pos_tab[65*5];
                    // --------------------------------------------------------------------------------------------------------------- user_hi3531_dec.cpp - hi_decode_h264_to_buffer() begin
                    unsigned char b0,b1,b2,b3,b4,b5,b6;
                    memcpy(tmp_line_mask_id_ptr,(HI_U8 *)(pY + width*1087 + 0),1920);
                    int i = 0;
                    for(i=0;i<1920;i++)
                    {
                        if(tmp_line_mask_id_ptr[i]<0x40)
                        {
                            tmp_line_mask_id_ptr_a[i] = 0;
                        }
                        else
                        {
                            tmp_line_mask_id_ptr_a[i] = 1;
                        }
                    }
                    for(i=0;i<1920;i++)
                    {
                        if(		(tmp_line_mask_id_ptr_a[i+0]==1)&&(tmp_line_mask_id_ptr_a[i+1]==0)&&(tmp_line_mask_id_ptr_a[i+2]==1)&&(tmp_line_mask_id_ptr_a[i+3]==0)
                            &&  (tmp_line_mask_id_ptr_a[i+4]==1)&&(tmp_line_mask_id_ptr_a[i+5]==0)&&(tmp_line_mask_id_ptr_a[i+6]==1)&&(tmp_line_mask_id_ptr_a[i+7]==0)
                            &&  (tmp_line_mask_id_ptr_a[i+8]==1)&&(tmp_line_mask_id_ptr_a[i+9]==0)&&(tmp_line_mask_id_ptr_a[i+10]==1)&&(tmp_line_mask_id_ptr_a[i+11]==0)
                            &&  (tmp_line_mask_id_ptr_a[i+12]==1)&&(tmp_line_mask_id_ptr_a[i+13]==0)&&(tmp_line_mask_id_ptr_a[i+14]==1)&&(tmp_line_mask_id_ptr_a[i+15]==1)
                            )
                        {
                            i += 16;
                            break;
                        }
                    }
                    if(i<0x30)
                    {
                        b0 = 0;
                        HI_U8 bits_index = 0;
                        HI_U8 byte_index = 4;
                        for(;i<1920;i++)
                        {
                            b0 >>= 1;
                            b0 += (tmp_line_mask_id_ptr_a[i]==1)?0x80:0;
                            bits_index++;
                            if(bits_index>=8)
                            {
                                bits_index = 0;
                                tmp_line_mask_id_ptr[byte_index] = b0;
                                byte_index++;
                            }
                        }
                        b0 = 0;
                        {
                            unsigned int target_pos_tab_len = 0;
                            for(i=0;i<256*5;i++)
                            {
                                ((unsigned char *)&target_pos_tab[0][0])[i] = 0;
                            }
                            unsigned int j = 0;
                            {
                                unsigned char limit_cnt = 0;
                                memcpy(tmp_prew_pos_tab,&tmp_line_mask_id_ptr[4],240);
                                b0 = tmp_prew_pos_tab[(0<<2)+0];
                                b1 = tmp_prew_pos_tab[(0<<2)+1];
                                b2 = tmp_prew_pos_tab[(0<<2)+2];
                                b3 = tmp_prew_pos_tab[(0<<2)+3];
                                if((b0==0xec)&&(b1==0x98)&&(b3==0xaa))
                                {
                                    limit_cnt = b2;
                                }
                                target_pos_tab[target_pos_tab_len][0] = 0xec;
                                target_pos_tab[target_pos_tab_len][1] = 0x98;
                                target_pos_tab[target_pos_tab_len][2] = limit_cnt;
                                target_pos_tab[target_pos_tab_len][3] = 0xaa;
                                target_pos_tab[target_pos_tab_len][4] = 0x55;
                                target_pos_tab_len++;
                                for(i=0;i<limit_cnt;i++)
                                {
                                    // updata_exp_a
                                    //b0 = tmp_prew_pos_tab[(i<<2)+0+4];
                                    b1 = tmp_prew_pos_tab[(i*3)+0+4];
                                    b2 = tmp_prew_pos_tab[(i*3)+1+4];
                                    b3 = tmp_prew_pos_tab[(i*3)+2+4];
                                    if((b2&0xc0)==0x80)
                                    {
                                        b5 = b0>>6;
                                        b5 &= 0x01;
                                        b6 = b1;//(b1<<1)+b5;//index
                                        b4 = (b3>>6);//src_type
                                        b2 &= 0x1f;//position_in_page

                                        target_pos_tab[target_pos_tab_len][0] = b6;//index
                                        target_pos_tab[target_pos_tab_len][1] = b4;//src_type
                                        target_pos_tab[target_pos_tab_len][2] = b2;//position_in_page
                                        target_pos_tab[target_pos_tab_len][3] = (b3&0x1f);//page index
                                        target_pos_tab[target_pos_tab_len][4] = (j+2)&0x03;
                                        target_pos_tab_len++;
                                    }
                                }
                            }
                            b0 = 0;
                        }
                        int n = 0;//updata_exp_a
                        for(i=0;i<(64+1);i++)
                        {
                            for(int j=0;j<5;j++)
                            {
                                tmp_prew_pos_tab[n++] = target_pos_tab[i][j];
                            }
                        }
                    }
                    else {
                        int n=0;
                        for(i=0;i<(64+1);i++)
                        {
                            for(int j=0;j<5;j++)
                            {
                                tmp_prew_pos_tab[n++] = 0xff;
                            }
                        }
                    }
                    // --------------------------------------------------------------------------------------------------------------- user_hi3531_dec.cpp - hi_decode_h264_to_buffer() end

                    // 发送帧数据信号
                    QByteArray byteY((const char *)pY, frame_yuv_size);
                    QByteArray byteU((const char *)pU, height* uvStride/2);
                    QByteArray byteV((const char *)pV, height* uvStride/2);
                    QByteArray byte_tmp_prew_pos_tab((const char *)tmp_prew_pos_tab, 65*5);

                    emit sigAppendVedioFrame(m_id, byteY, byteU, byteV, width, height, yStride, uvStride, byte_tmp_prew_pos_tab);

                    // 数据接收不够可能会造成死循环
                    if ( m_bQuit )
                        return;
                }
            }
        } else {
            QThread::msleep( 20 );
        }
    }
}

bool BCVeioDecodeThread::init_hi3531_h264_decode()
{
    //初始化
    m_pFrame=av_frame_alloc();
    m_pFrameRGB = av_frame_alloc();

    avcodec_register_all();

    m_pCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (!m_pCodec) {
        printf("Codec not found\n");
        return -1;
    }
    m_pCodecCtx = avcodec_alloc_context3(m_pCodec);
    if (!m_pCodecCtx){
        printf("Could not allocate video codec context\n");
        return -1;
    }
    pCodecParserCtx=av_parser_init(AV_CODEC_ID_H264);
    if (!pCodecParserCtx){
        printf("Could not allocate video parser context\n");
        return -1;
    }

    if (avcodec_open2(m_pCodecCtx, m_pCodec, NULL) < 0)
    {
        printf("Could not open codec\n");
        return -1;
    }

    return true;
}
