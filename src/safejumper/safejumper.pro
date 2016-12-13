#-------------------------------------------------
#
# Project created by QtCreator 2015-02-25T18:16:55
#
#-------------------------------------------------

QT	   += network xml core gui widgets

TARGET = safejumper
TEMPLATE = app

macx: {
    TARGET = Safejumper
    QMAKE_INFO_PLIST = ./Info.plist
    QMAKE_LFLAGS += -F /System/Library/Frameworks/
    QMAKE_RPATHDIR += @executable_path/../Frameworks
    LIBS += -framework Security
    target.path = /Applications
    resources.path = /Applications/Safejumper.app/Contents/Resources
    resources.files = ./resources/*
    INSTALLS = target resources
    ICON = Safejumper.icns
}

win32: {
    WINSDK_DIR = C:/Program Files/Microsoft SDKs/Windows/v7.1
    WIN_PWD = $$replace(PWD, /, \\)
    OUT_PWD_WIN = $$replace(OUT_PWD, /, \\)
    QMAKE_POST_LINK = "$$quote($$OUT_PWD_WIN\\..\\fixbinary.bat) $$quote($$OUT_PWD_WIN\\..\\safejumper.exe) $$quote($$WIN_PWD\\$$basename(TARGET).manifest)"
    RC_FILE = safejumper.rc
    LIBS += -lws2_32 -lIphlpapi
    DESTDIR = ../../buildwindows/
    MOC_DIR = ../.obj/
    HEADERS += \
        qtlocalpeer.h \
        qtlockedfile.h \
        qtsingleapplication.h \

    SOURCES += \
        qtlocalpeer.cpp \
        qtlockedfile.cpp \
        qtsingleapplication.cpp \
}

linux: {
    HEADERS += \
        qtlocalpeer.h \
        qtlockedfile.h \
        qtsingleapplication.h \

    SOURCES += \
        qtlocalpeer.cpp \
        qtlockedfile.cpp \
        qtsingleapplication.cpp \

    CONFIG += static
}

SOURCES += \
    main.cpp \
    sjmainwindow.cpp \
    scr_connect.cpp \
    scr_settings.cpp \
    common.cpp \
    scr_logs.cpp \
    authmanager.cpp \
    scr_map.cpp \
    wndmanager.cpp \
    dlg_error.cpp \
    setting.cpp \
    osspecific.cpp \
    log.cpp \
    flag.cpp \
    stun.cpp \
    thread_oldip.cpp \
    ministun.c \
    pingwaiter.cpp \
    pathhelper.cpp \
    thread_forwardports.cpp \
    portforwarder.cpp \
    acconnectto.cpp \
    lvrowdelegate.cpp \
    lvrowdelegateprotocol.cpp \
    fonthelper.cpp \
    dlg_newnode.cpp \
    lvrowdelegateencryption.cpp \
    scr_table.cpp \
    openvpnmanager.cpp \
    confirmationdialog.cpp

HEADERS += \
    sjmainwindow.h \
    scr_connect.h \
    scr_settings.h \
    common.h \
    scr_logs.h \
    authmanager.h \
    scr_map.h \
    wndmanager.h \
    dlg_error.h \
    setting.h \
    osspecific.h \
    log.h \
    flag.h \
    stun.h \
    thread_oldip.h \
    ministun.h \
    pingwaiter.h \
    pathhelper.h \
    thread_forwardports.h \
    portforwarder.h \
    acconnectto.h \
    lvrowdelegate.h \
    lvrowdelegateprotocol.h \
    fonthelper.h \
    version.h \
    update.h \
    dlg_newnode.h \
    lvrowdelegateencryption.h \
    scr_table.h \
    openvpnmanager.h \
    confirmationdialog.h

FORMS += \
    sjmainwindow.ui \
    scr_connect.ui \
    scr_settings.ui \
    scr_logs.ui \
    scr_map.ui \
    dlg_error.ui \
    dlg_newnode.ui \
    scr_table.ui \
    confirmationdialog.ui

RESOURCES += \
    imgs.qrc

