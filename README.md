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

---

## Setup & Database (Supabase)

1. Tambahkan env vars (`.env` atau di Vercel):

   - `SUPABASE_URL` (contoh: https://your-project.supabase.co)
   - `SUPABASE_ANON_KEY` (public anon key)
   - `SUPABASE_SERVICE_ROLE_KEY` (optional, server-side only)

2. Jalankan SQL migration di `db/migrations/` lewat Supabase SQL Editor:

   - `001_create_umkm_profiles_and_weekly_reports.sql` — buat tabel `umkm_profiles` dan `weekly_reports`.
   - `002_seed_sample_data.sql` — (opsional) isi data contoh untuk pengembangan.

3. Catatan schema:

   - `weekly_reports.untung_rugi` adalah kolom `GENERATED` (Postgres). Jika versi Postgres Anda tidak mendukung kolom `GENERATED`, hitung `untung_rugi` di aplikasi atau tambahkan trigger.
   - `user_id` dan `created_by` mengacu ke `auth.users(id)` (Supabase Auth); sesuaikan bila tidak memakai Supabase Auth.

4. Setelah SQL dijalankan, restart dev server dan pastikan `SUPABASE_URL` dan keys sudah tersedia.

---

Jika mau, saya bisa juga menambahkan skrip untuk menjalankan SQL secara otomatis (CI) atau membuat migrasi yang kompatibel dengan "pg-migrations"—katakan jika Anda ingin itu ditambahkan.
