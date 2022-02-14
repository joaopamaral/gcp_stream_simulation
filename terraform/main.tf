variable "ame_project" {default = "americanas-joao-test"}
variable "region" {default = "us-central1"}
variable "zone" {default = "us-central1-c"}
variable "environment" {default = "production"}


provider "google" {
  project = var.ame_project
  region  = var.region
  zone    = var.zone
}

resource "google_pubsub_topic" "pubsub_nyc" {
  project = var.ame_project
  name = "nyc_2019_taxi_trips"
  labels = {
    env = var.environment
  }
}

resource "google_bigquery_dataset" "default" {
  dataset_id                  = "ame_test_data"
  project                     = var.ame_project
  friendly_name               = "ame_test_data"
  description                 = "ame Data Test"
  location                    = "US"
  labels = {
    env = var.environment
  }
 delete_contents_on_destroy = true
}

resource "google_bigquery_table" "default" {
  dataset_id = google_bigquery_dataset.default.dataset_id
  project    = var.ame_project
  table_id   = "nyc_2019_taxi_trips"
  description = "NYC 2019 taxi trips"
  # The partition is recommended for a real solution (make queries faster and cheaper)
#  time_partitioning {
#    type = "DAY"
#  }
  labels = {
    env = var.environment
  }
  deletion_protection = false  # only used because it's a test
    schema = <<EOF
      [
        {
          "name": "vendorid",
          "type": "INT64",
          "mode": "NULLABLE",
          "description": "A code indicating the TPEP provider that provided the record."
        },
        {
          "name": "tpep_pickup_datetime",
          "type": "DATETIME",
          "mode": "NULLABLE",
          "description": "The date and time when the meter was engaged."
        },
        {
          "name": "tpep_dropoff_datetime",
          "type": "DATETIME",
          "mode": "NULLABLE",
          "description": "The date and time when the meter was disengaged."
        },
        {
          "name": "passenger_count",
          "type": "INT64",
          "mode": "NULLABLE",
          "description": "The number of passengers in the vehicle."
        },
        {
          "name": "trip_distance",
          "type": "FLOAT64",
          "mode": "NULLABLE",
          "description": "The elapsed trip distance in miles reported by the taximeter."
        },
        {
          "name": "ratecodeid",
          "type": "INT64",
          "mode": "NULLABLE",
          "description": "The final rate code in effect at the end of the trip."
        },
        {
          "name": "store_and_fwd_flag",
          "type": "STRING",
          "mode": "NULLABLE",
          "description": "This flag indicates whether the trip record was held in vehicle memory before sending to the vendor, aka 'store and forward,' because the vehicle did not have a connection to the server."
        },
        {
          "name": "pulocationid",
          "type": "INT64",
          "mode": "NULLABLE",
          "description": "TLC Taxi Zone in which the taximeter was engaged"
        },
        {
          "name": "dolocationid",
          "type": "INT64",
          "mode": "NULLABLE",
          "description": "DOLocationID TLC Taxi Zone in which the taximeter was disengaged"
        },
        {
          "name": "payment_type",
          "type": "INT64",
          "mode": "NULLABLE",
          "description": "A numeric code signifying how the passenger paid for the trip."
        },
        {
          "name": "fare_amount",
          "type": "FLOAT64",
          "mode": "NULLABLE",
          "description": "The time-and-distance fare calculated by the meter."
        },
        {
          "name": "mta_tax",
          "type": "FLOAT64",
          "mode": "NULLABLE",
          "description": "$0.50 MTA tax that is automatically triggered based on the metered rate in use."
        },
        {
          "name": "tip_amount",
          "type": "FLOAT64",
          "mode": "NULLABLE",
          "description": "Tip amount – This field is automatically populated for credit card tips. Cash tips are not included."
        },
        {
          "name": "tolls_amount",
          "type": "FLOAT64",
          "mode": "NULLABLE",
          "description": "Total amount of all tolls paid in trip."
        },
        {
          "name": "improvement_surcharge",
          "type": "FLOAT64",
          "mode": "NULLABLE",
          "description": "$0.30 improvement surcharge assessed trips at the flag drop. The improvement surcharge began being levied in 2015."
        },
        {
          "name": "total_amount",
          "type": "FLOAT64",
          "mode": "NULLABLE",
          "description": "The total amount charged to passengers. Does not include cash tips."
        },
        {
          "name": "congestion_surcharge",
          "type": "STRING",
          "mode": "NULLABLE",
          "description": ""
        },
        {
          "name": "extra",
          "type": "FLOAT64",
          "mode": "NULLABLE",
          "description": "Miscellaneous extras and surcharges. Currently, this only includes the $0.50 and $1 rush hour and overnight charges."
        }
      ]
      EOF
}

resource "google_storage_bucket" "temp_bucket" {
  name     = "${var.ame_project}-temp"
  location   = var.region
  labels = {
    env = var.environment
  }
}

resource "google_dataflow_job" "pubsub_bigquery_flow" {
  name = "ame-teste-ps-bq-dataflow"
  template_gcs_path = "gs://dataflow-templates-us-central1/latest/PubSub_to_BigQuery"
  temp_gcs_location = "gs://${google_storage_bucket.temp_bucket.name}/"
  parameters = {
    inputTopic = "projects/${var.ame_project}/topics/${google_pubsub_topic.pubsub_nyc.name}"
    outputTableSpec    = "${var.ame_project}:${google_bigquery_table.default.dataset_id}.${google_bigquery_table.default.table_id}"
  }
  labels = {
    env = var.environment
  }
  on_delete = "cancel"
  depends_on = [
    google_pubsub_topic.pubsub_nyc,
    google_storage_bucket.temp_bucket,
    google_bigquery_table.default,
  ]
}

resource "google_cloud_run_service" "default" {
  name     = "stream-simulate"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/americanas-joao-test/stream_simulate"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
  depends_on = [
    google_pubsub_topic.pubsub_nyc,
  ]
}

##################################################################################
# Uploading the full data to run the queries in all data (get the correct answers)
##################################################################################
#resource "google_storage_bucket" "data_bucket" {
#  name     = "${var.ame_project}-data"
#  location   = var.region
#  labels = {
#    env = var.environment
#  }
#}
#
#resource "google_storage_bucket_object" "complete_data" {
#  name   = "2019_Yellow_Taxi_Trip_Data.csv"
#  bucket = google_storage_bucket.data_bucket.name
#  source = "../offline_data/2019_Yellow_Taxi_Trip_Data.csv"
#}
#
#resource "google_bigquery_table" "full_data" {
#  dataset_id = google_bigquery_dataset.default.dataset_id
#  project    = var.ame_project
#  table_id   = "nyc_2019_taxi_trips_full_data"
#  description = "NYC 2019 taxi trips (complete data)"
#  labels = {
#    env = var.environment
#  }
#  external_data_configuration {
#    autodetect    = true
#    source_format = "CSV"
#    source_uris   = [
#      "gs://${google_storage_bucket.data_bucket.name}/2019_Yellow_Taxi_Trip_Data.csv"
#    ]
#  }
#  deletion_protection = false  # only used because it's a test
#}
