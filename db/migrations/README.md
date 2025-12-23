# DB Migrations

This folder contains SQL migration files you can run in the Supabase SQL editor.

How to run

1. Open your Supabase project -> SQL Editor -> New query
2. Copy the SQL from `001_create_umkm_profiles_and_weekly_reports.sql` and run it.
3. (Optional) Run `002_seed_sample_data.sql` to populate sample data for local/dev testing.

Notes

- We enable `pgcrypto` to use `gen_random_uuid()` for UUID generation.
- `weekly_reports.untung_rugi` is a `GENERATED` column; if your Postgres version does not support generated columns, compute it in the application or add a trigger.
- `user_id` and `created_by` reference `auth.users(id)` (Supabase Auth). If you don't use Supabase Auth, remove or adjust the FK constraints.

If you want, I can split these into separate migration files and add a small script to run them automatically (e.g., in CI).
