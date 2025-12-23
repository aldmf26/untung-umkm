-- 002_seed_sample_data.sql
-- Sample seed data for local/dev environment.
-- Remove or edit before running in production.

insert into public.umkm_profiles (id, nama_usaha, nama_pemilik, no_wa, tanggal_join, status, catatan)
values
  (gen_random_uuid(), 'Warung Maju', 'Budi', '081234567890', current_date - interval '30 days', 'active', 'Klien percontohan'),
  (gen_random_uuid(), 'Laundry Bersih', 'Siti', '081298765432', current_date - interval '10 days', 'trial', null),
  (gen_random_uuid(), 'Cukur Jaya', 'Anton', '081377788899', current_date - interval '5 days', 'inactive', 'Butuh follow up');

-- Insert weekly reports for the first UMKM
insert into public.weekly_reports (umkm_id, periode_mulai, periode_selesai, uang_masuk, uang_keluar, masalah, saran)
select id, current_date - interval '14 days', current_date - interval '8 days', 1500000, 800000, 'Modal kurang', 'Saran meminimalkan stok'
  from public.umkm_profiles order by created_at limit 1;

-- You can place additional seed SQL as needed for testing.
