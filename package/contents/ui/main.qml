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
    // All of these come from the widget's Configure dialog (config/main.xml)
    readonly property int thumbW: Plasmoid.configuration.thumbWidth
    readonly property int thumbH: Math.round(thumbW * 9 / 16)
    readonly property int edgeMargin: Plasmoid.configuration.edgeMargin
    readonly property real topFraction: Plasmoid.configuration.topPercent / 100
    readonly property int verticalMargin: Plasmoid.configuration.bottomMargin
    readonly property real thumbOpacity: Plasmoid.configuration.thumbOpacity / 100
    readonly property real backdropOpacity: Plasmoid.configuration.backdropOpacity / 100
    readonly property bool onLeft: Plasmoid.configuration.side === 1

    preferredRepresentation: compactRepresentation
    toolTipMainText: "Window Overlay"
    toolTipSubText: overlayVisible ? "Click to hide overlays" : "Click to show overlays"

    compactRepresentation: Kirigami.Icon {
        source: "view-list-icons"
        active: ma.containsMouse
        opacity: root.overlayVisible ? 1.0 : 0.5
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.overlayVisible = !root.overlayVisible
        }
    }

    // One overlay per physical screen
    Instantiator {
        model: Qt.application.screens

        delegate: PlasmaCore.Dialog {
            id: dlg
            required property var modelData
            readonly property var scr: modelData

            visible: root.overlayVisible && winRepeater.count > 0
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
                            property int retries: 0

                            TaskManager.ScreencastingRequest {
                                id: sc
                                Component.onCompleted: uuid = cell.wantedUuid
                            }

                            // Window changed under this tile: start over
                            onWantedUuidChanged: {
                                retries = 0
                                sc.uuid = wantedUuid
                            }

                            // A brand-new window often isn't streamable yet, so the first
                            // request yields no node or no frames. Re-issue until it works.
                            Timer {
                                interval: 500
                                repeat: true
                                running: cell.wantedUuid !== ""
                                         && (sc.nodeId === 0 || !pw.ready)
                                         && cell.retries < 30
                                onTriggered: {
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
