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
const waImage = ref<HTMLElement | null>(null);
const heroSection = ref<HTMLElement | null>(null);
const chatSection = ref<HTMLElement | null>(null);
const featuresSection = ref<HTMLElement | null>(null);

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

const faqs = [
  {
    question: "Bagaimana cara kerja Laporku?",
    answer:
      "Anda cukup kirim data pemasukan dan pengeluaran via WhatsApp ke nomor kami. Tim kami akan memproses data tersebut dan mengirimkan laporan keuangan lengkap beserta analisis untung rugi dan saran bisnis setiap minggu.",
  },
  {
    question: "Berapa biaya berlangganan Laporku?",
    answer:
      "Kami menawarkan paket mingguan Rp 40.000 atau paket bulanan Rp 120.000. Minggu pertama gratis untuk Anda mencoba layanan kami tanpa risiko.",
  },
  {
    question: "Apakah data keuangan saya aman?",
    answer:
      "Ya, keamanan data adalah prioritas kami. Semua data keuangan Anda dijaga kerahasiaannya dan hanya digunakan untuk membuat laporan keuangan Anda. Kami tidak membagikan data Anda kepada pihak ketiga.",
  },
  {
    question: "Untuk jenis usaha apa saja Laporku cocok?",
    answer:
      "Laporku cocok untuk semua jenis UMKM seperti warung makan, toko kelontong, usaha catering, salon, bengkel, usaha online shop, konveksi, laundry, dan berbagai jenis usaha kecil menengah lainnya.",
  },
  {
    question: "Apakah saya perlu install aplikasi?",
    answer:
      "Tidak perlu! Laporku bekerja sepenuhnya melalui WhatsApp. Anda hanya perlu mengirim pesan seperti chat biasa, tanpa perlu download atau install aplikasi apapun.",
  },
];

// Mouse reactive logic
const mouseX = ref(0);
const mouseY = ref(0);

const onMouseMove = (e: MouseEvent) => {
  mouseX.value = e.clientX / window.innerWidth - 0.5;
  mouseY.value = e.clientY / window.innerHeight - 0.5;

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

  if (waImage.value) {
    gsap.to(waImage.value, {
      y: "-=20",
      duration: 3,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
    });
  }

  if (heroSection.value) {
    gsap.to(heroSection.value, {
      scrollTrigger: {
        trigger: heroSection.value,
        start: "top top",
        end: "bottom top",
        scrub: 1.5,
      },
      y: -150,
      opacity: 0.3,
      ease: "none",
    });
  }

  if (chatSection.value) {
    gsap.to(chatSection.value, {
      scrollTrigger: {
        trigger: chatSection.value,
        start: "top bottom",
        end: "bottom top",
        scrub: 2,
      },
      y: -80,
      ease: "none",
    });
  }

  gsap.utils.toArray(".feature-card").forEach((card: any, i) => {
    gsap.to(card, {
      scrollTrigger: {
        trigger: card,
        start: "top bottom",
        end: "bottom top",
        scrub: 1.5,
      },
      y: -50 * (i + 1) * 0.3,
      ease: "none",
    });
  });

  if (chatUser.value && chatBot1.value && chatBot2.value && chatBot3.value) {
    const tl = gsap.timeline({
      repeat: -1,
      repeatDelay: 2,
    });

    tl.set([chatUser.value, chatBot1.value, chatBot2.value, chatBot3.value], {
      opacity: 0,
      y: 12,
    })
      .set(chatUser.value, { text: "" })
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
      .to([chatUser.value, chatBot1.value, chatBot2.value, chatBot3.value], {
        opacity: 0,
        y: -10,
        duration: 0.5,
        delay: 4,
      });
  }

  const ctx = gsap.context(() => {
    gsap.from(".testi-card", {
      scrollTrigger: {
        trigger: ".testi-grid",
        start: "top 85%",
        toggleActions: "play none none reverse",
      },
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
          scrollTrigger: {
            trigger: stat,
            start: "top 90%",
            toggleActions: "play none none reverse",
            onEnter: () => {
              gsap.fromTo(
                stat,
                { innerText: 0 },
                {
                  innerText: target,
                  duration: 2,
                  snap: { innerText: 1 },
                  ease: "power2.out",
                  onUpdate: function () {
                    stat.innerHTML =
                      new Intl.NumberFormat("id-ID").format(
                        Math.ceil(Number(stat.innerText))
                      ) + suffix;
                  },
                }
              );
            },
            onLeaveBack: () => {
              stat.innerHTML = "0" + suffix;
            },
          },
        }
      );
    });

    gsap.to(".testi-grid", {
      scrollTrigger: {
        trigger: ".testi-grid",
        start: "top bottom",
        end: "bottom top",
        scrub: 1,
      },
      y: -30,
      ease: "none",
    });
  }, testimonialSection.value as HTMLElement);
});

