#ifndef SEARCHDEVICEUDP_H
#define SEARCHDEVICEUDP_H

#include <QObject>

class QTimer;
class MainManager;
class QUdpSocket;
class SearchDeviceUdp : public QObject
{
    Q_OBJECT
public:
    explicit SearchDeviceUdp(MainManager *parent = nullptr);
    ~SearchDeviceUdp();

signals:
    void sigDevice(const QString &name, const QString &ip, int port, const QString &mask, const QString &gateway, const QString &mac);
    void sigPreviewIP(const QString &ip, int port);

private slots:
    void processPendingDatagrams();
    void onSearchDevice();

    void onSearchPreviewDevice();
    void onRecvPreviewUdpData();

private:
    void GetDeviceConfig(int m1=0xff, int m2=0xff, int m3=0xff, int m4=0xff, int m5=0xff, int m6=0xff);

    MainManager *m_pMainMgr;
    QUdpSocket  *m_pUdpSocket;          // 广播的通讯UDP
    QUdpSocket  *m_pPreviewUdpSocket;   // 广播的预监UDP

    QTimer      *m_pTimer;              // 广播的定时器
    QStringList m_lstMac;               // 同一台设备只传出一次
    QStringList m_lstPreviewIP;         // 因为预监没有把mac传过来，所以只能用IP判断
};

#endif // SEARCHDEVICEUDP_H
