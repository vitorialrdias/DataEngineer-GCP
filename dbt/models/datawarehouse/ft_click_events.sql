{{ config(materialized='table') }}

select
    event_id,
    product_id,
    session_id,
    customer_id,
    event_timestamp,
    event_type,
    device
from {{ source('staging', 'stg_click_events') }}