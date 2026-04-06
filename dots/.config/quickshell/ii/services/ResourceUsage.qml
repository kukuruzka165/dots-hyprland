pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, and CPU usage.
 */
Singleton {
    id: root
	property real memoryTotal: 1
	property real memoryFree: 0
	property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryTotal > 0 ? (memoryUsed / memoryTotal) : 0
    property real swapTotal: 1
	property real swapFree: 0
	property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0
    property var previousCpuStats
    property var perCoreCpuUsage: []
    property var previousPerCoreStats: []

    property real diskReadRate: 0
    property real diskWriteRate: 0
    property real diskUtilization: 0
    property var previousDiskStats

    property real networkDownRate: 0
    property real networkUpRate: 0
    property var previousNetworkStats
    property real networkUsedPercentage: {
        const maxBw = Config?.options.resources.networkMaxBandwidth ?? 125000000
        return Math.min(1.0, (networkDownRate + networkUpRate) / maxBw)
    }

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: "--"
    property string maxAvailableDiskString: formatNetworkRate(diskReadRate + diskWriteRate)
    property string maxAvailableNetworkString: formatNetworkRate(Config?.options.resources.networkMaxBandwidth ?? 125000000)

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []
    property list<real> diskUsageHistory: []
    property list<real> networkUsageHistory: []
    property list<real> diskReadRateHistory: []
    property list<real> diskWriteRateHistory: []
    property list<real> networkDownRateHistory: []
    property list<real> networkUpRateHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function formatNetworkRate(bytesPerSec) {
        if (bytesPerSec >= 1000000000) return (bytesPerSec / 1000000000).toFixed(1) + " GB/s"
        if (bytesPerSec >= 1000000) return (bytesPerSec / 1000000).toFixed(1) + " MB/s"
        if (bytesPerSec >= 1000) return (bytesPerSec / 1000).toFixed(1) + " KB/s"
        return bytesPerSec.toFixed(0) + " B/s"
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage]
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory.shift()
        }
    }
    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage]
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory.shift()
        }
    }
    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage]
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory.shift()
        }
    }
    function updateDiskUsageHistory() {
        diskUsageHistory = [...diskUsageHistory, diskUtilization]
        if (diskUsageHistory.length > historyLength) {
            diskUsageHistory.shift()
        }
    }
    function updateNetworkUsageHistory() {
        networkUsageHistory = [...networkUsageHistory, networkUsedPercentage]
        if (networkUsageHistory.length > historyLength) {
            networkUsageHistory.shift()
        }
    }
    function updateDiskRateHistories() {
        diskReadRateHistory = [...diskReadRateHistory, diskReadRate]
        if (diskReadRateHistory.length > historyLength) diskReadRateHistory.shift()
        diskWriteRateHistory = [...diskWriteRateHistory, diskWriteRate]
        if (diskWriteRateHistory.length > historyLength) diskWriteRateHistory.shift()
    }
    function updateNetworkRateHistories() {
        networkDownRateHistory = [...networkDownRateHistory, networkDownRate]
        if (networkDownRateHistory.length > historyLength) networkDownRateHistory.shift()
        networkUpRateHistory = [...networkUpRateHistory, networkUpRate]
        if (networkUpRateHistory.length > historyLength) networkUpRateHistory.shift()
    }
    function updateHistories() {
        updateMemoryUsageHistory()
        updateSwapUsageHistory()
        updateCpuUsageHistory()
        updateDiskUsageHistory()
        updateNetworkUsageHistory()
        updateDiskRateHistories()
        updateNetworkRateHistories()
    }

	Timer {
		interval: 1
        running: true
        repeat: true
		onTriggered: {
            fileMeminfo.reload()
            fileStat.reload()
            fileNetDev.reload()
            fileDiskStats.reload()

            const now = Date.now()

            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)

            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }

                previousCpuStats = { total, idle }
            }

            const coreLines = textStat.match(/^cpu\d+\s+.+/gm)
            if (coreLines) {
                const newPerCoreStats = []
                const newPerCoreUsage = []
                for (let i = 0; i < coreLines.length; i++) {
                    const parts = coreLines[i].match(/^cpu\d+\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
                    if (parts) {
                        const stats = parts.slice(1).map(Number)
                        const total = stats.reduce((a, b) => a + b, 0)
                        const idle = stats[3]
                        newPerCoreStats.push({ total, idle })
                        if (previousPerCoreStats.length > i) {
                            const totalDiff = total - previousPerCoreStats[i].total
                            const idleDiff = idle - previousPerCoreStats[i].idle
                            newPerCoreUsage.push(totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0)
                        } else {
                            newPerCoreUsage.push(0)
                        }
                    }
                }
                previousPerCoreStats = newPerCoreStats
                perCoreCpuUsage = newPerCoreUsage
            }

            const textDiskStats = fileDiskStats.text()
            const diskLines = textDiskStats.split('\n')
            let totalSectorsRead = 0, totalSectorsWritten = 0, totalTimeIo = 0, diskCount = 0
            for (const line of diskLines) {
                const match = line.match(/^\s*\d+\s+\d+\s+(\S+)\s+\d+\s+\d+\s+(\d+)\s+\d+\s+\d+\s+\d+\s+(\d+)\s+\d+\s+\d+\s+(\d+)/)
                if (match && /^(sd[a-z]+|nvme\d+n\d+|vd[a-z]+|mmcblk\d+)$/.test(match[1])) {
                    totalSectorsRead += Number(match[2])
                    totalSectorsWritten += Number(match[3])
                    totalTimeIo += Number(match[4])
                    diskCount++
                }
            }
            if (previousDiskStats) {
                const elapsed = (now - previousDiskStats.timestamp) / 1000
                const elapsedMs = now - previousDiskStats.timestamp
                if (elapsed > 0) {
                    diskReadRate = Math.max(0, (totalSectorsRead - previousDiskStats.sectorsRead) * 512 / elapsed)
                    diskWriteRate = Math.max(0, (totalSectorsWritten - previousDiskStats.sectorsWritten) * 512 / elapsed)
                    diskUtilization = diskCount > 0 ? Math.min(1.0, ((totalTimeIo - previousDiskStats.timeIo) / elapsedMs) / diskCount) : 0
                }
            }
            previousDiskStats = { sectorsRead: totalSectorsRead, sectorsWritten: totalSectorsWritten, timeIo: totalTimeIo, timestamp: now }

            const textNetDev = fileNetDev.text()
            const netLines = textNetDev.split('\n')
            let totalRx = 0, totalTx = 0
            for (const line of netLines) {
                const match = line.match(/^\s*(\S+):\s*(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)/)
                if (match && match[1] !== 'lo') {
                    totalRx += Number(match[2])
                    totalTx += Number(match[3])
                }
            }
            if (previousNetworkStats) {
                const elapsed = (now - previousNetworkStats.timestamp) / 1000
                if (elapsed > 0) {
                    networkDownRate = Math.max(0, (totalRx - previousNetworkStats.rx) / elapsed)
                    networkUpRate = Math.max(0, (totalTx - previousNetworkStats.tx) / elapsed)
                }
            }
            previousNetworkStats = { rx: totalRx, tx: totalTx, timestamp: now }

            root.updateHistories()
            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileNetDev; path: "/proc/net/dev" }
    FileView { id: fileDiskStats; path: "/proc/diskstats" }

    Process {
        id: findCpuMaxFreqProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: true
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                root.maxAvailableCpuString = (parseFloat(outputCollector.text) / 1000).toFixed(0) + " GHz"
            }
        }
    }
}
