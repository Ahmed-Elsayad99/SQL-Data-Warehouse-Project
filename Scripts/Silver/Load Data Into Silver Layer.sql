/*
===============================================================================
ETL Script: Create Automated ETL Pipelines Process
===============================================================================
Script Purpose:
    This script creates Automated ETL Pipelines Process in the 'Silver' schema
===============================================================================
*/

EXEC silver.load_silver;
GO

Create or Alter Procedure silver.load_silver as
Begin
Print '=====================================================';
Print 'Loading Silver Layer';
Print '=====================================================';

Print '-----------------------------------------------------';
Print 'Loading ERP Tables';
Print '-----------------------------------------------------';


Print 'Truncating Table: olist_dwh.silver.erp_orders';
Truncate Table olist_dwh.silver.erp_orders;
Print 'Inserting Data Into: olist_dwh.silver.erp_orders';


with cleaned_a as (
    SELECT 
       UPPER(REPLACE(TRIM(order_id), '"','')) as order_id,
       UPPER(REPLACE(TRIM(customer_id), '"','')) as customer_id,
       UPPER(TRIM(order_status)) as order_status,
       
       Case 
          when order_purchase_timestamp > order_delivered_carrier_date and order_approved_at  > order_delivered_carrier_date
            then order_delivered_carrier_date
          else order_purchase_timestamp
       end as order_purchase_timestamp,

       Case 
          when order_purchase_timestamp > order_delivered_carrier_date and order_approved_at  > order_delivered_carrier_date
            then order_purchase_timestamp
          when order_approved_at  > order_delivered_carrier_date and order_approved_at  > order_delivered_customer_date
            and order_approved_at  > order_estimated_delivery_date 
            then order_delivered_carrier_date
          when order_approved_at  > order_delivered_carrier_date and order_approved_at  > order_delivered_customer_date
            then order_delivered_carrier_date
          when order_approved_at  > order_delivered_carrier_date
            then order_delivered_carrier_date
          when order_approved_at  > order_estimated_delivery_date
            then order_estimated_delivery_date
          else order_approved_at
       end as order_approved_at,

       Case 
         when order_purchase_timestamp > order_delivered_carrier_date and order_approved_at  > order_delivered_carrier_date
           then order_approved_at
         when order_approved_at  > order_delivered_carrier_date and order_approved_at  > order_delivered_customer_date
            and order_approved_at  > order_estimated_delivery_date 
           then order_delivered_customer_date
         when order_approved_at  > order_delivered_carrier_date and order_approved_at  > order_delivered_customer_date
           then order_delivered_customer_date
         when order_approved_at  > order_delivered_carrier_date
           then order_approved_at
         when order_delivered_carrier_date  > order_delivered_customer_date
           then order_delivered_customer_date
         when order_delivered_carrier_date  > order_estimated_delivery_date
           then order_estimated_delivery_date
         else order_delivered_carrier_date
      end as order_delivered_carrier_date,
    
      case 
        when order_approved_at  > order_delivered_carrier_date and order_approved_at  > order_delivered_customer_date
            and order_approved_at  > order_estimated_delivery_date 
          then order_estimated_delivery_date
        when order_approved_at  > order_delivered_carrier_date and order_approved_at  > order_delivered_customer_date
          then order_approved_at
        when order_delivered_carrier_date  > order_delivered_customer_date
          then order_delivered_carrier_date
        else order_delivered_customer_date
     end as order_delivered_customer_date,

     case 
       when order_approved_at  > order_delivered_carrier_date and order_approved_at  > order_delivered_customer_date
            and order_approved_at  > order_estimated_delivery_date 
         then order_approved_at
       when order_approved_at  > order_estimated_delivery_date
         then order_approved_at
       when order_delivered_carrier_date  > order_estimated_delivery_date
         then order_delivered_carrier_date
       else order_estimated_delivery_date
    end as order_estimated_delivery_date
  FROM olist_dwh.bronze.erp_Orders), 

cleaned_b as (      
  select 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,

    case 
       when order_approved_at  > order_delivered_customer_date and order_delivered_carrier_date > order_delivered_customer_date 
        then order_delivered_customer_date       
       else order_approved_at
    end as order_approved_at, 

    case 
       when order_approved_at  > order_delivered_customer_date and order_delivered_carrier_date > order_delivered_customer_date
        then order_approved_at
       when order_delivered_carrier_date > order_delivered_customer_date
        then order_delivered_customer_date
       else order_delivered_carrier_date
    end as order_delivered_carrier_date, 

    case 
       when order_approved_at  > order_delivered_customer_date and order_delivered_carrier_date > order_delivered_customer_date
        then order_delivered_carrier_date
       when order_delivered_carrier_date > order_delivered_customer_date
        then order_delivered_carrier_date
       else order_delivered_customer_date
    end as order_delivered_customer_date, 

    order_estimated_delivery_date  
  from cleaned_a )
 
