/*
 * SPDX-FileCopyrightText: 2020 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import org.kde.ki18n
import org.kde.kirigami as Kirigami
import org.kde.config as KConfig

import org.kde.haruna
import org.kde.haruna.playlist
import org.kde.haruna.transcript
import org.kde.haruna.utilities
import org.kde.haruna.settings
import org.kde.haruna.youtube

ApplicationWindow {
    id: appWindow

    property bool containsMouse: false

    property int previousVisibility: Window.Windowed
    property var acceptedSubtitleTypes: ["application/x-subrip", "text/x-ssa", "text/x-microdvd"]

    function initPlaylist() {
        if (!playlist.isReady || !mpv.isReady) {
            return
        }
        playlist.manager.initialize(CommandLineOptions.startupUrls)
        if (CommandLineOptions.startupUrls.length > 0) {
            Models.recentFilesModel.addRecentFile(CommandLineOptions.startupUrls[0], RecentFilesModel.OpenedFrom.ExternalApp)
        }
    }

    objectName: "HarunaMainWindow"

    visible: true
    title: mpv.mediaTitle || KI18n.i18nc("@title:window", "Natsuna")
    width: 1000
    height: 600
    minimumWidth: 400
    minimumHeight: 200
    color: Kirigami.Theme.backgroundColor

    onVisibilityChanged: function(visibility) {
        if (PlaybackSettings.pauseWhileMinimized) {
            if (visibility === Window.Minimized) {
                if (mpv.pause) {
                    mpv.preMinimizePlaybackState = MpvVideo.PlaybackState.Paused
                } else {
                    mpv.preMinimizePlaybackState = MpvVideo.PlaybackState.Playing
                }
                mpv.pause = true
            }
            if (previousVisibility === Window.Minimized
                    && visibility === Window.Windowed | Window.Maximized | Window.FullScreen) {
                if (mpv.preMinimizePlaybackState === MpvVideo.PlaybackState.Playing) {
                    mpv.pause = false
                }
            }
        }

        // used to restore window state, when exiting fullscreen,
        // to the one it had before going fullscreen
        if (visibility !== Window.FullScreen) {
            previousVisibility = visibility
        }
    }

    onClosing: {
        const settingsWindow = settingsLoader.item as Window
        const sortConfigWindow = playlist.advancedSortWindow.item as Kirigami.ApplicationWindow
        settingsWindow?.close()
        sortConfigWindow?.close()
    }

    header: Header {
        id: headerItem

        m_mpv: mpv
        m_menuBarLoader: menuBarLoader
        m_settingsLoader: settingsLoader
    }

    menuBar: MenuBarLoader {
        id: menuBarLoader

        m_mpv: mpv
        m_settingsLoader: settingsLoader
    }

    Connections {
        target: GeneralSettings
        function onOsdFontSizeChanged() {
            osd.message("Test osd font size")
        }
        function onMaxRecentFilesChanged() {
            Models.recentFilesModel.getItems()
        }
        function onResizeWindowToVideoChanged() {
            appWindow.resizeWindow()
        }
        function onColorSchemeChanged() {
            HarunaApp.activateColorScheme(GeneralSettings.colorScheme)
        }
    }
    Connections {
        target: AudioSettings
        function onPreferredTrackChanged() {
            mpv.audioId = AudioSettings.preferredTrack
        }
        function onPreferredLanguageChanged() {
            mpv.setProperty(MpvProperties.AudioLanguage, AudioSettings.preferredLanguage.replace(/\s+/g, ''))
        }
        function onReplayGainChanged() {
            mpv.setProperty(MpvProperties.ReplayGain, AudioSettings.replayGain)
        }
        function onReplayGainPreampChanged() {
            mpv.setProperty(MpvProperties.ReplayGainPreamp, AudioSettings.replayGainPreamp)
        }
        function onReplayGainPreventClipChanged() {
            mpv.setProperty(MpvProperties.ReplayGainClip, !AudioSettings.replayGainPreventClip)
        }
        function onReplayGainFallbackChanged() {
            mpv.setProperty(MpvProperties.ReplayGainFallback, AudioSettings.replayGainFallback)
        }
    }
    Connections {
        target: PlaybackSettings
        function onYtdlFormatChanged() {
            mpv.setProperty(MpvProperties.YtdlFormat, PlaybackSettings.ytdlFormat)
        }
        function onHWDecodingChanged() {
            mpv.setProperty(MpvProperties.HardwareDecoding, PlaybackSettings.hWDecoding)
        }
    }
    Connections {
        target: SubtitlesSettings
        function onAutoSelectSubtitlesChanged() {
            mpv.selectSubtitleTrack()
        }
        function onPreferredLanguageChanged() {
            mpv.setProperty(MpvProperties.SubtitleLanguage, SubtitlesSettings.preferredLanguage.replace(/\s+/g, ''))
        }
        function onPreferredTrackChanged() {
            mpv.subtitleId = SubtitlesSettings.preferredTrack
        }
        function onAllowOnBlackBordersChanged() {
            mpv.setProperty(MpvProperties.SubtitleUseMargins, SubtitlesSettings.allowOnBlackBorders ? "yes" : "no")
            mpv.setProperty(MpvProperties.SubtitleAssForceMargins, SubtitlesSettings.allowOnBlackBorders ? "yes" : "no")
        }
        function onFontFamilyChanged() {
            mpv.setProperty(MpvProperties.SubtitleFont, SubtitlesSettings.fontFamily)
        }
        function onFontSizeChanged() {
            appWindow.applySubtitleFontSize()
        }
        function onIsBoldChanged() {
            mpv.setProperty(MpvProperties.SubtitleBold, SubtitlesSettings.isBold)
        }
        function onIsItalicChanged() {
            mpv.setProperty(MpvProperties.SubtitleItalic, SubtitlesSettings.isItalic)
        }
        function onFontColorChanged() {
            mpv.setProperty(MpvProperties.SubtitleColor, SubtitlesSettings.fontColor)
        }
        function onShadowColorChanged() {
            appWindow.applySubtitleShadowColor()
        }
        function onShadowOpacityChanged() {
            appWindow.applySubtitleShadowColor()
        }
        function onShadowOffsetChanged() {
            mpv.setProperty(MpvProperties.SubtitleShadowOffset, SubtitlesSettings.shadowOffset)
        }
        function onBorderColorChanged() {
            mpv.setProperty(MpvProperties.SubtitleBorderColor, SubtitlesSettings.borderColor)
        }
        function onBorderSizeChanged() {
            mpv.setProperty(MpvProperties.SubtitleBorderSize, SubtitlesSettings.borderSize)
        }
        function onBorderStyleChanged() {
            mpv.setProperty(MpvProperties.SubtitleBorderStyle, SubtitlesSettings.borderStyle)
        }
    }
    Connections {
        target: VideoSettings
        function onScreenshotTemplateChanged() {
            mpv.setProperty(MpvProperties.ScreenshotTemplate, VideoSettings.screenshotTemplate)
        }
        function onScreenshotFormatChanged() {
            mpv.setProperty(MpvProperties.ScreenshotFormat, VideoSettings.screenshotFormat)
        }
    }

    Loader {
        active: false
        sourceComponent: KConfig.WindowStateSaver {
            configGroupName: "MainWindow"
        }
        Component.onCompleted: active = GeneralSettings.rememberWindowGeometry
    }

    MprisItem {
        mpvItem: mpv
        window: appWindow
        activePlaylist: playlist.manager.activePlaylist

        onRaise: { HarunaApp.raiseWindow() }
        onOpenUri: function(uri) {
            appWindow.openFile(uri, RecentFilesModel.OpenedFrom.ExternalApp)
        }
    }

    MpvVideo {
        id: mpv

        playlistsManager: playlist.manager

        // Natsuna: in auto-hide mode the window has no title bar, so the
        // video itself can be dragged to move the window
        DragHandler {
            target: null
            enabled: appWindow.natsunaFrameless
            acceptedButtons: Qt.LeftButton
            onActiveChanged: {
                if (active) {
                    appWindow.startSystemMove()
                }
            }
        }

        width: appWindow.contentItem.width
        height: appWindow.isFullScreen()
                ? appWindow.contentItem.height
                : appWindow.contentItem.height - (footerItem.isFloating ? 0 : footerItem.height)
        anchors.left: playlist.edge === Qt.LeftEdge
                      ? PlaylistSettings.overlayVideo ? appWindow.contentItem.left : playlist.right
                      : transcript.right
        anchors.right: playlist.edge === Qt.RightEdge
                       ? PlaylistSettings.overlayVideo ? appWindow.contentItem.right : playlist.left
                       : transcript.left
        anchors.top: appWindow.contentItem.top

        onFilesDropped: function(urls: list<url>, mode: int) {
            playlist.manager.defaultPlaylist.addFilesAndFolders(urls, mode)
            if (mode === PlaylistModel.Behavior.Clear) {
                Models.recentFilesModel.addRecentFile(playlist.manager.activeItemPath(), RecentFilesModel.OpenedFrom.Playlist)
            }
        }

        onVideoReconfig: {
            appWindow.resizeWindow()
        }

        onEofPlayNext: {
            Models.recentFilesModel.addRecentFile(playlist.manager.activeItemPath(), RecentFilesModel.OpenedFrom.Playlist)
        }

        onOsdMessage: function(text) {
            osd.message(text);
        }

        onMediaTitleMessage: function(text) {
            osd.titleMessage(text)
        }

        onIsReadyChanged: {
            osd.active = true
            appWindow.initPlaylist()
        }

        Osd {
            id: osd

            anchors.fill: parent
            maxWidth: mpv.width
        }
    }

    // extra space outside the playlist so that the playlist is not closed
    // when the mouse leaves it by mistake (dragging items, resizing the playlist)
    Item {
        // when window width is very small, there is only 50 pixels not covered by the playlist
        // in that case the extra space is reduced to 30 to allow the playlist to be closed with the mouse
        width: playlist.width >= Window.window.width - 70 ? 30 : 50
        height: playlist.height
        anchors.right: PlaylistSettings.position === "right" ? playlist.left : undefined
        anchors.left: PlaylistSettings.position === "left" ? playlist.right : undefined
        visible: playlist.visible
        HoverHandler {}
    }

    Transcript {
        id: transcript

        m_mpv: mpv
        height: mpv.height
        mainWindowWidth: appWindow.width
        fsScale: appWindow.isFullScreen() && PlaylistSettings.bigFontFullscreen ? 1.36 : 1

        Connections {
            target: actions
            function onToggleTranscript() {
                transcript.toggle()
            }
        }

        Connections {
            target: mpv
            function onPositionChanged() {
                transcript.updateCurrentEndTimes(mpv.position)
            }
        }
    }

    Playlist {
        id: playlist

        property bool isReady: false

        m_mpv: mpv
        height: mpv.height
        mainWindowWidth: appWindow.width
        fsScale: appWindow.isFullScreen() && PlaylistSettings.bigFontFullscreen ? 1.36 : 1

        Component.onCompleted: {
            isReady = true
            appWindow.initPlaylist()
        }

        Connections {
            target: actions
            function onTogglePlaylist() {
                if (playlist.state === "visible") {
                    playlist.state = "hidden"
                } else {
                    playlist.state = "visible"
                }
            }
        }

        Connections {
            target: HarunaApp
            function onQmlApplicationMouseLeave() {
                if (PlaylistSettings.canToggleWithMouse && (appWindow.isFullScreen() || appWindow.isMaximized())) {
                    playlist.state = "hidden"
                }
            }
        }

        Connections {
            target: mpv
            function onOpenPlaylist() {
                playlist.state = "visible"
            }
            function onClosePlaylist() {
                playlist.state = "hidden"
            }
        }
    }

    Footer {
        id: footerItem

        anchors.bottom: appWindow.contentItem.bottom

        m_mpv: mpv
        playlistsManager: playlist.manager
        m_menuBarLoader: menuBarLoader
        m_header: headerItem
        m_settingsLoader: settingsLoader
    }

    // Natsuna: auto-hide mode (View menu). The menu bar and toolbar are drawn
    // over the top of the video and fade in and out together with the floating
    // control bar, so the video can use the whole window.
    Item {
        id: autoHideTopBar

        readonly property bool active: GeneralSettings.autoHideInterface && !appWindow.isFullScreen()
                                       && (GeneralSettings.showMenuBar || GeneralSettings.showHeader)
        readonly property bool busy: topBarHover.hovered || overlayMenuBar.anyMenuOpen

        // the panel hugs its contents, with even padding on every side
        readonly property real sidePadding: Kirigami.Units.largeSpacing
        readonly property real verticalPadding: Kirigami.Units.smallSpacing
        readonly property real edgeMargin: Kirigami.Units.largeSpacing
        readonly property real contentWidth: Math.max(overlayMenuBar.visible ? overlayMenuBar.implicitWidth : 0,
                                                     overlayHeader.visible ? overlayHeader.implicitWidth : 0)

        anchors.top: appWindow.contentItem.top
        // centred by default, or near the left edge like the normal menu bar
        x: GeneralSettings.autoHideTopPanelPosition === "left"
           ? edgeMargin
           : (appWindow.contentItem.width - width) / 2
        width: Math.min(contentWidth + sidePadding * 2, appWindow.contentItem.width - edgeMargin * 2)
        height: topBarColumn.implicitHeight + verticalPadding * 2
        visible: active && opacity > 0
        opacity: active && footerItem.controlsShown ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        // a floating panel matching the bottom control bar: translucent, with
        // rounded corners where it meets the video
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.85)
            radius: Kirigami.Units.cornerRadius
            topLeftRadius: 0
            topRightRadius: 0
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
        }

        HoverHandler {
            id: topBarHover
        }

        // drag the panel (menu bar or toolbar) to move the window, like a title bar
        DragHandler {
            target: null
            acceptedButtons: Qt.LeftButton
            onActiveChanged: {
                if (active) {
                    appWindow.startSystemMove()
                }
            }
        }

        Column {
            id: topBarColumn

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: autoHideTopBar.sidePadding
                rightMargin: autoHideTopBar.sidePadding
                topMargin: autoHideTopBar.verticalPadding
            }

            MenuBar {
                id: overlayMenuBar

                readonly property bool anyMenuOpen: overlayMediaMenu.visible || overlayPlaybackMenu.visible
                                                    || overlayAudioMenu.visible || overlayVideoMenu.visible
                                                    || overlaySubtitleMenu.visible || overlayToolsMenu.visible
                                                    || overlayViewMenu.visible || overlayHelpMenu.visible

                width: parent.width
                visible: GeneralSettings.showMenuBar
                hoverEnabled: true
                background: Item {}

                NatsunaMediaMenu { id: overlayMediaMenu }
                NatsunaPlaybackMenu { id: overlayPlaybackMenu; m_mpv: mpv }
                NatsunaAudioMenu { id: overlayAudioMenu; m_mpv: mpv }
                NatsunaVideoMenu { id: overlayVideoMenu }
                NatsunaSubtitleMenu { id: overlaySubtitleMenu; m_mpv: mpv }
                NatsunaToolsMenu { id: overlayToolsMenu; m_settingsLoader: settingsLoader }
                NatsunaViewMenu { id: overlayViewMenu }
                NatsunaHelpMenu { id: overlayHelpMenu }
            }

            Header {
                id: overlayHeader

                width: parent.width
                inOverlay: true
                background: Item {}
                m_mpv: mpv
                m_menuBarLoader: menuBarLoader
                m_settingsLoader: settingsLoader
            }
        }
    }

    // Natsuna: subtitle size. mpv grows subtitles in direct proportion to the
    // video's height, which makes them too big in fullscreen on large screens.
    // The configured size applies at a 720 px tall picture; above that the text
    // grows more gently, below it shrinks more gently so it stays readable.
    function applySubtitleFontSize() : void {
        const base = SubtitlesSettings.fontSize
        const dims = mpv.getProperty("osd-dimensions")
        const videoHeight = dims ? dims.h - dims.mt - dims.mb : 0
        let size = base
        if (videoHeight > 0) {
            const factor = Math.min(1.6, Math.max(0.5, Math.pow(720 / videoHeight, 0.35)))
            size = Math.round(base * factor)
        }
        mpv.setProperty(MpvProperties.SubtitleFontSize, size)
    }

    Timer {
        id: subtitleSizeTimer

        // wait for mpv to settle on the new picture size before measuring it
        interval: 150
        onTriggered: appWindow.applySubtitleFontSize()
    }

    Connections {
        target: mpv
        function onWidthChanged() { subtitleSizeTimer.restart() }
        function onHeightChanged() { subtitleSizeTimer.restart() }
        function onVideoWidthChanged() { subtitleSizeTimer.restart() }
        function onVideoHeightChanged() { subtitleSizeTimer.restart() }
        function onVideoReconfig() { subtitleSizeTimer.restart() }
    }

    // Natsuna: clicking another window doesn't reach Qt's popups, so menus
    // used to stay open (and keep the auto-hide controls up). Close them all
    // as soon as another application becomes active.
    function closeAllMenus() : void {
        for (const bar of [menuBarLoader.item, overlayMenuBar]) {
            const menus = bar?.menus
            if (!menus) {
                continue
            }
            for (let i = 0; i < menus.length; ++i) {
                menus[i].dismiss()
            }
        }
        headerItem.closeMenus()
        overlayHeader.closeMenus()
        footerItem.closeMenus()
        mpvContextMenuLoader.close()
    }

    Connections {
        target: Qt.application
        function onStateChanged() {
            if (Qt.application.state !== Qt.ApplicationActive) {
                appWindow.closeAllMenus()
            }
        }
    }

    // Natsuna: shadow / background box color with the opacity setting applied,
    // as mpv's #AARRGGBB
    function applySubtitleShadowColor() : void {
        const c = Qt.color(SubtitlesSettings.shadowColor)
        const hex = v => Math.round(v * 255).toString(16).padStart(2, "0")
        const alpha = Math.max(0, Math.min(100, SubtitlesSettings.shadowOpacity)) / 100
        mpv.setProperty(MpvProperties.SubtitleShadowColor, `#${hex(alpha)}${hex(c.r)}${hex(c.g)}${hex(c.b)}`)
    }

    // Natsuna: no title bar and frame while auto-hide mode is on (windowed)
    readonly property bool natsunaFrameless: GeneralSettings.autoHideInterface
                                             && appWindow.visibility !== Window.FullScreen

    function applyNatsunaFrame() : void {
        // KWin's "No Titlebar and Frame" (applies immediately), or Qt's
        // frameless hint on other desktops
        NatsunaWindowUtils.setFrameless(appWindow, appWindow.natsunaFrameless)
    }

    Timer {
        // at startup the window must be on screen before KWin can change it
        interval: 500
        running: appWindow.natsunaFrameless
        onTriggered: appWindow.applyNatsunaFrame()
    }

    onNatsunaFramelessChanged: applyNatsunaFrame()

    // Without a frame the window manager offers no resize borders, so provide
    // invisible grab zones along the edges and corners
    component ResizeZone: MouseArea {
        property int edges: 0

        z: 1000
        enabled: appWindow.natsunaFrameless
        visible: enabled
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: {
            const h = (edges & Qt.LeftEdge) || (edges & Qt.RightEdge)
            const v = (edges & Qt.TopEdge) || (edges & Qt.BottomEdge)
            if (h && v) {
                const tlbr = (edges === (Qt.TopEdge | Qt.LeftEdge)) || (edges === (Qt.BottomEdge | Qt.RightEdge))
                return tlbr ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
            }
            return h ? Qt.SizeHorCursor : Qt.SizeVerCursor
        }
        onPressed: appWindow.startSystemResize(edges)
    }

    readonly property int natsunaResizeMargin: Kirigami.Units.smallSpacing * 1.5

    ResizeZone {
        edges: Qt.LeftEdge
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: appWindow.natsunaResizeMargin
    }
    ResizeZone {
        edges: Qt.RightEdge
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: appWindow.natsunaResizeMargin
    }
    ResizeZone {
        edges: Qt.TopEdge
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: appWindow.natsunaResizeMargin
    }
    ResizeZone {
        edges: Qt.BottomEdge
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: appWindow.natsunaResizeMargin
    }
    ResizeZone {
        edges: Qt.TopEdge | Qt.LeftEdge
        anchors { top: parent.top; left: parent.left }
        width: appWindow.natsunaResizeMargin * 3
        height: appWindow.natsunaResizeMargin * 3
    }
    ResizeZone {
        edges: Qt.TopEdge | Qt.RightEdge
        anchors { top: parent.top; right: parent.right }
        width: appWindow.natsunaResizeMargin * 3
        height: appWindow.natsunaResizeMargin * 3
    }
    ResizeZone {
        edges: Qt.BottomEdge | Qt.LeftEdge
        anchors { bottom: parent.bottom; left: parent.left }
        width: appWindow.natsunaResizeMargin * 3
        height: appWindow.natsunaResizeMargin * 3
    }
    ResizeZone {
        edges: Qt.BottomEdge | Qt.RightEdge
        anchors { bottom: parent.bottom; right: parent.right }
        width: appWindow.natsunaResizeMargin * 3
        height: appWindow.natsunaResizeMargin * 3
    }

    Binding {
        target: footerItem
        property: "holdVisible"
        value: autoHideTopBar.active && autoHideTopBar.busy
    }

    // Natsuna: Always on Top (View menu)
    Connections {
        target: GeneralSettings
        function onAlwaysOnTopChanged() {
            NatsunaWindowUtils.setKeepAbove(appWindow, GeneralSettings.alwaysOnTop)
        }
    }
    Timer {
        // the window must be on screen before the window manager can keep it above
        interval: 500
        running: GeneralSettings.alwaysOnTop
        onTriggered: NatsunaWindowUtils.setKeepAbove(appWindow, true)
    }

    Actions {
        id: actions

        m_mpv: mpv
        playlistsManager: playlist.manager
        m_mpvContextMenuLoader: mpvContextMenuLoader
        m_osd: osd
        m_footer: footerItem
        m_settingsLoader: settingsLoader
        m_openUrlPopup: openUrlPopup

        onOpenFileDialog: fileDialog.open()
        onOpenSubtitleDialog: subtitlesFileDialog.open()
    }

    Component {
        id: messageBoxComponent

        Kirigami.InlineMessage {
            id: messageBox

            width: Math.min(Kirigami.Units.gridUnit * 50, appWindow.width * 0.8)
            anchors.centerIn: parent

            type: Kirigami.MessageType.Error
            showCloseButton: true

            onVisibleChanged: {
                if (!visible) {
                    destroy()
                }
            }
        }
    }

    Connections {
        id: miscUtilsOnErrorConnection
        target: MiscUtils
        function onError(message) {
            const item = messageBoxComponent.createObject(appWindow)
            const messageBox = item as Kirigami.InlineMessage

            messageBox.visible = true
            messageBox.text = message
        }
    }

    MpvContextMenu {
        id: mpvContextMenuLoader

        m_mpv: mpv
    }

    SettingsWindow {
        id: settingsLoader

        m_mpv: mpv
    }

    Connections {
        target: HarunaApp
        function onQmlApplicationMouseLeave() {
            appWindow.containsMouse = false
        }
        function onQmlApplicationMouseEnter() {
            appWindow.containsMouse = true
        }
        function onOpenUrl(url) {
            if (GeneralSettings.appendVideoToSingleInstance) {
                let behavior = GeneralSettings.playNewFileInSingleInstance
                    ? PlaylistModel.AppendAndPlay
                    : PlaylistModel.Append

                playlist.manager.defaultPlaylist.addItem(url.toString(), behavior)
                return
            }

            appWindow.openFile(url, RecentFilesModel.OpenedFrom.ExternalApp)
        }
        function onOpenRecentFile(url) {
            appWindow.openFile(url, RecentFilesModel.OpenedFrom.Other)
        }
    }

    FileDialog {
        id: fileDialog

        title: KI18n.i18nc("@title:window", "Select File")
        currentFolder: GeneralSettings.fileDialogLastLocation
        fileMode: FileDialog.OpenFile

        onAccepted: {
            appWindow.openFile(fileDialog.selectedFile, RecentFilesModel.OpenedFrom.OpenAction)
            mpv.focus = true

            GeneralSettings.fileDialogLastLocation = PathUtils.parentUrl(fileDialog.selectedFile)
            GeneralSettings.save()
        }
        onRejected: mpv.focus = true
        onVisibleChanged: {
            HarunaApp.actionsEnabled = !visible
        }
    }

    FileDialog {
        id: subtitlesFileDialog

        title: KI18n.i18nc("@title:window", "Select Subtitles File")
        currentFolder: PathUtils.parentUrl(mpv.currentUrl)
        fileMode: FileDialog.OpenFile
        nameFilters: ["Subtitles (*.srt *.ssa *.ass *.sub)"]

        onAccepted: {
            if (appWindow.acceptedSubtitleTypes.includes(MiscUtils.mimeType(subtitlesFileDialog.selectedFile))) {
                mpv.addSubtitles(subtitlesFileDialog.selectedFile)
            }
        }
        onRejected: mpv.focus = true
        onVisibleChanged: {
            HarunaApp.actionsEnabled = !visible
        }
    }

    YouTube {
        id: youtube
    }

    InputPopup {
        id: openUrlPopup

        x: 10
        y: 10
        width: Math.min(appWindow.width * 0.9, 600)
        lastText: GeneralSettings.lastUrl
        buttonText: KI18n.i18nc("@action:button", "Open")
        warningText: youtube.hasYoutubeDl()
                     ? ""
                     : KI18n.i18nc("@info", "Neither <a href=\"https://github.com/yt-dlp/yt-dlp\">yt-dlp</a> nor <a href=\"https://github.com/ytdl-org/youtube-dl\">youtube-dl</a> was found.")

        onSubmitted: function(url) {
            appWindow.openFile(youtube.normalizeUrl(url), RecentFilesModel.OpenedFrom.OpenAction)

            GeneralSettings.lastUrl = url
            GeneralSettings.save()
        }
    }

    Component.onCompleted: {
        applyNatsunaFrame() // Natsuna: auto-hide mode removes the frame
        HarunaApp.setupEventFilter(appWindow)
        HarunaApp.activateColorScheme(GeneralSettings.colorScheme)

        const hasCommandLineFile = HarunaApp.url(0).toString() !== ""
        const hasLastPlayedFile = GeneralSettings.lastPlayedFile !== ""
        const hasFileToOpen = hasCommandLineFile || (PlaybackSettings.openLastPlayedFile && hasLastPlayedFile)
        if (GeneralSettings.fullscreenOnStartUp && hasFileToOpen) {
            toggleFullScreen()
        }
    }

    function openFile(path: string, openedFrom: int) : void {
        mpv.stop()
        Models.recentFilesModel.addRecentFile(path, openedFrom)
        playlist.manager.defaultPlaylist.addItem(path, PlaylistModel.Clear)
    }

    function isFullScreen() : bool {
        return appWindow.visibility === Window.FullScreen
    }

    function isMaximized() : bool {
        return appWindow.visibility === Window.Maximized
    }

    function toggleFullScreen() : void {
        if (!isFullScreen()) {
            appWindow.showFullScreen()
        } else {
            exitFullscreen()
        }
    }

    function exitFullscreen() : void {
        if (appWindow.previousVisibility === Window.Maximized) {
            appWindow.show()
            appWindow.showMaximized()
        } else {
            appWindow.showNormal()
        }
    }

    function resizeWindow() : void {
        if (SystemUtils.isPlatformWayland() || !GeneralSettings.resizeWindowToVideo || isFullScreen()) {
            return
        }

        appWindow.width = mpv.videoWidth
        appWindow.height = mpv.videoHeight
                + (footerItem.isFloating ? 0 : footerItem.height)
                + (headerItem.visible ? headerItem.height : 0)
                + (menuBar.visible ? menuBar.height : 0)
    }
}
