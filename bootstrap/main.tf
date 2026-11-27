# Bootstrap (se aplica una sola vez desde el equipo local):
#  - Bucket S3 para el estado remoto de Terraform (con bloqueo nativo use_lockfile)
#  - Proveedor OIDC de GitHub y rol IAM que asume el pipeline de GitHub Actions
#    (sin claves de acceso guardadas en GitHub)

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform-bootstrap"
    }
  }
}

data "aws_caller_identity" "current" {}

# ---------- Estado remoto ----------
resource "aws_s3_bucket" "tf_state" {
  bucket        = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # entorno academico: permite borrar el bucket con su contenido
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------- GitHub Actions OIDC ----------
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          # Solo este repositorio puede asumir el rol. GitHub usa ahora un
          # "sub" inmutable con los IDs del propietario y del repositorio
          # (repo:Owner@ID/Repo@ID:...); se acepta tambien el formato clasico.
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_owner}/${var.github_repo}:*",
              "repo:${var.github_owner}@*/${var.github_repo}@*:*"
            ]
          }
        }
      }
    ]
  })
}

# El pipeline crea VPC, EC2, RDS, ElastiCache, IAM y CloudWatch, por lo que
# necesita permisos amplios. La confianza esta limitada a un solo repositorio.
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "project_name" {
  type    = string
  default = "epm-openproject"
}

variable "github_owner" {
  description = "GitHub user or organization that owns the repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

output "state_bucket" {
  value = aws_s3_bucket.tf_state.bucket
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
