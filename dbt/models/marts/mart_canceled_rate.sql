select 
    coalesce(shipping_country, 'Não informado') as shipping_country,
    count(*)                                   as total_orders,
    countif(lower(status) = 'cancelled')       as canceled_orders,
    safe_divide(countif(lower(status) = 'cancelled'), count(*)) as cancel_rate
from {{ ref('ft_orders') }}
group by shipping_country