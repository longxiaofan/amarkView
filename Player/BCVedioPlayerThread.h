#ifndef BCVEDIOPLAYERTHREAD_H
#define BCVEDIOPLAYERTHREAD_H

#include <QThread>

class BCVedioManager;
class BCVedioPlayerThread : public QThread
{
    Q_OBJECT
public:
    BCVedioPlayerThread(BCVedioManager *parent = NULL);
    ~BCVedioPlayerThread();

    void run();

    void Quit();

signals:
    void sigImage(int gid, int winid, const QPixmap &pixmap);

private:
    bool m_bQuit;   // 退出标识

    uint8_t		*SrcData[4];
    int			SrcLinesize[4];

    uint8_t		*DesData[4];
    int			DesLinesize[4];

    // 临时链表，用来计算偏移量的
    uint8_t pCurrentFrame[1920*1080*4];

    BCVedioManager *m_parent;
};

#endif // BCVEDIOPLAYERTHREAD_H
