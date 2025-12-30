<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from "vue";
import gsap from "gsap";
import { TextPlugin } from "gsap/TextPlugin";
import { ScrollTrigger } from "gsap/ScrollTrigger";

if (process.client) {
  gsap.registerPlugin(TextPlugin, ScrollTrigger);
}

// Refs
const chatUser = ref<HTMLElement | null>(null);
const chatBot1 = ref<HTMLElement | null>(null);
const chatBot2 = ref<HTMLElement | null>(null);
const chatBot3 = ref<HTMLElement | null>(null);
const typingIndicator = ref<HTMLElement | null>(null);
const testimonialSection = ref<HTMLElement | null>(null);
const ctaButton = ref<any>(null);
const bgBlobs = ref<HTMLElement[]>([]);

let ctaIdleTween: gsap.core.Tween | null = null;

onMounted(() => {
  // --- 1. ANIMASI BACKGROUND (Blobs & Parallax) ---
  const blobs = document.querySelectorAll(".bg-blob");
  blobs.forEach((blob, i) => {
    // Gerakan melayang acak
    gsap.to(blob, {
      x: "random(-50, 50)",
      y: "random(-50, 50)",
      duration: "random(10, 20)",
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
    });
  });

  // Mouse Parallax Effect untuk background
  window.addEventListener("mousemove", (e) => {
    const { clientX, clientY } = e;
    const xPos = clientX / window.innerWidth - 0.5;
    const yPos = clientY / window.innerHeight - 0.5;

    blobs.forEach((blob, i) => {
      const speed = (i + 1) * 20;
      gsap.to(blob, {
        x: xPos * speed,
        y: yPos * speed,
        duration: 2,
        ease: "power2.out",
      });
    });
  });

  // --- 2. ANIMASI CHAT MOCKUP (Dengan Typing Indicator) ---
  if (
    chatUser.value &&
    chatBot1.value &&
    chatBot2.value &&
    chatBot3.value &&
    typingIndicator.value
  ) {
    gsap.set(
      [
        chatUser.value,
        chatBot1.value,
        chatBot2.value,
        chatBot3.value,
        typingIndicator.value,
      ],
      {
        opacity: 0,
        y: 15,
      }
    );

    const tl = gsap.timeline({ repeat: -1, repeatDelay: 3 });

    tl
      // A. Tampilkan indicator mengetik dulu
      .to(typingIndicator.value, { opacity: 1, y: 0, duration: 0.3 })
      .to(".dot", { y: -5, stagger: 0.1, repeat: 3, yoyo: true, duration: 0.2 })
      // B. Sembunyikan indicator, munculkan bubble user
      .to(typingIndicator.value, { opacity: 0, duration: 0.2 })
      .to(chatUser.value, { opacity: 1, y: 0, duration: 0.4 })
      .to(chatUser.value, {
        duration: 2,
        ease: "none",
        text: {
          value:
            "Laporan minggu ini 👇<br/>1–7 Januari<br/>Masuk: Rp3.500.000<br/>Keluar: Rp2.100.000",
          delimiter: "",
        },
      })
      // C. Bot Respon
      .to(chatBot1.value, {
        opacity: 1,
        y: 0,
        duration: 0.5,
        ease: "back.out(1.4)",
        delay: 0.5,
      })
      .to(chatBot2.value, {
        opacity: 1,
        y: 0,
        duration: 0.5,
        ease: "back.out(1.4)",
        delay: 0.2,
      })
      .to(chatBot3.value, {
        opacity: 1,
        y: 0,
        duration: 0.5,
        ease: "back.out(1.4)",
        delay: 0.2,
      })
      // D. Reset
      .to([chatUser.value, chatBot1.value, chatBot2.value, chatBot3.value], {
        opacity: 0,
        y: -10,
        duration: 0.5,
        delay: 4,
        stagger: 0.1,
      });
  }

  // --- 3. ANIMASI CTA BUTTON ---
  if (ctaButton.value) {
    const btnEl = ctaButton.value.$el;
    ctaIdleTween = gsap.to(btnEl, {
      y: -6,
      duration: 1.5,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
    });

    btnEl.addEventListener("mouseenter", () => {
      ctaIdleTween?.pause();
      gsap.to(btnEl, {
        scale: 1.1,
        duration: 0.8,
        ease: "elastic.out(1, 0.5)",
        y: 0,
      });
    });
    btnEl.addEventListener("mouseleave", () => {
      gsap.to(btnEl, {
        scale: 1,
        duration: 0.3,
        onComplete: () => ctaIdleTween?.resume(),
      });
    });
  }

  // --- 4. TESTIMONI & COUNTER (SAMA) ---
  const ctx = gsap.context(() => {
    gsap.from(".testi-card", {
      scrollTrigger: { trigger: ".testi-grid", start: "top 85%" },
      y: 60,
      opacity: 0,
      duration: 0.8,
      stagger: 0.15,
      ease: "back.out(1.2)",
    });

    const stats = document.querySelectorAll(".stat-number");
    stats.forEach((stat) => {
      const target = parseInt(stat.getAttribute("data-target") || "0");
      const suffix = stat.getAttribute("data-suffix") || "";
      gsap.fromTo(
        stat,
        { innerText: 0 },
        {
          scrollTrigger: { trigger: stat, start: "top 90%" },
          innerText: target,
          duration: 2,
          snap: { innerText: 1 },
          onUpdate: function () {
            stat.innerHTML =
              new Intl.NumberFormat("id-ID").format(
                Math.ceil(Number(stat.innerText))
              ) + suffix;
          },
        }
      );
    });
  }, testimonialSection.value as HTMLElement);
});

