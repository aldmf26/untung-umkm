<script setup lang="ts">
const colorMode = useColorMode();

const color = computed(() =>
  colorMode.value === "dark" ? "#1b1718" : "white"
);

useHead({
  meta: [
    { charset: "utf-8" },
    { name: "viewport", content: "width=device-width, initial-scale=1" },
    { key: "theme-color", name: "theme-color", content: color },
    {
      name: "google-site-verification",
      content: "zXSUGYqWBcpBipTJwAbAyB6DlidHDeqaXOdT",
    },
  ],
  link: [{ rel: "icon", href: "/favicon.ico" }],
  htmlAttrs: {
    lang: "en",
  },
});

const title = "%s - Laporku";
const description =
  "Laporku adalah aplikasi pendampingan keuangan untuk UMKM yang membantu pemilik usaha memahami kondisi bisnisnya tanpa harus membaca laporan yang rumit.";

useSeoMeta({
  titleTemplate: title,
  description,
  ogTitle: title,
  ogDescription: description,
});
</script>

<template>
  <UApp>
    <NuxtLoadingIndicator />

    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </UApp>
</template>
