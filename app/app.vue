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

useSeoMeta({
  title: "Laporku - Laporan Keuangan UMKM via WhatsApp | Mulai 40rb/minggu",
  description:
    "Kelola keuangan UMKM cukup lewat WhatsApp. Kirim pemasukan & pengeluaran, dapat laporan untung rugi + saran bisnis setiap minggu. Gratis 7 hari pertama! Harga mulai 40rb/minggu atau 120rb/bulan.",
  ogTitle: "Laporku - Kelola Untung Rugi Cukup Lewat WhatsApp",
  ogDescription:
    "Kirim data sederhana via WhatsApp, dapat ringkasan keuangan dan saran bisnis setiap minggu. Cocok untuk UMKM di Banjarmasin & seluruh Indonesia. Mulai 40rb/minggu!",
  ogImage: "https://laporku.vercel.app/og-image.png",
  ogUrl: "https://laporku.vercel.app",
  twitterTitle: "Laporku - Kelola Keuangan UMKM via WhatsApp",
  twitterDescription:
    "Pembukuan UMKM praktis via WhatsApp. 40rb/minggu, 120rb/bulan. Gratis 7 hari!",
  twitterImage: "https://laporku.vercel.app/og-image.png",
  twitterCard: "summary_large_image",
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
