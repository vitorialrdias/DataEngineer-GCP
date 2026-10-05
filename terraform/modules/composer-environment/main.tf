resource "google_composer_environment" "this" {
  name    = var.environment_name
  project = var.project_id
  region  = var.region

  config {
    software_config {
      image_version = "composer-3-airflow-2.11.1-build.19"

      pypi_packages = {
        "dbt-core"     = ""
        "dbt-bigquery" = ""
      }
    }
    node_config {
      service_account = var.service_account_email
    }
  }
  lifecycle {
    ignore_changes = [config[0].software_config[0].pypi_packages]
  }
}