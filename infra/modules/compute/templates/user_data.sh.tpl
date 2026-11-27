#!/bin/bash
# Arranque de la instancia (Amazon Linux 2023):
#  1. Swap, Docker y agente de CloudWatch
#  2. Lee la credencial de RDS desde Secrets Manager
#  3. Ejecuta OpenProject en Docker usando RDS (PostgreSQL) y ElastiCache (memcached)
# Log: /var/log/user-data.log (tambien se envia a CloudWatch Logs)
set -euxo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

REGION='${aws_region}'
PUBLIC_IP='${public_ip}'
OP_VERSION='${openproject_version}'
DB_HOST='${db_host}'
DB_PORT='${db_port}'
DB_NAME='${db_name}'
DB_SECRET_ARN='${db_secret_arn}'
CACHE_ENDPOINT='${cache_endpoint}'
APP_LOG_GROUP='${app_log_group}'
DATA_DIR=/var/lib/openproject

# ---------- Swap ----------
if [ ! -f /swapfile ]; then
  dd if=/dev/zero of=/swapfile bs=1M count=2048
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
fi

dnf install -y docker amazon-cloudwatch-agent
systemctl enable --now docker

# ---------- Agente de CloudWatch: metricas de memoria/disco + logs del sistema ----------
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
{
  "agent": { "metrics_collection_interval": 60, "run_as_user": "root" },
  "metrics": {
    "namespace": "${metrics_namespace}",
    "append_dimensions": { "InstanceId": "$${aws:InstanceId}" },
    "metrics_collected": {
      "mem":  { "measurement": ["mem_used_percent"] },
      "disk": { "measurement": ["used_percent"], "resources": ["/"] },
      "swap": { "measurement": ["swap_used_percent"] }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "/var/log/user-data.log", "log_group_name": "${system_log_group}", "log_stream_name": "{instance_id}/user-data" },
          { "file_path": "/var/log/messages",      "log_group_name": "${system_log_group}", "log_stream_name": "{instance_id}/messages" }
        ]
      }
    }
  }
}
CWCONFIG
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# ---------- Credenciales de RDS (Secrets Manager) ----------
SECRET_JSON="$(aws secretsmanager get-secret-value --region "$REGION" --secret-id "$DB_SECRET_ARN" --query SecretString --output text)"
DB_USER="$(echo "$SECRET_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["username"])')"
DB_PASS_ENC="$(echo "$SECRET_JSON" | python3 -c 'import sys,json,urllib.parse; print(urllib.parse.quote(json.load(sys.stdin)["password"], safe=""))')"
DATABASE_URL="postgres://$DB_USER:$DB_PASS_ENC@$DB_HOST:$DB_PORT/$DB_NAME?sslmode=require"

# ---------- SECRET_KEY_BASE (se genera en la instancia, no queda en Terraform) ----------
if [ ! -f /root/.openproject_secret ]; then
  openssl rand -hex 64 > /root/.openproject_secret
  chmod 600 /root/.openproject_secret
fi
SECRET_KEY_BASE="$(cat /root/.openproject_secret)"

mkdir -p "$DATA_DIR/assets"

# ---------- Contenedor de OpenProject ----------
# Los logs del contenedor van directo a CloudWatch Logs con el driver awslogs.
if ! docker ps -a --format '{{.Names}}' | grep -qx openproject; then
  docker run -d --name openproject --restart unless-stopped \
    -p 80:80 \
    --log-driver=awslogs \
    --log-opt awslogs-region="$REGION" \
    --log-opt awslogs-group="$APP_LOG_GROUP" \
    --log-opt awslogs-stream=openproject \
    -e DATABASE_URL="$DATABASE_URL" \
    -e OPENPROJECT_SECRET_KEY_BASE="$SECRET_KEY_BASE" \
    -e OPENPROJECT_HOST__NAME="$PUBLIC_IP" \
    -e OPENPROJECT_HTTPS=false \
    -e OPENPROJECT_RAILS__CACHE__STORE=memcache \
    -e OPENPROJECT_CACHE__MEMCACHE__SERVER="$CACHE_ENDPOINT" \
    -v "$DATA_DIR/assets:/var/openproject/assets" \
    "openproject/openproject:$OP_VERSION"
fi

# Espera (max. ~15 min) a que la aplicacion responda
for i in $(seq 1 90); do
  if curl -fs -o /dev/null http://localhost/health_checks/default; then
    echo "OpenProject is up"
    break
  fi
  sleep 10
done

echo "OpenProject installation finished"
