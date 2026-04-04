import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    // Helper function to format KB to GB
    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Column {
            width: 145
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "memory"
                label: "RAM"
            }
            Column {
                width: parent.width
                spacing: 4
                StyledPopupValueRow {
                    width: parent.width
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatKB(ResourceUsage.memoryUsed)
                }
                StyledPopupValueRow {
                    width: parent.width
                    icon: "check_circle"
                    label: Translation.tr("Free:")
                    value: root.formatKB(ResourceUsage.memoryFree)
                }
                StyledPopupValueRow {
                    width: parent.width
                    icon: "empty_dashboard"
                    label: Translation.tr("Total:")
                    value: root.formatKB(ResourceUsage.memoryTotal)
                }
            }
        }

        Column {
            width: 145
            visible: ResourceUsage.swapTotal > 0
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "swap_horiz"
                label: "Swap"
            }
            Column {
                width: parent.width
                spacing: 4
                StyledPopupValueRow {
                    width: parent.width
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatKB(ResourceUsage.swapUsed)
                }
                StyledPopupValueRow {
                    width: parent.width
                    icon: "check_circle"
                    label: Translation.tr("Free:")
                    value: root.formatKB(ResourceUsage.swapFree)
                }
                StyledPopupValueRow {
                    width: parent.width
                    icon: "empty_dashboard"
                    label: Translation.tr("Total:")
                    value: root.formatKB(ResourceUsage.swapTotal)
                }
            }
        }

        Column {
            width: 130
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "planner_review"
                label: "CPU"
            }
            Column {
                width: parent.width
                spacing: 4
                StyledPopupValueRow {
                    width: parent.width
                    icon: "bolt"
                    label: Translation.tr("Load:")
                    value: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
                }
            }
            Column {
                spacing: 0
                Repeater {
                    model: ResourceUsage.perCoreCpuUsage
                    Rectangle {
                        required property real modelData
                        width: 120
                        height: 2
                        color: Appearance.m3colors.m3outlineVariant
                        Rectangle {
                            width: parent.modelData * parent.width
                            height: parent.height
                            color: Appearance.colors.colPrimary
                        }
                    }
                }
            }
        }

        Column {
            width: 160
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "storage"
                label: Translation.tr("Disk")
            }
            Column {
                width: parent.width
                spacing: 4
                StyledPopupValueRow {
                    width: parent.width
                    icon: "arrow_downward"
                    label: Translation.tr("Read:")
                    value: ResourceUsage.formatNetworkRate(ResourceUsage.diskReadRate)
                }
                StyledPopupValueRow {
                    width: parent.width
                    icon: "arrow_upward"
                    label: Translation.tr("Write:")
                    value: ResourceUsage.formatNetworkRate(ResourceUsage.diskWriteRate)
                }
            }
        }

        Column {
            width: 155
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "network_check"
                label: Translation.tr("Network")
            }
            Column {
                width: parent.width
                spacing: 4
                StyledPopupValueRow {
                    width: parent.width
                    icon: "arrow_downward"
                    label: Translation.tr("Down:")
                    value: ResourceUsage.formatNetworkRate(ResourceUsage.networkDownRate)
                }
                StyledPopupValueRow {
                    width: parent.width
                    icon: "arrow_upward"
                    label: Translation.tr("Up:")
                    value: ResourceUsage.formatNetworkRate(ResourceUsage.networkUpRate)
                }
            }
        }
    }
}
