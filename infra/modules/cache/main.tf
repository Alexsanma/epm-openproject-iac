# Base de datos en memoria gestionada: Amazon ElastiCache for Memcached.
# OpenProject la usa como cache de Rails (OPENPROJECT_CACHE__MEMCACHE__SERVER).

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-cache-subnets"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_cluster" "main" {
  cluster_id         = "${var.project_name}-cache"
  engine             = "memcached"
  engine_version     = var.engine_version
  node_type          = var.node_type
  num_cache_nodes    = 1
  port               = 11211
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [var.security_group_id]
  apply_immediately  = true

  tags = {
    Name = "${var.project_name}-cache"
  }
}
