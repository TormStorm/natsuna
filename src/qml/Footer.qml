/*
 * SPDX-FileCopyrightText: 2024 George Florea Bănuș <georgefb899@gmail.com>
 * SPDX-FileCopyrightText: 2026 Natsuna contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

// Natsuna: VLC-style control bar.
//
// Windowed: a fixed bar below the video.
//   [elapsed] [========= seek bar =========] [total / -remaining]
//   [▶] [⏮][⏹][⏭] [⛶]                         [🔊 ▁▂▃▄ volume]
//
// Fullscreen: the same controls in a smaller box centred near the bottom of
// the screen. It appears whenever the mouse moves and fades out after the
// mouse has been still for a moment (unless the pointer is over it).

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.ki18n

import org.kde.kirigami as Kirigami
import org.kde.haruna
import org.kde.haruna.playlist
import org.kde.haruna.settings

Item {
    id: root

    required property MpvVideo m_mpv
    required property PlaylistsManager playlistsManager
    required property MenuBarLoader m_menuBarLoader
    required property Header m_header
    required property SettingsWindow m_settingsLoader

    property alias progressBar: progressBar
    property string footerState: isFloating ? "hidden" : "visible"
    property bool isFullScreen: root.Window.window?.visibility === Window.FullScreen
    // Auto-hide mode (View menu): all controls float over the video and hide together
    property bool autoHideWindowed: GeneralSettings.autoHideInterface && !isFullScreen
    // Floating = drawn over the video instead of below it
    property bool isFloating: isFullScreen || GeneralSettings.footerStyle === "floating"
                              || GeneralSettings.autoHideInterface
    // Set by the window while the top controls (auto-hide mode) are in use
    property bool holdVisible: false
    readonly property bool controlsShown: footerState === "visible"
    property bool isSmallSize: width < 600
    property int buttonSize: isSmallSize ? Kirigami.Units.iconSizes.small : Kirigami.Units.iconSizes.smallMedium
    // How long the floating controls stay after the mouse stops moving
    property int hideDelay: 2000

    implicitWidth: Window.window.contentItem.width
    // The floating controller sits flush against the bottom of the screen
    implicitHeight: footer.height

    // Close the hamburger menu (used when the app loses focus)
    function closeMenus() : void {
        hamburgerMenu.isOpen = false
    }

    // Show the floating controls (they hide again after hideDelay)
    function showControls() : void {
        footer.showFloating()
    }

    onIsFloatingChanged: {
        if (root.isFloating) {
            // briefly show the controls, like VLC does when entering fullscreen
            footer.showFloating()
        } else {
            hideFooterTimer.stop()
            root.footerState = "visible"
        }
    }

    // A flat icon button with an optional explanatory tooltip
    component BarButton: ToolButton {
        id: barButton

        property string toolTipText

        display: AbstractButton.IconOnly
        focusPolicy: Qt.NoFocus
        icon.width: root.buttonSize
        icon.height: root.buttonSize

        ToolTip {
            text: barButton.toolTipText
            delay: HarunaApp.isAltKeyPressed ? 0 : Kirigami.Units.toolTipDelay
            visible: barButton.hovered && barButton.toolTipText !== ""
                     && (GeneralSettings.showExplanatoryToolTips || HarunaApp.isAltKeyPressed)
        }
    }

    ToolBar {
        id: footer

        x: (root.width - width) / 2
        width: root.isFloating
               ? Math.min(root.width - Kirigami.Units.largeSpacing * (root.isSmallSize ? 2 : 4),
                          Kirigami.Units.gridUnit * 45)
               : root.width

        // Only the floating (fullscreen) controller ever hides
        state: root.isFloating ? root.footerState : "visible"
        padding: Kirigami.Units.smallSpacing
        leftPadding: Kirigami.Units.largeSpacing
        rightPadding: Kirigami.Units.largeSpacing
        position: ToolBar.Footer
        hoverEnabled: true
        background: Rectangle {
            color: Qt.alpha(Kirigami.Theme.backgroundColor, root.isFloating ? 0.85 : 1.0)
            // rounded top corners only, since the bottom edge touches the screen edge
            radius: root.isFloating ? Kirigami.Units.cornerRadius : 0
            bottomLeftRadius: 0
            bottomRightRadius: 0
            border.width: root.isFloating ? 1 : 0
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
        }

        // Floating mode: any mouse movement over the video shows the controls...
        Connections {
            target: root.m_mpv
            enabled: root.isFloating
            function onMousePositionChanged(x, y) {
                footer.showFloating()
            }
        }

        // ...and leaving the window hides them soon after.
        Connections {
            target: HarunaApp
            enabled: root.isFloating
            function onQmlApplicationMouseLeave() {
                hideFooterTimer.restart()
            }
        }

        Timer {
            id: hideFooterTimer

            interval: root.hideDelay
            onTriggered: {
                if (!root.isFloating) {
                    return
                }
                if (footer.hovered || hamburgerMenu.isOpen || progressBar.chaptersPopupIsOpen
                        || volumeSlider.pressed || root.holdVisible) {
                    // still in use, check again later
                    hideFooterTimer.restart()
                    return
                }
                root.footerState = "hidden"
            }
        }

        function showFloating() : void {
            root.footerState = "visible"
            hideFooterTimer.restart()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            // Row 1: elapsed time | seek bar | total or remaining time
            RowLayout {
                spacing: Kirigami.Units.largeSpacing

                Label {
                    id: elapsedLabel

                    text: root.m_mpv.formattedPosition
                    font: Kirigami.Theme.smallFont
                    horizontalAlignment: Text.AlignRight

                    Layout.minimumWidth: timeMetrics.width
                }

                HProgressBar {
                    id: progressBar

                    m_mpv: root.m_mpv

                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                }

                Label {
                    id: durationLabel

                    text: GeneralSettings.showRemainingTime
                          ? "-" + root.m_mpv.formattedRemaining
                          : root.m_mpv.formattedDuration
                    font: Kirigami.Theme.smallFont
                    horizontalAlignment: Text.AlignLeft

                    Layout.minimumWidth: timeMetrics.width

                    // Click to switch between total and remaining time, like VLC
                    MouseArea {
                        id: durationMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            GeneralSettings.showRemainingTime = !GeneralSettings.showRemainingTime
                            GeneralSettings.save()
                        }
                    }

                    ToolTip {
                        text: GeneralSettings.showRemainingTime
                              ? KI18n.i18nc("@info:tooltip", "Remaining time. Click to show total time")
                              : KI18n.i18nc("@info:tooltip", "Total time. Click to show remaining time")
                        delay: Kirigami.Units.toolTipDelay
                        visible: durationMouseArea.containsMouse
                    }
                }

                TextMetrics {
                    id: timeMetrics

                    font: Kirigami.Theme.smallFont
                    text: "-00:00:00"
                }
            }

            // Row 2: playback buttons ............................ volume
            RowLayout {
                spacing: root.isSmallSize ? 1 : Kirigami.Units.smallSpacing

                HamburgerMenu {
                    id: hamburgerMenu

                    m_mpv: root.m_mpv
                    m_settingsLoader: root.m_settingsLoader
                    m_menuBarLoader: root.m_menuBarLoader

                    position: HamburgerMenu.Position.Footer
                    // not needed when the auto-hide top strip already shows a menu bar or toolbar
                    visible: root.m_menuBarLoader.state === "hidden" && !root.m_header.visible
                             && !(root.autoHideWindowed && (GeneralSettings.showMenuBar || GeneralSettings.showHeader))
                    icon.width: root.buttonSize
                    icon.height: root.buttonSize
                }

                BarButton {
                    id: playPauseButton

                    icon.name: root.m_mpv.pause ? "media-playback-start" : "media-playback-pause"
                    icon.width: root.buttonSize * 1.25
                    icon.height: root.buttonSize * 1.25
                    enabled: root.m_mpv.duration !== 0
                    toolTipText: root.m_mpv.pause
                                 ? KI18n.i18nc("@info:tooltip", "Play")
                                 : KI18n.i18nc("@info:tooltip", "Pause")
                    onClicked: HarunaApp.actions.playPauseAction.trigger()
                }

                Item { Layout.preferredWidth: Kirigami.Units.smallSpacing }

                BarButton {
                    icon.name: footer.LayoutMirroring.enabled ? "media-skip-forward" : "media-skip-backward"
                    enabled: root.playlistsManager.activePlaylist.itemCount > 1
                    toolTipText: KI18n.i18nc("@info:tooltip", "Previous media in the playlist")
                    onClicked: HarunaApp.actions.playPreviousAction.trigger()
                }

                BarButton {
                    icon.name: "media-playback-stop"
                    enabled: root.m_mpv.duration !== 0
                    toolTipText: KI18n.i18nc("@info:tooltip", "Stop playback")
                    onClicked: HarunaApp.actions.stopAction.trigger()
                }

                BarButton {
                    icon.name: footer.LayoutMirroring.enabled ? "media-skip-backward" : "media-skip-forward"
                    enabled: root.playlistsManager.activePlaylist.itemCount > 1
                    toolTipText: KI18n.i18nc("@info:tooltip", "Next media in the playlist")
                    onClicked: HarunaApp.actions.playNextAction.trigger()
                }

                Item { Layout.preferredWidth: Kirigami.Units.smallSpacing }

                BarButton {
                    icon.name: root.isFullScreen ? "view-restore" : "view-fullscreen"
                    toolTipText: root.isFullScreen
                                 ? KI18n.i18nc("@info:tooltip", "Leave fullscreen")
                                 : KI18n.i18nc("@info:tooltip", "Toggle the video in fullscreen")
                    onClicked: HarunaApp.actions.toggleFullscreenAction.trigger()
                }

                BarButton {
                    id: chaptersMenuButton

                    icon.name: "overflow-menu"
                    visible: !progressBar.showChapterMarkers && root.m_mpv.chaptersModel.rowCount > 0
                    toolTipText: KI18n.i18nc("@info:tooltip", "Chapters")
                    onClicked: progressBar.openChapterPopup(this)
                }

                Item { Layout.fillWidth: true }

                BarButton {
                    id: mute

                    action: HarunaApp.actions.muteAction
                    icon.name: root.m_mpv.mute || root.m_mpv.volume === 0 ? "player-volume-muted" : "player-volume"
                    toolTipText: HarunaApp.actions.muteAction.text
                }

                VolumeSlider {
                    id: volumeSlider

                    m_mpv: root.m_mpv
                    label.font.pointSize: root.isSmallSize ? 8 : 10

                    Layout.preferredWidth: root.isSmallSize ? 60 : 100
                    Layout.preferredHeight: 20
                }
            }
        }

        states: [
            State {
                name: "hidden"
                PropertyChanges {
                    footer.opacity: 0
                    footer.visible: false
                }
            },
            State {
                name : "visible"
                PropertyChanges {
                    footer.opacity: 1
                    footer.visible: true
                }
            }
        ]

        transitions: [
            Transition {
                from: "visible"
                to: "hidden"

                SequentialAnimation {
                    NumberAnimation {
                        target: footer
                        property: "opacity"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    PropertyAction {
                        target: footer
                        property: "visible"
                        value: false
                    }
                }
            },
            Transition {
                from: "hidden"
                to: "visible"

                SequentialAnimation {
                    PropertyAction {
                        target: footer
                        property: "visible"
                        value: true
                    }
                    NumberAnimation {
                        target: footer
                        property: "opacity"
                        duration: Kirigami.Units.shortDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        ]
    }
}
