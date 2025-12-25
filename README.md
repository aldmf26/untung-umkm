# Layanan Pendampingan Keuangan UMKM via WhatsApp

# Laporku

Laporku adalah aplikasi pendampingan keuangan untuk UMKM yang membantu pemilik
usaha memahami kondisi bisnisnya tanpa harus membaca laporan yang rumit.

Melalui Laporku, UMKM akan menerima:

- Ringkasan untung dan rugi mingguan
- Total pemasukan dan pengeluaran
- Analisis sederhana performa usaha
- Saran praktis untuk meningkatkan keuntungan

Semua laporan dikirim langsung melalui WhatsApp, sehingga mudah dipahami dan
tidak membutuhkan aplikasi tambahan.

Laporku dirancang untuk UMKM Indonesia yang ingin fokus berjualan tanpa repot
mengelola laporan keuangan yang kompleks.

## Fitur Utama

- Kelola data UMKM (CRUD)
- Input laporan keuangan mingguan per klien
- Hitung untung/rugi otomatis
- Beri saran praktis
- Kirim ringkasan via WhatsApp
- Dashboard overview: total klien, status, revenue mingguan
- 📊 Laporan keuangan mingguan
- 💬 Notifikasi & laporan via WhatsApp
- 📈 Analisis sederhana dan mudah dipahami
- 💡 Saran bisnis praktis
- 🧾 Riwayat laporan UMKM

## Tech Stack

