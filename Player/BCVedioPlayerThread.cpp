#include "BCVedioPlayerThread.h"
#include "BCVedioManager.h"
#include <QTime>
#include <QPixmap>
#include "VideoPaintItem.h"

typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef unsigned long DWORD;
typedef long LONG;

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

BCVedioPlayerThread::BCVedioPlayerThread(BCVedioManager *parent)
    :QThread( parent )
{
    m_parent = parent;

    av_image_alloc(SrcData, SrcLinesize,1920, 1080, AV_PIX_FMT_YUV420P, 1);
    av_image_alloc(DesData, DesLinesize, 3840, 2160, AV_PIX_FMT_BGR24, 1);
    //av_image_alloc(DesData, DesLinesize, 3840, 2160, AV_PIX_FMT_RGB24, 1);

    m_bQuit = false;
}

BCVedioPlayerThread::~BCVedioPlayerThread()
{
    // 这里的srcData可能是野指针了，这里需要重新初始化并释放
    memset(SrcData, 0, sizeof(SrcData));
    memset(SrcLinesize, 0, sizeof(SrcLinesize));
    memset(DesData, 0, sizeof(DesData));
    memset(DesLinesize, 0, sizeof(DesLinesize));
    av_freep(&SrcData[0]);
    av_freep(&DesData[0]);

    qDebug() << "BCVedioPlayerThread::~BCVedioPlayerThread()~~";
}

void BCVedioPlayerThread::Quit()
{
    m_bQuit = true;

    this->requestInterruption();
    this->quit();
    this->wait(50);
    this->deleteLater();
}

// bmp图使用的结构体
typedef struct {
    WORD    bfType;
    DWORD   bfSize;
    WORD    bfReserved1;
    WORD    bfReserved2;
    DWORD   bfOffBits;
} BMPFILEHEADER_T;

// bmp图使用的结构体
typedef struct{
    DWORD      biSize;
    LONG       biWidth;
    LONG       biHeight;
    WORD       biPlanes;
    WORD       biBitCount;
    DWORD      biCompression;
    DWORD      biSizeImage;
    LONG       biXPelsPerMeter;
    LONG       biYPelsPerMeter;
    DWORD      biClrUsed;
    DWORD      biClrImportant;
} BMPINFOHEADER_T;

void memcpyFrame(QByteArray &byteArr, int width, int height )
{
    int nFrameSize = width*height*3*sizeof(uchar)+54; // 每个像素点3个字节
    // 位图第一部分，文件信息
    BMPFILEHEADER_T bfh;
    bfh.bfType = (WORD)0x4d42;  //bm
    bfh.bfSize = nFrameSize  // data size
            + sizeof( BMPFILEHEADER_T ) // first section size
            + sizeof( BMPINFOHEADER_T ) // second section size
            ;
    bfh.bfReserved1 = 0; // reserved
    bfh.bfReserved2 = 0; // reserved
    bfh.bfOffBits = sizeof( BMPFILEHEADER_T )+ sizeof( BMPINFOHEADER_T );//真正的数据的位置

    // 位图第二部分，数据信息
    BMPINFOHEADER_T bih;
    bih.biSize = sizeof(BMPINFOHEADER_T);
    bih.biWidth = width;
    bih.biHeight = -height;//BMP图片从最后一个点开始扫描，显示时图片是倒着的，所以用-height，这样图片就正了
    bih.biPlanes = 1;//为1，不用改
    bih.biBitCount = 24;
    bih.biCompression = 0;//不压缩
    bih.biSizeImage = nFrameSize;
    bih.biXPelsPerMeter = 2835 ;//像素每米
    bih.biYPelsPerMeter = 2835 ;
    bih.biClrUsed = 0;//已用过的颜色，24位的为0
    bih.biClrImportant = 0;//每个像素都重要

    byteArr = byteArr.append((const char *)&bfh, 8);
    byteArr = byteArr.append((const char *)&bfh.bfReserved2, sizeof(bfh.bfReserved2));
    byteArr = byteArr.append((const char *)&bfh.bfOffBits, sizeof(bfh.bfOffBits));
    byteArr = byteArr.append((const char *)&bih, sizeof(BMPINFOHEADER_T));
}

