{{ config(materialized= 'view') }}

select 
    shipping_country,
    count(status) AS total_cancel
from {{ source('datawarehouse', 'ft_orders') }}
where LOWER(status) = 'cancelled'
group by shipping_country