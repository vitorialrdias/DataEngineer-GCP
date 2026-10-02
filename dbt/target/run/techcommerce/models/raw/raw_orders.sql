
  
    

    create or replace table `dataengineer-gcp-510313`.`raw`.`raw_orders`
      
    
    

    
    OPTIONS()
    as (
      

select
    order_id,
    customer_id,
    cast(created_at as timestamp) as created_at,
    status,
    nullif(shipping_country, '') as shipping_country
from `dataengineer-gcp-510313`.`raw`.`orders`
    );
  