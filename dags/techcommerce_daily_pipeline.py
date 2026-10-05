from airflow.decorators import dag, task
from airflow.providers.standard.operators.bash import BashOperator
from datetime import datetime

TABELAS = [
    ("gs://techcommerce-raw/orders.csv", "staging.stg_orders"),
    ("gs://techcommerce-raw/order_items.csv", "staging.stg_order_items"),
    ("gs://techcommerce-raw/products.csv", "staging.stg_products"),
    ("gs://techcommerce-raw/customers.csv", "staging.stg_customers"),
    ("gs://techcommerce-raw/click_events.csv", "staging.stg_click_events"),            
]

@dag(schedule=None, start_date=datetime(2026, 1, 1), catchup=False)

def techcommerce_daily_pipeline():
    

    @task
    def load_raw():
        from extract.load_raw import load_from_gcs
        for blob, table in TABELAS:
            load_from_gcs(
                blob,
                table
            )
            
    run_dbt = BashOperator(
        task_id="run_dbt_datawarehouse",
        bash_command="cd /home/airflow/gcs/data/dbt && dbt run --select datawarehouse --profiles-dir /home/airflow/gcs/data/dbt_profiles --target-path /tmp/dbt_target --log-path /tmp/dbt_logs"
    )
    
    load_raw() >> run_dbt
    
techcommerce_daily_pipeline()