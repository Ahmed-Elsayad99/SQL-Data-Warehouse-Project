/*
===============================================================================
ETL Script: Create Automated ETL Pipelines Process
===============================================================================
Script Purpose:
    This script creates Automated ETL Pipelines Process in the 'Gold' schema
===============================================================================
*/

EXEC gold.load_gold;
GO

CREATE OR ALTER PROCEDURE gold.load_gold AS
BEGIN
Print '=====================================================';
Print 'Loading Gold Layer';
Print '=====================================================';

Print '-----------------------------------------------------';
Print 'Loading Dimension Tables';
Print '-----------------------------------------------------';


Print 'Truncating Table: olist_dwh.gold.dim_location';
Truncate Table olist_dwh.gold.dim_location;
Print 'Inserting Data Into: olist_dwh.gold.dim_location';

INSERT INTO olist_dwh.gold.dim_location (
    city,
    state,
    create_date
)

SELECT DISTINCT
    geolocation_city,
    geolocation_state,
    dwh_create_date
FROM olist_dwh.silver.crm_geo_location;


-- ================================================================================================== --

Print 'Truncating Table: olist_dwh.gold.dim_customers';
Truncate Table olist_dwh.gold.dim_customers;
Print 'Inserting Data Into: olist_dwh.gold.dim_customers';


INSERT INTO olist_dwh.gold.dim_customers (
    customer_id,
    customer_unique_id,
    location_sk,
    create_date
    )

SELECT
    c.customer_id,
    c.customer_unique_id,
    l.location_sk,
    c.dwh_create_date
FROM olist_dwh.silver.crm_customers c
LEFT JOIN olist_dwh.gold.dim_location l
    ON c.customer_city = l.city
    AND c.customer_state = l.state;


-- ================================================================================================== --

Print 'Truncating Table: olist_dwh.gold.dim_sellers';
Truncate Table olist_dwh.gold.dim_sellers;
Print 'Inserting Data Into: olist_dwh.gold.dim_sellers';

INSERT INTO olist_dwh.gold.dim_sellers (
    seller_id,
    location_sk,
    create_date 
    )

SELECT
    s.seller_id,
    l.location_sk,
    s.dwh_create_date
FROM olist_dwh.silver.csv_sellers s
LEFT JOIN olist_dwh.gold.dim_location l
    ON s.seller_city = l.city
    AND s.seller_state = l.state;

-- ================================================================================================== --

Print 'Truncating Table: olist_dwh.gold.dim_product_categories';
Truncate Table olist_dwh.gold.dim_product_categories;
Print 'Inserting Data Into: olist_dwh.gold.dim_product_categories';

INSERT INTO olist_dwh.gold.dim_product_categories (
    product_category_id,
    product_category_name,
    product_category_name_engilsh,
    create_date 
    )

SELECT
    product_category_id,
    product_category_name,
    product_category_name_english,
    dwh_create_date
FROM olist_dwh.silver.csv_product_categories;

-- ================================================================================================== --

Print 'Truncating Table: olist_dwh.gold.dim_products';
Truncate Table olist_dwh.gold.dim_products;
Print 'Inserting Data Into: olist_dwh.gold.dim_products';

INSERT INTO olist_dwh.gold.dim_products (
    product_id,
    product_category_id,
    weight_g,
    length_cm,
    height_cm,
    width_cm,
    create_date 
    )

SELECT
    p.product_id,
    pc.product_category_id,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    p.dwh_create_date
FROM olist_dwh.silver.csv_products p
LEFT JOIN olist_dwh.gold.dim_product_categories pc
    ON  p.product_category_name = pc.product_category_name;


-- ================================================================================================== --

Print '-----------------------------------------------------';
Print 'Loading Fact Tables';
Print '-----------------------------------------------------';

Print 'Truncating Table: olist_dwh.gold.fact_orders';
Truncate Table olist_dwh.gold.fact_orders;
Print 'Inserting Data Into: olist_dwh.gold.fact_orders';


INSERT INTO olist_dwh.gold.fact_orders (
    order_id,
	customer_sk,
	order_status,
	purchase_date,
	approved_date,
	delivered_carrier_date,
	expected_delivery_date,
	delivered_customer_date,
	create_date
	)
SELECT 
    o.order_id,
	c.customer_sk,
	o.order_status,
	CAST(o.order_purchase_timestamp AS DATE) AS purchase_date,
	CAST(o.order_approved_at AS DATE) AS approved_date,
	CAST(o.order_delivered_carrier_date AS DATE) AS delivered_carrier_date,
	CAST(o.order_estimated_delivery_date AS DATE) AS expected_delivery_date,
	CAST(o.order_delivered_customer_date AS DATE) AS delivered_customer_date,
    o.dwh_create_date
FROM olist_dwh.silver.erp_orders o
LEFT JOIN olist_dwh.gold.dim_customers c
    on o.customer_id = c.customer_id ;


-- ================================================================================================== --

Print 'Truncating Table: olist_dwh.gold.fact_order_items';
Truncate Table olist_dwh.gold.fact_order_items;
Print 'Inserting Data Into: olist_dwh.gold.fact_order_items';

INSERT INTO olist_dwh.gold.fact_order_items (
    order_sk,
    order_item_id,
    product_sk,
    seller_sk,
    shipping_limit_date,
    price,
    freight_value,
    create_date 
    )

SELECT
    o.order_sk,
    oi.order_item_id,
    p.product_sk,
    s.seller_sk,
    CAST(oi.shipping_limit_date AS DATE) AS shipping_limit_date,
    oi.price,
    oi.freight_value,
    oi.dwh_create_date
FROM olist_dwh.silver.erp_order_items oi
LEFT JOIN olist_dwh.gold.fact_orders o
    ON  oi.order_id = o.order_id
LEFT JOIN olist_dwh.gold.dim_products p
    ON oi.product_id = p.product_id
LEFT JOIN olist_dwh.gold.dim_sellers s
    ON oi.seller_id = s.seller_id;


-- ================================================================================================== --

Print 'Truncating Table: olist_dwh.gold.fact_order_payments';
Truncate Table olist_dwh.gold.fact_order_payments;
Print 'Inserting Data Into: olist_dwh.gold.fact_order_payments';

INSERT INTO olist_dwh.gold.fact_order_payments (
    order_sk,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,
    create_date 
    )

SELECT
    o.order_sk,
    op.payment_sequential,
    op.payment_type,
    op.payment_installments,
    op.payment_value,
    op.dwh_create_date
FROM olist_dwh.silver.erp_order_payments op
LEFT JOIN olist_dwh.gold.fact_orders o
    ON  op.order_id = o.order_id;


-- ================================================================================================== --

Print 'Truncating Table: olist_dwh.gold.fact_order_reviews';
Truncate Table olist_dwh.gold.fact_order_reviews;
Print 'Inserting Data Into: olist_dwh.gold.fact_order_reviews';

INSERT INTO olist_dwh.gold.fact_order_reviews (
    review_id,
    order_sk,
    review_score,
    review_creation_date,
    review_answer_date,
    create_date 
    )

SELECT
    ov.review_id,
    o.order_sk,
    ov.review_score,
    CAST(ov.review_creation_date AS DATE) review_creation_date,
    CAST(ov.review_answer_timestamp AS DATE) review_answer_date,
    ov.dwh_create_date
FROM olist_dwh.silver.erp_order_reviews ov
LEFT JOIN olist_dwh.gold.fact_orders o
    ON  ov.order_id = o.order_id;

END;
