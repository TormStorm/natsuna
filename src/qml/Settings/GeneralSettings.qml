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

    ColumnLayout {
        spacing: PrefStyle.sectionSpacing

        PrefHeading {
            text: KI18n.i18nc("@title", "General")
        }

        // ------------------------------------
        // Window
        // ------------------------------------
        PrefSection {
            title: KI18n.i18nc("@title", "Window")

            PrefRow {
                title: KI18n.i18nc("@option:check", "Start in fullscreen")
                help: KI18n.i18nc("@info:tooltip", "Enter fullscreen mode when the application starts.<br>" +
                                  "This takes precedence over Resize to fit video, and Remember window size and position settings.")

                Switch {
                    checked: GeneralSettings.fullscreenOnStartUp
                    onToggled: {
                        GeneralSettings.fullscreenOnStartUp = checked
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Remember window size and position")
                enabled: !GeneralSettings.resizeWindowToVideo
                helpIsWarning: SystemUtils.isPlatformWayland()
                help: {
                    const waylandMessage = SystemUtils.isPlatformWayland()
                            ? KI18n.i18nc("@info:tooltip extra wayland info for the “Remember window size and position” setting",
                                          "<b>Restoring position is not supported on Wayland.</b><br><br>")
                            : ""
                    return KI18n.i18nc("@info:tooltip", "Changes to the window’s size and position "
                                       + "are saved and used for newly opened windows.<br><br>"
                                       + "%1The “Resize to fit video” setting takes precedence.", waylandMessage)
                }

                Switch {
                    checked: GeneralSettings.rememberWindowGeometry
                    onToggled: {
                        GeneralSettings.rememberWindowGeometry = checked
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Resize to fit video")
                enabled: !SystemUtils.isPlatformWayland()
                description: SystemUtils.isPlatformWayland()
                             ? KI18n.i18nc("@info", "Not supported on Wayland.")
                             : KI18n.i18nc("@info", "The window is resized to the video’s resolution.")

                Switch {
                    checked: GeneralSettings.resizeWindowToVideo
                    onToggled: {
                        GeneralSettings.resizeWindowToVideo = checked
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Always on top")
                description: KI18n.i18nc("@info", "Keep the player above other windows.")

                Switch {
                    checked: GeneralSettings.alwaysOnTop
                    onToggled: {
                        GeneralSettings.alwaysOnTop = checked
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Allow only one instance")
                description: KI18n.i18nc("@info", "Files opened from elsewhere go to the running player.")

                Switch {
                    checked: GeneralSettings.useSingleInstance
                    onToggled: {
                        GeneralSettings.useSingleInstance = checked
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Add the file to the playlist")
                description: KI18n.i18nc("@info", "Instead of replacing it, add the file to the end of the playlist.")
                indented: true
                enabled: GeneralSettings.useSingleInstance

                Switch {
                    checked: GeneralSettings.appendVideoToSingleInstance
                    onToggled: {
                        GeneralSettings.appendVideoToSingleInstance = checked
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Play the added file")
                indented: true
                enabled: GeneralSettings.useSingleInstance && GeneralSettings.appendVideoToSingleInstance

                Switch {
                    checked: GeneralSettings.playNewFileInSingleInstance
                    onToggled: {
                        GeneralSettings.playNewFileInSingleInstance = checked
                        GeneralSettings.save()
                    }
                }
            }
        }

        // ------------------------------------
        // Interface
        // ------------------------------------
        PrefSection {
            title: KI18n.i18nc("@title", "Interface")

            PrefRow {
                title: KI18n.i18nc("@option:check", "Show menu bar")

                Switch {
                    checked: GeneralSettings.showMenuBar
                    onToggled: {
                        GeneralSettings.showMenuBar = checked
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Show toolbar")

                Switch {
                    checked: GeneralSettings.showHeader
                    onToggled: {
                        GeneralSettings.showHeader = checked
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Auto-hide interface")
                description: KI18n.i18nc("@info", "Hide the menu bar, toolbar and controls when the mouse is still, so only the video shows. Move the mouse over the player to bring them back. Ctrl+H toggles this.")

                Switch {
                    checked: GeneralSettings.autoHideInterface
                    onToggled: {
                        GeneralSettings.autoHideInterface = checked
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@label:listbox", "Top panel position")
                description: KI18n.i18nc("@info", "Where the menu bar and toolbar appear in auto-hide mode.")
                indented: true
                enabled: GeneralSettings.autoHideInterface

                ComboBox {
                    textRole: "text"
                    valueRole: "value"
                    model: ListModel {
                        id: topPanelPositionModel
                    }
                    Layout.preferredWidth: PrefStyle.fieldWidth
                    Component.onCompleted: {
                        topPanelPositionModel.append({
                            text: KI18n.i18nc("@item:listbox auto-hide top panel position", "Centered"),
                            value: "center"
                        })
                        topPanelPositionModel.append({
                            text: KI18n.i18nc("@item:listbox auto-hide top panel position", "Left"),
                            value: "left"
                        })
                        currentIndex = Math.max(0, indexOfValue(GeneralSettings.autoHideTopPanelPosition))
                    }
                    onActivated: function(index) {
                        GeneralSettings.autoHideTopPanelPosition = model.get(index).value
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@label:listbox", "Control bar")
                description: KI18n.i18nc("@info", "“Floating” draws the controls over the video and hides them when the mouse is still.")

                ComboBox {
                    textRole: "text"
                    valueRole: "value"
                    model: ListModel {
                        id: footerStyleModel
                    }
                    Layout.preferredWidth: PrefStyle.fieldWidth
                    Component.onCompleted: {
                        footerStyleModel.append({
                            text: KI18n.i18nc("@item:listbox the footer style", "Below the video"),
                            value: "default"
                        })
                        footerStyleModel.append({
                            text: KI18n.i18nc("@item:listbox the footer style", "Floating"),
                            value: "floating"
                        })
                        currentIndex = indexOfValue(GeneralSettings.footerStyle)
                    }
                    onActivated: function(index) {
                        GeneralSettings.footerStyle = model.get(index).value
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Show chapter markers")
                description: KI18n.i18nc("@info", "Mark chapters on the seek bar.")

                Switch {
                    checked: GeneralSettings.showChapterMarkers
                    onToggled: {
                        GeneralSettings.showChapterMarkers = checked
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Show preview thumbnail")
                description: KI18n.i18nc("@info", "Show a preview while hovering over the seek bar.")

                Switch {
                    checked: GeneralSettings.showPreviewThumbnail
                    onToggled: {
                        GeneralSettings.showPreviewThumbnail = checked
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Use accurate preview")
                description: KI18n.i18nc("@info", "Slower to generate.")
                indented: true
                enabled: GeneralSettings.showPreviewThumbnail

                Switch {
                    checked: GeneralSettings.accuratePreviewThumbnail
                    onToggled: {
                        GeneralSettings.accuratePreviewThumbnail = checked
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@label:spinbox", "Thumbnail width")
                indented: true
                enabled: GeneralSettings.showPreviewThumbnail

                SpinBox {
                    id: previewThumbnailWidth

                    from: 100
                    to: 10000
                    editable: true
                    value: GeneralSettings.previewThumbnailWidth
                    onValueModified: {
                        GeneralSettings.previewThumbnailWidth = previewThumbnailWidth.value
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@label:spinbox", "On-screen message size")
                description: KI18n.i18nc("@info", "Font size of messages shown over the video. Set to 0 to turn them off.")

                SpinBox {
                    id: osdFontSize

                    editable: true
                    from: 0
                    to: 100
                    value: GeneralSettings.osdFontSize
                    onValueModified: {
                        GeneralSettings.osdFontSize = osdFontSize.value
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Show explanatory tooltips")
                help: KI18n.i18nc("@info:tooltip",
                                  "Only affects tooltips that explain how something works or what it does.<br><br>"+
                                  "Tooltips that show extra information will not be disabled " +
                                  "(e.g. the seekbar tooltip showing the time at the mouse position, " +
                                  "tooltips for truncated text).")

                Switch {
                    checked: GeneralSettings.showExplanatoryToolTips
                    onToggled: {
                        GeneralSettings.showExplanatoryToolTips = checked
                        GeneralSettings.save()
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@option:check", "Show progress on taskbar icon")

                Switch {
                    checked: GeneralSettings.showTaskbarProgress
                    onToggled: {
                        GeneralSettings.showTaskbarProgress = checked
                        GeneralSettings.save()
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
                title: KI18n.i18nc("@label:listbox", "Color scheme")

                ComboBox {
                    id: colorThemeSwitcher

                    textRole: "display"
                    model: HarunaApp.colorSchemesModel
                    Layout.preferredWidth: PrefStyle.fieldWidth
                    delegate: ItemDelegate {
                        id: delegate

                        required property var model

                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                        width: parent.width
                        highlighted: delegate.model.display === GeneralSettings.colorScheme
                        contentItem: RowLayout {
                            Kirigami.Icon {
                                source: delegate.model.decoration
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            }
                            Label {
                                text: delegate.model.display
                                color: delegate.highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                Layout.fillWidth: true
                            }
                        }
                    }

                    onActivated: function(index) {
                        GeneralSettings.colorScheme = colorThemeSwitcher.textAt(index)
                        GeneralSettings.save()
                    }

                    Component.onCompleted: {
                        currentIndex = find(GeneralSettings.colorScheme)
                        if (currentIndex === -1) {
                            currentIndex = find("Default")
                        }
                    }
                }
            }

            PrefRow {
                title: KI18n.i18nc("@label:listbox", "Widget style")

                ComboBox {
                    id: guiStyleComboBox

                    textRole: "text"
                    valueRole: "value"
                    model: ListModel {
                        id: stylesModel
                    }
                    Layout.preferredWidth: PrefStyle.fieldWidth

                    onActivated: function(index) {
                        GeneralSettings.guiStyle = model.get(index).value
                        HarunaApp.setGuiStyle(GeneralSettings.guiStyle)
                        // some themes can cause a crash
                        // the timer prevents saving the crashing theme,
                        // which would cause the app to crash on startup
                        saveGuiStyleTimer.start()
                    }

                    Timer {
                        id: saveGuiStyleTimer

                        interval: 1000
                        running: false
                        repeat: false
                        onTriggered: GeneralSettings.save()
                    }

                    Component.onCompleted: {
                        stylesModel.append({
                            text: KI18n.i18nc("@item:listbox default GUI style", "Default"),
                            value: "Default"
                        })

                        const styles = HarunaApp.availableGuiStyles()
                        for (let i = 0; i < styles.length; ++i) {
                            stylesModel.append({ text: styles[i], value: styles[i] })
                        }

                        currentIndex = indexOfValue(GeneralSettings.guiStyle)
                    }
                }
            }
        }

        // ------------------------------------
        // Recent files
        // ------------------------------------
        PrefSection {
            title: KI18n.i18nc("@title", "Recent files")

            PrefRow {
                title: KI18n.i18nc("@label:spinbox", "Maximum recent files")
                description: KI18n.i18nc("@info", "How many files to list under Open Recent Media. Set to 0 to turn it off.")

                SpinBox {
                    id: maxRecentFiles

                    from: 0
                    to: 100
                    editable: true
                    value: GeneralSettings.maxRecentFiles
                    onValueModified: {
                        GeneralSettings.maxRecentFiles = maxRecentFiles.value
                        GeneralSettings.save()
                    }
                }
            }
        }

        Item { Layout.preferredHeight: Kirigami.Units.gridUnit }
    }
}
