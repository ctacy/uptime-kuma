<template>
    <div class="container-fluid service-status-page">
        <h2 class="page-title mb-4">
            <font-awesome-icon icon="th-large" class="me-2" />
            服务实时状态
        </h2>

        <div v-if="topGroups.length === 0" class="empty-tip text-muted">
            暂无分组数据，请先创建 Group 类型的监控并配置子服务。
        </div>

        <div v-for="group in topGroups" :key="group.id" class="group-section mb-5">
            <div class="group-container" @click="toggleFolder(group.id)" style="cursor: pointer; user-select: none;">
                <div class="group-info">
                    <div class="group-header d-flex justify-content-between align-items-center">
                        <div>
                            <font-awesome-icon icon="layer-group" class="me-2" />
                            <span class="group-name">{{ group.name }}</span>
                        </div>
                        <font-awesome-icon
                            icon="chevron-down"
                            class="expand-icon ms-3"
                            :class="{ rotated: expandedFolders.has(group.id) }"
                        />
                    </div>
                    <div class="group-summary">
                        <span class="summary-badge badge-soft-success">
                            <font-awesome-icon icon="check-circle" class="me-1" />
                            正常 {{ getGroupStats(group.id).normal }}
                        </span>
                        <span
                            class="summary-badge ms-2"
                            :class="getGroupStats(group.id).abnormal > 0 ? 'badge-soft-danger' : 'badge-soft-secondary'"
                        >
                            <font-awesome-icon :icon="getGroupStats(group.id).abnormal > 0 ? 'exclamation-triangle' : 'check-circle'" class="me-1" />
                            异常 {{ getGroupStats(group.id).abnormal }}
                        </span>
                    </div>
                    <div class="group-availability">
                        <div class="avail-label">整体可用率</div>
                        <div
                            class="avail-value"
                            :class="getGroupAvailability(group.id) >= 99 ? 'avail-good' : getGroupAvailability(group.id) >= 95 ? 'avail-warn' : 'avail-bad'"
                        >
                            {{ getGroupAvailability(group.id).toFixed(2) }}%
                        </div>
                    </div>
                </div>
                <div class="group-chart">
                    <GroupAvailabilityChart :groupId="group.id" />
                </div>
            </div>

            <transition name="slide-fade">
                <div class="mt-4" v-if="expandedFolders.has(group.id)">
                    <!-- Direct services of the top group -->
                    <div
                        v-if="getDirectServices(group.id).length > 0"
                        class="service-list mb-4 bg-white"
                        style="border: 1px solid #e5e7eb; border-radius: 12px; padding: 12px 18px;"
                        @click.stop
                    >
                        <div v-if="getFailedDirectServices(group.id).length === 0" class="all-ok border-0 m-0">
                            <font-awesome-icon icon="check-circle" class="me-1 text-success" />
                            所有服务运行正常
                        </div>
                        <div
                            v-for="svc in getExpandedDirectServices(group.id)"
                            :key="svc.id"
                            class="service-item"
                            :class="{ 'service-down': getServiceStatus(svc.id) !== 1 }"
                        >
                            <span
                                class="status-dot me-2"
                                :class="statusDotClass(svc.id)"
                            />
                            <router-link
                                :to="`/dashboard/${svc.id}`"
                                class="svc-link"
                                @click.stop
                            >
                                {{ svc.name }}
                            </router-link>
                            <span v-if="getLastMsg(svc.id)" class="svc-msg ms-2 text-muted">
                                {{ getLastMsg(svc.id) }}
                            </span>
                        </div>
                    </div>

                    <!-- Folder Cards -->
                    <div class="row g-3" v-if="getAllSubGroups(group.id).length > 0">
                        <div
                            v-for="node in getAllSubGroups(group.id)"
                            :key="node.folder.id"
                            class="col-12"
                        >
                            <div
                                class="folder-card"
                                :class="{
                                    'has-error': getFolderStats(node.folder.id).abnormal > 0,
                                    'expanded': expandedFolders.has(node.folder.id),
                                }"
                                :style="{ marginLeft: (node.level * 24) + 'px' }"
                                @click="toggleFolder(node.folder.id)"
                            >
                                <div class="folder-layout-container">
                                    <div class="folder-info-area">
                                        <div class="folder-header">
                                            <div class="folder-name-wrap">
                                                <font-awesome-icon icon="folder" class="me-2 folder-icon" />
                                                <span class="folder-name" :style="{ fontSize: Math.max(0.85, 1 - node.level * 0.05) + 'rem' }">{{ node.folder.name }}</span>
                                            </div>
                                            <font-awesome-icon
                                                icon="chevron-down"
                                                class="expand-icon ms-auto"
                                                :class="{ rotated: expandedFolders.has(node.folder.id) }"
                                            />
                                        </div>
                                        <div class="folder-badges mt-3 text-start">
                                            <span class="summary-badge badge-soft-success me-2">
                                                <font-awesome-icon icon="check-circle" class="me-1" />
                                                正常 {{ getFolderStats(node.folder.id).normal }}
                                            </span>
                                            <span
                                                class="summary-badge"
                                                :class="getFolderStats(node.folder.id).abnormal > 0 ? 'badge-soft-danger' : 'badge-soft-secondary'"
                                            >
                                                <font-awesome-icon :icon="getFolderStats(node.folder.id).abnormal > 0 ? 'exclamation-triangle' : 'check-circle'" class="me-1" />
                                                异常 {{ getFolderStats(node.folder.id).abnormal }}
                                            </span>
                                        </div>
                                    </div>
                                    <div class="folder-chart-area">
                                        <GroupAvailabilityChart :groupId="node.folder.id" />
                                    </div>
                                </div>

                                <transition name="slide-fade">
                                    <div
                                        v-if="expandedFolders.has(node.folder.id) && getDirectServices(node.folder.id).length > 0"
                                        class="service-list mt-2"
                                        @click.stop
                                    >
                                        <div v-if="getFailedDirectServices(node.folder.id).length === 0" class="all-ok">
                                            <font-awesome-icon icon="check-circle" class="me-1 text-success" />
                                            所有服务运行正常
                                        </div>
                                        <div
                                            v-for="svc in getExpandedDirectServices(node.folder.id)"
                                            :key="svc.id"
                                            class="service-item"
                                            :class="{ 'service-down': getServiceStatus(svc.id) !== 1 }"
                                        >
                                            <span
                                                class="status-dot me-2"
                                                :class="statusDotClass(svc.id)"
                                            />
                                            <router-link
                                                :to="`/dashboard/${svc.id}`"
                                                class="svc-link"
                                                @click.stop
                                            >
                                                {{ svc.name }}
                                            </router-link>
                                            <span v-if="getLastMsg(svc.id)" class="svc-msg ms-2 text-muted">
                                                {{ getLastMsg(svc.id) }}
                                            </span>
                                        </div>
                                    </div>
                                </transition>
                            </div>
                        </div>
                    </div>
                </div>
            </transition>
        </div>
    </div>
