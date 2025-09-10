CREATE TABLE urunler (
    urun_id INT PRIMARY KEY,
    marka VARCHAR(50),
    model VARCHAR(50),
    kategori VARCHAR(50)
);
 
INSERT INTO urunler VALUES
(1, 'Toyota', 'Corolla', 'Sedan'),
(2, 'Ford', 'Focus', 'Hatchback'),
(3, 'BMW', '320i', 'Sedan');
 
CREATE TABLE fiyat_gecmisi (
    fiyat_id INT IDENTITY(1,1) PRIMARY KEY,
    urun_id INT,
    fiyat NUMERIC(10,2),
    baslangic_tarihi DATE,
    bitis_tarihi DATE
);
 
INSERT INTO fiyat_gecmisi (urun_id, fiyat, baslangic_tarihi, bitis_tarihi) VALUES
(1, 200000, '2025-01-01', '2025-05-31'),
(1, 210000, '2025-06-01', '2025-12-31'),
(2, 150000, '2025-01-01', '2025-09-10'),
(3, 300000, '2025-01-01', '2025-06-30'),
(3, 320000, '2025-07-01', '2025-12-31');
 
CREATE TABLE stok_girisleri (
    stok_id INT IDENTITY(1,1) PRIMARY KEY,
    urun_id INT,
    stok_tarihi DATE,
    miktar INT
);
 
INSERT INTO stok_girisleri (urun_id, stok_tarihi, miktar) VALUES
(1, '2025-01-05', 10),
(1, '2025-02-10', 15),
(1, '2025-03-20', 5),
(2, '2025-01-15', 20),
(2, '2025-04-01', 10),
(3, '2025-06-10', 8),
(3, '2025-07-01', 12);
 
 
CREATE TABLE satislar (
    satis_id INT IDENTITY(1,1) PRIMARY KEY,
    urun_id INT,
    satis_tarihi DATE,
    miktar INT
);
 
INSERT INTO satislar (urun_id, satis_tarihi, miktar) VALUES
(1, '2025-01-10', 5),
(1, '2025-02-15', 10),
(1, '2025-03-25', 3),
(2, '2025-01-20', 8),
(2, '2025-04-10', 7),
(3, '2025-06-15', 4),
(3, '2025-07-20', 6);
 
 
WITH stok_aylik AS (
    SELECT
        urun_id,
        DATEADD(MONTH, DATEDIFF(MONTH, 0, stok_tarihi), 0) AS ay,
        SUM(miktar) AS aylik_stok
    FROM stok_girisleri
    GROUP BY urun_id, DATEADD(MONTH, DATEDIFF(MONTH, 0, stok_tarihi), 0)
),
satis_aylik AS (
    SELECT
        urun_id,
        DATEADD(MONTH, DATEDIFF(MONTH, 0, satis_tarihi), 0) AS ay,
        SUM(miktar) AS aylik_satis
    FROM satislar
    GROUP BY urun_id, DATEADD(MONTH, DATEDIFF(MONTH, 0, satis_tarihi), 0)
),
birlesik AS (
    SELECT
        CASE WHEN s.urun_id IS NOT NULL THEN s.urun_id ELSE sa.urun_id END AS urun_id,
        CASE WHEN s.ay IS NOT NULL THEN s.ay ELSE sa.ay END AS ay,
        s.aylik_stok,
        sa.aylik_satis
    FROM stok_aylik s
    FULL OUTER JOIN satis_aylik sa
        ON s.urun_id = sa.urun_id AND s.ay = sa.ay
),
stok_devir AS (
    SELECT
        b.urun_id,
        b.ay,
        b.aylik_stok,
        b.aylik_satis,
        CASE 
             WHEN b.aylik_satis > 0 THEN ROUND((b.aylik_stok * 30.0) / b.aylik_satis, 2)
            ELSE NULL
        END AS stok_devir_gunu
    FROM birlesik b
),
fiyat_aylik AS (
    -- Her ürün için ay bazında fiyat aralıklarını ayın ilk günü ile eşleştiriyoruz
    SELECT
        urun_id,
        DATEADD(MONTH, DATEDIFF(MONTH, 0, baslangic_tarihi), 0) AS ay,
        fiyat,
        baslangic_tarihi
    FROM fiyat_gecmisi
),
fiyatli AS (
    SELECT
        sd.*,
        fa.fiyat,
        ROW_NUMBER() OVER (PARTITION BY sd.urun_id, sd.ay ORDER BY fa.baslangic_tarihi DESC) AS rn
    FROM stok_devir sd
    LEFT JOIN fiyat_aylik fa
        ON sd.urun_id = fa.urun_id
        AND sd.ay = fa.ay
),
final AS (
    SELECT
        f.urun_id,
        f.ay,
        f.aylik_stok,
        f.aylik_satis,
        f.stok_devir_gunu,
        f.fiyat,
        u.marka,
        u.model,
        u.kategori
    FROM fiyatli f
    JOIN urunler u ON f.urun_id = u.urun_id
    WHERE f.rn = 1
)
SELECT *
FROM final
ORDER BY urun_id, ay DESC;
