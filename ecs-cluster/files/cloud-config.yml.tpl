
#cloud-config
bootcmd:
  - echo 'SERVER_ENVIRONMENT=${environment}' >> /etc/environment
  - echo 'SERVER_GROUP=${name}' >> /etc/environment
  - echo 'SERVER_REGION=${region}' >> /etc/environment

  - mkdir -p /etc/ecs
  - echo 'ECS_CLUSTER=${name}' >> /etc/ecs/ecs.config
