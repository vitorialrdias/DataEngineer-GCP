
  
    

    create or replace table `dataengineer-gcp-510313`.`datawarehouse`.`dm_order_items`
      
    
    

    
    OPTIONS()
    as (
      

select
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price
from `dataengineer-gcp-510313`.`staging`.`stg_order_items`
    );
  