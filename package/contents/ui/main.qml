import QtQuick
import QtQml
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import org.kde.pipewire as PipeWire

PlasmoidItem {
    id: root

    property bool overlayVisible: true

    // --- Safety guards: a runaway must cost a few requests, not freeze the shell ---
    // Overlays are hidden (and nothing streams) above this many windows on one screen.
    readonly property int maxTiles: 12
    // Global screencast request budget, refilled once per second.
    readonly property int requestsPerSecond: 15
    // Circuit breaker: more than this many requests in 10s disables streaming
    // until the user toggles the overlay again.
    readonly property int breakerLimit: 150
    property int budget: requestsPerSecond
    property int recentRequests: 0
    property bool tripped: false

    function takeToken() {
        if (tripped || budget <= 0)
            return false
        budget--
        recentRequests++
        if (recentRequests > breakerLimit) {
            tripped = true
            console.warn("windowoverlay: too many screencast requests, streaming disabled; click the icon to re-enable")
            return false
        }
        return true
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.overlayVisible && !root.tripped
        onTriggered: root.budget = root.requestsPerSecond
    }
    Timer {
        interval: 10000
        repeat: true
        running: root.overlayVisible && !root.tripped
        onTriggered: root.recentRequests = 0
    }
    // All of these come from the widget's Configure dialog (config/main.xml)
    readonly property int thumbW: Plasmoid.configuration.thumbWidth
    readonly property int thumbH: Math.round(thumbW * 9 / 16)
    readonly property int edgeMargin: Plasmoid.configuration.edgeMargin
    readonly property real topFraction: Plasmoid.configuration.topPercent / 100
    readonly property int verticalMargin: Plasmoid.configuration.bottomMargin
    readonly property real thumbOpacity: Plasmoid.configuration.thumbOpacity / 100
    readonly property real backdropOpacity: Plasmoid.configuration.backdropOpacity / 100
    readonly property bool onLeft: Plasmoid.configuration.side === 1

    preferredRepresentation: fullRepresentation
    toolTipMainText: "Window Overlay"
    toolTipSubText: overlayVisible ? "Click to hide overlays" : "Click to show overlays"

    // Panel button. Single-item widgets declare it as the full representation (like World Clock)
    fullRepresentation: MouseArea {
        id: ma
        hoverEnabled: true
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
        onClicked: {
            root.overlayVisible = !root.overlayVisible
            // Toggling re-arms the circuit breaker
            root.tripped = false
            root.recentRequests = 0
            root.budget = root.requestsPerSecond
        }
        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: ma.containsMouse
            opacity: root.overlayVisible ? 1.0 : 0.5
        }
    }

    // One overlay per physical screen
    Instantiator {
        model: Qt.application.screens

        delegate: PlasmaCore.Dialog {
            id: dlg
            required property var modelData
            readonly property var scr: modelData

            // Debounced window count: while the model is still filling in at startup the raw
            // count climbs 0 -> 1 -> 2, and showing/hiding the dialog on each step churns
            // native windows. Only act once the count has been stable for a moment.
            property int stableCount: 0
            visible: root.overlayVisible && stableCount > 1
                     && stableCount <= root.maxTiles
            location: PlasmaCore.Types.Floating
            type: PlasmaCore.Dialog.Normal
            backgroundHints: PlasmaCore.Types.NoBackground
            flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
                 | Qt.WindowDoesNotAcceptFocus | Qt.Tool
            hideOnWindowDeactivate: false

            // Shrink thumbnails when too many windows to fit the screen height
            readonly property int labelH: 20
            readonly property int gap: 8
            readonly property real fit: {
                const n = Math.max(1, winRepeater.count)
                const avail = scr.height * (1 - root.topFraction) - root.verticalMargin
                              - 16 - gap * (n - 1) - labelH * n
                return Math.max(0.35, Math.min(1.0, avail / (n * root.thumbH)))
            }
            readonly property int tw: Math.round(root.thumbW * fit)
            readonly property int th: Math.round(root.thumbH * fit)

            // Right edge of the screen, top fixed at topFraction of the screen height. The
            // column grows downward; x uses the content's wanted size so it stays on the edge.
            x: root.onLeft
               ? scr.virtualX + root.edgeMargin
               : scr.virtualX + scr.width - panel.implicitWidth - root.edgeMargin
            y: scr.virtualY + Math.round(scr.height * root.topFraction)

            mainItem: Rectangle {
                id: panel
                color: Qt.rgba(0, 0, 0, root.backdropOpacity)
                radius: 10
                implicitWidth: row.implicitWidth + 16
                implicitHeight: row.implicitHeight + 16
                // Explicit size so the Dialog window follows content changes
                width: implicitWidth
                height: implicitHeight

                Timer {
                    id: settle
                    interval: 600
                    onTriggered: dlg.stableCount = winRepeater.count
                }
                Connections {
                    target: winRepeater
                    function onCountChanged() { settle.restart() }
                }
                // The model may already be populated before the first countChanged
                Component.onCompleted: settle.restart()

                TaskManager.TasksModel {
                    id: tasksModel
                    screenGeometry: Qt.rect(dlg.scr.virtualX, dlg.scr.virtualY,
                                            dlg.scr.width, dlg.scr.height)
                    filterByScreen: true
                    filterByVirtualDesktop: true
                    filterByActivity: true
                    filterMinimized: false
                    groupMode: TaskManager.TasksModel.GroupDisabled
                }

                Grid {
                    id: row
                    anchors.centerIn: parent
                    spacing: dlg.gap
                    columns: 1

                    Repeater {
                        id: winRepeater
                        model: tasksModel

                        delegate: Item {
                            id: cell
                            required property int index
                            required property string display
                            required property var decoration
                            required property var model
                            readonly property var winIds: model.WinIdList
                            readonly property bool isActive: model.IsActive

                            width: dlg.tw
                            height: dlg.th + dlg.labelH

                            readonly property string wantedUuid:
                                winIds && winIds.length > 0 ? String(winIds[0]) : ""
                            // Only stream while this screen's overlay is actually shown;
                            // hidden tiles must not hammer the compositor with requests.
                            readonly property bool live: dlg.visible && !root.tripped && wantedUuid !== ""
                            property int retries: 0

                            TaskManager.ScreencastingRequest {
                                id: sc
                            }

                            function restart() {
                                retries = 0
                                // Out of budget: leave idle; the retry timer picks it up
                                sc.uuid = (live && root.takeToken()) ? wantedUuid : ""
                            }
                            onLiveChanged: restart()
                            onWantedUuidChanged: restart()
                            Component.onCompleted: restart()

                            // A brand-new window often isn't streamable yet, so the first
                            // request yields no node or no frames. Re-issue until it works.
                            Timer {
                                interval: 500
                                repeat: true
                                running: cell.live
                                         && (sc.nodeId === 0 || !pw.ready)
                                         && cell.retries < 30
                                onTriggered: {
                                    if (!root.takeToken())
                                        return   // throttled: don't burn a retry
                                    cell.retries++
                                    var u = cell.wantedUuid
                                    sc.uuid = ""
                                    sc.uuid = u
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: "transparent"
                                border.width: cell.isActive ? 2 : 1
                                border.color: cell.isActive
                                    ? Kirigami.Theme.highlightColor
                                    : Qt.rgba(1, 1, 1, 0.25)
                            }

                            PipeWire.PipeWireSourceItem {
                                id: pw
                                x: 3; y: 3
                                width: dlg.tw - 6
                                height: dlg.th - 6
                                nodeId: sc.nodeId
                                visible: nodeId > 0
                                opacity: root.thumbOpacity
                            }

                            Row {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 3
                                spacing: 4
                                Kirigami.Icon {
                                    source: cell.decoration
                                    width: 16; height: 16
                                }
                                Text {
                                    width: parent.width - 20
                                    text: cell.display
                                    color: "white"
                                    elide: Text.ElideRight
                                    font.pixelSize: 11
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: tasksModel.requestActivate(
                                    tasksModel.index(cell.index, 0))
                            }
                        }
                    }
                }
            }
        }
    }
}