void BCVedioPlayerThread::run()
{
    while ( !this->isInterruptionRequested() ) {
        if ( m_bQuit )
            return;

        QListIterator<VideoPaintItem *> it( m_parent->m_lstWindow );
        while ( it.hasNext() ) {
            if ( m_bQuit )
                return;

            //qDebug() << m_parent->m_lstWindow.count() << "~~~~~~~~~~~";
            //QTime beginTime = QTime::currentTime();
            QMutexLocker locker(&m_parent->m_mutexWindow);

            VideoPaintItem *pWindow = it.next();
            if (-1 == m_parent->m_lstWindow.indexOf( pWindow ))
                continue;

            // ??? 这里根据chid等信息找图片
            // m_id代表tab，从0-3
            // pWindow->m_chid代表通道ID
            // --------------------------------------------------------------------------------------------------------------- BRPlayer.cpp - GetYUVFrameData() begin
            unsigned char use_target_type;
            if((pWindow->m_size.width()>=1260)||(pWindow->m_size.height()>=640)) {
                use_target_type = 3;
            } else	if((pWindow->m_size.width()>=720)||(pWindow->m_size.height()>=400)) {
                use_target_type = 3;
            } else	if((pWindow->m_size.width()>=380)||(pWindow->m_size.height()>=300)) {
                use_target_type = 3;
            } else {
                use_target_type = 0;
            }

            // liuwl 直接找四个线程
            if (m_parent->m_lstFrameOfDecodeThread1.isEmpty()
                    || m_parent->m_lstFrameOfDecodeThread2.isEmpty()
                    || m_parent->m_lstFrameOfDecodeThread3.isEmpty()
                    || m_parent->m_lstFrameOfDecodeThread4.isEmpty()) {
                QThread::msleep( 100 );
                qDebug() << "decode thread is empty." << m_parent->m_lstFrameOfDecodeThread1.count()
                         << m_parent->m_lstFrameOfDecodeThread2.count()
                         << m_parent->m_lstFrameOfDecodeThread3.count()
                         << m_parent->m_lstFrameOfDecodeThread4.count();
                continue;
            }

            int nFrameMinCount = 2;    // 防止数据帧太少不能解码
            m_parent->m_mutexFrame.lock();
            BCVedioFrame frame1 = (m_parent->m_lstFrameOfDecodeThread1.count() <= nFrameMinCount) ? m_parent->m_lstFrameOfDecodeThread1.first() : m_parent->m_lstFrameOfDecodeThread1.takeFirst();
            BCVedioFrame frame2 = (m_parent->m_lstFrameOfDecodeThread2.count() <= nFrameMinCount) ? m_parent->m_lstFrameOfDecodeThread2.first() : m_parent->m_lstFrameOfDecodeThread2.takeFirst();
            BCVedioFrame frame3 = (m_parent->m_lstFrameOfDecodeThread3.count() <= nFrameMinCount) ? m_parent->m_lstFrameOfDecodeThread3.first() : m_parent->m_lstFrameOfDecodeThread3.takeFirst();
            BCVedioFrame frame4 = (m_parent->m_lstFrameOfDecodeThread4.count() <= nFrameMinCount) ? m_parent->m_lstFrameOfDecodeThread4.first() : m_parent->m_lstFrameOfDecodeThread4.takeFirst();
            m_parent->m_mutexFrame.unlock();

            unsigned char	tmp_prew_pos_tab[65*5]; // updata_exp_a
            unsigned int target_pos_tab_len = 0;
            unsigned char b0,b1,b2,b3;
            unsigned char target_pos_tab[256][5];
            int i,j,c0,c1;
            for(j=0;j<4;j++)
            {
                // liuwl
                char *frame_tmp_prew_pos_tab = NULL;
                switch ( j ) {
                case 0:
                    frame_tmp_prew_pos_tab = frame1.tmp_prew_pos_tab.data();
                    break;
                case 1:
                    frame_tmp_prew_pos_tab = frame2.tmp_prew_pos_tab.data();
                    break;
                case 2:
                    frame_tmp_prew_pos_tab = frame3.tmp_prew_pos_tab.data();
                    break;
                default:
                    frame_tmp_prew_pos_tab = frame4.tmp_prew_pos_tab.data();
                    break;
                }

                if (NULL == frame_tmp_prew_pos_tab)
                    continue;

                memcpy(tmp_prew_pos_tab, (void *)frame_tmp_prew_pos_tab, 65*5);

                b0 = tmp_prew_pos_tab[(0*5)+0];
                b1 = tmp_prew_pos_tab[(0*5)+1];
                b2 = tmp_prew_pos_tab[(0*5)+2];
                b3 = tmp_prew_pos_tab[(0*5)+3];
                if((b0==0xec)&&(b1==0x98)&&(b3==0xaa))
                {
                    b0 = 0;
                    int k = b2;
                    for(i=1;i<=k;i++)
                    {
                        target_pos_tab[target_pos_tab_len][0] = tmp_prew_pos_tab[(i*5)+0];
                        target_pos_tab[target_pos_tab_len][1] = tmp_prew_pos_tab[(i*5)+1];
                        target_pos_tab[target_pos_tab_len][2] = tmp_prew_pos_tab[(i*5)+2];
                        target_pos_tab[target_pos_tab_len][3] = tmp_prew_pos_tab[(i*5)+3];
                        target_pos_tab[target_pos_tab_len][4] = tmp_prew_pos_tab[(i*5)+4];
                        target_pos_tab_len++;
                    }
                }
            }

            b0 = 0;
            if((target_pos_tab_len==0)||(target_pos_tab_len>=0xf0))
            {
                c0 = 0;
                c1 = 0;
                use_target_type = 0;
                j = 0;
            }
            else
            {
                if(use_target_type>3)
                {
                    use_target_type = 0;
                }
                int tmp_use_target_type = use_target_type;
                for(;tmp_use_target_type>=0;tmp_use_target_type--)
                {
                    for(i=0;i<target_pos_tab_len;i++)
                    {
                        if((target_pos_tab[i][0]==pWindow->m_chid)&&(target_pos_tab[i][1]==tmp_use_target_type))
                        {
                            break;
                        }
                    }
                    if(i<target_pos_tab_len)
                    {
                        c0 = target_pos_tab[i][2];
                        c1 = target_pos_tab[i][3];
                        use_target_type = tmp_use_target_type;

                        break;
                    }
                    else
                    {
                        c0 = 0;
                        c1 = 0;

                        j = 0;
                    }
                }
            }

            if((c0>=0)&&(c0<=7)&&(c1>=0)&&(c1<=7))//updata_exp_b
            {
                j = 0;
            }
            else	if((c0>=11)&&(c0<=19)&&(c1>=0)&&(c1<=7))
            {
                c0-=11;
                j = 3;
            }
            else	if((c0>=0)&&(c0<=7)&&(c1>=19)&&(c1<=26))
            {
                c1-=19;
                j = 1;
            }
            else	if((c0>=11)&&(c0<=19)&&(c1>=19)&&(c1<=26))
            {
                c0-=11;
                c1-=19;
                j = 2;
            }

            int xstart = c0 * 240;
            int ystart = c1 * 136;
            int width = 240;
            int height = 136;
            if(use_target_type==0)
            {
                width = 240;
                height = 136;
            }
            else	if(use_target_type==1)
            {
                width = 480;
                height = 270;
            }
            else	if(use_target_type==2)
            {
                width = 960;
                height = 540;
            }
            else	if(use_target_type==3)
            {
                width = 1920;
                height = 1080;
            }
            // --------------------------------------------------------------------------------------------------------------- BRPlayer.cpp - GetYUVFrameData() end

            // j为端口ID，跟DLL中有偏差
            BYTE *pY = NULL;
            BYTE *pU = NULL;
            BYTE *pV = NULL;

            // 连接设备和连接服务器时对应的顺序不同
            int nPreviewDirectDevice = 1;
            int nCase1 = (1 == nPreviewDirectDevice) ? 0 : 2;
            int nCase2 = (1 == nPreviewDirectDevice) ? 1 : 3;
            int nCase3 = (1 == nPreviewDirectDevice) ? 2 : 0;
            if (j == nCase1) {
                pY = (BYTE *)frame2.pY.data();
                pU = (BYTE *)frame2.pU.data();
                pV = (BYTE *)frame2.pV.data();
            } else if (j == nCase2) {
                pY = (BYTE *)frame4.pY.data();
                pU = (BYTE *)frame4.pU.data();
                pV = (BYTE *)frame4.pV.data();
            } else if (j == nCase3) {
                pY = (BYTE *)frame3.pY.data();
                pU = (BYTE *)frame3.pU.data();
                pV = (BYTE *)frame3.pV.data();
            } else {
                pY = (BYTE *)frame1.pY.data();
                pU = (BYTE *)frame1.pU.data();
                pV = (BYTE *)frame1.pV.data();
            }

            int srcLeft = xstart;
            int scrTop = ystart;
            int srcWidth = width;
            int srcHeight = height;

            // 图片最大支持1920*1080，如果尺寸超出则重新计算尺寸
            srcWidth = (xstart+width) > 1920 ? (1920-xstart) : width;
            srcHeight = (ystart+height) > 1080 ? (1080-ystart) : height;

            // 窗口尺寸可能大于1920*1080
            int destWidth = pWindow->m_size.width();
            int destHeight = pWindow->m_size.height();

            // 当尺寸不合法时跳过
            if ((destWidth < 4) || (destHeight < 4))
                continue;

            SrcData[0] = (uint8_t *)pY + 1920*scrTop + srcLeft;
            SrcData[1] = (uint8_t *)pU + 480*scrTop + (srcLeft/2);
            SrcData[2] = (uint8_t *)pV + 480*scrTop + (srcLeft/2);

            // 如果图片原尺寸和转换后的尺寸一样则直接渲染YUV
            struct SwsContext *img_convert_ctx = sws_getContext(srcWidth, srcHeight,AV_PIX_FMT_YUV420P,destWidth, destHeight, AV_PIX_FMT_BGR24, SWS_BICUBIC, NULL, NULL, NULL);
            //struct SwsContext *img_convert_ctx = sws_getContext(srcWidth, srcHeight,AV_PIX_FMT_YUV420P,destWidth, destHeight, AV_PIX_FMT_RGB24, SWS_BICUBIC, NULL, NULL, NULL);
            if (NULL != img_convert_ctx) {
                sws_scale(img_convert_ctx, (const uint8_t* const*)SrcData, SrcLinesize, 0, srcHeight, DesData, DesLinesize);
                sws_freeContext(img_convert_ctx);
            }

            // 解码前有窗口，解码后可能窗口刚好被析构
            if ( m_bQuit ) {
                return;
            }

            // 在外面添加线程锁，如果开窗特别多可能会造成特别慢的问题
            if (-1 != m_parent->m_lstWindow.indexOf(pWindow)) {
                QByteArray byteArr;
                int offsetPix = 0; // 偏移像素点
#ifdef WIN32
                offsetPix = 2;
#else
                offsetPix = 2;
#endif

                memcpyFrame(byteArr, destWidth, destHeight);
                int nLinesize = destWidth*3*sizeof(uint8_t);
                for (int i = 0; i < destHeight; i++) {
                    // !!!偏移两个点，保证RGB对齐，可能会因为图像尺寸导致崩溃，需要注意
                    memcpy(&pCurrentFrame[i*nLinesize+offsetPix], &DesData[0][i*DesLinesize[0]], nLinesize);
                }
                byteArr = byteArr.append((const char*)pCurrentFrame, nLinesize*destHeight);

                QPixmap pixmap;
                pixmap.loadFromData(byteArr);

                emit sigImage(pWindow->m_gid, pWindow->m_wid, pixmap);
            }
        }

        QThread::msleep(10);
    }
}
