# Pipeline de Dados com GCP — TechCommerce

Projeto de aprendizado em engenharia de dados na Google Cloud Platform: um pipeline ELT completo, com dados sintéticos de um e-commerce fictício. O objetivo é praticar a integração entre infraestrutura como código, ingestão, orquestração, transformação em camadas e deploy automatizado.

---

## Arquitetura

```
CSVs locais
    │  extract_csv.py (upload manual)
    ▼
Cloud Storage — bucket: techcommerce-raw
    │  load_raw.py (autodetect, WRITE_TRUNCATE)        ← task Airflow: load_raw
    ▼
BigQuery — staging         (stg_*: dado bruto carregado)
    │  dbt run                                         ← task Airflow: run_dbt
    ▼
BigQuery — datawarehouse   (ft_* fatos, dm_* dimensões)
    │  dbt (views)
    ▼
BigQuery — marts           (mart_*: métricas agregadas)
```

A orquestração é feita pelo **Cloud Composer 3 (Airflow)** e o deploy do código é automatizado com **GitHub Actions**.

---

## Stack Tecnológica

| Camada | Tecnologia |
|---|---|
| Infraestrutura como código | Terraform >= 1.7 + provider Google ~> 5.0 |
| Armazenamento de objetos | Google Cloud Storage |
| Data Warehouse | BigQuery (datasets `staging`, `datawarehouse` e `marts`) |
| Orquestração | Apache Airflow 2.11.1 via Cloud Composer 3 |
| Transformação | dbt-core + dbt-bigquery (instalados no Composer via PyPI, sem versão fixa) |
| Extração e Carga | Python 3 com `google-cloud-storage` e `google-cloud-bigquery` |
| CI/CD | GitHub Actions com Workload Identity Federation (sem chave JSON) |

> As versões do dbt não são fixadas no Composer porque o `dbt-bigquery==1.9.0` entra em conflito com as dependências do Airflow 2.11.1.

---

## Estrutura do Projeto

```
DataEngineer-GCP/
├── .github/workflows/
│   └── deploy_composer.yml        # Deploy automático para o Cloud Composer
├── csv/                           # Dados sintéticos de origem (5 arquivos)
├── dags/
│   └── techcommerce_daily_pipeline.py   # DAG Airflow
├── dbt/
│   ├── dbt_project.yml
│   ├── macros/
│   │   └── generate_schema.sql    # Usa o nome do dataset exatamente como configurado
│   └── models/
│       ├── datawarehouse/         # Fatos e dimensões (tables)
│       │   ├── _sources.yml       # Fontes: dataset staging
│       │   ├── ft_orders.sql
│       │   ├── ft_order_items.sql
│       │   ├── ft_click_events.sql
│       │   ├── dm_customers.sql
│       │   └── dm_products.sql
│       └── marts/                 # Métricas agregadas (views)
│           ├── mart_month_revenue.sql
│           ├── mart_medium_ticket.sql
│           └── mart_canceled_rate.sql
├── extract/
│   ├── extract_csv.py             # Upload CSV → GCS (executado localmente)
│   └── load_raw.py                # Load GCS → BigQuery staging
├── terraform/
│   ├── environments/dev/          # Configuração do ambiente
│   └── modules/                   # Módulos: bigquery-dataset, storage-bucket, composer-environment
└── requirements.txt
```

---

## Pipeline ELT

### 1. Extract — `extract/extract_csv.py`

Lê os 5 arquivos CSV locais e envia para o bucket `techcommerce-raw` no GCS. Este passo roda na máquina local e **ainda não faz parte da DAG**.

### 2. Load — `extract/load_raw.py`

Lê cada objeto do GCS e carrega nas tabelas do dataset `staging` com detecção automática de schema (`autodetect=True`) e substituição completa da tabela (`WRITE_TRUNCATE`).

### 3. Transform — dbt

**Camada `datawarehouse`** (tables): lê de `staging` por `source()`.

| Modelo | Tipo | Descrição |
|---|---|---|
| `ft_orders` | Fato | Pedidos com status e país de envio (vazio vira `NULL`) |
| `ft_order_items` | Fato | Itens por pedido com quantidade e preço unitário |
| `ft_click_events` | Fato | Eventos de navegação por sessão, tipo de evento e dispositivo |
| `dm_customers` | Dimensão | Clientes com canal de aquisição |
| `dm_products` | Dimensão | Catálogo com custo e preço |

**Camada `marts`** (views): lê das fatos por `ref()`, o que permite ao dbt montar a ordem de execução e o grafo de linhagem.

| Modelo | Grão | Descrição |
|---|---|---|
| `mart_month_revenue` | mês | Receita mensal (itens × preço) sem pedidos cancelados, na coluna `gross_revenue` |
| `mart_medium_ticket` | mês | Ticket médio: receita dividida pelo número de pedidos |
| `mart_canceled_rate` | país de envio | Total de pedidos, cancelados e taxa de cancelamento |

