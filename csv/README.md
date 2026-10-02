# Dados sintéticos — TechCommerce

Cinco arquivos CSV, gerados (não reais, não de nenhuma empresa de verdade), mas com volume e
qualidade de dado realistas — incluindo as sujeiras que dado de produção costuma ter. É pra você
carregar no seu próprio BigQuery e praticar em cima de algo de verdade.

| Arquivo | Linhas | O que é | Equivalente na arquitetura |
|---|---|---|---|
| `customers.csv` | 300 | Clientes | Cloud SQL (OLTP) |
| `products.csv` | 80 | Catálogo de produtos | Cloud SQL (OLTP) |
| `orders.csv` | 1.200 | Pedidos | Cloud SQL (OLTP) |
| `order_items.csv` | ~2.900 | Itens de cada pedido | Cloud SQL (OLTP) |
| `click_events.csv` | 6.000 | Eventos de clique/navegação | Pub/Sub → Dataflow |

## Sujeira de propósito (não é bug)

- `customers.csv`: ~3% das linhas têm `email` vazio; um punhado de e-mails está duplicado entre
  clientes diferentes.
- `orders.csv`: ~1% das linhas têm `shipping_country` vazio.
- `click_events.csv`: ~20% dos eventos não têm `customer_id` (visitante anônimo, não logado) —
  e `product_id` fica vazio em eventos do tipo `page_view`, porque não existe produto associado.

Isso é proposital: é exatamente o tipo de coisa que a camada **staging** (prata) do dbt deveria
tratar — nulo tratado, duplicata resolvida — antes de qualquer coisa chegar na camada **ouro**.

## Como carregar no BigQuery

### Opção A — pelo console (mais simples pra começar)

BigQuery → seu projeto → clique nos três pontinhos do dataset (ou crie um novo) → **Create table**
→ Source: **Upload** → selecione o CSV → marque **Auto detect schema** → Create table.

### Opção B — pela CLI (`bq`), reproduzível

```bash
# 1. crie o dataset de dev, se ainda não existir
bq --location=US mk --dataset --description "dados sintéticos TechCommerce" SEU_PROJETO:raw

# 2. carregue cada CSV numa tabela, detectando o schema automaticamente
bq load --autodetect --source_format=CSV --skip_leading_rows=1 \
  SEU_PROJETO:raw.customers customers.csv

bq load --autodetect --source_format=CSV --skip_leading_rows=1 \
  SEU_PROJETO:raw.products products.csv

bq load --autodetect --source_format=CSV --skip_leading_rows=1 \
  SEU_PROJETO:raw.orders orders.csv

bq load --autodetect --source_format=CSV --skip_leading_rows=1 \
  SEU_PROJETO:raw.order_items order_items.csv

bq load --autodetect --source_format=CSV --skip_leading_rows=1 \
  SEU_PROJETO:raw.click_events click_events.csv
```

Troque `SEU_PROJETO` pelo ID do seu projeto GCP (confira com `gcloud config list`).

### Opção C — como seeds do dbt

Copie os cinco arquivos pra dentro de `dbt/seeds/` do seu projeto dbt e rode:

```bash
dbt seed
```

O dbt cria uma tabela pra cada CSV, no dataset configurado no seu `profiles.yml` — sem precisar
do `bq load` manual. É o caminho mais próximo do que o time realmente usa no dia a dia.

## Depois de carregado — uma query pra confirmar

```sql
select
  o.order_id,
  c.full_name,
  o.status,
  count(oi.order_item_id) as itens,
  sum(oi.quantity * oi.unit_price) as valor_total
from `SEU_PROJETO.raw.orders` o
join `SEU_PROJETO.raw.customers` c using (customer_id)
join `SEU_PROJETO.raw.order_items` oi using (order_id)
group by 1, 2, 3
order by valor_total desc
limit 10;
```
