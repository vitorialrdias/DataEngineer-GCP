module "staging_dataset" {
    source = "../../modules/bigquery-dataset"
    dataset_id = "staging"
    location = "US"
    project_id = var.project_id
}

module "datawarehouse_dataset" {
    source = "../../modules/bigquery-dataset"
    dataset_id = "datawarehouse"
    location = "US"
    project_id = var.project_id
}

module "raw_bucket" {
    source      = "../../modules/storage-bucket"
    project_id  = var.project_id
    bucket_name = "techcommerce-raw"
    location    = "US"
}


resource "google_project_service" "composer_api" {
  project = var.project_id
  service = "composer.googleapis.com"
  disable_on_destroy = false
}


resource "google_service_account" "composer_sa" {
  account_id   = "techcommerce-dev"
  display_name = "Service account do Cloud Composer - TechCommerce"
}

resource "google_project_iam_member" "composer_worker" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
  role    = "roles/composer.worker"
}

resource "google_project_iam_member" "composer_bq" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
  role    = "roles/bigquery.dataEditor"
}

resource "google_project_iam_member" "composer_bq_job" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
  role    = "roles/bigquery.jobUser"
}

resource "google_project_iam_member" "composer_storage" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
  role    = "roles/storage.objectAdmin"
}

module "composer_env" {
  source                = "../../modules/composer-environment"
  environment_name      = "techcommerce-dev"
  project_id            = var.project_id
  region                = "us-east1"  # mesma region do seu provider
  service_account_email = google_service_account.composer_sa.email
}

resource "google_project_iam_member" "cloudservices_editor" {
  project = var.project_id
  member  = "serviceAccount:1077263027522@cloudservices.gserviceaccount.com"
  role    = "roles/editor"
}

resource "google_project_iam_member" "composer_service_agent_v2ext" {
  project = var.project_id
  member  = "serviceAccount:service-1077263027522@cloudcomposer-accounts.iam.gserviceaccount.com"
  role    = "roles/composer.ServiceAgentV2Ext"
}