# Observabilidad con Amazon CloudWatch:
#  - Logs: contenedor de OpenProject y sistema de la instancia
#  - Metricas: EC2, RDS, ElastiCache y metricas del agente (memoria/disco)
#  - Metrica derivada de logs: errores de la aplicacion
#  - Alarmas notificadas por SNS y un dashboard unificado

locals {
  app_log_group    = "/${var.project_name}/app"
  system_log_group = "/${var.project_name}/system"
}

resource "aws_cloudwatch_log_group" "app" {
  name              = local.app_log_group
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "system" {
  name              = local.system_log_group
  retention_in_days = var.log_retention_days
}

# Cuenta las lineas de log del contenedor que contienen "ERROR"
resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  name           = "${var.project_name}-app-errors"
  log_group_name = aws_cloudwatch_log_group.app.name
  pattern        = "ERROR"

  metric_transformation {
    name          = "AppErrorCount"
    namespace     = var.metrics_namespace
    value         = "1"
    default_value = "0"
  }
}

# ---------- Notificaciones ----------
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ---------- Alarmas ----------
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "${var.project_name}-ec2-cpu-high"
  alarm_description   = "CPU de la instancia de OpenProject sobre 80% durante 10 minutos"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { InstanceId = var.instance_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  alarm_name          = "${var.project_name}-ec2-status-check"
  alarm_description   = "Falla de chequeo de estado de la instancia"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  dimensions          = { InstanceId = var.instance_id }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "ec2_memory_high" {
  alarm_name          = "${var.project_name}-ec2-memory-high"
  alarm_description   = "Memoria usada de la instancia sobre 90% (agente de CloudWatch)"
  namespace           = var.metrics_namespace
  metric_name         = "mem_used_percent"
  dimensions          = { InstanceId = var.instance_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 90
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  alarm_description   = "CPU de RDS PostgreSQL sobre 80%"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  dimensions          = { DBInstanceIdentifier = var.db_identifier }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${var.project_name}-rds-free-storage-low"
  alarm_description   = "Espacio libre de RDS por debajo de 2 GB"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  dimensions          = { DBInstanceIdentifier = var.db_identifier }
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 2147483648
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "app_errors" {
  alarm_name          = "${var.project_name}-app-errors"
  alarm_description   = "Mas de 10 errores en los logs de OpenProject en 5 minutos"
  namespace           = var.metrics_namespace
  metric_name         = "AppErrorCount"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# ---------- Dashboard ----------
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "text", x = 0, y = 0, width = 24, height = 2
        properties = {
          markdown = "# EPM - OpenProject\nEC2 (Docker) + RDS PostgreSQL + ElastiCache Memcached | Desplegado con Terraform y GitHub Actions"
        }
      },
      {
        type = "metric", x = 0, y = 2, width = 8, height = 6
        properties = {
          title   = "EC2 - CPU (%)"
          region  = var.aws_region
          stat    = "Average"
          period  = 60
          metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", var.instance_id]]
        }
      },
      {
        type = "metric", x = 8, y = 2, width = 8, height = 6
        properties = {
          title  = "EC2 - Memoria y disco (%) [agente]"
          region = var.aws_region
          stat   = "Average"
          period = 60
          metrics = [
            [var.metrics_namespace, "mem_used_percent", "InstanceId", var.instance_id],
            [var.metrics_namespace, "swap_used_percent", "InstanceId", var.instance_id],
            [var.metrics_namespace, "disk_used_percent", "InstanceId", var.instance_id, "path", "/", "device", "nvme0n1p1", "fstype", "xfs"]
          ]
        }
      },
      {
        type = "metric", x = 16, y = 2, width = 8, height = 6
        properties = {
          title  = "EC2 - Red (bytes)"
          region = var.aws_region
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", var.instance_id],
            ["AWS/EC2", "NetworkOut", "InstanceId", var.instance_id]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 8, width = 8, height = 6
        properties = {
          title  = "RDS - CPU (%) y conexiones"
          region = var.aws_region
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_identifier],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_identifier, { yAxis = "right" }]
          ]
        }
      },
      {
        type = "metric", x = 8, y = 8, width = 8, height = 6
        properties = {
          title  = "RDS - Memoria y almacenamiento libres (bytes)"
          region = var.aws_region
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", var.db_identifier],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.db_identifier]
          ]
        }
      },
      {
        type = "metric", x = 16, y = 8, width = 8, height = 6
        properties = {
          title  = "ElastiCache Memcached - aciertos, fallos y CPU"
          region = var.aws_region
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/ElastiCache", "GetHits", "CacheClusterId", var.cache_cluster_id],
            ["AWS/ElastiCache", "GetMisses", "CacheClusterId", var.cache_cluster_id],
            ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", var.cache_cluster_id, { stat = "Average", yAxis = "right" }]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 14, width = 8, height = 6
        properties = {
          title   = "OpenProject - errores en logs"
          region  = var.aws_region
          stat    = "Sum"
          period  = 300
          metrics = [[var.metrics_namespace, "AppErrorCount"]]
        }
      },
      {
        type = "alarm", x = 8, y = 14, width = 16, height = 6
        properties = {
          title = "Estado de las alarmas"
          alarms = [
            aws_cloudwatch_metric_alarm.ec2_cpu_high.arn,
            aws_cloudwatch_metric_alarm.ec2_status_check.arn,
            aws_cloudwatch_metric_alarm.ec2_memory_high.arn,
            aws_cloudwatch_metric_alarm.rds_cpu_high.arn,
            aws_cloudwatch_metric_alarm.rds_storage_low.arn,
            aws_cloudwatch_metric_alarm.app_errors.arn
          ]
        }
      },
      {
        type = "log", x = 0, y = 20, width = 24, height = 7
        properties = {
          title  = "Ultimos logs del contenedor de OpenProject"
          region = var.aws_region
          query  = "SOURCE '${local.app_log_group}' | fields @timestamp, @message | sort @timestamp desc | limit 50"
          view   = "table"
        }
      }
    ]
  })
}