O macro `generate_schema_name` faz o dbt gravar em `datawarehouse` e `marts` exatamente com esses nomes, sem concatenar com o dataset do profile.

### 4. Orquestração — DAG Airflow

A DAG `techcommerce_daily_pipeline` encadeia duas tarefas:

```
load_raw >> run_dbt
```

`load_raw` é uma task Python (TaskFlow API) e `run_dbt` executa `dbt run` por `BashOperator`, apontando para os arquivos do projeto e do profile na pasta `data/` do bucket do Composer. O `dbt run` sem seletor executa as duas camadas (`datawarehouse` e `marts`). Hoje a DAG é disparada manualmente (`schedule=None`).

---

## Regras de negócio das métricas

- **Receita** (`mart_month_revenue`) considera todos os pedidos, exceto os de status `Cancelled`. Pedidos `Returned` ainda entram.
- **Taxa de cancelamento** = pedidos cancelados ÷ total de pedidos do grupo. Pedidos sem país de envio aparecem no grupo "Não informado".
- **Ticket médio** (`mart_medium_ticket`) = receita dos itens ÷ pedidos distintos no mês. Ainda não aplica o filtro de pedidos cancelados da receita (ver pendências).
- Eventos de clique sem `customer_id` (visitantes anônimos) e `page_view` sem `product_id` são mantidos com `NULL`, sem valor substituto.

---

## Infraestrutura com Terraform

Os recursos são provisionados em `terraform/environments/dev/`:

- **Cloud Storage** — bucket `techcommerce-raw` (landing zone)
- **BigQuery** — datasets `staging`, `datawarehouse` e `marts` (região US)
- **Cloud Composer 3** — ambiente `techcommerce-dev` (us-east1), com pacotes dbt instalados e `ignore_changes` nos pacotes PyPI
- **IAM** — service account `composer-techcommerce` com `composer.worker`, `bigquery.dataEditor`, `bigquery.jobUser` e `storage.objectAdmin`

```bash
cd terraform/environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

O state é local e não é versionado (`*.tfstate` e `*.tfvars` estão no `.gitignore`).

---

## CI/CD com GitHub Actions

O workflow `.github/workflows/deploy_composer.yml` roda a cada push na branch `dev` que altere `dags/`, `extract/`, `dbt/` ou o próprio workflow (também pode ser disparado manualmente).

1. Autenticação por **Workload Identity Federation**: o GitHub emite um token OIDC que é trocado por credenciais temporárias da service account `techcommerce-ci`, sem nenhum segredo armazenado.
2. Importa a DAG e a pasta `extract/` para `dags/` do bucket do Composer.
3. Importa o projeto `dbt/` (modelos e macros) para `data/` do bucket do Composer.

Hoje o pipeline cobre apenas o **deploy (CD)**. Validações automáticas em pull request ainda não existem.

---

## Dados Sintéticos

Os CSVs foram gerados com imperfeições intencionais:

- `customers`: 3 e-mails vazios (1%) e 7 e-mails duplicados entre clientes diferentes.
- `orders`: 12 pedidos (1%) com `shipping_country` vazio.
- `click_events`: 1.225 eventos (20%) sem `customer_id` e 2.674 `page_view` sem `product_id`.

Volumes: 300 clientes, 80 produtos, 1.200 pedidos, 2.910 itens e 6.000 eventos de clique.

---

## Limitações Conhecidas e Próximos Passos

- [ ] Aplicar o filtro de pedidos cancelados também no `mart_medium_ticket`, para o ticket ser consistente com a receita
- [ ] Renomear o dataset `staging` para `raw` e criar uma camada `staging` do dbt com limpeza (tipos, nulos, e-mails duplicados)
- [ ] Testes dbt (`unique`, `not_null`, `relationships`, `accepted_values`) e uso de `dbt build` na DAG
- [ ] CI em pull request: lint, parse da DAG, `dbt parse` e `terraform validate`
- [ ] Alertas e retries na DAG (`on_failure_callback`) e agendamento real do `schedule`
- [ ] State do Terraform em backend remoto (GCS) e service account de CI + Workload Identity sob controle do Terraform
- [ ] Mover o upload dos CSVs (`extract_csv.py`) para dentro do fluxo orquestrado
- [ ] Ingestão em streaming de `click_events` via Pub/Sub + Dataflow

---

## Pré-requisitos

- Python 3.11+
- Terraform >= 1.7
- Conta GCP com as APIs habilitadas: BigQuery, Cloud Storage, Cloud Composer
- Autenticação local: `gcloud auth application-default login`

O `requirements.txt` reúne dependências de vários componentes (extração, dbt, Airflow); para uso local, prefira ambientes virtuais separados, pois as versões do dbt e do Airflow conflitam entre si.

Região do Composer: `us-east1`.

---

**Autora:** Vitoria Ribeiro Dias  
**Contexto:** Projeto de aprendizado em Engenharia de Dados com GCP
