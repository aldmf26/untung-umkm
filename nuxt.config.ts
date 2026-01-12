// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  modules: ['@nuxt/eslint', '@nuxt/ui', '@nuxtjs/supabase','@vueuse/nuxt','@nuxtjs/seo',
    '@nuxt/image'],
  devtools: {
    enabled: true
  },

  app: {
    head: {
      htmlAttrs: {
        lang: 'id'
      },
      charset: 'utf-8',
      viewport: 'width=device-width, initial-scale=1',
    }
  },

  site: {
    url: 'https://laporku.vercel.app',
    name: 'Laporku',
    description: 'Kelola keuangan UMKM cukup lewat WhatsApp. Kirim pemasukan & pengeluaran, dapat laporan untung rugi + saran bisnis setiap minggu.',
    defaultLocale: 'id',
  },

  sitemap: {
    strictNuxtContentPaths: true,
    urls: [
      {
        loc: '/',
        lastmod: new Date().toISOString(),
        changefreq: 'weekly',
        priority: 1.0,
      }
    ]
  },

  robots: {
    allow: '/',
    sitemap: 'https://laporku.vercel.app/sitemap.xml'
  },

  ogImage: {
    enabled: true,
    fonts: [
      'Inter:400',
      'Inter:700'
    ]
  },

  seoExperiments: {
    enabled: true
  },

  linkChecker: {
    enabled: true,
    excludeLinks: [
      'https://wa.me/*'
    ]
  },

  schemaOrg: {
    identity: {
      type: 'Organization',
      name: 'Laporku',
      url: 'https://laporku.vercel.app',
      logo: 'https://laporku.vercel.app/favicon.ico'
    }
  },


  supabase: {
    redirect: false, // Kita handle redirect manual
    types: false
  },

  css: ['~/assets/css/main.css'],

  routeRules: {
    '/': { prerender: true }
  },
// Google Analytics (ganti dengan GA ID kamu)
  gtag: {
    id: 'G-XXXXXXXXXX'
  },


  eslint: {
    config: {
      stylistic: {
        commaDangle: 'never',
        braceStyle: '1tbs'
      }
    }
  }
})