insert into olist_dwh.silver.erp_orders 
     (
       order_id,
       customer_id,
       order_status,
       order_purchase_timestamp,
       order_approved_at,
       order_delivered_carrier_date,
       order_delivered_customer_date,
       order_estimated_delivery_date
      )
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM cleaned_b;


-- ================================================================================================== --

Print 'Truncating Table: olist_dwh.silver.erp_order_items';
Truncate Table olist_dwh.silver.erp_order_items;
Print 'Inserting Data Into: olist_dwh.silver.erp_order_items';

insert into olist_dwh.silver.erp_order_items
     (
       order_id,
       order_item_id,
       product_id,
       seller_id,
       shipping_limit_date,
       price,
       freight_value
      )
SELECT 
    UPPER(REPLACE(TRIM(order_id), '"','')) as order_id,
    order_item_id,
    UPPER(REPLACE(TRIM(product_id), '"','')) as product_id,
    UPPER(REPLACE(TRIM(seller_id), '"','')) as seller_id,
    shipping_limit_date,
    price,
    freight_value
from olist_dwh.bronze.erp_order_items;

-- ================================================================================================== --

Print 'Truncating Table: olist_dwh.silver.erp_order_payments';
Truncate Table olist_dwh.silver.erp_order_payments;
Print 'Inserting Data Into: olist_dwh.silver.erp_order_payments';


insert into olist_dwh.silver.erp_order_payments
     (
       order_id,
       payment_sequential,
       payment_type,
       payment_installments,
       payment_value
      )
select 
   UPPER(REPLACE(TRIM(order_id), '"','')) as order_id,
   payment_sequential,
   UPPER(payment_type) as payment_type,
   payment_installments,
   payment_value
from olist_dwh.bronze.erp_order_payments;

-- ================================================================================================== --

Print 'Truncating Table: olist_dwh.silver.erp_order_reviews';
Truncate Table olist_dwh.silver.erp_order_reviews;
Print 'Inserting Data Into: olist_dwh.silver.erp_order_reviews';


insert into olist_dwh.silver.erp_order_reviews
     (
       review_id,
       order_id,
       review_score,
       review_comment_title,
       review_comment_message,
       review_creation_date,
       review_answer_timestamp
      )
select
    UPPER(REPLACE(TRIM(review_id), '"','')) as review_id,
    UPPER(REPLACE(TRIM(order_id), '"','')) as order_id,
    review_score,
    Coalesce(review_comment_title, 'n/a') as review_comment_title,
    Coalesce(review_comment_message, 'n/a') as review_comment_message,
    review_creation_date,
    review_answer_timestamp
from olist_dwh.bronze.erp_order_reviews;

-- ================================================================================================== --

Print '-----------------------------------------------------';
Print 'Loading CRM Tables';
Print '-----------------------------------------------------';


Print 'Truncating Table: olist_dwh.silver.crm_customers';
Truncate Table olist_dwh.silver.crm_customers;
Print 'Inserting Data Into: olist_dwh.silver.crm_customers';


insert into olist_dwh.silver.crm_customers
     (
       customer_id,
       customer_unique_id,
       customer_zip_code_prefix,
       customer_city,
       customer_state
      )
select
    UPPER(REPLACE(TRIM(customer_id), '"','')) as customer_id,
    UPPER(REPLACE(TRIM(customer_unique_id), '"','')) as customer_unique_id,
    REPLACE(TRIM(customer_zip_code_prefix), '"','') as customer_zip_code_prefix,
    UPPER(TRIM(customer_city)) as customer_city,
    
    CASE UPPER(TRIM(customer_state))
      WHEN 'PE' THEN 'Pernambuco'
      WHEN 'PB' THEN 'Paraiba'
      WHEN 'PA' THEN 'Para'
      WHEN 'RS' THEN 'Rio Grande do Sul'
      WHEN 'AC' THEN 'Acre'
      WHEN 'BA' THEN 'Bahia'
      WHEN 'SP' THEN 'Sao Paulo'
      WHEN 'SC' THEN 'Santa Catarina'
      WHEN 'SE' THEN 'Sergipe'
      WHEN 'MA' THEN 'Maranhao'
      WHEN 'TO' THEN 'Tocantins'
      WHEN 'RO' THEN 'Rondonia'
      WHEN 'DF' THEN 'Distrito Federal'
      WHEN 'MT' THEN 'Mato Grosso'
      WHEN 'PR' THEN 'Parana'
      WHEN 'CE' THEN 'Ceara'
      WHEN 'AL' THEN 'Alagoas'
      WHEN 'RR' THEN 'Roraima'
      WHEN 'MG' THEN 'Minas Gerais'
      WHEN 'MS' THEN 'Mato Grosso do Sul'
      WHEN 'GO' THEN 'Goias'
      WHEN 'RN' THEN 'Rio Grande do Norte'
      WHEN 'AP' THEN 'Amapa'
      WHEN 'RJ' THEN 'Rio de Janeiro'
      WHEN 'ES' THEN 'Espirito Santo'
      WHEN 'PI' THEN 'Piaui'
      WHEN 'AM' THEN 'Amazonas'
      ELSE UPPER(TRIM(customer_state))
    END AS customer_state
