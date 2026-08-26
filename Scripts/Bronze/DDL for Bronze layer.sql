-- Create DWH and Schema
create database olist_dwh;
go
use olist_dwh;
go
create schema bronze;
go
create schema silver;
go
create schema gold;
go


/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema
===============================================================================

*/

-- DDL erp source for Bronze layer in DWH
-- Orders Table
create table bronze.erp_Orders (
order_id varchar(50), 
customer_id varchar(50),
order_status varchar(50),
order_purchase_timestamp datetime,
order_approved_at datetime,
order_delivered_carrier_date datetime,
order_delivered_customer_date datetime,
order_estimated_delivery_date datetime
);
go

-- Order Items Table
create table bronze.erp_order_items (
order_id varchar(50),
order_item_id int,
product_id varchar(50),
seller_id varchar(50),
shipping_limit_date datetime,
price decimal(10,2),
freight_value decimal(10,2)
);
go

-- Order Payments Table
create table bronze.erp_order_payments(
order_id varchar(50),
payment_sequential int,
payment_type varchar(50),
payment_installments int,
payment_value decimal(10,2)
)
go

-- Order Reviews Table
create table bronze.erp_order_reviews(
review_id nvarchar(max),
order_id nvarchar(max),
review_score int,
review_comment_title nvarchar(max),
review_comment_message nvarchar(max),
review_creation_date nvarchar(max),
review_answer_timestamp nvarchar(max)
)
go


-- DDL CRM Source for Bronze layer in DWH
-- Customers Table
create table bronze.crm_customers(
customer_id varchar(100),
customer_unique_id varchar(100),
customer_zip_code_prefix varchar(100),
customer_city varchar(100),
customer_state varchar(100)
);
go
				
-- Geo Location Table
create table bronze.crm_geo_location(
geolocation_zip_code_prefix varchar(100),
geolocation_lat varchar(100),
geolocation_lng varchar(100),
geolocation_city nvarchar(100),
geolocation_state nvarchar(100)
);
go


-- DDL CSV Source for Bronze layer in DWH

-- sellers Table
create table bronze.csv_sellers(
seller_id varchar(100),
seller_zip_code_prefix varchar(50),
seller_city varchar(100),
seller_state varchar(100)
);
go

-- Products	Table					
create table bronze.csv_products(
product_id varchar(100),
product_category_name varchar(100),
product_name_lenght int,
product_description_lenght int,
product_photos_qty int,
product_weight_g int,
product_length_cm int,
product_height_cm int,
product_width_cm int
);
go

-- Product Categories Table
create table bronze.csv_product_Categories(
product_category_name nvarchar(225),
product_category_name_english nvarchar(225)
);
go


