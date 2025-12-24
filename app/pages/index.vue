<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from "vue";

useHead({
  title: "Pendampingan Keuangan UMKM",
  meta: [
    {
      name: "description",
      content:
        "Laporan keuangan mingguan UMKM via WhatsApp. Sederhana dan praktis.",
    },
  ],
});

// mouse reactive background
const mouseX = ref(50);
const mouseY = ref(50);

const onMouseMove = (e: MouseEvent) => {
  mouseX.value = (e.clientX / window.innerWidth) * 100;
  mouseY.value = (e.clientY / window.innerHeight) * 100;
};

onMounted(() => {
  window.addEventListener("mousemove", onMouseMove);
});

onBeforeUnmount(() => {
  window.removeEventListener("mousemove", onMouseMove);
});
</script>

<template>
  <div
    class="relative min-h-screen overflow-hidden bg-background text-foreground"
  >
    <!-- Mouse reactive + animated background -->
    <div
      class="pointer-events-none absolute inset-0 -z-10 animate-gradient transition-all duration-300"
      :style="{
        background: `
          radial-gradient(circle at ${mouseX}% ${mouseY}%,
            rgba(16,185,129,0.25),
            transparent 40%),
          radial-gradient(circle at ${100 - mouseX}% ${100 - mouseY}%,
            rgba(6,182,212,0.2),
            transparent 45%)
        `,
      }"
    />

    <main class="max-w-4xl mx-auto px-6 pt-10 pb-20 text-center">
      <!-- HERO -->
      <Transition name="fade-up" appear>
        <section>
          <UBadge
            color="success"
            variant="soft"
            size="lg"
            class="mb-6 rounded-full px-4"
          >
            Solusi Keuangan UMKM
          </UBadge>

          <h1
            class="text-5xl md:text-6xl font-extrabold tracking-tight leading-[1.1]"
          >
            Kelola Untung Rugi <br />
            <span class="text-primary">Lewat WhatsApp</span>
          </h1>

          <p class="mt-6 text-lg text-muted max-w-2xl mx-auto leading-relaxed">
            Dapatkan ringkasan performa bisnis dan saran praktis setiap minggu
            tanpa perlu pusing baca grafik yang rumit.
          </p>

          <div
            class="mt-10 flex flex-col sm:flex-row gap-4 justify-center items-center"
          >
            <UButton
              size="xl"
              color="primary"
              class="px-8 shadow-lg transition-transform hover:scale-105"
            >
              Mulai Sekarang
            </UButton>

            <UButton variant="ghost" size="xl" icon="i-heroicons-play-circle">
              Lihat Demo
            </UButton>
          </div>
        </section>
      </Transition>

      <!-- MOCKUP -->
      <Transition name="fade-up" appear>
        <section class="mt-16 relative flex justify-center">
          <div
            class="relative z-10 w-full max-w-[500px] aspect-[16/10] bg-card rounded-2xl shadow-2xl border border-border overflow-hidden"
          >
            <div
              class="absolute inset-0 bg-muted flex items-center justify-center"
            >
              <div class="text-center p-8">
                <div
                  class="w-16 h-16 bg-primary/15 rounded-full flex items-center justify-center mx-auto mb-4"
                >
                  <UIcon
                    name="i-heroicons-chat-bubble-left-right"
                    class="w-8 h-8 text-primary"
                  />
                </div>

                <p class="text-sm font-medium text-muted italic">
                  "Laporan Minggu Ini: Keuntungan Anda naik 12%!"
                </p>

                <div class="mt-4 flex gap-2 justify-center">
                  <div class="h-2 w-24 bg-primary/30 rounded-full"></div>
                  <div class="h-2 w-12 bg-primary/15 rounded-full"></div>
                </div>
              </div>
            </div>

            <div
              class="absolute inset-0 bg-gradient-to-t from-background/30 to-transparent"
            />
          </div>

          <div
            class="absolute -top-10 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-primary/20 blur-[100px] -z-10 rounded-full"
          />
        </section>
      </Transition>

      <!-- FEATURES -->
      <Transition name="fade-up" appear>
        <section class="mt-24 grid grid-cols-1 md:grid-cols-3 gap-12 text-left">
          <div class="space-y-3 text-center md:text-left">
            <div
              class="w-10 h-10 bg-primary/15 text-primary rounded-lg flex items-center justify-center mx-auto md:mx-0"
            >
              <UIcon name="i-heroicons-bolt" class="w-6 h-6" />
            </div>
            <h3 class="font-bold">Input Cepat</h3>
            <p class="text-sm text-muted">
              Admin hanya butuh 5 menit untuk memperbarui data mingguan Anda.
            </p>
          </div>

          <div class="space-y-3 text-center md:text-left">
            <div
              class="w-10 h-10 bg-primary/15 text-primary rounded-lg flex items-center justify-center mx-auto md:mx-0"
            >
              <UIcon
                name="i-heroicons-presentation-chart-line"
                class="w-6 h-6"
              />
            </div>
            <h3 class="font-bold">Saran Praktis</h3>
            <p class="text-sm text-muted">
              Bukan sekadar angka, kami berikan langkah nyata untuk besarkan
              bisnis.
            </p>
          </div>

          <div class="space-y-3 text-center md:text-left">
            <div
              class="w-10 h-10 bg-primary/15 text-primary rounded-lg flex items-center justify-center mx-auto md:mx-0"
            >
              <UIcon name="i-heroicons-gift" class="w-6 h-6" />
            </div>
            <h3 class="font-bold">Minggu Pertama Gratis</h3>
            <p class="text-sm text-muted">
              Coba layanan kami tanpa biaya di minggu pertama pendaftaran.
            </p>
          </div>
        </section>
      </Transition>
    </main>

    <footer class="py-10 border-t border-border text-center text-muted text-sm">
      &copy; 2025 Pendampingan UMKM. All rights reserved.
    </footer>
  </div>
</template>

<style>
@keyframes gradientMove {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}

.animate-gradient {
  background-size: 200% 200%;
  animation: gradientMove 18s ease infinite;
}

/* fade + slide animation */
.fade-up-enter-active,
.fade-up-appear-active {
  transition: all 0.8s ease;
}
.fade-up-enter-from,
.fade-up-appear-from {
  opacity: 0;
  transform: translateY(20px);
}
.fade-up-enter-to,
.fade-up-appear-to {
  opacity: 1;
  transform: translateY(0);
}
</style>
