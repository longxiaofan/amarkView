QT += quick xml
CONFIG += c++11

# The following define makes your compiler emit warnings if you use
# any feature of Qt which as been marked deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if you use deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

HEADERS += \
    MainManager.h \
    VideoPaintItem.h \
    Player/BCVedioDecodeThread.h \
    Player/BCVedioManager.h \
    Player/BCVedioPlayerThread.h \
    SearchDeviceUdp.h

SOURCES += main.cpp \
    MainManager.cpp \
    VideoPaintItem.cpp \
    Player/BCVedioDecodeThread.cpp \
    Player/BCVedioManager.cpp \
    Player/BCVedioPlayerThread.cpp \
    SearchDeviceUdp.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

#QMAKE_LFLAGS += -Wl,--rpath=lib

win32: {
LIBS += -L$$PWD/Player/win32/lib/ -llibavcodec.dll \
        -L$$PWD/Player/win32/lib/ -llibavdevice.dll \
        -L$$PWD/Player/win32/lib/ -llibavfilter.dll \
        -L$$PWD/Player/win32/lib/ -llibavformat.dll \
        -L$$PWD/Player/win32/lib/ -llibavutil.dll \
        -L$$PWD/Player/win32/lib/ -llibpostproc.dll \
        -L$$PWD/Player/win32/lib/ -llibswresample.dll \
        -L$$PWD/Player/win32/lib/ -llibswscale.dll

INCLUDEPATH += $$PWD/Player/win32/include
}

unix:!macx: {
LIBS += -L$$PWD/Player/unix/lib/ -lavcodec \
        -L$$PWD/Player/unix/lib/ -lavfilter \
        -L$$PWD/Player/unix/lib/ -lavformat \
        -L$$PWD/Player/unix/lib/ -lavutil \
        -L$$PWD/Player/unix/lib/ -lfdk-aac \
        -L$$PWD/Player/unix/lib/ -lswresample \
        -L$$PWD/Player/unix/lib/ -lswscale

INCLUDEPATH += $$PWD/Player/unix/include
}

contains(ANDROID_TARGET_ARCH,armeabi-v7a) {
    ANDROID_EXTRA_LIBS = \
        $$PWD/Player/unix/lib/libavcodec.so \
        $$PWD/Player/unix/lib/libavfilter.so \
        $$PWD/Player/unix/lib/libavformat.so \
        $$PWD/Player/unix/lib/libavutil.so \
        $$PWD/Player/unix/lib/libfdk-aac.so \
        $$PWD/Player/unix/lib/libswresample.so \
        $$PWD/Player/unix/lib/libswscale.so
}

DISTFILES += \
    android/AndroidManifest.xml \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradlew \
    android/res/values/libs.xml \
    android/build.gradle \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew.bat

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
