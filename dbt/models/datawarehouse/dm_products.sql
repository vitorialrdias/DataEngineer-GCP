{{ config(materialized='table') }}

select
    product_id,
    product_name,
    category,
    brand,
    cost,
    price
from {{ source('staging', 'stg_products') }}
