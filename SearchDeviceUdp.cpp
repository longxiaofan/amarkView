#include "SearchDeviceUdp.h"
#include <QUdpSocket>
#include <QTimer>
#include "MainManager.h"

typedef unsigned char BYTE;
SearchDeviceUdp::SearchDeviceUdp(MainManager *parent) : QObject(parent)
{
    m_pMainMgr = parent;

    // 搜索设备的UDP
    m_pUdpSocket = new QUdpSocket(this);
    m_pUdpSocket->bind(1500, QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint);
    connect(m_pUdpSocket, SIGNAL(readyRead()), this, SLOT(processPendingDatagrams()));

    // 搜索预监回显的UDP
    m_pPreviewUdpSocket = new QUdpSocket(this);
    connect(m_pPreviewUdpSocket, SIGNAL(readyRead()), this, SLOT(onRecvPreviewUdpData()));
    // ----------------------------------------------------------------------------------------------

    m_pTimer = new QTimer();
    m_pTimer->setInterval( 100 );
    connect(m_pTimer, SIGNAL(timeout()), this, SLOT(onSearchDevice()));             // 搜索通讯设备
    connect(m_pTimer, SIGNAL(timeout()), this, SLOT(onSearchPreviewDevice()));      // 搜索预监设备
    m_pTimer->start();
}

SearchDeviceUdp::~SearchDeviceUdp()
{
    m_pTimer->stop();
    m_pTimer->deleteLater();

    m_pUdpSocket->deleteLater();
    m_pPreviewUdpSocket->deleteLater();
}

void SearchDeviceUdp::onSearchPreviewDevice()
{
    unsigned char ssmsg[4];

    ssmsg[0] = 0xec;
    ssmsg[1] = 0x98;
    ssmsg[2] = 0x16;
    ssmsg[3] = 0x10;
    m_pPreviewUdpSocket->writeDatagram((char*)ssmsg, 4, QHostAddress::Broadcast, 6061);   // 搜索设备
}

void SearchDeviceUdp::onRecvPreviewUdpData()
{
    while(m_pPreviewUdpSocket->hasPendingDatagrams())
    {
        QByteArray datagram;
        datagram.resize(m_pPreviewUdpSocket->pendingDatagramSize());

        unsigned char tmpbuf[4096];
        int bread = m_pPreviewUdpSocket->readDatagram((char *)tmpbuf, 256);

        // 搜索设备是1024，预监回显服务器是256
        int nMaxBreadCount = 1024;
        if((bread>0)&&(bread<nMaxBreadCount))
        {
            unsigned char flagBuf[6];
            flagBuf[0] = 0xec;
            flagBuf[1] = 0x98;
            flagBuf[2] = 0x61;
            flagBuf[3] = 0x20;
            flagBuf[4] = 0x01;
            flagBuf[5] = 0x10;

            if((tmpbuf[0]==flagBuf[0])&&(tmpbuf[1]==flagBuf[1])&&(tmpbuf[2]==flagBuf[2])&&(tmpbuf[3]==flagBuf[3])&&(tmpbuf[4]==flagBuf[4])&&(bread==flagBuf[5]))
            {
                QString qsIP = QString("%1.%2.%3.%4").arg(tmpbuf[5]).arg(tmpbuf[6]).arg(tmpbuf[7]).arg(tmpbuf[8]);

                if ( m_lstPreviewIP.contains(qsIP) )
                    return;

                QString qsMac = QString("%1-%2-%3-%4-%5-%6").arg(QString::number(tmpbuf[9], 16)).arg(QString::number(tmpbuf[10], 16)).arg(QString::number(tmpbuf[11], 16))
                        .arg(QString::number(tmpbuf[12], 16)).arg(QString::number(tmpbuf[13], 16)).arg(QString::number(tmpbuf[14], 16));

                int C0 = tmpbuf[9];
                C0<<= 8;
                C0 += tmpbuf[10];

                // 把信息传出给管理类
                m_lstPreviewIP.append( qsIP );
                m_pMainMgr->AppendOnlinePreview(qsIP, C0, qsMac);
            }
        }
    }
}

void SearchDeviceUdp::onSearchDevice()
{
    unsigned char ssmsg_user_k2[4];
    ssmsg_user_k2[0] = 0xff;
    ssmsg_user_k2[1] = 0x01;
    ssmsg_user_k2[2] = 0x01;
    ssmsg_user_k2[3] = 0x02;

    m_pUdpSocket->writeDatagram((char*)ssmsg_user_k2, 4, QHostAddress::Broadcast, 1500);//将data中的数据发送
}

