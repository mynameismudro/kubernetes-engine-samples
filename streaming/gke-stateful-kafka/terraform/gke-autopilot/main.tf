#Copyright 2022 Google

#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at

#    http://www.apache.org/licenses/LICENSE-2.0

#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}
// [START artifactregistry_create_docker_repo]
resource "google_artifact_registry_repository" "main" {
  location      = "asia"
  repository_id = "main"
  format        = "DOCKER"
  project       = var.project_id
}
resource "google_artifact_registry_repository_iam_binding" "binding" {
  provider   = google-beta
  project    = google_artifact_registry_repository.main.project
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.reader"
  members = [
    "serviceAccount:${module.gke_kafka_central.service_account}",
  ]
}
// [END artifactregistry_create_docker_repo]

module "network" {
  source     = "../modules/network"
  project_id = var.project_id
}
# [START gke_autopilot_private_regional_primary_cluster]
module "gke_kafka_east2" {
  source                          = "../modules/beta-autopilot-private-cluster"
  project_id                      = var.project_id
  name                            = "gke-kafka-asia-east2"
  kubernetes_version              = "1.25"
  region                          = "asia-east2"
  regional                        = true
  zones                           = ["asia-east2-a", "asia-east2-b", "asia-east2-c"]
  network                         = module.network.network_name
  subnetwork                      = module.network.primary_subnet_name
  ip_range_pods                   = "ip-range-pods-asia-east2"
  ip_range_services               = "ip-range-svc-asia-east2"
  horizontal_pod_autoscaling      = true
  release_channel                 = "REGULAR"
  enable_vertical_pod_autoscaling = true
  enable_private_endpoint         = false
  enable_private_nodes            = true
  master_ipv4_cidr_block          = "172.16.0.0/28"
  create_service_account          = true
  grant_registry_access           = true
}
# [END gke_autopilot_private_regional_primary_cluster]
# [START gke_autopilot_private_regional_backup_cluster]
module "gke_kafka_south1" {
  source                          = "../modules/beta-autopilot-private-cluster"
  project_id                      = var.project_id
  name                            = "gke-kafka-asia-south1"
  kubernetes_version              = "1.25"
  region                          = "asia-south1"
  regional                        = true
  zones                           = ["asia-south1-a", "asia-south1-b", "asia-south1-c"]
  network                         = module.network.network_name
  subnetwork                      = module.network.secondary_subnet_name
  ip_range_pods                   = "ip-range-pods-asia-south1"
  ip_range_services               = "ip-range-svc-asia-south1"
  horizontal_pod_autoscaling      = true
  release_channel                 = "REGULAR"
  enable_vertical_pod_autoscaling = true
  enable_private_endpoint         = false
  enable_private_nodes            = true
  master_ipv4_cidr_block          = "172.16.0.16/28"
  create_service_account          = false
  service_account                 = module.gke_kafka_central.service_account
  grant_registry_access           = true
}
# [END gke_autopilot_private_regional_backup_cluster]
