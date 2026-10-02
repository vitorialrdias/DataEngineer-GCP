{{ config(materialized='table') }}

select
    customer_id,
    full_name,
    email,
    signup_date,
    country,
    marketing_channel
from {{ source('staging', 'stg_customers') }}
