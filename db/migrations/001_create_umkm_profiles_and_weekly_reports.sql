-- Tabel weekly_reports
CREATE TABLE IF NOT EXISTS public.weekly_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  umkm_id UUID NOT NULL REFERENCES public.umkm_profiles(id) ON DELETE CASCADE,
  periode_mulai DATE NOT NULL,
  periode_selesai DATE NOT NULL,
  uang_masuk NUMERIC(15, 2) NOT NULL DEFAULT 0,
  uang_keluar NUMERIC(15, 2) NOT NULL DEFAULT 0,
  untung_rugi NUMERIC(15, 2) GENERATED ALWAYS AS (uang_masuk - uang_keluar) STORED,
  masalah TEXT,
  saran TEXT NOT NULL,
  is_partial BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Index untuk performa query
CREATE INDEX idx_weekly_reports_umkm_id ON public.weekly_reports(umkm_id);
CREATE INDEX idx_weekly_reports_periode ON public.weekly_reports(periode_mulai, periode_selesai);
CREATE INDEX idx_weekly_reports_created_at ON public.weekly_reports(created_at DESC);

-- Trigger untuk update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_weekly_reports_updated_at 
  BEFORE UPDATE ON public.weekly_reports
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies (Enable RLS)
ALTER TABLE public.weekly_reports ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all reports
CREATE POLICY "Allow authenticated read access"
  ON public.weekly_reports
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Allow authenticated users to insert reports
CREATE POLICY "Allow authenticated insert access"
  ON public.weekly_reports
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Policy: Allow authenticated users to update reports
CREATE POLICY "Allow authenticated update access"
  ON public.weekly_reports
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Policy: Allow authenticated users to delete reports
CREATE POLICY "Allow authenticated delete access"
  ON public.weekly_reports
  FOR DELETE
  TO authenticated
  USING (true);

-- Comment untuk dokumentasi
COMMENT ON TABLE public.weekly_reports IS 'Tabel laporan keuangan mingguan UMKM';
COMMENT ON COLUMN public.weekly_reports.untung_rugi IS 'Kolom generated otomatis: uang_masuk - uang_keluar';
COMMENT ON COLUMN public.weekly_reports.is_partial IS 'Flag untuk minggu pertama (trial/gratis)';