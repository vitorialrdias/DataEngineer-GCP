# Pipeline de Dados com GCP — TechCommerce

Projeto acadêmico de engenharia de dados na Google Cloud Platform, implementando um pipeline ELT completo com dados sintéticos de um e-commerce fictício. O objetivo é praticar a integração entre ferramentas modernas de ingestão, orquestração, armazenamento e transformação de dados.

---

## Arquitetura

```
CSVs Locais
    │
    ▼
[extract_csv.py]
    │  upload
    ▼
Google Cloud Storage (bucket: techcommerce-raw)
    │
    ▼
[load_raw.py]
    │  load com autodetect
    ▼
BigQuery — dataset: staging
    │  (stg_orders, stg_order_items, stg_products, stg_customers, stg_click_events)
    │
    ▼
dbt (Cloud Composer)
    │  modelos SQL
    ▼
BigQuery — dataset: datawarehouse
    (ft_orders, ft_order_items, ft_click_events, dm_customers, dm_products)
```

A orquestração é feita via **Cloud Composer 3 (Airflow)** e o deploy do código é automatizado com **GitHub Actions**.

---

## Stack Tecnológica

| Camada | Tecnologia |
|---|---|
| Infraestrutura como código | Terraform >= 1.7 + provider Google ~> 5.0 |
| Armazenamento de objetos | Google Cloud Storage |
| Data Warehouse | BigQuery (datasets `staging` e `datawarehouse`) |
| Orquestração | Apache Airflow 2.11.1 via Cloud Composer 3 |
| Transformação | dbt-core 1.9.0 + dbt-bigquery 1.9.0 |
| Extração e Carga | Python 3 com `google-cloud-storage` e `google-cloud-bigquery` |
| CI/CD | GitHub Actions com Workload Identity Federation |

---

## Estrutura do Projeto

```
DataEngineer-GCP/
├── .github/workflows/
│   └── deploy_composer.yml     # Deploy automático para o Cloud Composer
├── csv/
│   ├── customers.csv           # 300 clientes sintéticos
│   ├── products.csv            # 80 produtos
│   ├── orders.csv              # 1.200 pedidos
│   ├── order_items.csv         # ~2.900 itens de pedido
│   └── click_events.csv        # 6.000 eventos de clique
├── dags/
│   └── techcommerce_daily_pipeline.py  # DAG Airflow
├── dbt/
│   ├── dbt_project.yml
│   └── models/datawarehouse/
│       ├── _sources.yml
│       ├── ft_orders.sql
│       ├── ft_order_items.sql
│       ├── ft_click_events.sql
│       ├── dm_customers.sql
│       └── dm_products.sql
├── extract/
│   ├── extract_csv.py          # Upload CSV → GCS
│   └── load_raw.py             # Load GCS → BigQuery staging
├── terraform/
│   ├── environments/dev/       # Configuração do ambiente
│   └── modules/                # Módulos: bigquery, storage, composer
└── requirements.txt
```

---

## Pipeline ELT

### 1. Extract — `extract/extract_csv.py`

Lê os 5 arquivos CSV locais e faz upload para o bucket `techcommerce-raw` no GCS usando a biblioteca `google-cloud-storage`.

### 2. Load — `extract/load_raw.py`

Lê cada objeto do GCS e carrega nas tabelas do dataset `staging` no BigQuery com detecção automática de schema (`autodetect=True`) e substituição completa (`WRITE_TRUNCATE`).

### 3. Transform — dbt (`dbt/models/datawarehouse/`)

Lê das tabelas de staging e grava no dataset `datawarehouse`. Todos os modelos são materializados como `table`.

| Modelo | Tipo | Descrição |
|---|---|---|
| `ft_orders` | Fato | Pedidos com status e país de envio |
| `ft_order_items` | Fato | Itens por pedido com preço unitário |
| `ft_click_events` | Fato | Eventos de clique por sessão/dispositivo |
| `dm_customers` | Dimensão | Perfil de clientes com canal de aquisição |
| `dm_products` | Dimensão | Catálogo de produtos com custo e preço |

### 4. Orquestração — DAG Airflow

A DAG `techcommerce_daily_pipeline` encadeia as tarefas em sequência:

```
load_raw() >> run_dbt
```

O dbt é executado via `BashOperator` apontando para os arquivos montados pelo Cloud Composer no GCS.

---

## Infraestrutura com Terraform

Os recursos GCP são provisionados via Terraform no diretório `terraform/environments/dev/`:

- **Google Cloud Storage** — bucket `techcommerce-raw` para landing zone
- **BigQuery** — datasets `staging` e `datawarehouse` na região US
- **Cloud Composer 3** — ambiente Airflow com service account dedicada
- **IAM** — service account `composer-techcommerce` com roles mínimas necessárias

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

---

## CI/CD com GitHub Actions

O workflow `.github/workflows/deploy_composer.yml` é ativado por push na branch `dev` com mudanças em `dags/`, `extract/`, `dbt/` ou `.github/workflows/`.

Etapas do deploy:
1. Autenticação via **Workload Identity Federation** (sem chave JSON)
2. Upload do DAG e da pasta `extract/` para o bucket do Composer
3. Upload do projeto `dbt/` para a pasta `data/` do Composer

---

## Dados Sintéticos

Os CSVs foram gerados com imperfeições intencionais para simular dados reais:

- ~3% dos clientes têm e-mail vazio ou duplicado
- ~1% dos pedidos têm `shipping_country` vazio
- ~20% dos `click_events` não têm `customer_id` (visitantes anônimos)

---

## Serviços GCP Utilizados

| Serviço | Uso |
|---|---|
| Cloud Storage | Landing zone raw e armazenamento interno do Composer |
| BigQuery | Camadas de staging e datawarehouse |
| Cloud Composer 3 | Orquestração do pipeline ELT |
| IAM / Service Accounts | Controle de acesso com privilégio mínimo |
| Workload Identity Federation | Autenticação do GitHub Actions sem chave JSON |

Projeto GCP: `dataengineer-gcp-510313` — Região: `us-east1`

---

## Próximas Etapas (Trabalhos Futuros)

- [ ] Ingestão em streaming de `click_events` via Pub/Sub + Dataflow (Apache Beam já declarado no `requirements.txt`)
- [ ] Limpeza de dados na camada staging do dbt (tratamento de nulos e duplicatas)
- [ ] Testes dbt para validação de schema e dados
- [ ] Monitoramento e alertas do pipeline

---

## Pré-requisitos

- Python 3.11+
- Terraform >= 1.7
- dbt-core 1.9.0 e dbt-bigquery 1.9.0
- Conta GCP com as APIs habilitadas: BigQuery, Cloud Storage, Cloud Composer
- Autenticação: `gcloud auth application-default login`

```bash
pip install -r requirements.txt
```

---

**Autora:** Vitoria Ribeiro Dias  
**Contexto:** Projeto de aprendizado em Engenharia de Dados com GCP
