import logging
from pathlib import Path
from google.cloud import storage

logger = logging.getLogger(__name__)

CSV = [
        (Path(r"C:\Users\vitoria.lribeiro\OneDrive - gpssa.com.br\POWERBI-VITORIA\Learning\DataEngineer-GCP\csv\orders.csv"),
        "orders.csv"),
        (Path(r"C:\Users\vitoria.lribeiro\OneDrive - gpssa.com.br\POWERBI-VITORIA\Learning\DataEngineer-GCP\csv\order_items.csv"),
        "order_items.csv"),
        (Path(r"C:\Users\vitoria.lribeiro\OneDrive - gpssa.com.br\POWERBI-VITORIA\Learning\DataEngineer-GCP\csv\products.csv"),
        "products.csv"),       
        (Path(r"C:\Users\vitoria.lribeiro\OneDrive - gpssa.com.br\POWERBI-VITORIA\Learning\DataEngineer-GCP\csv\customers.csv"),
        "customers.csv"),       
        (Path(r"C:\Users\vitoria.lribeiro\OneDrive - gpssa.com.br\POWERBI-VITORIA\Learning\DataEngineer-GCP\csv\click_events.csv"),
        "click_events.csv"),       
       ]

def upload_raw(local_path: Path, dest_blob: str, bucket_name = "techcommerce-raw") -> None:
    """ Envia um arquivo local para raw landing zone no Cloud Storage """
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(dest_blob)
    blob.upload_from_filename(str(local_path))
    
    logger.info(f"Arquivo {local_path} enviado com sucesso para: gs://{bucket_name}/{dest_blob}")
    

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    
    for file, blob in CSV:
        upload_raw(
            file,
            blob
        )
