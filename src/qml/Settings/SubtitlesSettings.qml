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
import org.kde.haruna.utilities
import org.kde.haruna.settings

SettingsBasePage {
    id: root

    readonly property string trackPriorityHelp: KI18n.i18nc("@info:tooltip",
                                                            "Track selection priority:<br>" +
                                                            "- preferred track id<br>" +
                                                            "- track matching the preferred language<br>" +
                                                            "- default track<br>" +
                                                            "- no track")

    // A color swatch, hex field and reset button bound to one subtitle color setting
    component ColorRow: PrefRow {
        id: colorRow

        property string color
        property string defaultColor
        signal colorEdited(string color)

        ColorPickerButton {
            id: picker

            color: colorRow.color
            onColorChosen: function(color) {
                colorField.text = color
            }
            Layout.preferredHeight: colorField.height
            Layout.preferredWidth: colorField.height
        }

        TextField {
            id: colorField

            text: colorRow.color
            font.family: "monospace"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 7
            onTextChanged: save()

            Connections {
                target: root
                function onSave() {
                    colorField.save()
                }
            }

            function save() : void {
                picker.color = text
                colorRow.colorEdited(text)
            }
        }

        PrefResetButton {
            onClicked: colorField.text = colorRow.defaultColor
        }
    }

    ColumnLayout {
        spacing: PrefStyle.sectionSpacing

        PrefHeading {
            text: KI18n.i18nc("@title", "Subtitles")
        }

        // ------------------------------------
        // Track selection
        // ------------------------------------
        PrefSection {
            title: KI18n.i18nc("@title", "Track selection")

            PrefRow {
                title: KI18n.i18nc("@label:check", "Turn on subtitles automatically")
                description: KI18n.i18nc("@info", "Pick and show a subtitle track when a file starts.")

                Switch {
                    id: autoSelectSubtitles

                    checked: SubtitlesSettings.autoSelectSubtitles
                    onToggled: {
                        SubtitlesSettings.autoSelectSubtitles = checked
                        SubtitlesSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@label:textbox", "Preferred language")
                description: KI18n.i18nc("@info", "Language codes, for example: eng, ger")
                help: root.trackPriorityHelp
                indented: true
                enabled: autoSelectSubtitles.checked

                TextField {
                    id: preferredLanguage

                    text: SubtitlesSettings.preferredLanguage
                    placeholderText: "eng, ger"
                    Layout.preferredWidth: PrefStyle.fieldWidth
                    onEditingFinished: save()

                    Connections {
                        target: root
                        function onSave() {
                            preferredLanguage.save()
                        }
                    }

                    function save() : void {
                        SubtitlesSettings.preferredLanguage = text
                        SubtitlesSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@label:spinbox", "Preferred track")
                help: root.trackPriorityHelp
                indented: true
                enabled: autoSelectSubtitles.checked

                SpinBox {
                    from: 0
                    to: 100
                    editable: true
                    value: SubtitlesSettings.preferredTrack
                    onValueModified: {
                        SubtitlesSettings.preferredTrack = value
                        SubtitlesSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Allow subtitles in black borders")
                description: KI18n.i18nc("@info", "Subtitles may be drawn outside the picture. Might not work for all .ass subtitles.")

                Switch {
                    checked: SubtitlesSettings.allowOnBlackBorders
                    onToggled: {
                        SubtitlesSettings.allowOnBlackBorders = checked
                        SubtitlesSettings.save()
                    }
                }
            }
        }

        // ------------------------------------
        // Appearance
        // ------------------------------------
        PrefSection {
            title: KI18n.i18nc("@title", "Appearance")

            PrefRow {
                title: KI18n.i18nc("@label:listbox", "Font")

                ComboBox {
                    id: subtitleFont

                    property string defaultFamily: "Liberation Sans"

                    model: SystemUtils.getFonts()
                    Layout.preferredWidth: PrefStyle.fieldWidth * 1.4
                    onActivated: function(index) {
                        setFontFamily()
                    }

                    Component.onCompleted: currentIndex = indexOfValue(SubtitlesSettings.fontFamily)

                    function setFontFamily() {
                        SubtitlesSettings.fontFamily = currentText
                        SubtitlesSettings.save()
                    }
                }

                PrefResetButton {
                    onClicked: {
                        subtitleFont.currentIndex = subtitleFont.find(subtitleFont.defaultFamily)
                        subtitleFont.setFontFamily()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@label:spinbox", "Size")

                SpinBox {
                    from: 0
                    to: 1000
                    editable: true
                    value: SubtitlesSettings.fontSize
                    onValueModified: {
                        SubtitlesSettings.fontSize = value
                        SubtitlesSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Bold")

                Switch {
                    checked: SubtitlesSettings.isBold
                    onToggled: {
                        SubtitlesSettings.isBold = checked
                        SubtitlesSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Italic")

                Switch {
                    checked: SubtitlesSettings.isItalic
                    onToggled: {
                        SubtitlesSettings.isItalic = checked
                        SubtitlesSettings.save()
                    }
                }
            }

            ColorRow {
                title: KI18n.i18nc("@label:textbox", "Text color")
                color: SubtitlesSettings.fontColor
                defaultColor: "#FFFFFFFF"
                onColorEdited: function(color) {
                    SubtitlesSettings.fontColor = color
                    SubtitlesSettings.save()
                }
            }
        }

        // ------------------------------------
        // Outline and shadow
        // ------------------------------------
        PrefSection {
            title: KI18n.i18nc("@title", "Outline and shadow")

            PrefRow {
                title: KI18n.i18nc("@label:listbox", "Style")

                ComboBox {
                    textRole: "text"
                    valueRole: "value"
                    model: ListModel {
                        id: borderStyleModel
                    }
                    Layout.preferredWidth: PrefStyle.fieldWidth
                    Component.onCompleted: {
                        borderStyleModel.append({
                            text: KI18n.i18nc("@item:listbox border style", "Outline and Shadow"),
                            value: "outline-and-shadow"
                        })
                        borderStyleModel.append({
                            text: KI18n.i18nc("@item:listbox border style", "Opaque Box"),
                            value: "opaque-box"
                        })
                        borderStyleModel.append({
                            text: KI18n.i18nc("@item:listbox border style", "Background Box"),
                            value: "background-box"
                        })
                        currentIndex = indexOfValue(SubtitlesSettings.borderStyle)
                    }

                    onActivated: function(index) {
                        SubtitlesSettings.borderStyle = model.get(index).value
                        SubtitlesSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@label:spinbox", "Outline width")
                description: KI18n.i18nc("@info", "Set to 0 to turn the outline off.")

                SpinBox {
                    from: 0
                    to: 25
                    editable: true
                    value: SubtitlesSettings.borderSize
                    onValueModified: {
                        SubtitlesSettings.borderSize = value
                        SubtitlesSettings.save()
                    }
                }
            }

            ColorRow {
                title: KI18n.i18nc("@label:textbox", "Outline color")
                color: SubtitlesSettings.borderColor
                defaultColor: "#FF000000"
                onColorEdited: function(color) {
                    SubtitlesSettings.borderColor = color
                    SubtitlesSettings.save()
                }
            }

            PrefRow {
                title: KI18n.i18nc("@label:spinbox", "Shadow offset")
                description: KI18n.i18nc("@info", "With Background Box, the padding around the text. Otherwise the shadow distance; 0 turns the shadow off.")

                SpinBox {
                    from: 0
                    to: 25
                    editable: true
                    value: SubtitlesSettings.shadowOffset
                    onValueModified: {
                        SubtitlesSettings.shadowOffset = value
                        SubtitlesSettings.save()
                    }
                }
            }

            ColorRow {
                title: KI18n.i18nc("@label:textbox", "Shadow color")
                description: KI18n.i18nc("@info", "Also the color of the background box.")
                color: SubtitlesSettings.shadowColor
                defaultColor: "#FF000000"
                onColorEdited: function(color) {
                    SubtitlesSettings.shadowColor = color
                    SubtitlesSettings.save()
                }
            }

            PrefRow {
                id: shadowOpacityRow

                title: KI18n.i18nc("@label:slider", "Shadow opacity")
                description: KI18n.i18nc("@info", "How see-through the shadow or background box is. 0% is invisible, 100% is solid.")

                function setOpacity(value) {
                    SubtitlesSettings.shadowOpacity = value
                    SubtitlesSettings.save()
                }

                Slider {
                    id: shadowOpacitySlider

                    from: 0
                    to: 100
                    stepSize: 5
                    snapMode: Slider.SnapAlways
                    value: SubtitlesSettings.shadowOpacity
                    Layout.preferredWidth: PrefStyle.fieldWidth
                    onMoved: shadowOpacityRow.setOpacity(Math.round(value))
                }

                Label {
                    text: KI18n.i18nc("@label %1 is a percentage", "%1%", Math.round(shadowOpacitySlider.value))
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                }

                PrefResetButton {
                    onClicked: shadowOpacityRow.setOpacity(50)
                }
            }
        }

        // ------------------------------------
        // Subtitle files
        // ------------------------------------
        PrefSection {
            title: KI18n.i18nc("@title", "Subtitle files")

            SubtitlesFolders {
                id: subtitleFolders

                Layout.fillWidth: true
            }
        }

        Item { Layout.preferredHeight: Kirigami.Units.gridUnit }
    }
}
