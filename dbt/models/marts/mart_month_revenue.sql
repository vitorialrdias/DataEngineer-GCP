{{ config(materialized='view')}}

select 
    SUM(oi.unit_price * oi.quantity) as revenue,
    DATE_TRUNC(ord.created_at, MONTH) AS month,
from {{ source('datawarehouse', 'ft_order_items')}} oi
left join {{ source('datawarehouse', 'ft_orders')}} ord on ord.order_id = oi.order_id
group by month