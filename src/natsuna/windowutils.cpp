/*
 * SPDX-FileCopyrightText: 2026 Natsuna contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "windowutils.h"

#include "config-haruna.h"

#include <QCoreApplication>
#include <QDir>
#include <QJsonArray>
#include <QJsonDocument>
#include <QTemporaryFile>
#include <QWindow>

#include <KConfig>
#include <KConfigGroup>

#if HAVE_DBUS
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusMessage>
#include <QDBusReply>
#endif

using namespace Qt::StringLiterals;

namespace
{
// A JavaScript string literal for `text`, safely escaped
QString jsString(const QString &text)
{
    const auto json = QString::fromUtf8(QJsonDocument(QJsonArray{text}).toJson(QJsonDocument::Compact));
    return json.mid(1, json.size() - 2); // strip the surrounding [ ]
}
}

NatsunaWindowUtils::NatsunaWindowUtils(QObject *parent)
    : QObject(parent)
{
}

void NatsunaWindowUtils::setKeepAbove(QWindow *window, bool keepAbove)
{
    if (!window) {
        return;
    }

    const QString script = uR"(
const windows = workspace.windowList ? workspace.windowList() : workspace.clientList();
for (const w of windows) {
    if (w.pid === %1 && w.normalWindow) {
        w.keepAbove = %2;
    }
}
)"_s.arg(QCoreApplication::applicationPid())
                               .arg(keepAbove ? u"true"_s : u"false"_s);

    if (runKWinScript(u"natsuna-keepabove"_s, script)) {
        // "Keep Above Others" alone loses to a focused fullscreen window, which
        // KWin stacks in a higher layer; the Overlay layer rule beats that too.
        setOverlayLayerRule(keepAbove);
        return;
    }

    // Not running under KWin: ask the window manager through Qt.
    // Changing window flags can hide the window, so show it again if needed.
    const bool wasVisible = window->isVisible();
    window->setFlag(Qt::WindowStaysOnTopHint, keepAbove);
    if (wasVisible && !window->isVisible()) {
        window->show();
    }
}

void NatsunaWindowUtils::setFrameless(QWindow *window, bool frameless)
{
    if (!window) {
        return;
    }

    // Only this window (not e.g. the Preferences window): KWin's caption starts
    // with the window title, possibly followed by " — Natsuna".
    const QString script = uR"(
const windows = workspace.windowList ? workspace.windowList() : workspace.clientList();
const title = %3;
for (const w of windows) {
    if (w.pid === %1 && w.normalWindow && w.caption.startsWith(title)) {
        w.noBorder = %2;
    }
}
)"_s.arg(QCoreApplication::applicationPid())
                               .arg(frameless ? u"true"_s : u"false"_s)
                               .arg(jsString(window->title()));

    if (runKWinScript(u"natsuna-noborder"_s, script)) {
        // make sure Qt's own frameless hint isn't also set from the fallback path
        if (window->flags() & Qt::FramelessWindowHint) {
            window->setFlag(Qt::FramelessWindowHint, false);
        }
        return;
    }

    // Not running under KWin: use Qt's frameless window hint.
    const bool wasVisible = window->isVisible();
    window->setFlag(Qt::FramelessWindowHint, frameless);
    if (wasVisible && !window->isVisible()) {
        window->show();
    }
}

bool NatsunaWindowUtils::setOverlayLayerRule(bool enabled)
{
#if HAVE_DBUS
    auto bus = QDBusConnection::sessionBus();
    if (!bus.isConnected() || !bus.interface() || !bus.interface()->isServiceRegistered(u"org.kde.KWin"_s)) {
        return false;
    }

    // Same format as rules made in System Settings -> Window Management -> Window Rules
    KConfig rules(u"kwinrulesrc"_s, KConfig::NoGlobals);
    const QString groupName = u"natsuna-always-on-top"_s;
    const bool exists = rules.hasGroup(groupName);
    if (enabled == exists) {
        return true;
    }

    if (enabled) {
        KConfigGroup rule(&rules, groupName);
        rule.writeEntry("Description", u"Natsuna: Always on Top (managed by Natsuna)"_s);
        // the app id on Wayland is io.github.tormstorm.natsuna, the class on X11 is natsuna
        rule.writeEntry("wmclass", u"natsuna"_s);
        rule.writeEntry("wmclassmatch", 2); // substring
        // the player window, not the Preferences window
        rule.writeEntry("title", u"^(?!Preferences)"_s);
        rule.writeEntry("titlematch", 3); // regular expression
        rule.writeEntry("types", 1); // normal windows
        rule.writeEntry("layer", u"overlay"_s);
        rule.writeEntry("layerrule", 2); // force
    } else {
        rules.deleteGroup(groupName);
    }
    rules.sync();

    // ask KWin to reload its rules; it re-applies them to open windows
    auto reconfigure = QDBusMessage::createMethodCall(u"org.kde.KWin"_s, u"/KWin"_s, u"org.kde.KWin"_s, u"reconfigure"_s);
    bus.call(reconfigure);
    return true;
#else
    Q_UNUSED(enabled)
    return false;
#endif
}

bool NatsunaWindowUtils::runKWinScript(const QString &name, const QString &body)
{
#if HAVE_DBUS
    auto bus = QDBusConnection::sessionBus();
    if (!bus.isConnected() || !bus.interface() || !bus.interface()->isServiceRegistered(u"org.kde.KWin"_s)) {
        return false;
    }

    QTemporaryFile file(QDir::tempPath() + u"/%1-XXXXXX.js"_s.arg(name));
    if (!file.open()) {
        return false;
    }
    file.write(body.toUtf8());
    file.flush();

    const QString service = u"org.kde.KWin"_s;
    const QString scriptingPath = u"/Scripting"_s;
    const QString scriptingIface = u"org.kde.kwin.Scripting"_s;

    // Remove a leftover copy from an earlier call, if any.
    auto unload = QDBusMessage::createMethodCall(service, scriptingPath, scriptingIface, u"unloadScript"_s);
    unload << name;
    bus.call(unload);

    auto load = QDBusMessage::createMethodCall(service, scriptingPath, scriptingIface, u"loadScript"_s);
    load << file.fileName() << name;
    QDBusReply<int> scriptId = bus.call(load);
    if (!scriptId.isValid() || scriptId.value() < 0) {
        return false;
    }

    auto run = QDBusMessage::createMethodCall(service,
                                              u"/Scripting/Script%1"_s.arg(scriptId.value()),
                                              u"org.kde.kwin.Script"_s,
                                              u"run"_s);
    const auto runReply = bus.call(run);

    bus.call(unload);

    return runReply.type() != QDBusMessage::ErrorMessage;
#else
    Q_UNUSED(name)
    Q_UNUSED(body)
    return false;
#endif
}
