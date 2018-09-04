#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTextCodec>
#include "MainManager.h"
#include "VideoPaintItem.h"
#include "Player/BCVedioManager.h"

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);

    // 设置编码
    QTextCodec::setCodecForLocale(QTextCodec::codecForName("UTF-8"));

    // c++ manager
    MainManager mainMgr;
    QQmlApplicationEngine engine;

    // qml invoke function of c++
    qmlRegisterType<VideoPaintItem>("com.MainManager", 1, 0, "MainManager");
    engine.rootContext()->setContextProperty("mainMgr", &mainMgr);
    // preview image by c++
    qmlRegisterType<VideoPaintItem>("com.VideoPaintItem", 1, 0, "VideoPaintItem");
    // load UI
    engine.load(QUrl(QLatin1String("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    // c++ invoke function of qml
    QObject *root = engine.rootObjects().first();
    mainMgr.SetQMLRoot( root );

    // signal-slot
    QObject::connect(root, SIGNAL(sigGWinsize(int,int,int,int,int,int,int)), &mainMgr, SLOT(onGWinsize(int,int,int,int,int,int,int)));

    return app.exec();
}
