terraform {
  backend "gcs" {
    bucket = "test-for-mils"
    prefix = "terraform/state"
  }
}
