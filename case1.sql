-- TABLO 
DROP TABLE IF EXISTS raw_cars;
CREATE TABLE raw_cars (
  brand TEXT,
  model TEXT,
  year  INTEGER,
  mileage_km INTEGER,
  price INTEGER,
  sale_duration_days INTEGER,
  region TEXT
);

--  ÖRNEK VERİ 
INSERT INTO raw_cars (brand, model, year, mileage_km, price, sale_duration_days, region) VALUES
-- BMW
('BMW','1 Series',2019,65000,1450000,28,'Istanbul'),
('BMW','3 Series',2020,60000,1900000,45,'Ankara'),
('BMW','5 Series',2021,35000,3200000,52,'Istanbul'),
('BMW','X1',2018,90000,1600000,40,'Izmir'),
('BMW','X3',2020,50000,2700000,48,'Bursa'),
('BMW','X5',2020,45000,4500000,55,'Istanbul'),
('BMW','3 Series',2018,85000,1700000,38,'Bursa'),

-- MINI
('MINI','Cooper',2019,70000,1200000,30,'Bursa'),
('MINI','Countryman',2021,40000,1750000,36,'Istanbul'),
('MINI','Clubman',2018,80000,1100000,24,'Izmir'),
('MINI','Cooper',2020,50000,1350000,29,'Ankara'),

-- Jaguar
('Jaguar','XE',2019,60000,1600000,33,'Istanbul'),
('Jaguar','XF',2018,75000,1700000,37,'Izmir'),
('Jaguar','F-PACE',2020,55000,2500000,46,'Ankara'),
('Jaguar','E-PACE',2019,65000,1900000,42,'Bursa'),
('Jaguar','I-PACE',2020,40000,3400000,58,'Istanbul'),

-- Land Rover
('Land Rover','Range Rover Evoque',2019,60000,2200000,41,'Istanbul'),
('Land Rover','Range Rover Velar',2018,70000,2600000,47,'Ankara'),
('Land Rover','Discovery Sport',2020,50000,2700000,49,'Izmir'),
('Land Rover','Defender 110',2021,30000,4200000,60,'Istanbul'),
('Land Rover','Range Rover Sport',2020,45000,5000000,61,'Istanbul'),


('BMW','5 Series',2019,80000,2500000,44,'Ankara'),
('BMW','X3',2018,95000,2100000,39,'Izmir'),
('MINI','Countryman',2019,65000,1500000,35,'Bursa'),
('MINI','Cooper',2018,90000,1050000,23,'Istanbul'),
('Jaguar','F-PACE',2018,85000,2100000,43,'Izmir'),
('Jaguar','XE',2021,30000,1950000,40,'Ankara'),
('Land Rover','Discovery Sport',2019,70000,2350000,45,'Bursa'),
('Land Rover','Range Rover Evoque',2021,35000,2650000,50,'Istanbul'),
('Land Rover','Defender 110',2020,45000,3950000,59,'Ankara'),
('BMW','X5',2019,60000,4200000,56,'Izmir');

-- =============== WINDOW ÖZETLER + METRİKLER ===============
DROP VIEW IF EXISTS car_pricing_features;
CREATE VIEW car_pricing_features AS
WITH base AS (
  SELECT *
  FROM raw_cars
  WHERE price IS NOT NULL
    AND mileage_km IS NOT NULL
    AND year BETWEEN 1990 AND strftime('%Y','now')
),
w AS (
  SELECT
    b.*,

    -- Marka bazlı: ortalama + sıralama + çeyreklikler
    AVG(price) OVER (PARTITION BY brand) AS brand_avg_price,
    RANK()  OVER (PARTITION BY brand ORDER BY price) AS price_rank_in_brand,
    NTILE(4) OVER (PARTITION BY brand ORDER BY price) AS price_quartile_in_brand,

    -- Bölge bazlı: ortalama + sıralama + çeyreklikler
    AVG(price) OVER (PARTITION BY region) AS region_avg_price,
    RANK()  OVER (PARTITION BY region ORDER BY price) AS price_rank_in_region,
    NTILE(4) OVER (PARTITION BY region ORDER BY price) AS price_quartile_in_region
  FROM base b
)
SELECT
  *,
  ROUND(1.0 * price / NULLIF(brand_avg_price,0), 3)  AS price_vs_brand_avg,
  ROUND(1.0 * price / NULLIF(region_avg_price,0), 3) AS price_vs_region_avg
FROM w;

-- ===============  ÇIKTI =================
SELECT * FROM car_pricing_features;
