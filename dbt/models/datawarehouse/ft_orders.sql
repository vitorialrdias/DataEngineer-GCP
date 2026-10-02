{{ config(materialized='table') }}

select
    order_id,
    customer_id,
    cast(created_at as timestamp) as created_at,
    status,
    nullif(shipping_country, '') as shipping_country
from {{ source('staging', 'stg_orders') }}
