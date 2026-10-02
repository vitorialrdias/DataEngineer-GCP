
  
    

    create or replace table `dataengineer-gcp-510313`.`raw_trusted`.`trusted_orders`
      
    
    

    
    OPTIONS()
    as (
      

select
    order_id,
    customer_id,
    created_at,
    status,
    shipping_country
from `dataengineer-gcp-510313`.`raw`.`raw_orders`
    );
  