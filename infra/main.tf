provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
      Pipeline  = "github-actions"
    }
  }
}

module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  http_allowed_cidrs   = var.http_allowed_cidrs
}

module "database" {
  source = "./modules/database"

  project_name       = var.project_name
  subnet_ids         = module.networking.private_subnet_ids
  security_group_id  = module.networking.db_security_group_id
  engine_version     = var.db_engine_version
  instance_class     = var.db_instance_class
  allocated_storage  = var.db_allocated_storage
  db_name            = var.db_name
  db_username        = var.db_username
  log_retention_days = var.log_retention_days
}

module "cache" {
  source = "./modules/cache"

  project_name      = var.project_name
  subnet_ids        = module.networking.private_subnet_ids
  security_group_id = module.networking.cache_security_group_id
  engine_version    = var.cache_engine_version
  node_type         = var.cache_node_type
}

module "compute" {
  source = "./modules/compute"

  project_name      = var.project_name
  aws_region        = var.aws_region
  subnet_id         = module.networking.public_subnet_id
  security_group_id = module.networking.web_security_group_id

  instance_type       = var.instance_type
  root_volume_size    = var.root_volume_size
  openproject_version = var.openproject_version

  db_host        = module.database.address
  db_port        = module.database.port
  db_name        = module.database.db_name
  db_secret_arn  = module.database.master_secret_arn
  cache_endpoint = module.cache.endpoint

  app_log_group     = module.observability.app_log_group
  system_log_group  = module.observability.system_log_group
  metrics_namespace = var.metrics_namespace
}

module "observability" {
  source = "./modules/observability"

  project_name       = var.project_name
  aws_region         = var.aws_region
  metrics_namespace  = var.metrics_namespace
  log_retention_days = var.log_retention_days
  alert_email        = var.alert_email

  instance_id      = module.compute.instance_id
  db_identifier    = module.database.identifier
  cache_cluster_id = module.cache.cluster_id
}
