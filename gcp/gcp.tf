
################
### Services ###
################

resource "google_project_service" "services" {
  count   = length(var.google_project_services)
  project = "ageless-granite-273208"
  service = var.google_project_services[count.index]
}

#################
### Cloud SQL ###
#################

resource "google_sql_database_instance" "cms_database_instance" {
  project             = google_project.project.project_id
  name                = "cms"
  database_version    = "MYSQL_5_7"
  region              = var.gcp_region
  deletion_protection = false

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"

    backup_configuration {
      enabled            = true
      binary_log_enabled = true
      start_time         = "00:00"
    }

    ip_configuration {
      dynamic "authorized_networks" {
        for_each = var.pipelines_ip_addresses
        iterator = pipelines_ip_addresses

        content {
          name  = "Bitbucket Pipelines IP ${pipelines_ip_addresses.key}"
          value = pipelines_ip_addresses.value
        }
      }
    }
  }
}

resource "random_password" "cms_sql_root_password" {
  length  = 16
  special = true
}

resource "google_sql_user" "root" {
  project  = google_project.project.project_id
  instance = google_sql_database_instance.cms_database_instance.name
  name     = "root"
  password = random_password.cms_sql_root_password.result
  host     = "%"
}

resource "random_password" "cms_sql_local_password" {
  length  = 16
  special = true
}

resource "google_sql_user" "local" {
  project  = google_project.project.project_id
  instance = google_sql_database_instance.cms_database_instance.name
  name     = "local"
  password = random_password.cms_sql_local_password.result
  host     = "%"
}

resource "google_sql_database" "cms_database_development" {
  project  = google_project.project.project_id
  instance = google_sql_database_instance.cms_database_instance.name
  name     = "development"
}

resource "google_sql_database" "cms_database_production" {
  project  = google_project.project.project_id
  instance = google_sql_database_instance.cms_database_instance.name
  name     = "production"
}

#################
### Cloud Run ###
#################

resource "google_cloud_run_service" "cms" {
  project  = google_project.project.project_id
  name     = "${google_project.project.project_id}-cms"
  location = var.gcp_region

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
    metadata {
      annotations = {
        "run.googleapis.com/cloudsql-instances" = "${google_project.project.project_id}:${var.gcp_region}:${google_sql_database_instance.cms_database_instance.name}"
      }
    }
  }

  depends_on = [google_project_service.services]
}

resource "google_cloud_run_service" "app" {
  project  = google_project.project.project_id
  name     = "${google_project.project.project_id}-app"
  location = "europe-west1"

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
        resources {
          limits = {
            cpu    = "1"
            memory = "256Mi"
          }
        }
      }
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "10"
      }
    }
  }

  depends_on = [google_project_service.services]
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth_cms" {
  location    = google_cloud_run_service.cms.location
  project     = google_cloud_run_service.cms.project
  service     = google_cloud_run_service.cms.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_cloud_run_service_iam_policy" "noauth_app" {
  location    = google_cloud_run_service.app.location
  project     = google_cloud_run_service.app.project
  service     = google_cloud_run_service.app.name
  policy_data = data.google_iam_policy.noauth.policy_data
}



resource "google_service_account" "local_database" {
  project      = google_project.project.project_id
  account_id   = "local-database"
  display_name = "Local Database"
  depends_on   = [google_project_service.services]
}

resource "google_project_iam_member" "local_database_viewer" {
  project    = google_project.project.project_id
  role       = "roles/viewer"
  member     = "serviceAccount:${google_service_account.local_database.email}"
  depends_on = [google_project_service.services]
}

resource "google_project_iam_member" "local_database_sql_client" {
  project    = google_project.project.project_id
  role       = "roles/cloudsql.client"
  member     = "serviceAccount:${google_service_account.local_database.email}"
  depends_on = [google_project_service.services]
}

resource "google_project_iam_member" "local_database_sql_viewer" {
  project    = google_project.project.project_id
  role       = "roles/cloudsql.viewer"
  member     = "serviceAccount:${google_service_account.local_database.email}"
  depends_on = [google_project_service.services]
}

resource "google_service_account_key" "local_database" {
  service_account_id = google_service_account.local_database.name
}
