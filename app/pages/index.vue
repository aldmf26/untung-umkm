<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from "vue";
import gsap from "gsap";
import { TextPlugin } from "gsap/TextPlugin";
import { ScrollTrigger } from "gsap/ScrollTrigger";

// Register plugin hanya di client side
if (process.client) {
  gsap.registerPlugin(TextPlugin, ScrollTrigger);
}

const testimonialSection = ref<HTMLElement | null>(null);
const chatUser = ref<HTMLElement | null>(null);
const chatBot1 = ref<HTMLElement | null>(null);
const chatBot2 = ref<HTMLElement | null>(null);
const chatBot3 = ref<HTMLElement | null>(null);
const waImage = ref<HTMLElement | null>(null); // Ref baru untuk gambar WA

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

// Mouse reactive logic
const mouseX = ref(0);
const mouseY = ref(0);

const onMouseMove = (e: MouseEvent) => {
  // Simpan nilai untuk parallax
  mouseX.value = e.clientX / window.innerWidth - 0.5;
  mouseY.value = e.clientY / window.innerHeight - 0.5;

  // Efek Parallax halus pada Gambar WA
  if (waImage.value) {
    gsap.to(waImage.value, {
      x: mouseX.value * 40,
      y: mouseY.value * 40,
      duration: 2,
      ease: "power2.out",
    });
  }
};

