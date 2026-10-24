/*
 * SPDX-FileCopyrightText: 2026 Natsuna contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef NATSUNA_WINDOWUTILS_H
#define NATSUNA_WINDOWUTILS_H

#include <QObject>
#include <QQmlEngine>
#include <QWindow> // moc needs the full type for Q_INVOKABLE pointer arguments

// Window helpers for Natsuna that Haruna doesn't have.
class NatsunaWindowUtils : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit NatsunaWindowUtils(QObject *parent = nullptr);

    // Keeps the window above all other windows ("Always on Top").
    // On KDE Plasma this uses KWin's "Keep Above Others" plus a window rule that
    // puts the player in the Overlay layer, so it also stays above focused
    // fullscreen windows. Elsewhere it falls back to Qt's stay-on-top hint.
    Q_INVOKABLE void setKeepAbove(QWindow *window, bool keepAbove);

    // Hides the title bar and frame (auto-hide mode).
    // On KDE Plasma this uses KWin's "No Titlebar and Frame", which applies
    // immediately. Elsewhere it falls back to Qt's frameless window hint.
    Q_INVOKABLE void setFrameless(QWindow *window, bool frameless);

private:
    // Runs a small KWin script; returns false when KWin isn't available
    bool runKWinScript(const QString &name, const QString &body);

    // Adds (or removes) a KWin window rule that puts the player window in the
    // Overlay layer, above even focused fullscreen windows.
    bool setOverlayLayerRule(bool enabled);
};

#endif // NATSUNA_WINDOWUTILS_H
