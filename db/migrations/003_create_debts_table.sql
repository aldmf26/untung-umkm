-- Tabel debts (hutang/piutang)
CREATE TABLE IF NOT EXISTS public.debts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  umkm_id UUID NOT NULL REFERENCES public.umkm_profiles(id) ON DELETE CASCADE,
  nama_debitur VARCHAR(255) NOT NULL,
  no_wa VARCHAR(20),
  jumlah NUMERIC(15, 2) NOT NULL DEFAULT 0,
  tanggal_hutang DATE NOT NULL,
  jatuh_tempo DATE,
  keterangan TEXT,
  status VARCHAR(20) DEFAULT 'belum_lunas' CHECK (status IN ('belum_lunas', 'lunas')),
  tanggal_lunas DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Index untuk performa query
CREATE INDEX idx_debts_umkm_id ON public.debts(umkm_id);
CREATE INDEX idx_debts_tanggal_hutang ON public.debts(tanggal_hutang DESC);
CREATE INDEX idx_debts_status ON public.debts(status);
CREATE INDEX idx_debts_jatuh_tempo ON public.debts(jatuh_tempo);

-- Trigger untuk update updated_at (reuse function dari migration sebelumnya jika sudah ada)
CREATE TRIGGER update_debts_updated_at 
  BEFORE UPDATE ON public.debts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies (Enable RLS)
ALTER TABLE public.debts ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all debts
CREATE POLICY "Allow authenticated read debts"
  ON public.debts
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Allow authenticated users to insert debts
CREATE POLICY "Allow authenticated insert debts"
  ON public.debts
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Policy: Allow authenticated users to update debts
CREATE POLICY "Allow authenticated update debts"
  ON public.debts
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Policy: Allow authenticated users to delete debts
CREATE POLICY "Allow authenticated delete debts"
  ON public.debts
  FOR DELETE
  TO authenticated
  USING (true);

-- Comment untuk dokumentasi
COMMENT ON TABLE public.debts IS 'Tabel pencatatan hutang/piutang pelanggan ke UMKM';
COMMENT ON COLUMN public.debts.nama_debitur IS 'Nama orang yang berhutang';
COMMENT ON COLUMN public.debts.status IS 'Status hutang: belum_lunas atau lunas';
COMMENT ON COLUMN public.debts.tanggal_lunas IS 'Tanggal pelunasan hutang (diisi saat status = lunas)';
