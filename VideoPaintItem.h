#ifndef VIDEOPAINTITEM_H
#define VIDEOPAINTITEM_H

#include <QQuickPaintedItem>
#include <QPixmap>

class MainManager;
class VideoPaintItem : public QQuickPaintedItem
{
    Q_OBJECT
    Q_DISABLE_COPY(VideoPaintItem)

public:
    VideoPaintItem(QQuickItem *parent=NULL);
    ~VideoPaintItem();

    Q_INVOKABLE void SetBaseInfo(QObject *mgr, int gid, int wid, int chid); // 设置基础属性
    Q_INVOKABLE void UpdateChannel(int chid);                               // 更新内部通道时使用

    Q_INVOKABLE void OpenPreview(int w, int h);
    Q_INVOKABLE void ClosePreview();

    // Manager
    int m_gid;  // group id
    int m_wid;  // window id
    int m_chid; // channel id

    QSize m_size;

public slots:
    void updateImage(int gid, int winid, const QPixmap &pixmap);

protected:
    void paint(QPainter* painter);

    MainManager *m_pMainMgr;

    bool m_bPreview;
    QPixmap m_pixmap;
};

#endif // VIDEOPAINTITEM_H
