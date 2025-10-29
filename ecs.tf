data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = var.cluster_name
}

resource "aws_service_discovery_http_namespace" "namespace" {
  name = local.task_name
}