FROM olist_dwh.bronze.crm_customers;

update olist_dwh.silver.crm_customers
set customer_state = UPPER(customer_state);

-- ================================================================================================== --


Print 'Truncating Table: olist_dwh.silver.crm_geo_location';
Truncate Table olist_dwh.silver.crm_geo_location;
Print 'Inserting Data Into: olist_dwh.silver.crm_geo_location';


insert into olist_dwh.silver.crm_geo_location
     (
       geolocation_zip_code_prefix,
       geolocation_lat,
       geolocation_lng,
       geolocation_city,
       geolocation_state
      )
select 
    TRIM(geolocation_zip_code_prefix) AS geolocation_zip_code_prefix,
    ROUND(geolocation_lat,6) AS geolocation_lat,
    ROUND(geolocation_lng,6) AS geolocation_lng,
    TRIM(REPLACE(geolocation_city, '"', '')) AS geolocation_city,
    
    CASE UPPER(LEFT(RIGHT(TRIM(geolocation_state), 3),2))
      WHEN 'PE' THEN 'Pernambuco'
      WHEN 'PB' THEN 'Paraiba'
      WHEN 'PA' THEN 'Para'
      WHEN 'RS' THEN 'Rio Grande do Sul'
      WHEN 'AC' THEN 'Acre'
      WHEN 'BA' THEN 'Bahia'
      WHEN 'SP' THEN 'Sao Paulo'
      WHEN 'SC' THEN 'Santa Catarina'
      WHEN 'SE' THEN 'Sergipe'
      WHEN 'MA' THEN 'Maranhao'
      WHEN 'TO' THEN 'Tocantins'
      WHEN 'RO' THEN 'Rondonia'
      WHEN 'DF' THEN 'Distrito Federal'
      WHEN 'MT' THEN 'Mato Grosso'
      WHEN 'PR' THEN 'Parana'
      WHEN 'CE' THEN 'Ceara'
      WHEN 'AL' THEN 'Alagoas'
      WHEN 'RR' THEN 'Roraima'
      WHEN 'MG' THEN 'Minas Gerais'
      WHEN 'MS' THEN 'Mato Grosso do Sul'
      WHEN 'GO' THEN 'Goias'
      WHEN 'RN' THEN 'Rio Grande do Norte'
      WHEN 'AP' THEN 'Amapa'
      WHEN 'RJ' THEN 'Rio de Janeiro'
      WHEN 'ES' THEN 'Espirito Santo'
      WHEN 'PI' THEN 'Piaui'
      WHEN 'AM' THEN 'Amazonas'
      ELSE UPPER(LEFT(RIGHT(TRIM(geolocation_state), 3),2))
    END AS geolocation_state
FROM olist_dwh.bronze.crm_geo_location;

update olist_dwh.silver.crm_geo_location
set geolocation_state = UPPER(geolocation_state);

-- ================================================================================================== --

-- ================================================================================================== --
Print '-----------------------------------------------------';
Print 'Loading CSV Tables';
Print '-----------------------------------------------------';


Print 'Truncating Table: olist_dwh.silver.csv_sellers';
Truncate Table olist_dwh.silver.csv_sellers;
Print 'Inserting Data Into: olist_dwh.silver.csv_sellers';

insert into olist_dwh.silver.csv_sellers
     (
       seller_id,
       seller_zip_code_prefix,
       seller_city,
       seller_state
      )