onMounted(() => {
  window.addEventListener("mousemove", onMouseMove);

  // --- 1. ANIMASI FLOATING GAMBAR WA (Wow Factor) ---
  if (waImage.value) {
    gsap.to(waImage.value, {
      y: "-=20",
      duration: 3,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
    });
  }

  // --- 2. ANIMASI CHAT USER (Professional Loop) ---
  if (chatUser.value && chatBot1.value && chatBot2.value && chatBot3.value) {
    const tl = gsap.timeline({
      repeat: -1,
      repeatDelay: 2,
    });

    tl.set([chatUser.value, chatBot1.value, chatBot2.value, chatBot3.value], {
      opacity: 0,
      y: 12,
    })
      .set(chatUser.value, { text: "" }) // Kosongkan teks sebelum mulai ketik

      // User Mengetik
      .to(chatUser.value, {
        opacity: 1,
        y: 0,
        duration: 0.4,
      })
      .to(chatUser.value, {
        duration: 2.5,
        text: {
          value:
            "Laporan minggu ini 👇<br/>1–7 Januari<br/>Masuk: Rp3.500.000<br/>Keluar: Rp2.100.000",
        },
        ease: "none",
      })

      // Bot Membalas berurutan dengan efek "pop"
      .to(
        chatBot1.value,
        { opacity: 1, y: 0, duration: 0.5, ease: "back.out(1.7)" },
        "+=0.5"
      )
      .to(
        chatBot2.value,
        { opacity: 1, y: 0, duration: 0.5, ease: "back.out(1.7)" },
        "-=0.2"
      )
      .to(
        chatBot3.value,
        { opacity: 1, y: 0, duration: 0.5, ease: "back.out(1.7)" },
        "-=0.2"
      )

      // Stay sejenak lalu fade out semua
      .to([chatUser.value, chatBot1.value, chatBot2.value, chatBot3.value], {
        opacity: 0,
        y: -10,
        duration: 0.5,
        delay: 4,
      });
  }

  // --- 3. TESTIMONI & COUNTER (ScrollTrigger) ---
  const ctx = gsap.context(() => {
    gsap.from(".testi-card", {
      scrollTrigger: { trigger: ".testi-grid", start: "top 85%" },
      y: 60,
      opacity: 0,
      duration: 0.8,
      stagger: 0.15,
      ease: "back.out(1.2)",
    });

    document.querySelectorAll(".stat-number").forEach((stat) => {
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
  window.removeEventListener("mousemove", onMouseMove);
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

const openWa = () => {
  const no = "62895413111053";
  const msg = encodeURIComponent(
    "Halo, admin Laporku. Saya ingin bertanya tentang berlangganan atau ingin meminta bantuan lainnya. Bisa dibantu?"
  );
  window.open(`https://wa.me/${no}?text=${msg}`, "_blank");
};
</script>

<template>
  <div
    class="relative min-h-screen overflow-hidden bg-background text-foreground"
  >
    <div
      class="absolute inset-0 -z-10 flex items-center justify-center overflow-hidden pointer-events-none"
    >
      <img
        ref="waImage"
        src="/images/wa.webp"
        class="absolute opacity-20 w-[800px] max-w-none lg:bottom-[-10%] md:bottom-[-5%] transition-opacity duration-1000"
        alt=""
      />
      <div
        class="absolute bottom-0 w-full h-1/2 bg-gradient-to-t from-background to-transparent"
      ></div>
    </div>

    <main class="max-w-4xl mx-auto px-6 text-center relative z-10">
      <Transition name="fade-up" appear>
        <section>
          <UBadge
            color="success"
            variant="soft"
            size="lg"
            class="rounded-full hidden md:block px-4 border border-success/20 animate-pulse"
          >
            Satu-satunya Pendamping Keuangan UMKM via WA
          </UBadge>

          <h1
            class="text-4xl md:text-7xl font-extrabold tracking-tight leading-tight"
          >
            Kelola
            <span class="text-primary relative inline-block"
              >Untung
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
            Rugi <br />
            <span>Cukup Lewat WhatsApp</span>
          </h1>

          <p
            class="mt-6 md:text-lg text-sm text-muted max-w-2xl mx-auto leading-relaxed"
          >
            Kirim data sederhana, dapat ringkasan dan saran bisnis setiap
            minggu.
          </p>

          <div class="pt-4">
            <UButton
              ref="ctaButton"
              size="xl"
              color="primary"
              icon="i-simple-icons-whatsapp"
              class="px-10 py-4 md:text-lg text-xs rounded-pointer rounded-2xl shadow-2xl shadow-primary/40"
              @click="openWa"
            >
              Mulai Sekarang — Gratis 7 Hari
            </UButton>
          </div>
        </section>
      </Transition>

      <Transition name="fade-up" appear>
        <section class="mt-14 relative flex justify-center">
          <div
            class="relative z-10 w-full max-w-[500px] md:min-h-[460px] min-h-[500px] rounded-2xl overflow-hidden bg-gradient-to-br from-background/90 to-background/70 backdrop-blur-md shadow-[0_30px_80px_-30px_RGBA(0,0,0,0.5)] border border-border/40"
          >
            <div
              class="flex items-center gap-3 px-4 py-3 border-b border-border/40 bg-background/70"
            >
              <img src="/favicon.ico" class="w-14 h-14 rounded-full" alt="" />
              <div class="text-left leading-tight">
                <div class="text-sm font-semibold text-foreground">Laporku</div>
                <div
                  class="text-[10px] text-emerald-400 flex items-center gap-1"
                >
                  <span
                    class="w-1.5 h-1.5 bg-emerald-400 rounded-full animate-ping"
                  ></span>
                  Online
                </div>
              </div>
            </div>

            <div
              class="absolute inset-x-0 bottom-0 top-[60px] flex flex-col justify-end px-4 pb-6 space-y-3 text-sm"
            >
              <div
                ref="chatUser"
                class="ml-auto max-w-[85%] rounded-2xl rounded-br-sm bg-primary text-primary-foreground px-4 py-2.5 text-left leading-relaxed shadow-md shadow-primary/20 min-h-[40px]"
              ></div>

              <div
                ref="chatBot1"
                class="mr-auto max-w-[80%] rounded-2xl rounded-bl-sm bg-background/95 border border-border/40 px-4 py-2 text-left leading-relaxed shadow-sm"
              >
                📊 <b>Ringkasan Mingguan</b><br />
                <span class="text-success text-lg">Untung: Rp 1.400.000</span>
              </div>

              <div
                ref="chatBot2"
                class="mr-auto max-w-[80%] rounded-2xl rounded-bl-sm bg-background/95 border border-border/40 px-4 py-2 text-left leading-relaxed shadow-sm"
              >
                ⚠️ <b>Perlu diperhatikan</b><br />Biaya bahan baku meningkat
                minggu ini
              </div>

              <div
                ref="chatBot3"
                class="mr-auto max-w-[80%] rounded-2xl rounded-bl-sm bg-background/95 border border-border/40 px-4 py-2 text-left leading-relaxed shadow-sm"
              >
                💡 <b>Saran</b><br />Cari supplier dengan harga lebih stabil
              </div>
            </div>
          </div>

          <div
            class="absolute -top-10 left-1/2 -translate-x-1/2 w-[110%] h-[110%] bg-primary/10 blur-[100px] -z-10 rounded-full"
          />
        </section>
      </Transition>

      <Transition name="fade-up" appear>
        <section ref="testimonialSection" class="mt-32">
          <div class="mb-16 text-center">
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
                <div class="flex flex-col items-center gap-1 text-center">
                  <span class="font-bold text-lg text-foreground">{{
                    testi.name
                  }}</span>
                  <span
                    class="text-xs text-primary/80 uppercase tracking-widest"
                    >{{ testi.business }}</span
                  >
                </div>
                <p
                  class="text-sm leading-relaxed opacity-80 italic text-center"
                >
                  "{{ testi.quote }}"
                </p>
                <div
                  class="pt-4 border-t border-border/40 flex justify-between items-center text-[10px] text-muted-foreground uppercase tracking-tighter"
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
            class="mt-24 grid grid-cols-2 md:grid-cols-4 gap-8 bg-white/5 p-10 rounded-3xl border border-white/5"
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
      </Transition>

      <Transition name="fade-up" appear>
        <section class="mt-24 grid grid-cols-1 md:grid-cols-3 gap-12 text-left">
          <UCard
            class="space-y-3 text-center md:text-left shadow-sm rounded-2xl border border-success"
          >
            <div
              class="w-10 h-10 bg-primary/15 text-primary rounded-lg flex items-center justify-center mx-auto md:mx-0"
            >
              <UIcon name="i-heroicons-bolt" class="w-6 h-6" />
            </div>

            <h3 class="font-bold">Input Cepat</h3>

            <p class="text-sm text-muted">
              Kirim pesan ke WhatsApp, kami proses.
            </p>
          </UCard>

          <UCard
            class="space-y-3 text-center md:text-left shadow-sm rounded-2xl border border-success"
          >
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
          </UCard>

          <UCard
            class="space-y-3 text-center md:text-left shadow-sm rounded-2xl border border-success"
          >
            <div
              class="w-10 h-10 bg-primary/15 text-primary rounded-lg flex items-center justify-center mx-auto md:mx-0"
            >
              <UIcon name="i-heroicons-gift" class="w-6 h-6" />
            </div>

            <h3 class="font-bold">Minggu Pertama Gratis</h3>

            <p class="text-sm text-muted">Tidak cocok? Tidak perlu lanjut.</p>
          </UCard>
        </section>
      </Transition>
    </main>

    <!-- FEATURES -->

    <footer
      class="py-12 border-t border-white/5 text-center text-muted-foreground text-xs tracking-widest"
    >
      &copy; 2025 LAPORKU • SIMPLE BUSINESS SOLUTION
    </footer>
  </div>
</template>

<style>
/* Jangan diubah, ini transisi khas Nuxt kamu */
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

/* Tambahan agar bubble bot awalnya tidak terlihat sebelum timeline jalan */
div[ref="chatBot1"],
div[ref="chatBot2"],
div[ref="chatBot3"] {
  will-change: transform, opacity;
}
</style>
