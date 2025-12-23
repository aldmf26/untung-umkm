<script setup lang="ts">
useHead({
  title: "Pendampingan Keuangan UMKM — Dashboard Admin",
  meta: [
    {
      name: "description",
      content:
        "Layanan pendampingan keuangan sederhana via WhatsApp untuk UMKM kecil. Admin memasukkan laporan mingguan dan sistem mengirim ringkasan keuntungan/rugi.",
    },
    {
      property: "og:title",
      content: "Pendampingan Keuangan UMKM — Dashboard Admin",
    },
    {
      property: "og:description",
      content:
        "Layanan pendampingan keuangan sederhana via WhatsApp untuk UMKM kecil.",
    },
    { property: "og:type", content: "website" },
  ],
  link: [{ rel: "canonical", href: "https://yourdomain.example/" }],
  script: [
    {
      type: "application/ld+json",
      children: JSON.stringify({
        "@context": "https://schema.org",
        "@type": "WebPage",
        name: "Pendampingan Keuangan UMKM",
        description:
          "Layanan pendampingan keuangan via WhatsApp untuk UMKM kecil (admin-only).",
      }),
    },
  ],
});
</script>

<template>
  <UContainer class="min-h-screen">
    <main class="max-w-6xl mx-auto px-6 mt-12">
      <section class="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
        <div>
          <h1 class="text-4xl md:text-5xl font-extrabold leading-tight">
            Pendampingan Keuangan Sederhana untuk UMKM
          </h1>
          <p class="mt-4 text-gray-600">
            Terima ringkasan untung/rugi mingguan yang gampang dimengerti,
            dikirim langsung via WhatsApp. Admin kami yang berpengalaman
            mengelola input dan pengiriman.
          </p>

          <div class="mt-6 flex flex-wrap gap-3">
            <RouterLink to="/login">
              <UButton size="lg" color="success">Login sebagai Admin</UButton>
            </RouterLink>

            <UButton variant="outline" size="sm" class="px-4 py-3">
              Pelajari Lebih Lanjut
            </UButton>
          </div>

          <ul id="features" class="mt-8 grid grid-cols-1 sm:grid-cols-2 gap-4">
            <li class="flex items-start gap-3">
              <div class="text-green-500 mt-1">✓</div>
              <div>
                <h4 class="font-medium">Input cepat oleh admin</h4>
                <p class="text-sm text-gray-600">
                  Admin input laporan mingguan hanya dalam 5-10 menit per klien.
                </p>
              </div>
            </li>

            <li class="flex items-start gap-3">
              <div class="text-green-500 mt-1">✓</div>
              <div>
                <h4 class="font-medium">Ringkasan & saran praktis</h4>
                <p class="text-sm text-gray-600">
                  Sistem memberi ringkasan untung/rugi dan 1-2 saran sederhana
                  untuk perbaikan.
                </p>
              </div>
            </li>

            <li class="flex items-start gap-3">
              <div class="text-green-500 mt-1">✓</div>
              <div>
                <h4 class="font-medium">Dikirim via WhatsApp</h4>
                <p class="text-sm text-gray-600">
                  Hasil dikirim ke klien lewat format pesan standar WhatsApp.
                </p>
              </div>
            </li>

            <li class="flex items-start gap-3">
              <div class="text-green-500 mt-1">✓</div>
              <div>
                <h4 class="font-medium">Gratis di minggu pertama</h4>
                <p class="text-sm text-gray-600">
                  Flag is_partial untuk minggu pertama sehingga klien
                  mendapatkan minggu pertama gratis.
                </p>
              </div>
            </li>
          </ul>
        </div>

        <div class="hidden md:block">
          <!-- Simple illustration -->
          <div
            class="w-full h-80 rounded-xl bg-gradient-to-br from-emerald-50 to-white border p-6 flex items-center justify-center"
          >
            <svg
              width="240"
              height="160"
              viewBox="0 0 240 160"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <rect
                x="0"
                y="0"
                width="240"
                height="160"
                rx="12"
                fill="#ECFDF5"
              />
              <path d="M32 112h176v8H32z" fill="#D1FAE5" />
              <rect
                x="40"
                y="36"
                width="160"
                height="64"
                rx="6"
                fill="#fff"
                stroke="#D1FAE5"
              />
              <rect x="52" y="48" width="36" height="8" rx="3" fill="#ECFDF5" />
              <rect
                x="52"
                y="60"
                width="100"
                height="8"
                rx="3"
                fill="#ECFDF5"
              />
              <rect x="52" y="72" width="72" height="8" rx="3" fill="#ECFDF5" />
            </svg>
          </div>
        </div>
      </section>
    </main>
  </UContainer>
</template>