SELECT 
    UPPER(TRIM(REPLACE(seller_id, '"', ''))) AS seller_id,
    TRIM(REPLACE(seller_zip_code_prefix, '"', '')) AS seller_zip_code_prefix,
    
    CASE TRIM(REPLACE(seller_city, '"',''))
      WHEN 'sbc' THEN 'sao bernardo do campo'
      WHEN 'vendas@creditparts.com.br' THEN 'curitiba'
      WHEN '04482255' THEN 'rio de janeiro'
      ELSE TRIM(REPLACE(seller_city, '"',''))
    END AS seller_city ,

    CASE UPPER(LEFT(RIGHT(TRIM(seller_state), 3),2))
      WHEN 'PE' THEN 'Pernambuco'
      WHEN 'PB' THEN 'Paraiba'
      WHEN 'PA' THEN 'Para'
      WHEN 'RS' THEN 'Rio Grande do Sul'
      WHEN 'AC' THEN 'Acre'
      WHEN 'BA' THEN 'Bahia'
      WHEN 'SP' THEN 'Sao Paulo'
      WHEN 'SC' THEN 'Santa Catarina'
      WHEN 'SE' THEN 'Sergipe'
      WHEN 'MA' THEN 'Maranhao'
      WHEN 'TO' THEN 'Tocantins'
      WHEN 'RO' THEN 'Rondonia'
      WHEN 'DF' THEN 'Distrito Federal'
      WHEN 'MT' THEN 'Mato Grosso'
      WHEN 'PR' THEN 'Parana'
      WHEN 'CE' THEN 'Ceara'
      WHEN 'AL' THEN 'Alagoas'
      WHEN 'RR' THEN 'Roraima'
      WHEN 'MG' THEN 'Minas Gerais'
      WHEN 'MS' THEN 'Mato Grosso do Sul'
      WHEN 'GO' THEN 'Goias'
      WHEN 'RN' THEN 'Rio Grande do Norte'
      WHEN 'AP' THEN 'Amapa'
      WHEN 'RJ' THEN 'Rio de Janeiro'
      WHEN ',R' THEN 'Rio de Janeiro'
      WHEN 'ES' THEN 'Espirito Santo'
      WHEN 'PI' THEN 'Piaui'
      WHEN 'AM' THEN 'Amazonas'
      ELSE UPPER(LEFT(RIGHT(TRIM(seller_state), 3),2))
    END AS seller_state
FROM olist_dwh.bronze.csv_sellers;

UPDATE olist_dwh.silver.csv_sellers
SET 
   seller_city =
    UPPER(
     CASE
        WHEN seller_city like 'sao pa%' or seller_city = 'sp' THEN 'sao paulo'
        WHEN seller_city LIKE '%/%' THEN TRIM(LEFT(seller_city, CHARINDEX('/', seller_city + '/') - 1))
        WHEN seller_city LIKE '%(%' THEN TRIM(LEFT(seller_city, CHARINDEX('(', seller_city + '(') - 1))
        WHEN seller_city LIKE '%-%' THEN TRIM(LEFT(seller_city, CHARINDEX('-', seller_city + '-') - 1))
        ELSE TRIM(seller_city)
     END
     );

 
-- ================================================================================================== --


Print 'Truncating Table: olist_dwh.silver.csv_products';
Truncate Table olist_dwh.silver.csv_products;
Print 'Inserting Data Into: olist_dwh.silver.csv_products';

insert into olist_dwh.silver.csv_products
     (
       product_id,
       product_category_name,
       product_name_lenght,
       product_description_lenght,
       product_photos_qty,
       product_weight_g,
       product_length_cm,
       product_height_cm,
       product_width_cm
      )
SELECT 
    UPPER(TRIM(REPLACE(product_id, '"',''))) AS product_id,
    COALESCE(REPLACE(product_category_name, '_', ' '), 'n/a') AS product_category_name,
    COALESCE(product_name_lenght, 0) AS product_name_lenght,
    COALESCE(product_description_lenght, 0) AS product_description_lenght,
    COALESCE(product_photos_qty, 0) AS product_photos_qty,
    COALESCE(product_weight_g, 0) AS product_weight_g,
    COALESCE(product_length_cm, 0) AS product_length_cm,
    COALESCE(product_height_cm, 0) AS product_height_cm,
    COALESCE(product_width_cm, 0) AS product_width_cm
FROM olist_dwh.bronze.csv_products;

-- ================================================================================================== --


Print 'Truncating Table: olist_dwh.silver.csv_product_categories';
Truncate Table olist_dwh.silver.csv_product_categories;
Print 'Inserting Data Into: olist_dwh.silver.csv_product_categories';

insert into olist_dwh.silver.csv_product_categories
     (
       product_category_name,
       product_category_name_english
      )
SELECT 
   REPLACE(product_category_name, '_', ' ') AS product_category_name,
   REPLACE(product_category_name_english, '_', ' ') AS product_category_name_english
FROM olist_dwh.bronze.csv_product_categories;


End;