onBeforeUnmount(() => {
  ScrollTrigger.getAll().forEach((t) => t.kill());
  ctaIdleTween?.kill();
});

const openWa = () => {
  window.open(`https://wa.me/62895413111053`, "_blank");
};
</script>

<template>
  <div
    class="relative min-h-screen overflow-hidden bg-background text-foreground selection:bg-primary/30"
  >
    <div class="absolute inset-0 -z-10 overflow-hidden pointer-events-none">
      <div
        class="bg-blob absolute top-[10%] left-[10%] w-72 h-72 bg-primary/10 blur-[100px] rounded-full"
      ></div>
      <div
        class="bg-blob absolute bottom-[20%] right-[10%] w-96 h-96 bg-emerald-500/10 blur-[120px] rounded-full"
      ></div>
      <div
        class="bg-blob absolute top-[40%] left-[50%] w-64 h-64 bg-blue-500/10 blur-[80px] rounded-full"
      ></div>
    </div>

    <main class="max-w-4xl mx-auto px-6 pt-16 pb-20 text-center relative z-10">
      <section class="space-y-6">
        <UBadge
          color="success"
          variant="soft"
          size="lg"
          class="rounded-full px-4 border border-success/20 animate-pulse"
        >
          Satu-satunya Pendamping Keuangan UMKM via WA
        </UBadge>

        <h1
          class="text-5xl md:text-7xl font-extrabold tracking-tight leading-tight"
        >
          Bisnis Makin
          <span class="text-primary relative inline-block"
            >Rapi
            <svg
              class="absolute -bottom-2 left-0 w-full"
              height="8"
              viewBox="0 0 100 8"
              preserveAspectRatio="none"
            >
              <path
                d="M0 7C30 7 70 2 100 2"
                stroke="currentColor"
                stroke-width="4"
                fill="none"
                class="opacity-30"
              />
            </svg>
          </span>
          <br />
          Cukup Lewat WhatsApp
        </h1>

        <p class="text-lg text-muted max-w-xl mx-auto leading-relaxed">
          Ubah chat sederhana jadi laporan keuangan profesional. <br />
          Dapatkan saran bisnis mingguan layaknya punya konsultan pribadi.
        </p>

        <div class="pt-4">
          <UButton
            ref="ctaButton"
            size="xl"
            color="primary"
            icon="i-simple-icons-whatsapp"
            class="px-10 py-4 text-lg rounded-full shadow-2xl shadow-primary/40"
            @click="openWa"
          >
            Mulai Sekarang — Gratis 7 Hari
          </UButton>
        </div>
      </section>

      <section class="mt-20 relative flex justify-center">
        <div
          class="relative z-10 w-full max-w-[450px] min-h-[420px] rounded-3xl overflow-hidden bg-background/40 backdrop-blur-xl border border-white/10 shadow-[0_50px_100px_-20px_rgba(0,0,0,0.3)]"
        >
          <div
            class="flex items-center gap-3 px-6 py-4 border-b border-white/5 bg-white/5"
          >
            <div
              class="w-10 h-10 rounded-full bg-emerald-500 flex items-center justify-center text-white font-bold shadow-lg"
            >
              L
            </div>
            <div class="text-left">
              <div class="text-sm font-bold tracking-wide">Laporku AI</div>
              <div class="text-[10px] text-emerald-400 flex items-center gap-1">
                <span
                  class="w-1.5 h-1.5 bg-emerald-400 rounded-full animate-ping"
                ></span>
                Online
              </div>
            </div>
          </div>

          <div
            class="absolute inset-x-0 bottom-0 top-[72px] flex flex-col justify-end px-6 pb-6 space-y-4 text-sm"
          >
            <div
              ref="typingIndicator"
              class="mr-auto bg-white/10 px-4 py-3 rounded-2xl flex gap-1 items-center"
            >
              <span class="dot w-1.5 h-1.5 bg-white/40 rounded-full"></span>
              <span class="dot w-1.5 h-1.5 bg-white/40 rounded-full"></span>
              <span class="dot w-1.5 h-1.5 bg-white/40 rounded-full"></span>
            </div>

            <div
              ref="chatUser"
              class="ml-auto max-w-[85%] rounded-2xl rounded-br-none bg-primary text-primary-foreground px-4 py-3 text-left shadow-lg"
            ></div>

            <div
              ref="chatBot1"
              class="mr-auto max-w-[85%] rounded-2xl rounded-bl-none bg-white/10 border border-white/10 px-4 py-3 text-left backdrop-blur-md"
            >
              📊 <b>Ringkasan Terkirim!</b><br />Untung Bersih: Rp1.400.000
            </div>
            <div
              ref="chatBot2"
              class="mr-auto max-w-[85%] rounded-2xl rounded-bl-none bg-white/10 border border-white/10 px-4 py-3 text-left backdrop-blur-md"
            >
              💡 <b>Saran Bisnis:</b><br />Stok bahan baku sebelum hari Jumat
              untuk hemat 5%.
            </div>
          </div>
        </div>

        <div
          class="absolute -top-20 left-1/2 -translate-x-1/2 w-full max-w-[600px] h-[400px] bg-primary/20 blur-[120px] -z-10 rounded-full"
        />
      </section>

      <section ref="testimonialSection" class="mt-32">
        <div class="mb-16">
          <h2 class="text-3xl font-bold">Dipercaya Ratusan UMKM Lokal</h2>
          <div class="h-1 w-20 bg-primary mx-auto mt-4 rounded-full"></div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-8 testi-grid">
          <UCard
            v-for="(testi, i) in testimonials"
            :key="i"
            class="testi-card border-white/5 bg-white/5 backdrop-blur-sm hover:bg-white/10 transition-colors"
          >
            <div class="space-y-4 py-2">
              <div class="flex flex-col items-center gap-1">
                <span class="font-bold text-lg">{{ testi.name }}</span>
                <span
                  class="text-xs text-primary/80 uppercase tracking-widest"
                  >{{ testi.business }}</span
                >
              </div>
              <p class="text-sm leading-relaxed opacity-80 italic">
                "{{ testi.quote }}"
              </p>
              <div
                class="pt-4 border-t border-white/5 flex justify-between items-center text-[10px] text-muted-foreground uppercase tracking-tighter"
              >
                <span>{{ testi.location }}</span>
                <div class="flex text-warning">
                  <UIcon
                    v-for="s in 5"
                    :key="s"
                    name="i-heroicons-star-solid"
                    class="w-3 h-3"
                  />
                </div>
              </div>
            </div>
          </UCard>
        </div>

        <div
          class="mt-24 grid grid-cols-2 md:grid-cols-4 gap-12 bg-white/5 p-10 rounded-3xl border border-white/5"
        >
          <div v-for="stat in stats" :key="stat.label">
            <div
              class="text-4xl font-black text-primary stat-number"
              :data-target="stat.val"
              :data-suffix="stat.suffix"
            >
              0
            </div>
            <div
              class="text-xs text-muted-foreground mt-2 uppercase tracking-widest font-medium"
            >
              {{ stat.label }}
            </div>
          </div>
        </div>
      </section>
    </main>

    <footer
      class="py-12 border-t border-white/5 text-center text-muted-foreground text-xs tracking-widest"
    >
      &copy; 2025 LAPORKU • SIMPLE & ELEGANT BUSINESS SOLUTION
    </footer>
  </div>
</template>

<script lang="ts">
const testimonials = [
  {
    name: "Bu Rahmah",
    business: "Warung Nasi Kuning",
    quote:
      "Dulu bingung untung lari kemana. Sekarang tiap minggu dapat laporan rapi di WA.",
    location: "Banjarmasin",
  },
  {
    name: "Ibu Hamdallah",
    business: "Cemilan Pisang",
    quote:
      "Inputnya gampang banget, tinggal ketik kayak chat biasa. Sangat terbantu!",
    location: "Banjarmasin",
  },
  {
    name: "Ibu Rina",
    business: "Soto Kuin Apung",
    quote:
      "Saran strateginya jitu! Saya jadi berani stok barang lebih banyak saat murah.",
    location: "Muara Teweh",
  },
];
const stats = [
  { val: 100, suffix: "+", label: "UMKM Aktif" },
  { val: 500, suffix: "+", label: "Laporan Terproses" },
  { val: 98, suffix: "%", label: "Kepuasan User" },
  { val: 30, suffix: "%", label: "Kenaikan Profit" },
];
</script>

<style scoped>
.bg-blob {
  will-change: transform;
}
.dot {
  display: inline-block;
}
</style>
