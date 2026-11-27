# Base de datos relacional gestionada: Amazon RDS for PostgreSQL.
# La contrasena maestra la crea y guarda RDS en AWS Secrets Manager
# (manage_master_user_password), por lo que no aparece en el codigo ni en el estado.

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnets"
  }
}

# Grupo de logs creado por Terraform (antes que RDS) para controlar la
# retencion y que se elimine junto con el resto en terraform destroy.
resource "aws_cloudwatch_log_group" "postgresql" {
  name              = "/aws/rds/instance/${var.project_name}-db/postgresql"
  retention_in_days = var.log_retention_days
}

resource "aws_db_instance" "main" {
  depends_on = [aws_cloudwatch_log_group.postgresql]

  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = var.engine_version
  # Permite subir de version mayor desde el pipeline (p. ej. 16 -> 17)
  allow_major_version_upgrade = true
  instance_class              = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 1
  # Exporta los logs del motor a CloudWatch Logs (observabilidad)
  enabled_cloudwatch_logs_exports = ["postgresql"]
  performance_insights_enabled    = false

  # Entorno academico: se puede destruir sin snapshot final
  skip_final_snapshot = true
  deletion_protection = false
  apply_immediately   = true

  tags = {
    Name = "${var.project_name}-db"
  }
}
