/*
 * SPDX-FileCopyrightText: 2020 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Controls

import org.kde.kirigami as Kirigami
import org.kde.haruna
import org.kde.haruna.settings

Item {
    id: root

    required property int maxWidth

    property bool active: false

    Label {
        id: label

        property int textWidth: Math.ceil(textMetrics.advanceWidth) + padding * 2

        x: Kirigami.Units.largeSpacing
        y: Kirigami.Units.largeSpacing
        width: textWidth > root.maxWidth ? root.maxWidth : undefined
        visible: false
        background: Rectangle {
            color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.8)
            radius: Kirigami.Units.cornerRadius
        }
        padding: Kirigami.Units.largeSpacing
        font.pointSize: parseInt(GeneralSettings.osdFontSize)
        maximumLineCount: 5
        wrapMode: Text.WrapAnywhere

        TextMetrics {
            id: textMetrics

            font: label.font
            text: label.text
        }
    }

    // Natsuna: the name of the file that just started, centred at the
    // bottom of the video with no background (like VLC's media title)
    Label {
        id: titleLabel

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Kirigami.Units.gridUnit * 2
        width: Math.min(implicitWidth, root.width - Kirigami.Units.gridUnit * 4)
        visible: false
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideMiddle
        color: "white"
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.6)
        font.pointSize: Math.max(parseInt(GeneralSettings.osdFontSize), 12) * 1.6
    }

    Timer {
        id: titleTimer

        interval: 3000
        onTriggered: titleLabel.visible = false
    }

    function titleMessage(text: string) : void {
        // shown even when other on-screen messages are turned off (size 0)
        if (!root.active || !text) {
            return
        }

        titleLabel.text = text
        titleLabel.visible = true
        titleTimer.restart()
    }

    Timer {
        id: timer
        running: false
        repeat: false
        interval: 3000

        onTriggered: {
            label.visible = false
        }
    }

    function message(text: string) : void {
        if (!root.active) {
            return
        }

        if (text === "" || text === null || text === undefined) {
            return
        }

        const osdFontSize = parseInt(GeneralSettings.osdFontSize)
        if (osdFontSize === 0) {
            return;
        }

        timer.restart()
        label.text = text
        label.visible = true
    }

}
