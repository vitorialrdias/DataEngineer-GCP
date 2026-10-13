{{ config(materialized= 'view')}}

select
    SAFE_DIVIDE(
    SUM(unit_price * quantity),
    COUNT(DISTINCT order_id)
    ) as ticket_medium
from {{ source('datawarehouse', 'ft_order_items')}}
group by order_id