</template>

<script>
import {
    LineController,
    LineElement,
    PointElement,
    LinearScale,
    TimeScale,
    Tooltip,
    Filler,
    Chart,
} from "chart.js";
import "chartjs-adapter-dayjs-4";
import { Line } from "vue-chartjs";
import dayjs from "dayjs";
import { h } from "vue";

Chart.register(
    LineController,
    LineElement,
    PointElement,
    TimeScale,
    LinearScale,
    Tooltip,
    Filler
);

// Sub-component for group availability chart
const GroupAvailabilityChart = {
    name: "GroupAvailabilityChart",
    components: { Line },
    props: {
        groupId: {
            type: Number,
            required: true,
        },
    },
    render() {
        return h("div", { class: "chart-box" }, [
            this.chartData
                ? h(Line, { data: this.chartData, options: this.chartOptions })
                : null,
        ]);
    },
    data() {
        return {
            chartData: null,
            refreshTimer: null,
        };
    },
    computed: {
        chartOptions() {
            const isDark = document.documentElement.classList.contains("dark");
            const textColor = isDark ? "#cbd5e1" : "#64748b";

            return {
                responsive: true,
                maintainAspectRatio: false,
                animation: { duration: 300 },
                interaction: {
                    intersect: false,
                    mode: "index",
                },
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        backgroundColor: isDark ? "#1f2937" : "rgba(0, 0, 0, 0.8)",
                        titleColor: "#fff",
                        bodyColor: "#fff",
                        callbacks: {
                            label: (context) => {
                                return `可用率: ${context.parsed.y.toFixed(1)}%`;
                            },
                        },
                    },
                },
                scales: {
                    x: {
                        type: "time",
                        time: {
                            unit: "minute",
                            displayFormats: { minute: "HH:mm" },
                        },
                        grid: { display: false },
                        ticks: { color: textColor, maxTicksLimit: 6 },
                    },
                    y: {
                        min: 0,
                        max: 100,
                        grid: { color: isDark ? "rgba(255,255,255,0.06)" : "rgba(0,0,0,0.06)" },
                        ticks: {
                            color: textColor,
                            callback: (v) => v + "%",
                            stepSize: 25,
                        },
                    },
                },
            };
        },
    },
    methods: {
        getDescendantServices(parentId, childrenMap) {
            if (!childrenMap) {
                childrenMap = new Map();
                for (const id in this.$root.monitorList) {
                    const m = this.$root.monitorList[id];
                    if (m.parent) {
                        if (!childrenMap.has(m.parent)) childrenMap.set(m.parent, []);
                        childrenMap.get(m.parent).push(m);
                    }
                }
            }
            const directChildren = childrenMap.get(parentId) || [];
            const services = [];
            for (const child of directChildren) {
                if (child.type === "group") {
                    services.push(...this.getDescendantServices(child.id, childrenMap));
                } else {
                    services.push(child);
                }
            }
            return services;
        },
        refresh() {
            const services = this.getDescendantServices(this.groupId);
            const timeMap = new Map();

            for (const svc of services) {
                const hbList = this.$root.heartbeatList[svc.id] || [];
                for (const hb of hbList) {
                    const ts = dayjs(hb.time).valueOf();
                    const bucket = Math.floor(ts / (60 * 1000));
                    if (!timeMap.has(bucket)) {
                        timeMap.set(bucket, { total: 0, up: 0 });
                    }
                    const entry = timeMap.get(bucket);
                    entry.total++;
                    if (hb.status === 1) {
                        entry.up++;
                    }
                }
            }

            const points = [];
            for (const [bucket, stats] of timeMap.entries()) {
                points.push({
                    x: bucket * 60 * 1000,
                    y: (stats.up / stats.total) * 100,
                });
            }
            points.sort((a, b) => a.x - b.x);

            const isDark = document.documentElement.classList.contains("dark");

            this.chartData = {
                datasets: [{
                    label: "可用率",
                    data: points.slice(-50),
                    borderColor: isDark ? "#22c55e" : "#3b82f6",
                    backgroundColor: (context) => {
                        const chart = context.chart;
                        const { ctx, chartArea } = chart;
                        if (!chartArea) return isDark ? "rgba(34, 197, 94, 0.15)" : "rgba(59, 130, 246, 0.15)";
                        const gradient = ctx.createLinearGradient(0, chartArea.top, 0, chartArea.bottom);
                        if (isDark) {
                            gradient.addColorStop(0, "rgba(34, 197, 94, 0.4)");
                            gradient.addColorStop(1, "rgba(34, 197, 94, 0.01)");
                        } else {
                            gradient.addColorStop(0, "rgba(59, 130, 246, 0.4)");
                            gradient.addColorStop(1, "rgba(59, 130, 246, 0.01)");
                        }
                        return gradient;
                    },
                    borderWidth: 3,
                    fill: true,
                    tension: 0.45,
                    pointRadius: 0,
                    pointHoverRadius: 5,
                }],
            };
        },
    },
    mounted() {
        this.refresh();
        this.refreshTimer = setInterval(() => this.refresh(), 30 * 1000);
    },
    beforeUnmount() {
        if (this.refreshTimer) clearInterval(this.refreshTimer);
    },
};

