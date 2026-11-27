# EPM con OpenProject en AWS — IaC + CI/CD + Observabilidad

Actividad 6 (Modelos de informática en la nube, ITM). Opción B: **CI/CD de la infraestructura como código** con GitHub Actions.

## Arquitectura
- **Contenedores:** OpenProject 16 en Docker sobre EC2 (Amazon Linux 2023).
- **Base relacional gestionada:** Amazon RDS for PostgreSQL 16 (subredes privadas, contraseña en AWS Secrets Manager).
- **Base en memoria gestionada:** Amazon ElastiCache for Memcached (caché de Rails).
- **Observabilidad:** Amazon CloudWatch con logs del contenedor (driver `awslogs`), agente de CloudWatch (memoria, disco y swap), métrica de errores obtenida de los logs, 6 alarmas con SNS y un dashboard.
- **CI/CD:** GitHub Actions + OIDC (sin claves de AWS en GitHub) + estado remoto en S3 con bloqueo nativo.

## Estructura
```
bootstrap/            # se aplica una vez en local: bucket S3 del estado + rol OIDC de GitHub
infra/                # infraestructura que despliega el pipeline
  main.tf variables.tf outputs.tf versions.tf terraform.tfvars
  modules/
    networking/       # VPC, subred pública, 2 subredes privadas, security groups
    database/         # RDS PostgreSQL + grupo de logs
    cache/            # ElastiCache Memcached
    compute/          # EC2 + Docker + OpenProject, Elastic IP, rol IAM
    observability/    # logs, métricas, alarmas, SNS, dashboard
.github/workflows/terraform.yml
```

## Pipeline
| Evento | Trabajos |
|---|---|
| Pull request a `main` | `fmt -check`, `init`, `validate`, `plan` y comentario con el plan en el PR |
| Push a `main` | lo anterior + `apply` del plan guardado |
| Manual (`workflow_dispatch`) | `plan`, `apply` o `destroy` |

Variables del repositorio: `AWS_REGION`, `AWS_ROLE_ARN`, `TF_STATE_BUCKET`.

## Limpieza
1. Ejecutar el workflow manual con `destroy`.
2. En local: `cd bootstrap && terraform destroy`.
