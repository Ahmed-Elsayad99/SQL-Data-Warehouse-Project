/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'Silver' schema
===============================================================================

*/
--================================================================--
-- DDL ERP Source in Silver layer
-- erp_orders table
create table silver.erp_Orders (
order_id varchar(50), 
customer_id varchar(50),
order_status varchar(50),
order_purchase_timestamp datetime,
order_approved_at datetime,
order_delivered_carrier_date datetime,
order_delivered_customer_date datetime,
order_estimated_delivery_date datetime,
dwh_create_date datetime default getdate( )
);
go


-- erp_order_items
create table silver.erp_order_items (
order_id varchar(50),
order_item_id int,
product_id varchar(50),
seller_id varchar(50),
shipping_limit_date datetime,
price decimal(10,2),
freight_value decimal(10,2),
dwh_create_date datetime default getdate( )
);
go


-- erp_order_payments
create table silver.erp_order_payments(
order_id varchar(50),
payment_sequential int,
payment_type varchar(50),
payment_installments int,
payment_value decimal(10,2),
dwh_create_date datetime default getdate( )
)
go


-- erp_order_reviews
create table silver.erp_order_reviews(
review_id varchar(max),
order_id varchar(max),
review_score int,
review_comment_title nvarchar(max),
review_comment_message nvarchar(max),
review_creation_date datetime,
review_answer_timestamp datetime,
dwh_create_date datetime default getdate( )
)
go

--================================================================--
-- DDL CRM Source in Silver layer
-- crm_customers
create table silver.crm_customers(
customer_id varchar(100),
customer_unique_id varchar(100),
customer_zip_code_prefix int,
customer_city varchar(100),
customer_state varchar(100),
dwh_create_date datetime default getdate( )
);
go
				
-- crm_geo_location
create table silver.crm_geo_location(
geolocation_zip_code_prefix int,
geolocation_lat decimal(10,6),
geolocation_lng decimal(10,6),
geolocation_city varchar(100),
geolocation_state varchar(100),
dwh_create_date datetime default getdate( )
);
go


--================================================================--
-- DDL CSV Source in Silver layer
-- csv_sellers
create table silver.csv_sellers(
seller_id varchar(100),
seller_zip_code_prefix int,
seller_city varchar(100),
seller_state varchar(100),
dwh_create_date datetime default getdate( )
);
go


-- csv_products		
create table silver.csv_products(
product_id varchar(100),
product_category_name varchar(100),
product_name_lenght int,
product_description_lenght int,
product_photos_qty int,
product_weight_g int,
product_length_cm int,
product_height_cm int,
product_width_cm int,
dwh_create_date datetime default getdate( )
);
go


-- csv_product_categories
create table silver.csv_product_Categories(
product_category_id bigint identity(1,1) primary key,
product_category_name varchar(225),
product_category_name_english varchar(225),
dwh_create_date datetime default getdate( )
);
go




