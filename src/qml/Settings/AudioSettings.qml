/*
 * SPDX-FileCopyrightText: 2020 George Florea Bănuș <georgefb899@gmail.com>
 * SPDX-FileCopyrightText: 2026 Natsuna contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.ki18n
import org.kde.kirigami as Kirigami

import org.kde.haruna
import org.kde.haruna.settings

SettingsBasePage {
    id: root

    readonly property string trackPriorityHelp: KI18n.i18nc("@info:tooltip",
                                                            "Track selection priority:<br>" +
                                                            "- preferred track id<br>" +
                                                            "- track matching the preferred language<br>" +
                                                            "- default track<br>" +
                                                            "- no track")

    ColumnLayout {
        spacing: PrefStyle.sectionSpacing

        PrefHeading {
            text: KI18n.i18nc("@title", "Audio")
        }

        // ------------------------------------
        // Volume and tracks
        // ------------------------------------
        PrefSection {
            title: KI18n.i18nc("@title", "Volume and tracks")

            PrefRow {
                title: KI18n.i18nc("@label:spinbox", "Volume step")
                description: KI18n.i18nc("@info", "How much the volume changes per key press or scroll.")

                SpinBox {
                    id: volumeStep

                    editable: true
                    from: 0
                    to: 100
                    value: AudioSettings.volumeStep
                    onValueModified: {
                        AudioSettings.volumeStep = volumeStep.value
                        AudioSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@label:textbox", "Preferred language")
                description: KI18n.i18nc("@info", "Language codes, for example: eng, ger")
                help: root.trackPriorityHelp

                TextField {
                    id: preferredLanguage

                    text: AudioSettings.preferredLanguage
                    placeholderText: "eng, ger"
                    Layout.preferredWidth: PrefStyle.fieldWidth
                    onEditingFinished: save()

                    Connections {
                        target: root
                        function onSave() {
                            preferredLanguage.save()
                        }
                    }

                    function save() {
                        AudioSettings.preferredLanguage = text
                        AudioSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@label:spinbox", "Preferred track")
                help: root.trackPriorityHelp

                SpinBox {
                    from: 0
                    to: 100
                    editable: true
                    value: AudioSettings.preferredTrack
                    onValueModified: {
                        AudioSettings.preferredTrack = value
                        AudioSettings.save()
                    }
                }
            }
        }

        // ------------------------------------
        // Replay gain
        // See: https://mpv.io/manual/stable/#options-replaygain
        // ------------------------------------
        PrefSection {
            title: KI18n.i18nc("@title", "Replay gain")

            PrefRow {
                title: KI18n.i18nc("@label:listbox", "Mode")
                description: KI18n.i18nc("@info", "Evens out loudness using volume info stored in music files, so quiet and loud songs play at a similar level. Track: per song. Album: keeps an album's own quiet/loud differences.")
                help: KI18n.i18nc("@info:tooltip", "Adjust volume gain according to <i>replaygain</i> " +
                                  "values stored in the file metadata. If set to album gain, " +
                                  "apply album gain if present and fallback to track gain otherwise.")
                helpWidth: 450

                ComboBox {
                    textRole: "text"
                    valueRole: "value"
                    model: ListModel {
                        id: replayGainModel
                    }
                    Layout.preferredWidth: PrefStyle.fieldWidth
                    Component.onCompleted: {
                        replayGainModel.append({
                            text: KI18n.i18nc("@item:listbox replay gain", "Disabled"),
                            value: "no"
                        })
                        replayGainModel.append({
                            text: KI18n.i18nc("@item:listbox replay gain", "Track"),
                            value: "track"
                        })
                        replayGainModel.append({
                            text: KI18n.i18nc("@item:listbox replay gain", "Album"),
                            value: "album"
                        })
                        currentIndex = indexOfValue(AudioSettings.replayGain)
                    }

                    onActivated: function(index) {
                        AudioSettings.replayGain = model.get(index).value
                        AudioSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@label:spinbox", "Prevent clipping")
                description: KI18n.i18nc("@info", "Lower the gain when it would cause clipping.")

                Switch {
                    checked: AudioSettings.replayGainPreventClip
                    onToggled: {
                        AudioSettings.replayGainPreventClip = checked
                        AudioSettings.save()
                    }
                }
            }

            PrefRow {
                id: preamp

                title: KI18n.i18nc("@label:spinbox", "Preamp (dB)")
                description: KI18n.i18nc("@info", "Extra boost (or cut) added on top of the replay gain adjustment.")

                function setPreamp(val) {
                    AudioSettings.replayGainPreamp = val
                    AudioSettings.save()
                }

                SpinBox {
                    editable: true
                    from: -150
                    to: 150
                    value: AudioSettings.replayGainPreamp
                    onValueModified: preamp.setPreamp(value)
                }

                PrefResetButton {
                    onClicked: preamp.setPreamp(0)
                }
            }

            PrefRow {
                id: fallback

                title: KI18n.i18nc("@label:spinbox", "Fallback (dB)")
                description: KI18n.i18nc("@info", "Volume change for files without replay gain info. Also applied to every file while Mode is Disabled, so leave it at 0 unless you want that.")
                help: KI18n.i18nc("@info:tooltip", "Gain in dB to apply if the file has no replay gain tags.<br><br>" +
                                  "This setting is in effect only when:<br>" +
                                  "- the replaygain setting is disabled<br>" +
                                  "- the replaygain setting is enabled and the file has no replaygain metadata<br>" +
                                  "If this is in effect, other replaygain settings are ignored.")
                helpWidth: 450

                function setFallback(val) {
                    AudioSettings.replayGainFallback = val
                    AudioSettings.save()
                }

                SpinBox {
                    editable: true
                    from: -200
                    to: 60
                    value: AudioSettings.replayGainFallback
                    onValueModified: fallback.setFallback(value)
                }

                PrefResetButton {
                    onClicked: fallback.setFallback(0)
                }
            }
        }

        Item { Layout.preferredHeight: Kirigami.Units.gridUnit }
    }
}
