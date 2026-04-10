<template>
    <div class="container-fluid">
        <div class="row">
            <div v-if="!$root.isMobile && !isServiceStatusPage" class="col-12 col-md-5 col-xl-4 ps-0">
                <div>
                    <router-link to="/add" class="btn btn-primary mb-3">
                        <font-awesome-icon icon="plus" />
                        {{ $t("Add New Monitor") }}
                    </router-link>
                </div>
                <MonitorList :scrollbar="true" />
            </div>

            <div
                ref="container"
                class="mb-3 gx-0"
                :class="isServiceStatusPage ? 'col-12' : 'col-12 col-md-7 col-xl-8'"
            >
                <!-- Add :key to disable vue router re-use the same component -->
                <router-view :key="$route.fullPath" :calculatedHeight="height" />
            </div>
        </div>
    </div>
</template>

<script>
import MonitorList from "../components/MonitorList.vue";

export default {
    components: {
        MonitorList,
    },
    data() {
        return {
            height: 0,
        };
    },
    computed: {
        isServiceStatusPage() {
            return this.$route.path === "/service-status";
        },
    },
    mounted() {
        this.height = this.$refs.container.offsetHeight;
    },
};
</script>

<style lang="scss" scoped>
.container-fluid {
    width: 98%;
}
</style>