export default {
    name: "ServiceStatus",

    components: {
        GroupAvailabilityChart,
    },

    data() {
        return {
            expandedFolders: new Set(),
            hasInitializedTopGroups: false,
        };
    },

    computed: {
        topGroups() {
            return Object.values(this.$root.monitorList)
                .filter((m) => m.type === "group" && (m.parent === null || m.parent === undefined))
                .sort((a, b) => (a.weight ?? 2000) - (b.weight ?? 2000) || a.name.localeCompare(b.name));
        },
        childrenMap() {
            const map = new Map();
            for (const id in this.$root.monitorList) {
                const m = this.$root.monitorList[id];
                if (m.parent) {
                    if (!map.has(m.parent)) map.set(m.parent, []);
                    map.get(m.parent).push(m);
                }
            }
            return map;
        }
    },

    watch: {
        topGroups: {
            immediate: true,
            handler(newVal) {
                if (!this.hasInitializedTopGroups && newVal && newVal.length > 0) {
                    const next = new Set(this.expandedFolders);
                    for (const group of newVal) {
                        next.add(group.id);
                    }
                    this.expandedFolders = next;
                    this.hasInitializedTopGroups = true;
                }
            }
        },
        /**
         * When new heartbeat arrives, the counts need to update
         */
        "$root.lastHeartbeatList": {
            deep: true,
            handler() {
                if (this.updateTimer) return;
                this.updateTimer = setTimeout(() => {
                    this.updateTimer = null;
                    this.$forceUpdate();
                }, 300);
            },
        },
        "$root.monitorList": {
            deep: true,
            handler() {
                if (this.updateTimer) return;
                this.updateTimer = setTimeout(() => {
                    this.updateTimer = null;
                    this.$forceUpdate();
                }, 300);
            },
        },
    },

    methods: {
        getFolders(groupId) {
            return (this.childrenMap.get(groupId) || [])
                .filter((m) => m.type === "group")
                .sort((a, b) => (a.weight ?? 2000) - (b.weight ?? 2000) || a.name.localeCompare(b.name));
        },

        getAllSubGroups(parentId, level = 0) {
            const children = (this.childrenMap.get(parentId) || [])
                .filter((m) => m.type === "group")
                .sort((a, b) => (a.weight ?? 2000) - (b.weight ?? 2000) || a.name.localeCompare(b.name));
            
            let result = [];
            for (const child of children) {
                result.push({ folder: child, level });
                if (this.expandedFolders.has(child.id)) {
                    result.push(...this.getAllSubGroups(child.id, level + 1));
                }
            }
            return result;
        },

        getDescendantServices(parentId) {
            const directChildren = this.childrenMap.get(parentId) || [];
            const services = [];

            for (const child of directChildren) {
                if (child.type === "group") {
                    services.push(...this.getDescendantServices(child.id));
                } else {
                    services.push(child);
                }
            }

            return services;
        },

        getServices(folderId) {
            return this.getDescendantServices(folderId);
        },

        getServiceStatus(monitorId) {
            const hb = this.$root.lastHeartbeatList[monitorId];
            return hb ? hb.status : null;
        },

        getLastMsg(monitorId) {
            const hb = this.$root.lastHeartbeatList[monitorId];
            return hb ? hb.msg : "";
        },

        getFolderStats(folderId) {
            const services = this.getServices(folderId);
            let normal = 0;
            let abnormal = 0;
            for (const svc of services) {
                const status = this.getServiceStatus(svc.id);
                if (status === 1) {
                    normal++;
                } else {
                    abnormal++;
                }
            }
            return { normal, abnormal };
        },

        getGroupStats(groupId) {
            const folders = this.getFolders(groupId);
            let normal = 0;
            let abnormal = 0;
            for (const folder of folders) {
                const stats = this.getFolderStats(folder.id);
                normal += stats.normal;
                abnormal += stats.abnormal;
            }
            return { normal, abnormal };
        },

        getGroupAvailability(groupId) {
            const services = this.getDescendantServices(groupId);
            let normal = 0;
            let total = 0;
            for (const svc of services) {
                const status = this.getServiceStatus(svc.id);
                total++;
                if (status === 1) {
                    normal++;
                }
            }
            if (total === 0) return 100;
            return (normal / total) * 100;
        },

        getFailedServices(folderId) {
            return this.getServices(folderId).filter((svc) => this.getServiceStatus(svc.id) !== 1);
        },

        getExpandedServices(folderId) {
            const services = this.getServices(folderId);
            const failed = services.filter((s) => this.getServiceStatus(s.id) !== 1);
            const ok = services.filter((s) => this.getServiceStatus(s.id) === 1);
            return [...failed, ...ok];
        },

        getDirectServices(folderId) {
            const directChildren = this.childrenMap.get(folderId) || [];
            return directChildren.filter((m) => m.type !== "group");
        },

        getFailedDirectServices(folderId) {
            return this.getDirectServices(folderId).filter((svc) => this.getServiceStatus(svc.id) !== 1);
        },

        getExpandedDirectServices(folderId) {
            const services = this.getDirectServices(folderId);
            const failed = services.filter((s) => this.getServiceStatus(s.id) !== 1);
            const ok = services.filter((s) => this.getServiceStatus(s.id) === 1);
            return [...failed, ...ok];
        },

        statusDotClass(monitorId) {
            const status = this.getServiceStatus(monitorId);
            if (status === 1) return "dot-up";
            if (status === 0) return "dot-down";
            if (status === 2) return "dot-pending";
            if (status === 3) return "dot-maintenance";
            return "dot-unknown";
        },

        toggleFolder(folderId) {
            const next = new Set(this.expandedFolders);
            if (next.has(folderId)) {
                next.delete(folderId);
            } else {
                next.add(folderId);
            }
            this.expandedFolders = next;
        },
    },
};
</script>

