resource "google_composer_environment" "this" {
  name    = var.environment_name
  project = var.project_id
  region  = var.region

  config {
    software_config {
      image_version = "composer-3-airflow-2.11.1-build.19"

      pypi_packages = {
        "dbt-core"     = "==1.9.0"
        "dbt-bigquery" = "==1.9.0"
      }
    }
    node_config {
      service_account = var.service_account_email
    }
  }
}