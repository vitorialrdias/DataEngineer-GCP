select
    SAFE_DIVIDE(
    SUM(unit_price * quantity),
    COUNT(DISTINCT oi.order_id)
    ) as ticket_medium,
    DATE_TRUNC(ord.created_at, MONTH) AS month,
from {{ ref('ft_order_items')}} oi
left join {{ ref('ft_orders')}} ord on ord.order_id = oi.order_id
group by month