<style lang="scss" scoped>
@import "../assets/vars.scss";

.service-status-page {
    padding: 24px;
}

.page-title {
    font-size: 1.8rem;
    font-weight: 700;
    background: linear-gradient(135deg, $primary 0%, #2a6fd4 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
}

.group-section {
    background: linear-gradient(145deg, #ffffff 0%, #f8fafc 100%);
    border-radius: 16px;
    padding: 20px 24px;
    border: 1px solid rgba(226, 232, 240, 0.8);
    box-shadow: 0 4px 20px rgba(0,0,0,0.02), inset 0 1px 0 rgba(255,255,255,1);
}

.group-container {
    display: flex;
    gap: 24px;
    align-items: stretch;
    margin-bottom: 16px;
    transition: transform 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.group-container:hover {
    transform: translateY(-2px);
}

@media (max-width: 768px) {
    .group-container {
        flex-direction: column;
    }

    .group-info {
        flex: none;
    }
}

.group-info {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
}

.group-chart {
    flex: 2;
    min-height: 160px;
    position: relative;
    width: 0;
}

.chart-box {
    width: 100%;
    height: 100%;
    min-height: 160px;
    position: relative;
}

.group-header {
    display: flex;
    align-items: center;
    font-size: 1.5rem;
    font-weight: 600;
    border-left: 5px solid $primary;
    padding-left: 12px;
}

.group-name {
    font-size: 1.5rem;
    color: #111827;
    font-weight: 700;
}

.group-summary {
    margin-top: 12px;
    display: flex;
    gap: 10px;
}

.summary-badge {
    display: inline-flex;
    align-items: center;
    padding: 4px 10px;
    border-radius: 6px;
    font-size: 0.9rem;
    font-weight: 600;
}

.badge-soft-success {
    background-color: rgba(34, 197, 94, 0.15) !important;
    color: #15803d !important;
}

.badge-soft-danger {
    background-color: rgba(239, 68, 68, 0.15) !important;
    color: #dc2626 !important;
}

.badge-soft-secondary {
    background-color: rgba(107, 114, 128, 0.1) !important;
    color: #4b5563 !important;
}

.group-availability {
    margin-top: 12px;
    display: flex;
    align-items: baseline;
    gap: 8px;
    padding: 8px 12px;
    background: #f3f4f6;
    border-radius: 8px;
}

.avail-label {
    font-size: 0.85rem;
    color: #6b7280;
}

.avail-value {
    font-size: 1.4rem;
    font-weight: 700;
}

.avail-good {
    color: #16a34a;
}

.avail-warn {
    color: #f59e0b;
}

.avail-bad {
    color: #dc2626;
}

.mt-4 {
    margin-top: 16px;
}

.folder-card {
    background: rgba(255, 255, 255, 0.9);
    backdrop-filter: blur(8px);
    border: 1px solid #e2e8f0;
    border-left: 4px solid rgba(203, 213, 225, 0.4);
    border-radius: 12px;
    padding: 16px 18px;
    cursor: pointer;
    transition: all 0.25s ease;
    user-select: none;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.03);

    &:hover {
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
        transform: translateY(-2px);
        border-left-color: rgba(99, 102, 241, 0.5); /* Primary glow on hover */
    }

    &.has-error {
        border-color: #fca5a5;
        border-left-color: #ef4444;
        background: linear-gradient(135deg, rgba(254, 242, 242, 0.8) 0%, rgba(255, 248, 248, 0.8) 100%);
    }

    &.expanded {
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
        border-color: $primary;
    }
}

.folder-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
}

.folder-layout-container {
    display: flex;
    gap: 24px;
    align-items: stretch;
}

@media (max-width: 768px) {
    .folder-layout-container {
        flex-direction: column;
    }

    .folder-info-area {
        flex: none !important;
    }
}

.folder-info-area {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
}

.folder-chart-area {
    flex: 2;
    min-height: 120px;
    position: relative;
    width: 0;
}

.folder-name-wrap {
    display: flex;
    align-items: center;
    font-weight: 600;
    min-width: 0;
    flex: 1;
}

.folder-icon {
    color: #f59e0b;
    flex-shrink: 0;
    font-size: 1.1rem;
}

.folder-name {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    font-size: 1rem;
    color: #1f2937;
}

.folder-badges {
    display: flex;
    align-items: center;
    flex-shrink: 0;
}

.expand-icon {
    font-size: 0.75rem;
    color: #6b7280;
    transition: transform 0.25s;

    &.rotated {
        transform: rotate(180deg);
    }
}

.service-list {
    background: #f8fafc;
    border-radius: 8px;
    padding: 14px;
    border-top: none;
    box-shadow: inset 0 2px 6px rgba(0, 0, 0, 0.02);
    margin-top: 16px;
    border: 1px solid #f1f5f9;
}

.all-ok {
    font-size: 0.9rem;
    color: #16a34a;
    padding: 8px 0;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #f0fdf4;
    border-radius: 6px;
}

.service-item {
    display: flex;
    align-items: center;
    padding: 8px 6px;
    font-size: 0.9rem;
    border-bottom: 1px solid #f3f4f6;
    border-radius: 6px;
    transition: background-color 0.15s;

    &:last-child {
        border-bottom: none;
    }

    &:hover {
        background-color: #f9fafb;
    }

    &.service-down {
        color: #dc2626;
        background-color: #fef2f2;
    }
}

.status-dot {
    display: inline-block;
    width: 10px;
    height: 10px;
    border-radius: 50%;
    flex-shrink: 0;
    box-shadow: 0 0 0 3px rgba(0, 0, 0, 0.05);

    &.dot-up { background-color: #22c55e; }
    &.dot-down { background-color: #ef4444; }
    &.dot-pending { background-color: #eab308; }
    &.dot-maintenance { background-color: #0ea5e9; }
    &.dot-unknown { background-color: #9ca3af; }
}

.svc-link {
    color: inherit;
    text-decoration: none;
    font-weight: 500;

    &:hover {
        text-decoration: underline;
    }
}

.svc-msg {
    font-size: 0.8rem;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    max-width: 220px;
    color: #6b7280;
}

.empty-tip {
    padding: 60px 0;
    text-align: center;
    font-size: 1.05rem;
    color: #6b7280;
    background: #f9fafb;
    border-radius: 12px;
    border: 1px dashed #d1d5db;
}

// Slide animation
.slide-fade-enter-active {
    transition: all 0.25s ease;
}
.slide-fade-leave-active {
    transition: all 0.18s ease;
}
.slide-fade-enter-from,
.slide-fade-leave-to {
    opacity: 0;
    transform: translateY(-10px);
}

// Dark mode
.dark {
    .group-section {
        background: $dark-bg;
        border-color: $dark-border-color;
        box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.05);
    }

    .group-header {
        color: $dark-font-color;
    }

    .group-name {
        color: $dark-font-color;
    }

    .group-availability {
        background: rgba(255, 255, 255, 0.05);
    }

    .group-info {
        color: $dark-font-color;
    }

    .folder-card {
        background: $dark-bg2;
        border-color: $dark-border-color;
        border-left-color: rgba(148, 163, 184, 0.2);

        &:hover {
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.35);
            border-left-color: rgba(99, 102, 241, 0.6);
        }

        &.has-error {
            border-color: #991b1b;
            border-left-color: #ef4444;
            background: linear-gradient(135deg, rgba(69, 10, 10, 0.4) 0%, rgba(69, 10, 10, 0.8) 100%);
        }

        &.expanded {
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.45);
            border-color: $primary;
        }
    }

    .folder-name {
        color: $dark-font-color;
    }

    .badge-soft-success {
        background-color: rgba(74, 222, 128, 0.15) !important;
        color: #4ade80 !important;
    }

    .badge-soft-danger {
        background-color: rgba(248, 113, 113, 0.15) !important;
        color: #f87171 !important;
    }

    .badge-soft-secondary {
        background-color: rgba(156, 163, 175, 0.1) !important;
        color: #9ca3af !important;
    }

    .service-list {
        background-color: rgba(0, 0, 0, 0.25);
        border-color: $dark-border-color;
        box-shadow: inset 0 2px 6px rgba(0, 0, 0, 0.2);
    }

    .all-ok {
        background: rgba(22, 163, 74, 0.1);
        color: #4ade80;
    }

    .service-item {
        border-bottom-color: $dark-border-color;

        &:hover {
            background-color: rgba(255, 255, 255, 0.05);
        }

        &.service-down {
            background-color: rgba(239, 68, 68, 0.15);
            color: #fca5a5;
        }
    }

    .svc-msg {
        color: #9ca3af;
    }

    .empty-tip {
        background: $dark-bg;
        border-color: $dark-border-color;
        color: #9ca3af;
    }
}
</style>
