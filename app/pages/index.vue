<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from "vue";
import gsap from "gsap";
import { TextPlugin } from "gsap/TextPlugin";
import { ScrollTrigger } from "gsap/ScrollTrigger";

// Register plugin hanya di client side
if (process.client) {
  gsap.registerPlugin(TextPlugin, ScrollTrigger);
}
const testiWrapper = ref<HTMLElement | null>(null);
const testiTrack = ref<HTMLElement | null>(null);
let testiIndex = 0;
let testiTl: gsap.core.Tween | null = null;

const testimonialSection = ref<HTMLElement | null>(null);
const chatUser = ref<HTMLElement | null>(null);
const chatBot1 = ref<HTMLElement | null>(null);
const chatBot2 = ref<HTMLElement | null>(null);
const chatBot3 = ref<HTMLElement | null>(null);
const waImage = ref<HTMLElement | null>(null); // Ref baru untuk gambar WA
const pricingSection = ref<HTMLElement | null>(null);

const testimonials = [
  {
    name: "Pa Rahman",
    business: "Warung Maju",
    quote:
      "Untung saya naik 3x lipat! Dari awalnya bingung, sekarang jelas kemana uang mengalir. Laporan mingguannya membantu banget buat ambil keputusan stok.",
    location: "Banjarmasin",
    profit: "Rp 3.900.000",
  },
  {
    name: "Pak Andi",
    business: "Toko Sumber Rezeki",
    quote:
      "Setelah pakai Laporku, saya tahu kapan harus beli stok dan kapan harus hemat. Profit meningkat stabil setiap minggu.",
    location: "Banjarmasin",
    profit: "Rp 3.100.000",
  },
  {
    name: "Pak Budi",
    business: "Warung Pak Budi",
    quote:
      "Gampang banget inputnya, tinggal chat aja. Laporan lengkap langsung dikirim. Anak saya yang bantu juga ngerti cara pakainya.",
    location: "Muara Teweh",
    profit: "Rp 2.500.000",
  },
  {
    name: "Mbak Hamdallah",
    business: "Pisang Keju Kaca HKSN",
    quote:
      "Baru coba trial udah langsung keliatan hasilnya. Sekarang tau persis untung bersih tiap minggu. Recommended!",
    location: "Banjarmasin",
    profit: "Rp 150.000",
  },
  {
    name: "Bu Sari",
    business: "Toko Hj Norma",
    quote:
      "Sempat rugi di awal, tapi berkat saran dari Laporku, sekarang udah mulai naik lagi. Terima kasih supportnya!",
    location: "Palangkaraya",
    profit: "Lagi perbaikan",
  },
  {
    name: "Ibu Fatimah",
    business: "Kue Basah Bu Fat",
    quote:
      "Dulu cuma pencatat di buku, sering keselip. Sekarang rapi semua di HP, bisa lihat history kapan aja.",
    location: "Banjarmasin",
    profit: "Rp 1.500.000",
  },
];

const stats = [
  { val: 100, suffix: "+", label: "UMKM Aktif" },
  { val: 500, suffix: "+", label: "Laporan Terproses" },
  { val: 98, suffix: "%", label: "Kepuasan User" },
  { val: 30, suffix: "%", label: "Kenaikan Profit" },
];

const pricingPlans = [
  {
    name: "Trial",
    price: "GRATIS",
    period: "2 Minggu Pertama",
    features: [
      "Laporan mingguan via WhatsApp",
      "Ringkasan untung/rugi",
      "Saran bisnis dasar",
      "Support chat",
    ],
    highlight: false,
    cta: "Coba Gratis",
  },
  {
    name: "Bulanan",
    price: "50K",
    period: "per bulan",
    features: [
      "Semua fitur Trial",
      "Analisis tren bulanan",
      "Rekomendasi strategi",
      "Priority support",
      "Export data Excel",
    ],
    highlight: true,
    popular: true,
    cta: "Mulai Berlangganan",
  },
  {
    name: "Mingguan",
    price: "15K",
    period: "per minggu",
    features: [
      "Laporan mingguan via WhatsApp",
      "Ringkasan untung/rugi",
      "Saran bisnis praktis",
      "Support chat",
    ],
    highlight: false,
    cta: "Pilih Paket Ini",
  },
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
        "+=0.5",
      )
      .to(
        chatBot2.value,
        { opacity: 1, y: 0, duration: 0.5, ease: "back.out(1.7)" },
        "-=0.2",
      )
      .to(
        chatBot3.value,
        { opacity: 1, y: 0, duration: 0.5, ease: "back.out(1.7)" },
        "-=0.2",
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

    // Animasi Pricing Cards
    gsap.from(".pricing-card", {
      scrollTrigger: { trigger: ".pricing-grid", start: "top 85%" },
      y: 60,
      opacity: 0,
      duration: 0.8,
      stagger: 0.2,
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
                Math.ceil(Number(stat.innerText)),
              ) + suffix;
          },
        },
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

