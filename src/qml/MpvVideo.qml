/*
 * SPDX-FileCopyrightText: 2020 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects

import org.kde.ki18n

import org.kde.haruna
import org.kde.haruna.playlist
import org.kde.haruna.utilities
import org.kde.haruna.settings

import org.kde.kirigami as Kirigami

MpvItem {
    id: root

    property var window: Window.window
    property int preMinimizePlaybackState: MpvItem.PlaybackState.Playing
    property alias mouseY: mouseArea.mouseY
    property bool isRemoteUrl: typeof currentUrl.toString() === "string" && currentUrl.toString().startsWith("http")

    signal mousePositionChanged(double x, double y)
    signal openPlaylist()
    signal closePlaylist()
    signal filesDropped(list<url> urls, int mode)

    onPlaybackStateChanged: {
        switch(playbackState) {
        case MpvItem.PlaybackState.Stopped:
            loadingIndicator.play = false
            break
        case MpvItem.PlaybackState.Playing:
            loadingIndicator.play = false
            break
        case MpvItem.PlaybackState.Loading:
            if (root.isRemoteUrl) {
                loadingIndicator.play = true
            }
            break
        }
    }

    onPlayNext: { HarunaApp.actions.playNextAction.trigger() }
    onPlayPrevious: { HarunaApp.actions.playPreviousAction.trigger() }

    Timer {
        id: hideCursorTimer

        running: root.window.isFullScreen() && mouseArea.containsMouse

        repeat: true
        interval: 2000
        onTriggered: mouseArea.hideCursor = true
    }

    MouseArea {
        id: mouseArea

        property bool hideCursor: false

        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.ForwardButton | Qt.BackButton
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: hideCursor && root.window.isFullScreen() ? Qt.BlankCursor : Qt.ArrowCursor

        onPositionChanged: {
            root.mousePositionChanged(mouseX, mouseY)

            hideCursor = false
            hideCursorTimer.restart()

            if (!PlaylistSettings.canToggleWithMouse) {
                return
            }
            if (PlaylistSettings.position === "right") {
                if (mouseX > width - 50) {
                    root.openPlaylist()
                } else {
                    root.closePlaylist()
                }
            } else {
                if (mouseX < 50) {
                    root.openPlaylist()
                } else {
                    root.closePlaylist()
                }
            }
        }

        onWheel: function(wheel) {
            const model = Models.mouseActionsModel
            let actionName
            let modifier = wheel.modifiers
            if (wheel.angleDelta.y > 0) {
                actionName = model.getAction(MouseActionsModel.ScrollUp, modifier)
            } else if (wheel.angleDelta.y) {
                actionName = model.getAction(MouseActionsModel.ScrollDown, modifier)
            }

            if (actionName) {
                HarunaApp.actions[actionName].trigger()
            }
        }

        // Single-click actions are deferred while a double-click is still
        // possible, so double-clicking (e.g. to go fullscreen) never also
        // triggers the single-click action (e.g. pause).
        property string pendingClickAction: ""

        function actionForButton(button, modifier, isDoubleClick) {
            const model = Models.mouseActionsModel
            switch (button) {
            case Qt.LeftButton:
            case Qt.MiddleButton:
            case Qt.RightButton:
            case Qt.ForwardButton:
            case Qt.BackButton:
                return model.getAction(button, modifier, isDoubleClick)
            }
            return ""
        }

        function triggerAction(actionName) {
            if (actionName && HarunaApp.actions[actionName]) {
                HarunaApp.actions[actionName].trigger()
            }
        }

        Timer {
            id: singleClickTimer

            interval: Application.styleHints.mouseDoubleClickInterval
            onTriggered: {
                mouseArea.triggerAction(mouseArea.pendingClickAction)
                mouseArea.pendingClickAction = ""
            }
        }

        onPressed: function(mouse) {
            focus = true
            const actionName = actionForButton(mouse.button, mouse.modifiers, false)
            if (!actionName) {
                return
            }
            const doubleAction = actionForButton(mouse.button, mouse.modifiers, true)
            // context menus should open immediately
            if (!doubleAction || actionName === "openContextMenuAction") {
                triggerAction(actionName)
                return
            }
            pendingClickAction = actionName
            singleClickTimer.restart()
        }

        onDoubleClicked: function(mouse) {
            focus = true
            singleClickTimer.stop()
            pendingClickAction = ""
            triggerAction(actionForButton(mouse.button, mouse.modifiers, true))
        }
    }

    // Natsuna: dropping files on the video plays them. (Haruna split the
    // window into "Add to Playlist" / "Play Now" zones; to add files to the
    // playlist, drop them on the playlist panel instead.)
    DropArea {
        id: dropArea

        property bool dragMedia: false
        property bool dragSubtitle: false
        property int subtitleIndex: -1

        anchors.fill: parent
        keys: ["text/uri-list"]

        onEntered: function (drag) {
            for (var i = 0; i < drag.urls.length; ++i) {
                let mimeType = MiscUtils.mimeType(drag.urls[i])
                let isDir = PathUtils.isDir(drag.urls[i])
                if (mimeType.startsWith("video/") || mimeType.startsWith("audio/") || isDir) {
                    dragMedia = true
                    return
                }
                if (root.window.acceptedSubtitleTypes.includes(mimeType)) {
                    dragSubtitle = true
                    subtitleIndex = i
                }
            }
        }

        onExited: {
            dragMedia = false
            dragSubtitle = false
            subtitleIndex = -1
        }

        onDropped: function (drop) {
            if (dragSubtitle && !dragMedia) {
                // only subtitle files were dropped: load the subtitle for the current video
                root.addSubtitles(drop.urls[subtitleIndex])
            } else if (drop.urls.length > 1 || PathUtils.isDir(drop.urls[0])) {
                // several files, or a folder: play them as the new playlist
                root.filesDropped(drop.urls, PlaylistModel.Clear)
            } else {
                // one file: play it
                root.window.openFile(drop.urls[0], RecentFilesModel.OpenedFrom.ExternalApp)
            }

            dragMedia = false
            dragSubtitle = false
            subtitleIndex = -1
        }
    }

    Rectangle {
        id: loadingIndicator

        property bool play: false
        property int size: 200

        visible: root.playbackState === MpvItem.PlaybackState.Stopped
                 || (root.playbackState === MpvItem.PlaybackState.Loading && root.isRemoteUrl)
        anchors.centerIn: parent
        radius: Kirigami.Units.cornerRadius
        width: root.width > size ? size : root.width - 10
        height: root.height > size ? size : root.height - 10
        color: play ? Qt.alpha(Kirigami.Theme.backgroundColor, 0.6) : "transparent"

        ColumnLayout {
            anchors.centerIn: parent

            Item {
                property int spriteSize: {
                    const _paddedMaxHeight = root.height - Kirigami.Units.largeSpacing * 2 - loadingText.implicitHeight
                    const _clampedHeight = Math.min(Kirigami.Units.iconSizes.enormous, _paddedMaxHeight)
                    return Math.max(Kirigami.Units.iconSizes.small, _clampedHeight)
                }
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: spriteSize
                Layout.preferredHeight: spriteSize

                Loader {
                    id: loadingIndicatorSprite

                    anchors.fill: parent
                    active: true
                    asynchronous: true
                    sourceComponent: AnimatedSprite {
                        finishBehavior: AnimatedSprite.FinishAtInitialFrame
                        frameCount: 8
                        // Do NOT use frameRate. It causes flickering. Use frameDuration instead
                        frameDuration: Math.round(1000.0 / 30.0)
                        frameHeight: 192
                        frameWidth: 192
                        interpolate: false
                        source: "qrc:/data/animations/192-natsuna-animation-sliding.png"
                        reverse: false
                        running: loadingIndicator.play
                        onRunningChanged: currentFrame = 0
                    }
                }
            }

            Text {
                id: loadingText

                text: KI18n.i18nc("@label:title", "Loading…")
                visible: loadingIndicator.play

                font {
                    bold: true
                    pointSize: 16
                }

                Layout.alignment: Qt.AlignHCenter
            }

            layer.enabled: true
            layer.samplerName: "maskSource"
            layer.effect: ShaderEffect {
                property color colorSource: loadingIndicator.play ? Qt.alpha(Kirigami.Theme.textColor, 0.65) : "#222"
                fragmentShader: "qrc:/shader/colorfill.frag.qsb"
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Window
            }
        }
    }
}