- Nuxt 3
- Nuxt UI[](https://ui.nuxt.com)
- Supabase (nanti untuk database)
- Deploy: Vercel

## Struktur Halaman

- `/dashboard` → Home / Overview (stats + recent activity)
- `/dashboard/customers` → Daftar UMKM + CRUD
- `/dashboard/laporan/input` → Form input laporan mingguan
- `/dashboard/umkm/[id]` → Detail + riwayat laporan per UMKM

## Catatan untuk Developer

- Gunakan komponen Nuxt UI sebanyak mungkin: UCard, UStats, UTable, UBadge, dll
- Desain dark mode friendly
- Prioritas sekarang: tampilan dashboard yang clean & informatif
- Data sementara pakai ref() dummy, nanti ganti Supabase

## Struktur Database (ringkasan) 🔧

Berikut ringkasan tabel yang digunakan oleh aplikasi (diambil dari `db/migrations` dan penggunaan di kode):

### `umkm_profiles` (profil klien)

- id: UUID (PK)
- nama_usaha: TEXT
- nama_pemilik: TEXT
- no_wa: TEXT
- tanggal_join: TIMESTAMP
- status: TEXT ('active' | 'trial' | 'inactive')
- catatan: TEXT | NULL
- user_id: UUID | NULL (referensi ke `auth.users`)
- created_at, updated_at: TIMESTAMP WITH TIME ZONE

> Catatan: pembuatan tabel `umkm_profiles` tidak ditemukan sebagai SQL di folder migrasi — struktur di atas diinferensikan dari seed data dan penggunaan di kode (lihat `/app/pages/*`). Pastikan menambahkan file migrasi untuk `umkm_profiles` bila ingin menjalankan DB dari script.

### `weekly_reports` (laporan mingguan)

- id: UUID (PK, gen_random_uuid())
- umkm_id: UUID (FK → `umkm_profiles.id`)
- periode_mulai: DATE
- periode_selesai: DATE
- uang_masuk: NUMERIC(15,2)
- uang_keluar: NUMERIC(15,2)
- untung_rugi: NUMERIC(15,2) — GENERATED ALWAYS AS (uang_masuk - uang_keluar) STORED
- masalah: TEXT | NULL
- saran: TEXT
- is_partial: BOOLEAN DEFAULT FALSE
- created_at, updated_at: TIMESTAMP WITH TIME ZONE

- Index: `idx_weekly_reports_umkm_id`, `idx_weekly_reports_periode`, `idx_weekly_reports_created_at`
- RLS policies + trigger `update_updated_at_column` disertakan di migrasi.

### `payments` (pencatatan pembayaran)

- id: UUID (PK)
- umkm_id: UUID (FK → `umkm_profiles.id`)
- jumlah: NUMERIC / INTEGER
- periode: TEXT | NULL
- tanggal_bayar: DATE
- keterangan: TEXT | NULL
- created_at: TIMESTAMP WITH TIME ZONE

(Contoh seed data ada di `db/migrations/002_seed_sample_data.sql`)

---

## Alur Program (singkat) 🚦

Ringkas alur aplikasi berdasarkan folder `app/pages` dan composables:

1. Landing / Publik

   - `/` → Halaman marketing & demo UI (animasi, fitur ringkasan). Tidak perlu login.
   - `/login` → Autentikasi menggunakan Supabase Auth melalui `useAuth`.

2. Middleware & Auth

   - `app/middleware/auth.ts` memastikan rute `/dashboard/**` hanya diakses jika ada sesi Supabase.

3. Dashboard (protected)

   - `/dashboard` → Menampilkan ringkasan: total klien (`umkm_profiles`), pendapatan (dari `payments`), grafik ringkasan.
   - Mengambil data via `useAsyncData` dan `useSupabaseClient()`.

4. Manajemen Klien

   - `/dashboard/customers` → List `umkm_profiles`. CRUD dilakukan lewat modal (`Add`, `Edit`, `Delete`).
   - Tersedia aksi cepat: input laporan, lihat riwayat, kirim reminder WA, copy template pesan.

5. Laporan Mingguan

   - `/dashboard/laporan/input` → Form validasi (`zod`), simpan ke `weekly_reports`. Ada preview & tombol kirim WA.
   - `/dashboard/laporan` → Daftar laporan, edit, hapus, link ke profil UMKM.

6. Pembayaran

   - `/dashboard/payments/input` → Form pencatatan pembayaran, simpan ke tabel `payments`.
   - `/dashboard/payments` → Riwayat pembayaran (join ke `umkm_profiles` untuk tampilkan nama).

7. Detail UMKM

   - `/dashboard/umkm/[id]` → Profil klien, ringkasan kumulatif (untung/rugi), grafik, tabel laporan, tombol cepat (input laporan / pembayaran / kirim WA).

8. Composables & Plugins
   - `useAuth` → wrapper untuk Supabase Auth (signIn, signUp, signOut).
   - `useDashboard` → shared composable (shortcuts, notifikasi UI state).
   - `plugins/supabase.client.ts` → menyediakan `$supabase` alias.

### Detail Rute & File (quick reference) 📁

- `/` → `app/pages/index.vue` — Landing page & demo UI.
- `/login` → `app/pages/login.vue` — Form login, redirect ke `/dashboard` setelah berhasil.
- `/dashboard` → `app/pages/dashboard/index.vue` — Summary cards, charts, mengambil data dari `umkm_profiles` dan `payments`.
- `/dashboard/customers` → `app/pages/dashboard/customers/index.vue` (+ `app/components/customers/` modal components) — CRUD UMKM, quick actions (WA, template, input laporan).
- `/dashboard/laporan` → `app/pages/dashboard/laporan/index.vue` — List, edit, delete; `/dashboard/laporan/input` → `app/pages/dashboard/laporan/input.vue` — Form validasi & WhatsApp preview.
- `/dashboard/payments` → `app/pages/dashboard/payments/index.vue` — Riwayat pembayaran; `/dashboard/payments/input` → `app/pages/dashboard/payments/input.vue` — Catat pembayaran.
- `/dashboard/umkm/[id]` → `app/pages/dashboard/umkm/[id]/index.vue` — Profil, grafik, laporan per-UMKM, tombol cepat.
- Middlewares: `app/middleware/auth.ts` — proteksi rute-dashboard.
- Migrations: `db/migrations/001_create_umkm_profiles_and_weekly_reports.sql`, `db/migrations/002_seed_sample_data.sql`.

> Catatan penting: aplikasi mengandalkan Supabase (Auth + Postgres). Jika menjalankan lokal, pastikan menjalankan SQL di `db/migrations` (001 dan optional 002) atau menambahkan migrasi untuk `umkm_profiles` & `payments` jika belum ada.

---

