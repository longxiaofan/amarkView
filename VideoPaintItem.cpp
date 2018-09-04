#include "VideoPaintItem.h"
#include <QPainter>
#include <QDebug>
#include "Player/BCVedioManager.h"
#include "MainManager.h"

VideoPaintItem::VideoPaintItem(QQuickItem *parent)
    :QQuickPaintedItem(parent)
{
    m_pMainMgr = NULL;
    m_bPreview = false;
}

VideoPaintItem::~VideoPaintItem()
{
    if (NULL != m_pMainMgr) {
        BCVedioManager *pMgr = m_pMainMgr->GetPreviewMgr();
        if (NULL != pMgr) {
            pMgr->Detach( this );
        }
    }
}

void VideoPaintItem::SetBaseInfo(QObject *mgr, int gid, int wid, int chid)
{
    if (NULL == m_pMainMgr) {
        m_pMainMgr = dynamic_cast<MainManager *>( mgr );
    }

    m_gid = gid;
    m_wid = wid;
    m_chid = chid;
}
void VideoPaintItem::UpdateChannel(int chid)
{
    if (NULL != m_pMainMgr) {
        BCVedioManager *pMgr = m_pMainMgr->GetPreviewMgr();
        if (NULL == pMgr)
            return;

        pMgr->Detach( this );
        m_chid = chid;
        pMgr->Attach( this );
    }
}

void VideoPaintItem::OpenPreview(int w, int h)
{
    m_bPreview = true;
    w = (w/4)*4;
    m_size = QSize(w, h);

    if (NULL != m_pMainMgr) {
        BCVedioManager *pMgr = m_pMainMgr->GetPreviewMgr();
        if (NULL == pMgr)
            return;

        pMgr->Attach( this );
    }
}
void VideoPaintItem::ClosePreview()
{
    m_bPreview = false;
    if (NULL != m_pMainMgr) {
        BCVedioManager *pMgr = m_pMainMgr->GetPreviewMgr();
        if (NULL == pMgr)
            return;

        pMgr->Detach( this );

        // 更新空图片
        QPixmap pixmap;
        updateImage(m_gid, m_wid, pixmap);
    }
}

void VideoPaintItem::updateImage(int gid, int winid, const QPixmap &pixmap)
{
    if ((gid != m_gid) || (winid != m_wid))
        return;

    if (m_gid == -1)    // 预监时需要切掉最下面一像素，否则会闪现
        m_pixmap = pixmap.copy(0, 0, pixmap.width(), pixmap.height()-1);
    else
        m_pixmap = pixmap;

    this->update();
}

void VideoPaintItem::paint(QPainter* painter)
{
    // 如果没打开预监回显把图像置空
    if ( !m_bPreview )
        m_pixmap = QPixmap();

    painter->drawImage(this->boundingRect(), m_pixmap.toImage());
}
