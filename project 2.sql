-- ========================================================
-- Olist E-Commerce Data Warehouse & ETL Pipeline (Fixed)
-- ========================================================

-- 1. السماح بتحميل الملفات المحلية (مطلوب لـ LOAD DATA LOCAL)
--    ملحوظة: لازم تفتح الاتصال بخيار allowLoadLocalInfile / --local-infile=1
SET GLOBAL local_infile = 1;

-- 2. إنشاء قاعدة البيانات
CREATE DATABASE IF NOT EXISTS ECOMMERCE;
USE ECOMMERCE;

-- ========================================================
-- 3. العملاء (CUSTOMER)
-- ========================================================
CREATE TABLE IF NOT EXISTS CUSTOMER (
    customer_id              VARCHAR(50) PRIMARY KEY,
    customer_unique_id       VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city            VARCHAR(100),
    customer_state           CHAR(2)
);

TRUNCATE TABLE CUSTOMER;

LOAD DATA LOCAL INFILE 'C:/project dadta base/olist_customers_dataset.csv'
INTO TABLE CUSTOMER
FIELDS TERMINATED BY ';' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state);

-- ========================================================
-- 4. الطلبات (OLIST_ORDER) عبر Staging  [تمت إضافة customer_id]
-- ========================================================
CREATE TABLE IF NOT EXISTS OLIST_ORDER (
    order_id                      VARCHAR(50) PRIMARY KEY,
    customer_id                   VARCHAR(50),
    order_status                  VARCHAR(50),
    order_purchase_timestamp      DATETIME,
    order_approved_at             DATETIME,
    order_delivered_carrier_date  DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

DROP TABLE IF EXISTS OLIST_ORDER_STAGING;
CREATE TABLE OLIST_ORDER_STAGING (
    order_id                      VARCHAR(100),
    customer_id                   VARCHAR(100),
    order_status                  VARCHAR(100),
    order_purchase_timestamp      VARCHAR(100),
    order_approved_at             VARCHAR(100),
    order_delivered_carrier_date  VARCHAR(100),
    order_delivered_customer_date VARCHAR(100),
    order_estimated_delivery_date VARCHAR(100)
);

LOAD DATA LOCAL INFILE 'C:/project dadta base/olist_orders_dataset.csv'
INTO TABLE OLIST_ORDER_STAGING
FIELDS TERMINATED BY ';' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

TRUNCATE TABLE OLIST_ORDER;

INSERT INTO OLIST_ORDER
SELECT
    TRIM(order_id),
    TRIM(customer_id),
    TRIM(order_status),
    COALESCE(
        STR_TO_DATE(NULLIF(TRIM(order_purchase_timestamp), ''), '%d/%m/%Y %H:%i:%s'),
        STR_TO_DATE(NULLIF(TRIM(order_purchase_timestamp), ''), '%d/%m/%Y %H:%i'),
        STR_TO_DATE(NULLIF(TRIM(order_purchase_timestamp), ''), '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(NULLIF(TRIM(order_purchase_timestamp), ''), '%Y-%m-%d %H:%i')),
    COALESCE(
        STR_TO_DATE(NULLIF(TRIM(order_approved_at), ''), '%d/%m/%Y %H:%i:%s'),
        STR_TO_DATE(NULLIF(TRIM(order_approved_at), ''), '%d/%m/%Y %H:%i'),
        STR_TO_DATE(NULLIF(TRIM(order_approved_at), ''), '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(NULLIF(TRIM(order_approved_at), ''), '%Y-%m-%d %H:%i')),
    COALESCE(
        STR_TO_DATE(NULLIF(TRIM(order_delivered_carrier_date), ''), '%d/%m/%Y %H:%i:%s'),
        STR_TO_DATE(NULLIF(TRIM(order_delivered_carrier_date), ''), '%d/%m/%Y %H:%i'),
        STR_TO_DATE(NULLIF(TRIM(order_delivered_carrier_date), ''), '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(NULLIF(TRIM(order_delivered_carrier_date), ''), '%Y-%m-%d %H:%i')),
    COALESCE(
        STR_TO_DATE(NULLIF(TRIM(order_delivered_customer_date), ''), '%d/%m/%Y %H:%i:%s'),
        STR_TO_DATE(NULLIF(TRIM(order_delivered_customer_date), ''), '%d/%m/%Y %H:%i'),
        STR_TO_DATE(NULLIF(TRIM(order_delivered_customer_date), ''), '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(NULLIF(TRIM(order_delivered_customer_date), ''), '%Y-%m-%d %H:%i')),
    COALESCE(
        STR_TO_DATE(NULLIF(TRIM(order_estimated_delivery_date), ''), '%d/%m/%Y %H:%i:%s'),
        STR_TO_DATE(NULLIF(TRIM(order_estimated_delivery_date), ''), '%d/%m/%Y %H:%i'),
        STR_TO_DATE(NULLIF(TRIM(order_estimated_delivery_date), ''), '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(NULLIF(TRIM(order_estimated_delivery_date), ''), '%Y-%m-%d %H:%i'))
FROM OLIST_ORDER_STAGING;

DROP TABLE IF EXISTS OLIST_ORDER_STAGING;

-- ========================================================
-- 5. الموقع الجغرافي (GEOLOCATION)
-- ========================================================
CREATE TABLE IF NOT EXISTS GEOLOCATION (
    geolocation_zip_code_prefix INT,
    geolocation_lat             DECIMAL(11,8),
    geolocation_lng             DECIMAL(11,8),
    geolocation_city            VARCHAR(100),
    geolocation_state           CHAR(2)
);

TRUNCATE TABLE GEOLOCATION;

LOAD DATA LOCAL INFILE 'C:/project dadta base/olist_geolocation_dataset.csv'
INTO TABLE GEOLOCATION
FIELDS TERMINATED BY ';' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- ========================================================
-- 6. المنتجات (PRODUCTS) عبر Staging (لأن فيه قيم فاضية في أعمدة رقمية)
-- ========================================================
CREATE TABLE IF NOT EXISTS PRODUCTS (
    product_id                 VARCHAR(50) PRIMARY KEY,
    product_category_name      VARCHAR(100),
    product_name_lenght        INT,
    product_description_lenght INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT
);

DROP TABLE IF EXISTS PRODUCTS_STAGING;
CREATE TABLE PRODUCTS_STAGING (
    product_id                 VARCHAR(100),
    product_category_name      VARCHAR(100),
    product_name_lenght        VARCHAR(50),
    product_description_lenght VARCHAR(50),
    product_photos_qty         VARCHAR(50),
    product_weight_g           VARCHAR(50),
    product_length_cm          VARCHAR(50),
    product_height_cm          VARCHAR(50),
    product_width_cm           VARCHAR(50)
);

LOAD DATA LOCAL INFILE 'C:/project dadta base/olist_products_dataset.csv'
INTO TABLE PRODUCTS_STAGING
FIELDS TERMINATED BY ';' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

TRUNCATE TABLE PRODUCTS;

INSERT INTO PRODUCTS
SELECT
    TRIM(product_id),
    NULLIF(TRIM(product_category_name), ''),
    CAST(NULLIF(TRIM(product_name_lenght), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(product_description_lenght), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(product_photos_qty), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(product_weight_g), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(product_length_cm), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(product_height_cm), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(product_width_cm), '') AS UNSIGNED)
FROM PRODUCTS_STAGING;

DROP TABLE IF EXISTS PRODUCTS_STAGING;

-- ========================================================
-- 7. البائعين (SELLERS)
-- ========================================================
CREATE TABLE IF NOT EXISTS SELLERS (
    seller_id              VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city            VARCHAR(100),
    seller_state           CHAR(2)
);

TRUNCATE TABLE SELLERS;

LOAD DATA LOCAL INFILE 'C:/project dadta base/olist_sellers_dataset.csv'
INTO TABLE SELLERS
FIELDS TERMINATED BY ';' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- ========================================================
-- 8. الدفعات (PAYMENT)
-- ========================================================
CREATE TABLE IF NOT EXISTS PAYMENT (
    order_id             VARCHAR(50),
    payment_sequential   INT,
    payment_type         VARCHAR(50),
    payment_installments INT,
    payment_value        DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

TRUNCATE TABLE PAYMENT;

LOAD DATA LOCAL INFILE 'C:/project dadta base/olist_order_payments_dataset.csv'
INTO TABLE PAYMENT
FIELDS TERMINATED BY ';' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- ========================================================
-- 9. عناصر الطلبات (ORDER_ITEMS) عبر Staging (للتواريخ)
-- ========================================================
CREATE TABLE IF NOT EXISTS ORDER_ITEMS (
    order_id            VARCHAR(50),
    order_item_id       INT,
    product_id          VARCHAR(50),
    seller_id           VARCHAR(50),
    shipping_limit_date DATETIME,
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

DROP TABLE IF EXISTS ORDER_ITEMS_STAGING;
CREATE TABLE ORDER_ITEMS_STAGING (
    order_id            VARCHAR(100),
    order_item_id       VARCHAR(50),
    product_id          VARCHAR(100),
    seller_id           VARCHAR(100),
    shipping_limit_date VARCHAR(100),
    price               VARCHAR(50),
    freight_value       VARCHAR(50)
);

LOAD DATA LOCAL INFILE 'C:/project dadta base/olist_order_items_dataset.csv'
INTO TABLE ORDER_ITEMS_STAGING
FIELDS TERMINATED BY ';' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

TRUNCATE TABLE ORDER_ITEMS;

INSERT INTO ORDER_ITEMS
SELECT
    TRIM(order_id),
    CAST(TRIM(order_item_id) AS UNSIGNED),
    TRIM(product_id),
    TRIM(seller_id),
    COALESCE(
        STR_TO_DATE(NULLIF(TRIM(shipping_limit_date), ''), '%d/%m/%Y %H:%i:%s'),
        STR_TO_DATE(NULLIF(TRIM(shipping_limit_date), ''), '%d/%m/%Y %H:%i'),
        STR_TO_DATE(NULLIF(TRIM(shipping_limit_date), ''), '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(NULLIF(TRIM(shipping_limit_date), ''), '%Y-%m-%d %H:%i')),
    CAST(REPLACE(NULLIF(TRIM(price), ''), ',', '.') AS DECIMAL(10,2)),
    CAST(REPLACE(NULLIF(TRIM(freight_value), ''), ',', '.') AS DECIMAL(10,2))
FROM ORDER_ITEMS_STAGING;

DROP TABLE IF EXISTS ORDER_ITEMS_STAGING;

-- ========================================================
-- 10. تنظيف البيانات اليتيمة (نسخة واحدة بـ LEFT JOIN)
-- ========================================================
SET SQL_SAFE_UPDATES = 0;

-- طلبات بدون عميل
DELETE o FROM OLIST_ORDER o
LEFT JOIN CUSTOMER c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- دفعات بدون طلب
DELETE p FROM PAYMENT p
LEFT JOIN OLIST_ORDER o ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- عناصر بدون طلب / منتج / بائع
DELETE oi FROM ORDER_ITEMS oi
LEFT JOIN OLIST_ORDER o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

DELETE oi FROM ORDER_ITEMS oi
LEFT JOIN PRODUCTS pr ON oi.product_id = pr.product_id
WHERE pr.product_id IS NULL;

DELETE oi FROM ORDER_ITEMS oi
LEFT JOIN SELLERS s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

SET SQL_SAFE_UPDATES = 1;

-- ========================================================
-- 11. المفاتيح الخارجية (مرة واحدة فقط، بعد التنظيف)
-- ========================================================
ALTER TABLE OLIST_ORDER
    ADD CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id);

ALTER TABLE ORDER_ITEMS
    ADD CONSTRAINT fk_items_orders   FOREIGN KEY (order_id)   REFERENCES OLIST_ORDER(order_id),
    ADD CONSTRAINT fk_items_products FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id),
    ADD CONSTRAINT fk_items_sellers  FOREIGN KEY (seller_id)  REFERENCES SELLERS(seller_id);

ALTER TABLE PAYMENT
    ADD CONSTRAINT fk_payment_orders FOREIGN KEY (order_id) REFERENCES OLIST_ORDER(order_id);

-- ========================================================
-- 12. فحص سريع للنتيجة
-- ========================================================
SELECT 'CUSTOMER'    AS tbl, COUNT(*) AS cnt FROM CUSTOMER
UNION ALL SELECT 'OLIST_ORDER', COUNT(*) FROM OLIST_ORDER
UNION ALL SELECT 'ORDER_ITEMS', COUNT(*) FROM ORDER_ITEMS
UNION ALL SELECT 'PRODUCTS',    COUNT(*) FROM PRODUCTS
UNION ALL SELECT 'SELLERS',     COUNT(*) FROM SELLERS
UNION ALL SELECT 'PAYMENT',     COUNT(*) FROM PAYMENT;