void SearchDeviceUdp::GetDeviceConfig(int m1, int m2, int m3, int m4, int m5, int m6)
{
    unsigned char	ssmsg_user_k2[22]={0xff,0x13,0x03,0x00,0x71,0x77,0x7c,0x42,0x2f,0x61,0x64,0x6d,0x69,0x6e,0x00,0x61,0x64,0x6d,0x69,0x6e,0x00,0xfd};
    ssmsg_user_k2[3] = (unsigned char)m1;
    ssmsg_user_k2[4] = (unsigned char)m2;
    ssmsg_user_k2[5] = (unsigned char)m3;
    ssmsg_user_k2[6] = (unsigned char)m4;
    ssmsg_user_k2[7] = (unsigned char)m5;
    ssmsg_user_k2[8] = (unsigned char)m6;
    unsigned char B0 = 0;
    for (int i=1;i<21;i++) {
        B0 = B0 + ssmsg_user_k2[i];
    }
    ssmsg_user_k2[21] = B0;

    m_pUdpSocket->writeDatagram((char *)ssmsg_user_k2, 22, QHostAddress::Broadcast, 1500);//将data中的数据发送
}

// 接收UDP信息
void SearchDeviceUdp::processPendingDatagrams()
{
    while(m_pUdpSocket->hasPendingDatagrams())
    {
        QByteArray datagram;
        datagram.resize(m_pUdpSocket->pendingDatagramSize());

        unsigned char tmpbuf[4096];
        int bread = m_pUdpSocket->readDatagram((char *)tmpbuf, 256);

        if ((tmpbuf[0]==0xff)&&(tmpbuf[1]==0x24)&&(tmpbuf[2]==0x01)&&(bread==0x24)) {
            // 9~14为设备的Mac地址，根据这个可以获得设备的信息
            QString qsMac = QString("%1-%2-%3-%4-%5-%6").arg(QString::number(tmpbuf[9], 16)).arg(QString::number(tmpbuf[10], 16)).arg(QString::number(tmpbuf[11], 16))
                    .arg(QString::number(tmpbuf[12], 16)).arg(QString::number(tmpbuf[13], 16)).arg(QString::number(tmpbuf[14], 16));

            if ( !m_lstMac.contains(qsMac) )
                GetDeviceConfig((int)tmpbuf[9], (int)tmpbuf[10], (int)tmpbuf[11], (int)tmpbuf[12], (int)tmpbuf[13], (int)tmpbuf[14]);
        } else if((bread==0x82)&&(tmpbuf[0]==0x95)&&(tmpbuf[1]==0x63)&&(tmpbuf[2]==0x03)&&((tmpbuf[3]==0x80)||(tmpbuf[3]==0x00))) {
            QString qsMac = QString("%1-%2-%3-%4-%5-%6").arg(QString::number(tmpbuf[53], 16)).arg(QString::number(tmpbuf[54], 16)).arg(QString::number(tmpbuf[55], 16))
                    .arg(QString::number(tmpbuf[56], 16)).arg(QString::number(tmpbuf[57], 16)).arg(QString::number(tmpbuf[58], 16));

            if ( m_lstMac.contains(qsMac) )
                return;

            // 网关、子网掩码和端口直接copy头儿的代码
            QString qsGateway = QString("%1.%2.%3.%4").arg((int)tmpbuf[0x10]).arg((int)(tmpbuf[0x0f])).arg((int)(tmpbuf[0x0e])).arg((int)(tmpbuf[0x0d]));
            QString qsMask = QString("%1.%2.%3.%4").arg((int)tmpbuf[0x14]).arg((int)(tmpbuf[0x13])).arg((int)(tmpbuf[0x12])).arg((int)(tmpbuf[0x11]));
            unsigned int C0 = tmpbuf[0x50];
            unsigned int C1 =tmpbuf[0x4f];
            C0<<=8;
            C0+=C1;

            int port = C0;

            // ??? ip取9~12位，mac取53~58位，user取21~26位，可能存在BUG
            QString qsIP = QString("%1.%2.%3.%4").arg((int)tmpbuf[12]).arg((int)(tmpbuf[11])).arg((int)(tmpbuf[10])).arg((int)(tmpbuf[9]));
            QString qsUser = QString("%1%2%3%4%5%6").arg(QString(tmpbuf[21])).arg(QString(tmpbuf[22])).arg(QString(tmpbuf[23]))
                    .arg(QString(tmpbuf[24])).arg(QString(tmpbuf[25])).arg(QString(tmpbuf[26]));

            m_lstMac.append( qsMac );
            m_pMainMgr->AppendOnlineDevice(qsUser, qsIP, port, qsMask, qsGateway, qsMac);
        }
    }
}
