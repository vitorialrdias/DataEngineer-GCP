from google.cloud import bigquery

def load_from_gcs(uri: str, table: str) -> None:
    """ Carrega um arquivo CSV do Cloud Storage para uma tabela no BigQuery"""
    client = bigquery.Client()
    job_config = bigquery.LoadJobConfig(
        source_format = bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        autodetect=True,
        write_disposition="WRITE_TRUNCATE",
    )
    
    job = client.load_table_from_uri(uri, table, job_config=job_config)
    
    job.result()
    
if __name__ == "__main__":

    TABELAS = [
        ("gs://techcommerce-raw/orders.csv", "staging.stg_orders"),
        ("gs://techcommerce-raw/order_items.csv", "staging.stg_order_items"),
        ("gs://techcommerce-raw/products.csv", "staging.stg_products"),
        ("gs://techcommerce-raw/customers.csv", "staging.stg_customers"),
        ("gs://techcommerce-raw/click_events.csv", "staging.stg_click_events"),            
    ]
    for uri, table in TABELAS:
        load_from_gcs(uri, table)