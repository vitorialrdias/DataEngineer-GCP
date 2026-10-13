select 
    SUM(oi.unit_price * oi.quantity) as gross_revenue,
    DATE_TRUNC(ord.created_at, MONTH) AS month,
from {{ ref('ft_order_items')}} oi
left join {{ ref('ft_orders')}} ord on ord.order_id = oi.order_id
where ord.status != 'Cancelled'
group by month