const openWa = (plan?: string) => {
  const no = "62895413111053";
  let msg =
    "Halo, admin Laporku. Saya ingin bertanya tentang berlangganan atau ingin meminta bantuan lainnya. Bisa dibantu?";

  if (plan) {
    msg = `Halo admin Laporku, saya tertarik dengan paket ${plan}. Bisa dibantu untuk proses selanjutnya?`;
  }

  window.open(`https://wa.me/${no}?text=${encodeURIComponent(msg)}`, "_blank");
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
        class="absolute opacity-20 w-[800px] max-w-none transition-opacity duration-100"
        alt=""
      />
      <div
        class="absolute bottom-0 w-full h-1/2 bg-gradient-to-t from-background to-transparent"
      ></div>
    </div>

    <main class="max-w-4xl mx-auto px-4 md:px-6 text-center relative z-10">
      <Transition name="fade-up" appear>
        <section class="pt-6 md:pt-0">
          <UBadge
            color="success"
            variant="soft"
            size="lg"
            class="rounded-full mt-2 text-[10px] md:text-sm px-3 md:px-4 py-1 border border-success/20 animate-pulse"
          >
            Pendamping Keuangan UMKM via WA
          </UBadge>

          <h1
            class="text-3xl md:text-7xl font-extrabold tracking-tight leading-tight mt-4"
          >
            Kelola
            <span class="text-primary relative inline-block"
              >Untung
              <svg
                class="absolute -bottom-1 md:-bottom-2 left-0 w-full"
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
            class="mt-4 md:mt-6 text-sm md:text-lg text-muted max-w-2xl mx-auto leading-relaxed px-2"
          >
            Kirim data sederhana, dapat ringkasan dan saran bisnis setiap
            minggu.
          </p>

          <div class="pt-6 md:pt-4">
            <UButton
              ref="ctaButton"
              size="xl"
              color="primary"
              class="px-6 md:px-10 py-3 md:py-4 text-sm md:text-lg rounded-2xl shadow-2xl shadow-primary/40"
              @click="openWa()"
            >
              <img src="/images/wabold.gif" class="w-10" alt="" />
              Mulai Sekarang — Gratis 2 Minggu
            </UButton>
          </div>
        </section>
      </Transition>

      <!-- CHAT DEMO SECTION -->
      <Transition name="fade-up" appear>
        <section class="mt-8 md:mt-14 relative flex justify-center px-2">
          <div
            class="relative z-10 w-full max-w-[500px] md:min-h-[460px] min-h-[520px] rounded-2xl overflow-hidden bg-gradient-to-br from-background/90 to-background/70 backdrop-blur-md shadow-[0_30px_80px_-30px_RGBA(0,0,0,0.5)] border border-border/40"
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

      <!-- NEW FEATURE: PORTAL CLIENT -->
      <Transition name="fade-up" appear>
        <section class="mt-16 md:mt-32 px-2">
          <!-- Gunakan style yang sama dengan Pricing/Testimonial (glassmorphism) agar senada -->
          <div class="relative rounded-3xl overflow-hidden border border-white/10 bg-white/5 backdrop-blur-md p-8 md:p-12 text-left shadow-2xl">
            <!-- Background Glow halus -->
            <div class="absolute top-0 right-0 w-64 h-64 bg-primary/10 blur-[80px] rounded-full -z-10"></div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
              <div>
                <UBadge
                  color="primary"
                  variant="subtle"
                  size="md"
                  class="rounded-full px-3 py-1 text-[10px] font-bold mb-4"
                >
                  FITUR BARU 🚀
                </UBadge>
                <h2 class="text-2xl md:text-4xl font-bold text-foreground mb-4 leading-tight">
                  Pantau Bisnis <br/> <span class="text-primary">Kapan Saja</span>
                </h2>
                <p class="text-muted-foreground text-sm md:text-base leading-relaxed mb-6">
                  Tidak perlu tunggu balasan admin. Cek laporan keuangan, riwayat pembayaran, dan data hutang pelanggan langsung dari HP Anda.
                </p>
                
                <div class="space-y-4">
                  <div class="flex items-center gap-3 text-foreground/90 text-sm">
                    <div class="p-2 rounded-lg bg-primary/10">
                      <UIcon name="i-heroicons-chart-bar" class="w-5 h-5 text-primary" />
                    </div>
                    <span>Grafik Untung/Rugi Real-time</span>
                  </div>
                  <div class="flex items-center gap-3 text-foreground/90 text-sm">
                     <div class="p-2 rounded-lg bg-primary/10">
                      <UIcon name="i-heroicons-document-arrow-down" class="w-5 h-5 text-primary" />
                    </div>
                    <span>Download Laporan Excel</span>
                  </div>
                   <div class="flex items-center gap-3 text-foreground/90 text-sm">
                     <div class="p-2 rounded-lg bg-primary/10">
                      <UIcon name="i-heroicons-link" class="w-5 h-5 text-primary" />
                     </div>
                    <span>Akses Mudah via Link (Tanpa Login)</span>
                  </div>
                </div>

                <div class="mt-8">
                  <UButton
                    size="xl"
                    color="primary"
                    variant="solid"
                    class="rounded-xl font-bold px-8 shadow-lg shadow-primary/20"
                    @click="openWa('Portal Client')"
                  >
                    Tanya Fitur Portal
                  </UButton>
                </div>
              </div>

              <!-- Visual mock yang lebih simple dan clean -->
              <div class="relative mt-8 md:mt-0">
                <div class="absolute inset-0 bg-primary/20 blur-2xl rounded-full transform rotate-6 scale-90"></div>
                <!-- Card Portal Preview -->
                <div class="relative bg-background border border-border/50 rounded-2xl p-5 shadow-2xl rotate-1 hover:rotate-0 transition-all duration-500 max-w-sm mx-auto">
                   <!-- Fake Header -->
                  <div class="flex items-center justify-between mb-6 pb-4 border-b border-border/50">
                    <div class="flex items-center gap-3">
                       <div class="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center">
                         <UIcon name="i-heroicons-building-storefront" class="w-4 h-4 text-primary" />
                       </div>
                       <div>
                         <div class="h-2 w-20 bg-foreground/20 rounded mb-1"></div>
                         <div class="h-1.5 w-12 bg-muted-foreground/20 rounded"></div>
                       </div>
                    </div>
                    <div class="h-6 w-16 bg-primary/10 rounded-full"></div>
                  </div>
                  
                  <!-- Fake Stats -->
                  <div class="grid grid-cols-2 gap-3 mb-6">
                    <div class="bg-primary/5 rounded-xl p-3 border border-primary/10">
                      <div class="h-1.5 w-16 bg-primary/30 rounded mb-2"></div>
                      <div class="h-4 w-20 bg-primary rounded"></div>
                    </div>
                     <div class="bg-muted/5 rounded-xl p-3 border border-border/30">
                      <div class="h-1.5 w-16 bg-muted-foreground/30 rounded mb-2"></div>
                      <div class="h-4 w-10 bg-foreground/50 rounded"></div>
                    </div>
                  </div>

                  <!-- Fake Chart -->
                  <div class="bg-muted/5 rounded-xl p-4 border border-border/30 h-32 flex items-end justify-between gap-1">
                      <div class="w-full bg-primary/20 rounded-t h-[40%]"></div>
                      <div class="w-full bg-primary/30 rounded-t h-[60%]"></div>
                      <div class="w-full bg-primary/40 rounded-t h-[30%]"></div>
                      <div class="w-full bg-primary/60 rounded-t h-[70%]"></div>
                      <div class="w-full bg-primary rounded-t h-[50%] relative">
                        <div class="absolute -top-6 left-1/2 -translate-x-1/2 bg-foreground text-background text-[8px] py-0.5 px-1.5 rounded font-bold">
                          1.5jt
                        </div>
                      </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </Transition>

      <!-- PRICING SECTION -->
      <Transition name="fade-up" appear>
        <section ref="pricingSection" class="mt-16 md:mt-32 px-2">
          <div class="mb-8 md:mb-12 text-center">
            <h2 class="text-2xl md:text-3xl font-bold">
              Pilih Paket yang Sesuai
            </h2>
            <p class="text-sm md:text-base text-muted mt-2">
              Mulai gratis, lanjut dengan harga terjangkau
            </p>
            <div class="h-1 w-20 bg-primary mx-auto mt-4 rounded-full"></div>
          </div>

          <div
            class="grid grid-cols-1 md:grid-cols-3 gap-6 md:gap-8 pricing-grid"
          >
            <UCard
              v-for="(plan, i) in pricingPlans"
              :key="i"
              class="pricing-card relative border-white/5 bg-white/5 backdrop-blur-sm hover:bg-white/10 transition-all duration-300"
              :class="{
                'border-primary border-2 shadow-2xl shadow-primary/20 scale-105':
                  plan.highlight,
                'hover:scale-105': !plan.highlight,
              }"
            >
              <div
                v-if="plan.popular"
                class="absolute -top-0.5 pt-2 left-1/2 -translate-x-1/2"
              >
                <UBadge
                  color="primary"
                  variant="solid"
                  size="sm"
                  class="rounded-full px-3 py-1 text-[10px] font-bold"
                >
                  PALING POPULER
                </UBadge>
              </div>

              <div class="space-y-4 md:space-y-6 py-4">
                <div class="text-center">
                  <h3 class="text-lg md:text-xl font-bold text-foreground mb-2">
                    {{ plan.name }}
                  </h3>
                  <div class="flex items-baseline justify-center gap-1">
                    <span class="text-3xl md:text-5xl font-black text-primary">
                      {{ plan.price }}
                    </span>
                  </div>
                  <p
                    class="text-[10px] md:text-xs text-muted-foreground mt-1 uppercase tracking-wider"
                  >
                    {{ plan.period }}
                  </p>
                </div>

                <div class="space-y-2.5 md:space-y-3 px-2">
                  <div
                    v-for="(feature, idx) in plan.features"
                    :key="idx"
                    class="flex items-start gap-2 text-left"
                  >
                    <UIcon
                      name="i-heroicons-check-circle-solid"
                      class="w-4 h-4 md:w-5 md:h-5 text-success shrink-0 mt-0.5"
                    />
                    <span class="text-xs md:text-sm text-foreground/90">
                      {{ feature }}
                    </span>
                  </div>
                </div>

                <div class="pt-4">
                  <UButton
                    :color="plan.highlight ? 'primary' : 'white'"
                    :variant="plan.highlight ? 'solid' : 'outline'"
                    size="lg"
                    block
                    class="rounded-xl font-semibold"
                    @click="openWa(plan.name)"
                  >
                    {{ plan.cta }}
                  </UButton>
                </div>
              </div>
            </UCard>
          </div>

          <div class="mt-8 text-center">
            <p class="text-xs md:text-sm text-muted-foreground">
              💡 <b>Tips:</b> Paket bulanan lebih hemat Rp10.000 dibanding bayar
              mingguan
            </p>
          </div>
        </section>
      </Transition>

      <!-- TESTIMONIAL SECTION -->
      <Transition name="fade-up" appear>
        <section ref="testimonialSection" class="mt-16 md:mt-32">
          <div class="mb-8 md:mb-16 text-center px-2">
            <h2 class="text-2xl md:text-3xl font-bold">
              Dipercaya Ratusan UMKM Lokal
            </h2>
            <div class="h-1 w-20 bg-primary mx-auto mt-4 rounded-full"></div>
          </div>

          <!-- Mobile: Grid biasa, Desktop: Carousel -->
          <div class="block md:hidden px-2">
            <div class="grid grid-cols-1 gap-4 testi-grid">
              <UCard
                v-for="(testi, i) in testimonials.slice(0, 3)"
                :key="i"
                class="testi-card border-white/5 bg-white/5 backdrop-blur-sm hover:bg-white/10 transition-colors"
              >
                <div class="space-y-3 py-2">
                  <div class="flex flex-col items-center gap-1 text-center">
                    <span class="font-bold text-base text-foreground">
                      {{ testi.name }}
                    </span>
                    <span
                      class="text-[10px] text-primary/80 uppercase tracking-widest"
                    >
                      {{ testi.business }}
                    </span>
                  </div>
                  <p
                    class="text-xs leading-relaxed opacity-80 italic text-center"
                  >
                    "{{ testi.quote }}"
                  </p>
                  <div class="pt-3 border-t border-border/40">
                    <div
                      class="flex justify-between items-center text-[9px] text-muted-foreground uppercase tracking-tighter mb-2"
                    >
                      <span>📍 {{ testi.location }}</span>
                      <div class="flex text-warning">
                        <UIcon
                          v-for="s in 5"
                          :key="s"
                          name="i-heroicons-star-solid"
                          class="w-2.5 h-2.5"
                        />
                      </div>
                    </div>
                    <div class="text-center">
                      <span class="text-xs font-semibold text-success">
                        💰 {{ testi.profit }}
                      </span>
                    </div>
                  </div>
                </div>
              </UCard>
            </div>
          </div>

          <!-- Desktop: Carousel -->
          <div class="hidden md:block px-2">
            <UCarousel
              v-slot="{ item }"
              :items="testimonials"
              :ui="{
                item: 'basis-1/3',
                container: 'gap-6',
              }"
              class="testi-carousel"
              loop
              :autoplay="{ delay: 2000 }"
            >
              <UCard
                class="border-white/5 bg-white/5 backdrop-blur-sm hover:bg-white/10 transition-all duration-300 h-full"
              >
                <div class="space-y-4 py-2">
                  <div class="flex flex-col items-center gap-1 text-center">
                    <span class="font-bold text-lg text-foreground">
                      {{ item.name }}
                    </span>
                    <span
                      class="text-xs text-primary/80 uppercase tracking-widest"
                    >
                      {{ item.business }}
                    </span>
                  </div>
                  <p
                    class="text-sm leading-relaxed opacity-80 italic text-center min-h-[100px]"
                  >
                    "{{ item.quote }}"
                  </p>
                  <div class="pt-4 border-t border-border/40">
                    <div
                      class="flex justify-between items-center text-[10px] text-muted-foreground uppercase tracking-tighter mb-2"
                    >
                      <span>📍 {{ item.location }}</span>
                      <div class="flex text-warning">
                        <UIcon
                          v-for="s in 5"
                          :key="s"
                          name="i-heroicons-star-solid"
                          class="w-3 h-3"
                        />
                      </div>
                    </div>
                    <div class="text-center">
                      <span class="text-xs font-semibold text-success">
                        💰 {{ item.profit }}
                      </span>
                    </div>
                  </div>
                </div>
              </UCard>
            </UCarousel>
          </div>

          <div
            class="mt-12 md:mt-20 grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-8 bg-white/5 p-6 md:p-10 rounded-3xl border border-white/5 mx-2"
          >
            <div v-for="stat in stats" :key="stat.label">
              <div
                class="text-2xl md:text-4xl font-black text-primary stat-number"
                :data-target="stat.val"
                :data-suffix="stat.suffix"
              >
                0
              </div>
              <div
                class="text-[9px] md:text-xs text-muted-foreground mt-1 md:mt-2 uppercase tracking-widest font-medium"
              >
                {{ stat.label }}
              </div>
            </div>
          </div>
        </section>
      </Transition>

      

      <Transition name="fade-up" appear>
        <section
          class="mt-12 md:mt-24 grid grid-cols-1 md:grid-cols-3 gap-6 md:gap-12 text-left px-2"
        >
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

    <footer
      class="py-8 md:py-12 mt-12 md:mt-0 border-t border-white/5 text-center text-muted-foreground text-[10px] md:text-xs tracking-widest"
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
