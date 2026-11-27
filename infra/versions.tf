terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Estado remoto en S3 con bloqueo nativo (use_lockfile).
  # Los valores (bucket, key, region) se pasan con -backend-config=backend.hcl
  backend "s3" {}
}
