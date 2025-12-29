<script setup lang="ts">
import type { NavigationMenuItem } from "@nuxt/ui";
import UDashboardLayout from "~/layouts/dashboard.vue";

definePageMeta({
  middleware: "auth",
  layout: "dashboard",
});

const links = [
  [
    {
      label: "Rekap",
      to: "/dashboard/laporan/rekap",
      exact: true,
      icon: "i-lucide-file-text",
    },
    {
      label: "Laporan",
      icon: "i-lucide-file-text",
      to: "/dashboard/laporan",
      exact: true,
    },
  ],
] satisfies NavigationMenuItem[][];

useHead({
  title: "Laporan",
});
</script>

<template>
  <UDashboardPanel id="laporan">
    <template #header>
      <UDashboardNavbar title="Laporan">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>
      </UDashboardNavbar>

      <UDashboardToolbar>
        <!-- NOTE: The `-mx-1` class is used to align with the `DashboardSidebarCollapse` button here. -->
        <UNavigationMenu :items="links" highlight class="-mx-1" />
      </UDashboardToolbar>
    </template>

    <template #body>
      <NuxtPage />
    </template>
  </UDashboardPanel>
</template>
