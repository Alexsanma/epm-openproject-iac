data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# La IP elastica se crea primero (sin instancia) para que OpenProject conozca
# su propio host name desde el arranque. Se asocia a la instancia al final.
resource "aws_eip" "openproject" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}

resource "aws_instance" "openproject" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  monitoring             = false

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    aws_region          = var.aws_region
    public_ip           = aws_eip.openproject.public_ip
    openproject_version = var.openproject_version
    db_host             = var.db_host
    db_port             = var.db_port
    db_name             = var.db_name
    db_secret_arn       = var.db_secret_arn
    cache_endpoint      = var.cache_endpoint
    app_log_group       = var.app_log_group
    system_log_group    = var.system_log_group
    metrics_namespace   = var.metrics_namespace
  })
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "${var.project_name}-instance"
  }
}

resource "aws_eip_association" "openproject" {
  instance_id   = aws_instance.openproject.id
  allocation_id = aws_eip.openproject.id
}

# ---------- IAM de la instancia ----------
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# Administracion por SSM Session Manager (sin SSH)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Agente de CloudWatch: metricas de memoria/disco y envio de logs
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Lectura unicamente del secreto de RDS
resource "aws_iam_role_policy" "read_db_secret" {
  name = "${var.project_name}-read-db-secret"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.db_secret_arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}