onBeforeUnmount(() => {
  window.removeEventListener("mousemove", onMouseMove);
  ScrollTrigger.getAll().forEach((trigger) => trigger.kill());
});

// SEO Meta Tags
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

useHead({
  htmlAttrs: {
    lang: "id",
  },
  link: [
    {
      rel: "canonical",
      href: "https://laporku.vercel.app",
    },
  ],
});

// Schema.org Structured Data
useSchemaOrg([
  {
    "@type": "SoftwareApplication",
    name: "Laporku",
    applicationCategory: "FinanceApplication",
    operatingSystem: "Web, WhatsApp",
    offers: {
      "@type": "AggregateOffer",
      lowPrice: "40000",
      highPrice: "120000",
      priceCurrency: "IDR",
      offerCount: "2",
    },
    aggregateRating: {
      "@type": "AggregateRating",
      ratingValue: "4.9",
      ratingCount: "100",
    },
    description:
      "Aplikasi laporan keuangan UMKM via WhatsApp untuk pelaku usaha kecil menengah",
  },
  {
    "@type": "Organization",
    name: "Laporku",
    url: "https://laporku.vercel.app",
    logo: "https://laporku.vercel.app/favicon.ico",
    contactPoint: {
      "@type": "ContactPoint",
      telephone: "+62-895-4131-11053",
      contactType: "Customer Service",
      availableLanguage: "Indonesian",
    },
    sameAs: [],
  },
  {
    "@type": "FAQPage",
    mainEntity: faqs.map((faq) => ({
      "@type": "Question",
      name: faq.question,
      acceptedAnswer: {
        "@type": "Answer",
        text: faq.answer,
      },
    })),
  },
]);

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
        class="absolute opacity-20 w-[800px] max-w-none transition-opacity duration-100"
        alt="WhatsApp Background"
      />
      <div
        class="absolute bottom-0 w-full h-1/2 bg-gradient-to-t from-background to-transparent"
      ></div>
    </div>

    <main class="max-w-4xl mx-auto px-4 md:px-6 text-center relative z-10">
      <Transition name="fade-up" appear>
        <section ref="heroSection" class="pt-6 md:pt-0">
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
            Kirim data pemasukan & pengeluaran sederhana, dapat ringkasan
            laporan keuangan dan saran bisnis setiap minggu.
            <strong>Mulai Rp 40.000/minggu</strong> atau
            <strong>Rp 120.000/bulan</strong>.
          </p>

          <div class="pt-6 md:pt-4">
            <UButton
              size="xl"
              color="primary"
              icon="i-simple-icons-whatsapp"
              class="px-6 md:px-10 py-3 md:py-4 text-sm md:text-lg rounded-2xl shadow-2xl shadow-primary/40 hover:scale-105 transition-transform"
              @click="openWa"
              aria-label="Mulai berlangganan Laporku via WhatsApp"
            >
              Mulai Sekarang — Gratis 7 Hari
            </UButton>
          </div>
        </section>
      </Transition>

      <Transition name="fade-up" appear>
        <section
          ref="chatSection"
          class="mt-8 md:mt-14 relative flex justify-center px-2"
        >
          <div
            class="relative z-10 w-full max-w-[500px] md:min-h-[460px] min-h-[520px] rounded-2xl overflow-hidden bg-gradient-to-br from-background/90 to-background/70 backdrop-blur-md shadow-[0_30px_80px_-30px_RGBA(0,0,0,0.5)] border border-border/40"
            role="img"
            aria-label="Demo percakapan Laporku di WhatsApp"
          >
            <div
              class="flex items-center gap-3 px-4 py-3 border-b border-border/40 bg-background/70"
            >
              <img
                src="/favicon.ico"
                class="w-14 h-14 rounded-full"
                alt="Logo Laporku"
              />
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
            aria-hidden="true"
          />
        </section>
      </Transition>

      <Transition name="fade-up" appear>
        <section ref="testimonialSection" class="mt-16 md:mt-32 px-2">
          <div class="mb-8 md:mb-16 text-center">
            <h2 class="text-2xl md:text-3xl font-bold">
              Dipercaya Ratusan UMKM Lokal
            </h2>
            <div class="h-1 w-20 bg-primary mx-auto mt-4 rounded-full"></div>
          </div>

          <div
            class="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-8 testi-grid"
          >
            <UCard
              v-for="(testi, i) in testimonials"
              :key="i"
              class="testi-card border-white/5 bg-white/5 backdrop-blur-sm hover:bg-white/10 transition-all hover:scale-105"
            >
              <article class="space-y-3 md:space-y-4 py-2">
                <div class="flex flex-col items-center gap-1 text-center">
                  <span
                    class="font-bold text-base md:text-lg text-foreground"
                    >{{ testi.name }}</span
                  >
                  <span
                    class="text-[10px] md:text-xs text-primary/80 uppercase tracking-widest"
                    >{{ testi.business }}</span
                  >
                </div>
                <blockquote
                  class="text-xs md:text-sm leading-relaxed opacity-80 italic text-center"
                >
                  "{{ testi.quote }}"
                </blockquote>
                <div
                  class="pt-3 md:pt-4 border-t border-border/40 flex justify-between items-center text-[9px] md:text-[10px] text-muted-foreground uppercase tracking-tighter"
                >
                  <span>{{ testi.location }}</span>
                  <div
                    class="flex text-warning"
                    role="img"
                    aria-label="Rating 5 dari 5 bintang"
                  >
                    <UIcon
                      v-for="s in 5"
                      :key="s"
                      name="i-heroicons-star-solid"
                      class="w-2.5 h-2.5 md:w-3 md:h-3"
                    />
                  </div>
                </div>
              </article>
            </UCard>
          </div>

          <div
            class="mt-12 md:mt-20 grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-8 bg-white/5 p-6 md:p-10 rounded-3xl border border-white/5"
          >
            <div v-for="stat in stats" :key="stat.label">
              <div
                class="text-2xl md:text-4xl font-black text-primary stat-number"
                :data-target="stat.val"
                :data-suffix="stat.suffix"
              >
                0{{ stat.suffix }}
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
          ref="featuresSection"
          class="mt-12 md:mt-24 grid grid-cols-1 md:grid-cols-3 gap-6 md:gap-12 text-left px-2"
        >
          <UCard
            class="feature-card space-y-3 text-center md:text-left shadow-sm rounded-2xl border border-success hover:border-primary transition-all hover:scale-105"
          >
            <div
              class="w-10 h-10 bg-primary/15 text-primary rounded-lg flex items-center justify-center mx-auto md:mx-0"
            >
              <UIcon name="i-heroicons-bolt" class="w-6 h-6" />
            </div>

            <h3 class="font-bold">Input Cepat</h3>

            <p class="text-sm text-muted">
              Kirim pesan ke WhatsApp, kami proses laporan keuangan Anda.
            </p>
          </UCard>

          <UCard
            class="feature-card space-y-3 text-center md:text-left shadow-sm rounded-2xl border border-success hover:border-primary transition-all hover:scale-105"
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

            <p class="text-sm text-muted">
              Bukan cuma laporan, tapi solusi bisnis yang actionable.
            </p>
          </UCard>

          <UCard
            class="feature-card space-y-3 text-center md:text-left shadow-sm rounded-2xl border border-success hover:border-primary transition-all hover:scale-105"
          >
            <div
              class="w-10 h-10 bg-primary/15 text-primary rounded-lg flex items-center justify-center mx-auto md:mx-0"
            >
              <UIcon name="i-heroicons-gift" class="w-6 h-6" />
            </div>

            <h3 class="font-bold">Minggu Pertama Gratis</h3>

            <p class="text-sm text-muted">
              Tidak cocok? Tidak perlu lanjut berlangganan.
            </p>
          </UCard>
        </section>
      </Transition>

      <!-- FAQ Section untuk SEO -->
      <Transition name="fade-up" appear>
        <section class="mt-16 md:mt-32 px-2 text-left max-w-3xl mx-auto">
          <div class="text-center mb-8 md:mb-12">
            <h2 class="text-2xl md:text-3xl font-bold">
              Pertanyaan yang Sering Ditanyakan
            </h2>
            <div class="h-1 w-20 bg-primary mx-auto mt-4 rounded-full"></div>
          </div>

          <div class="space-y-4">
            <details
              v-for="(faq, i) in faqs"
              :key="i"
              class="p-4 rounded-lg bg-white/5 border border-white/5 hover:bg-white/10 transition-colors group"
            >
              <summary
                class="font-semibold cursor-pointer flex items-center justify-between"
              >
                {{ faq.question }}
                <UIcon
                  name="i-heroicons-chevron-down"
                  class="w-5 h-5 transition-transform group-open:rotate-180"
                />
              </summary>
              <p class="mt-3 text-sm text-muted leading-relaxed">
                {{ faq.answer }}
              </p>
            </details>
          </div>
        </section>
      </Transition>

      <!-- CTA Section -->
      <Transition name="fade-up" appear>
        <section
          class="mt-16 md:mt-24 px-2 py-12 bg-primary/10 rounded-3xl border border-primary/20"
        >
          <h2 class="text-2xl md:text-4xl font-bold mb-4">
            Siap Kelola Keuangan UMKM Lebih Mudah?
          </h2>
          <p class="text-sm md:text-base text-muted mb-6 max-w-2xl mx-auto">
            Bergabung dengan ratusan UMKM yang sudah merasakan kemudahan
            mengelola keuangan via WhatsApp
          </p>
          <UButton
            size="xl"
            color="primary"
            icon="i-simple-icons-whatsapp"
            class="px-8 md:px-12 py-3 md:py-4 text-base md:text-xl rounded-2xl shadow-2xl shadow-primary/40 hover:scale-105 transition-transform"
            @click="openWa"
            aria-label="Hubungi Laporku via WhatsApp"
          >
            Hubungi Kami Sekarang
          </UButton>
        </section>
      </Transition>
    </main>

    <footer
      class="py-8 md:py-12 mt-12 border-t border-white/5 text-center text-muted-foreground text-[10px] md:text-xs tracking-widest"
    >
      <p>&copy; 2025 LAPORKU • SIMPLE BUSINESS SOLUTION</p>
      <p class="mt-2">
        Laporan Keuangan UMKM via WhatsApp | Banjarmasin, Kalimantan Selatan
      </p>
    </footer>
  </div>
</template>

<style>
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

div[ref="chatBot1"],
div[ref="chatBot2"],
div[ref="chatBot3"] {
  will-change: transform, opacity;
}
</style>
