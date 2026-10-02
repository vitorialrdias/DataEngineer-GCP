resource "google_bigquery_dataset" "this" {
  dataset_id = var.dataset_id
  location   = var.location
  project    = var.project_id
}