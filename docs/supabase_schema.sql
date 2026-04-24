-- ============================================================
-- SAWIT DIAGNOSA - Supabase Schema
-- ============================================================

-- 1. Master data penyakit
CREATE TABLE penyakit (
    id          SERIAL PRIMARY KEY,
    kode        VARCHAR(50) UNIQUE NOT NULL,
    nama        VARCHAR(100) NOT NULL,
    deskripsi   TEXT,
    gejala_umum TEXT,
    treatment   TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Riwayat diagnosa per user
CREATE TABLE riwayat_diagnosa (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    penyakit_id         INT REFERENCES penyakit(id),
    penyakit_nama       VARCHAR(100),   -- snapshot nama saat diagnosa
    confidence_fuzzy    FLOAT,          -- confidence dari fuzzy engine (%)
    confidence_ml       FLOAT,          -- confidence dari ML model (%)
    confidence_final    FLOAT,          -- confidence hybrid final (%)
    metode              VARCHAR(20) DEFAULT 'hybrid', -- 'fuzzy' | 'ml' | 'hybrid'
    foto_url            TEXT,           -- URL foto dari Supabase Storage
    semua_skor          JSONB,          -- semua skor penyakit dari fuzzy
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Detail input gejala per diagnosa
CREATE TABLE gejala_input (
    id                      SERIAL PRIMARY KEY,
    diagnosa_id             UUID REFERENCES riwayat_diagnosa(id) ON DELETE CASCADE,
    tingkat_kekuningan      FLOAT NOT NULL CHECK (tingkat_kekuningan BETWEEN 0 AND 10),
    luas_bercak             FLOAT NOT NULL CHECK (luas_bercak BETWEEN 0 AND 10),
    kondisi_batang          FLOAT NOT NULL CHECK (kondisi_batang BETWEEN 0 AND 10),
    pertumbuhan_terhambat   FLOAT NOT NULL CHECK (pertumbuhan_terhambat BETWEEN 0 AND 10)
);

-- ============================================================
-- SEED: Master data 6 penyakit
-- ============================================================
INSERT INTO penyakit (kode, nama, deskripsi, gejala_umum, treatment) VALUES
(
    'GANODERMA',
    'Ganoderma Boschii',
    'Penyakit busuk pangkal batang yang disebabkan jamur Ganoderma boninense. Paling merusak di perkebunan kelapa sawit.',
    'Daun menguning dari pelepah bawah, batang membusuk di pangkal, pertumbuhan terhambat, muncul tubuh buah jamur berwarna coklat kemerahan.',
    'Tidak ada obat yang efektif. Tindakan: isolasi tanaman terinfeksi, cabut dan bakar, aplikasi Trichoderma pada lubang bekas, replanting dengan bibit tahan.'
),
(
    'BLIGHT',
    'Blight (Hawar Daun)',
    'Penyakit hawar daun yang menyebabkan kematian jaringan daun secara cepat.',
    'Bercak coklat kebasahan pada daun, daun mengering dari ujung, bercak meluas dengan cepat, tepi bercak berwarna kuning.',
    'Aplikasi fungisida berbahan aktif mankozeb atau tembaga hidroksida. Pangkas daun terinfeksi dan bakar. Perbaiki drainase kebun.'
),
(
    'CROWN_DISEASE',
    'Crown Disease',
    'Kelainan genetik atau akibat defisiensi nutrisi yang menyebabkan daun mahkota tumbuh abnormal.',
    'Daun mahkota (spear) tumbuh tidak normal, anak daun tidak membuka sempurna, pertumbuhan tanaman terhambat, daun berbentuk seperti pita.',
    'Aplikasi pupuk boron dan magnesium. Pada kasus genetik, tidak ada penanganan khusus selain seleksi bibit unggul.'
),
(
    'PESTALOTIOPSIS',
    'Pestalotiopsis',
    'Penyakit bercak daun yang disebabkan jamur Pestalotiopsis sp., umumnya menyerang bibit dan tanaman muda.',
    'Bercak hitam kecoklatan pada daun, nekrosis di tepi daun, bercak dikelilingi halo kuning, daun gugur prematur.',
    'Aplikasi fungisida sistemik (azoksistrobin atau propikonazol). Kurangi kelembaban dengan pemangkasan. Hindari luka mekanis pada daun.'
),
(
    'BASAL_STEM_ROT',
    'Basal Stem Rot',
    'Busuk pangkal batang parah yang menyerang bagian bawah batang hingga akar.',
    'Batang membusuk dari bagian bawah, daun bawah layu dan mati, akar membusuk, tanaman mudah roboh, bau busuk di pangkal batang.',
    'Injeksi fungisida sistemik pada batang. Aplikasi Trichoderma harzianum di zona akar. Perbaiki drainase. Kasus parah: tebang dan musnahkan.'
),
(
    'SPEAR_ROT',
    'Spear Rot',
    'Pembusukan pada daun tombak (spear) yang belum membuka, sering dikaitkan dengan defisiensi boron atau serangan bakteri.',
    'Daun tombak membusuk sebelum membuka, bau busuk pada bagian pucuk, daun tombak berwarna coklat kehitaman, pertumbuhan pucuk terhenti.',
    'Aplikasi boron foliar dan ke tanah. Fungisida + bakterisida pada pucuk. Pastikan drainase baik. Hindari pelukaan saat panen.'
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE riwayat_diagnosa ENABLE ROW LEVEL SECURITY;
ALTER TABLE gejala_input ENABLE ROW LEVEL SECURITY;

-- User hanya bisa akses data miliknya sendiri
CREATE POLICY "user_own_diagnosa" ON riwayat_diagnosa
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "user_own_gejala" ON gejala_input
    FOR ALL USING (
        diagnosa_id IN (
            SELECT id FROM riwayat_diagnosa WHERE user_id = auth.uid()
        )
    );

-- Penyakit bisa dibaca semua user (public)
ALTER TABLE penyakit ENABLE ROW LEVEL SECURITY;
CREATE POLICY "penyakit_public_read" ON penyakit
    FOR SELECT USING (true);

-- ============================================================
-- STORAGE BUCKET untuk foto
-- ============================================================
-- Jalankan di Supabase Dashboard > Storage:
-- Buat bucket: "foto-diagnosa" dengan setting Public: false
-- INSERT INTO storage.buckets (id, name, public) VALUES ('foto-diagnosa', 'foto-diagnosa', false);

-- ============================================================
-- TABEL PROFILES (user profile)
-- ============================================================
CREATE TABLE profiles (
    id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nama        VARCHAR(100),
    lokasi_kebun VARCHAR(200),
    no_hp       VARCHAR(20),
    avatar_url  TEXT,
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_own_profile" ON profiles
    FOR ALL USING (auth.uid() = id);

-- Auto-create profile saat user register
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();
