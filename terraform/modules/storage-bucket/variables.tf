variable "project_id" {
  type        = string
  description = "ID do projeto GCP onde o bucket será criado"
}

variable "bucket_name" {
  type        = string
  description = "Nome do bucket (precisa ser globalmente único em todo o GCS)"
}

variable "location" {
  type        = string
  default     = "US"
  description = "Região/multi-região do bucket"
}
