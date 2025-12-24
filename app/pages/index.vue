<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from "vue";
import gsap from "gsap";
import { TextPlugin } from "gsap/TextPlugin";

gsap.registerPlugin(TextPlugin);
const chatUser = ref<HTMLElement | null>(null);
const chatBot1 = ref<HTMLElement | null>(null);
const chatBot2 = ref<HTMLElement | null>(null);
const chatBot3 = ref<HTMLElement | null>(null);

onMounted(() => {
  window.addEventListener("mousemove", onMouseMove);

  if (!chatUser.value || !chatBot1.value || !chatBot2.value || !chatBot3.value)
    return;

  gsap.set([chatUser.value, chatBot1.value, chatBot2.value, chatBot3.value], {
    opacity: 0,
    y: 12,
  });

  const tl = gsap.timeline({
    repeat: -1,
    repeatDelay: 1.5,
  });

  tl.to(chatUser.value, {
    opacity: 1,
    y: 0,
    duration: 0.5,
    text: {
      value:
        "Laporan minggu ini 👇:<br/>1–7 Januari<br/>Masuk: Rp3.500.000<br/>Keluar: Rp2.100.000",
      delimiter: "",
    },
  })
    .to(chatBot1.value, {
      opacity: 1,
      y: 0,
      duration: 0.4,
      delay: 0.6,
    })
    .to(chatBot2.value, {
      opacity: 1,
      y: 0,
      duration: 0.4,
      delay: 0.6,
    })
    .to(chatBot3.value, {
      opacity: 1,
      y: 0,
      duration: 0.4,
      delay: 0.6,
    })
    .to([chatUser.value, chatBot1.value, chatBot2.value, chatBot3.value], {
      opacity: 0,
      duration: 0.4,
      delay: 2,
    });
});

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
    <img src="/images/wa.webp" class="absolute opacity-25 lg:bottom-24 md:bottom-32" alt="" />
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
            <span class="text-primary">Cukup Lewat WhatsApp</span>
          </h1>

          <p class="mt-6 text-lg text-muted max-w-2xl mx-auto leading-relaxed">
            Kirim data sederhana, dapat ringkasan dan saran bisnis setiap
            minggu.
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
          </div>
        </section>
      </Transition>

      <!-- MOCKUP -->
      <Transition name="fade-up" appear>
        <section class="mt-16 relative flex justify-center">
          <div
            class="relative z-10 w-full max-w-[500px] md:min-h-[450px] min-h-[480px] rounded-2xl overflow-hidden bg-gradient-to-br from-background/90 to-background/70 backdrop-blur-md shadow-[0_30px_80px_-30px_RGBA(0,0,0,0.5)] border border-border/40 md:border-none"
          >
            <!-- Header -->
            <div
              class="flex items-center gap-3 px-4 py-3 border-b border-border/40 bg-background/70"
            >
              <div
                class="w-8 h-8 rounded-full bg-emerald-500 flex items-center justify-center text-white text-sm font-bold"
              >
                U
              </div>
              <div class="text-left leading-tight">
                <div class="text-sm font-semibold">Laporku</div>
                <div class="text-xs text-muted">via WhatsApp</div>
              </div>
            </div>

            <!-- Chat Area -->
            <div
              class="absolute inset-x-0 bottom-0 top-[56px] flex flex-col justify-end px-4 pb-4 space-y-3 text-sm"
            >
              <!-- User bubble -->
              <div
                ref="chatUser"
                class="ml-auto max-w-[78%] rounded-2xl rounded-br-sm bg-primary text-primary-foreground px-4 py-2 text-left leading-relaxed shadow-md shadow-primary/25"
              ></div>

              <!-- Bot bubble -->
              <div
                ref="chatBot1"
                class="mr-auto max-w-[78%] rounded-2xl rounded-bl-sm bg-background/95 border border-border/40 px-4 py-2 text-left leading-relaxed shadow-sm"
              >
                📊 <b>Ringkasan Mingguan</b><br />
                Untung: Rp1.400.000
              </div>

              <div
                ref="chatBot2"
                class="mr-auto max-w-[78%] rounded-2xl rounded-bl-sm bg-background/95 border border-border/40 px-4 py-2 text-left leading-relaxed shadow-sm"
              >
                ⚠️ <b>Perlu diperhatikan</b><br />
                Biaya bahan baku meningkat minggu ini
              </div>

              <div
                ref="chatBot3"
                class="mr-auto max-w-[78%] rounded-2xl rounded-bl-sm bg-background/95 border border-border/40 px-4 py-2 text-left leading-relaxed shadow-sm"
              >
                💡 <b>Saran</b><br />
                Cari supplier dengan harga lebih stabil
              </div>
            </div>
          </div>

          <!-- Glow -->
          <div
            class="absolute -top-10 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-primary/25 blur-[120px] -z-10 rounded-full"
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
              Kirim pesan ke WhatsApp, kami proses.
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
            <p class="text-sm text-muted">Bukan cuma laporan, tapi solusi.</p>
          </div>

          <div class="space-y-3 text-center md:text-left">
            <div
              class="w-10 h-10 bg-primary/15 text-primary rounded-lg flex items-center justify-center mx-auto md:mx-0"
            >
              <UIcon name="i-heroicons-gift" class="w-6 h-6" />
            </div>
            <h3 class="font-bold">Minggu Pertama Gratis</h3>
            <p class="text-sm text-muted">Tidak cocok? Tidak perlu lanjut.</p>
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
