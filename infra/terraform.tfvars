aws_region   = "us-east-2"
project_name = "epm-openproject"

vpc_cidr             = "10.2.0.0/16"
public_subnet_cidr   = "10.2.1.0/24"
private_subnet_cidrs = ["10.2.11.0/24", "10.2.12.0/24"]
http_allowed_cidrs   = ["0.0.0.0/0"]

instance_type       = "c7i-flex.large"
root_volume_size    = 30
openproject_version = "16"

db_engine_version    = "17"
db_instance_class    = "db.t4g.micro"
db_allocated_storage = 20

cache_engine_version = "1.6.22"
cache_node_type      = "cache.t3.micro"

log_retention_days = 7
