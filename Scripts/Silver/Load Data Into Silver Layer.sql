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

update olist_dwh.silver.erp_orders
set 
    order_approved_at = order_delivered_customer_date,
    order_delivered_carrier_date = order_approved_at,
    order_delivered_customer_date = order_delivered_carrier_date
where order_approved_at  > order_delivered_customer_date and order_delivered_carrier_date > order_delivered_customer_date; 

update olist_dwh.silver.erp_orders
set 
    order_delivered_carrier_date = order_delivered_customer_date,
    order_delivered_customer_date = order_delivered_carrier_date
where order_delivered_carrier_date > order_delivered_customer_date; 






SELECT COUNT(*) AS invalid_orders
FROM olist_dwh.silver.erp_orders
WHERE
       order_purchase_timestamp > order_approved_at
    OR order_approved_at > order_delivered_carrier_date
    OR order_delivered_carrier_date > order_delivered_customer_date;