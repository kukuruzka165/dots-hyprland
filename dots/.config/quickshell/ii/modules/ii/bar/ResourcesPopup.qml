import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

StyledPopup {
    id: root

    // Helper function to format KB to GB
    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    component RateGraph: Rectangle {
        id: rateGraph
        required property string dirIcon
        required property list<real> rateHistory

        property real peak: {
            let max = 0
            for (let i = 0; i < rateHistory.length; i++)
                if (rateHistory[i] > max) max = rateHistory[i]
            return max
        }

        width: parent.width
        height: 64
        radius: Appearance.rounding.verysmall
        color: Appearance.colors.colSecondaryContainer

        Row {
            id: graphLabel
            anchors {
                top: parent.top
                left: parent.left
                margins: 4
            }
            spacing: 2

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: rateGraph.dirIcon
                iconSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: ResourceUsage.formatNetworkRate(rateGraph.peak)
                font {
                    family: Appearance.font.family.numbers
                    pixelSize: Appearance.font.pixelSize.smallie
                }
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        Rectangle {
            anchors {
                top: graphLabel.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            radius: Appearance.rounding.verysmall
            color: "transparent"
            clip: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: rateGraph.width
                    height: rateGraph.height
                    radius: rateGraph.radius
                }
            }

            Graph {
                anchors.fill: parent
                values: {
                    const p = rateGraph.peak
                    if (p <= 0) return rateGraph.rateHistory.map(() => 0)
                    return rateGraph.rateHistory.map(v => v / p)
                }
                points: ResourceUsage.historyLength
                alignment: Graph.Alignment.Right
            }
        }
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
                    icon: "percent"
                    label: Translation.tr("Load:")
                    value: `${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%`
                }
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
            }

            StyledPopupHeaderRow {
                visible: ResourceUsage.swapTotal > 0
                icon: "swap_horiz"
                label: "Swap"
            }
            Column {
                visible: ResourceUsage.swapTotal > 0
                width: parent.width
                spacing: 4
                StyledPopupValueRow {
                    width: parent.width
                    icon: "percent"
                    label: Translation.tr("Load:")
                    value: `${Math.round(ResourceUsage.swapUsedPercentage * 100)}%`
                }
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
            }
        }

        Column {
            id: cpuColumn
            width: 155
            anchors { top: parent.top; bottom: parent.bottom }
            spacing: 8

            StyledPopupHeaderRow {
                id: cpuHeader
                icon: "planner_review"
                label: "CPU"
            }
            Rectangle {
                id: cpuGraphBg
                width: parent.width
                height: 64
                radius: Appearance.rounding.verysmall
                color: Appearance.colors.colSecondaryContainer

                Row {
                    id: cpuGraphLabel
                    anchors {
                        top: parent.top
                        left: parent.left
                        margins: 4
                    }
                    spacing: 2

                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "bolt"
                        iconSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
                        font {
                            family: Appearance.font.family.numbers
                            pixelSize: Appearance.font.pixelSize.smallie
                        }
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                Rectangle {
                    anchors {
                        top: cpuGraphLabel.bottom
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    radius: Appearance.rounding.verysmall
                    color: "transparent"
                    clip: true
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: cpuGraphBg.width
                            height: cpuGraphBg.height
                            radius: cpuGraphBg.radius
                        }
                    }

                    Graph {
                        anchors.fill: parent
                        values: ResourceUsage.cpuUsageHistory
                        points: ResourceUsage.historyLength
                        alignment: Graph.Alignment.Right
                    }
                }
            }
            Item {
                width: parent.width
                height: cpuColumn.height - cpuHeader.height - cpuGraphBg.height - cpuColumn.spacing * 2

                Grid {
                    id: coreGrid
                    anchors.fill: parent
                    columns: 2
                    columnSpacing: 3
                    rowSpacing: 3

                    Repeater {
                        model: ResourceUsage.perCoreCpuUsage
                        Rectangle {
                            required property real modelData
                            required property int index
                            width: Math.floor((coreGrid.width - coreGrid.columnSpacing) / 2)
                            height: Math.max(2, Math.floor((coreGrid.height - (Math.ceil(ResourceUsage.perCoreCpuUsage.length / 2) - 1) * coreGrid.rowSpacing) / Math.ceil(ResourceUsage.perCoreCpuUsage.length / 2)))
                            radius: height / 2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Appearance.colors.colPrimary }
                                GradientStop { position: modelData; color: Appearance.colors.colPrimary }
                                GradientStop { position: modelData + 0.001; color: Appearance.colors.colSecondaryContainer }
                                GradientStop { position: 1.0; color: Appearance.colors.colSecondaryContainer }
                            }
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
            RateGraph {
                dirIcon: "arrow_downward"
                rateHistory: ResourceUsage.diskReadRateHistory
            }
            RateGraph {
                dirIcon: "arrow_upward"
                rateHistory: ResourceUsage.diskWriteRateHistory
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
            RateGraph {
                dirIcon: "arrow_downward"
                rateHistory: ResourceUsage.networkDownRateHistory
            }
            RateGraph {
                dirIcon: "arrow_upward"
                rateHistory: ResourceUsage.networkUpRateHistory
            }
        }
    }
}
