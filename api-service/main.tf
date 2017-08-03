/**
 * Usage:
 *
 *      module "auth_service" {
 *        source    = "stack/api-service"
 *        name      = "auth-api-service"
 *        image     = "auth-api-service"
 *        cluster   = "default"
 *      }
 *
 */

/**
 * Resources.
 */

data "aws_region" "current" {
  current = true
}

resource "aws_s3_bucket" "main" {
  bucket = "${var.name}-deployments"
  acl = "private"

  tags {
    Name = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_cloudformation_stack" "main" {
  name = "${var.name}-${var.environment}"
  template_body = <<STACK
Parameters:
  GitHubRepo:
    Type: String

  GitHubBranch:
    Type: String

  GitHubToken:
    Type: String

  GitHubUser:
    Type: String

  TemplateBucket:
    Type: String

  Tag:
    Type: String
    Default: latest

  Name:
    Type: String

  ContainerName:
    Type: String

  ContainerPort:
    Type: String

  DesiredCount:
    Type: Number
    Default: 0

  LoadBalancerName:
    Type: String

  Cluster:
    Type: String

  RDS_DB_NAME:
    Type: String

  RDS_HOSTNAME:
    Type: String

  RDS_USERNAME:
    Type: String

  RDS_PASSWORD:
    Type: String

  AwslogsGroup:
    Type: String

  AwslogsRegion:
    Type: String

  AwslogsStreamPrefix:
    Type: String


Resources:
  Repository:
    Type: AWS::ECR::Repository
    DeletionPolicy: Retain

  CloudFormationExecutionRole:
    Type: AWS::IAM::Role
    DeletionPolicy: Retain
    Properties:
      Path: /
      AssumeRolePolicyDocument: |
        {
            "Statement": [{
                "Effect": "Allow",
                "Principal": { "Service": [ "cloudformation.amazonaws.com" ]},
                "Action": [ "sts:AssumeRole" ]
            }]
        }
      Policies:
        - PolicyName: root
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Resource: "*"
                Effect: Allow
                Action:
                  - ecs:*
                  - ecr:*
                  - iam:*

  CodeBuildServiceRole:
    Type: AWS::IAM::Role
    Properties:
      Path: /
      AssumeRolePolicyDocument: |
        {
            "Statement": [{
                "Effect": "Allow",
                "Principal": { "Service": [ "codebuild.amazonaws.com" ]},
                "Action": [ "sts:AssumeRole" ]
            }]
        }
      Policies:
        - PolicyName: root
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Resource: "*"
                Effect: Allow
                Action:
                  - logs:CreateLogGroup
                  - logs:CreateLogStream
                  - logs:PutLogEvents
                  - ecr:GetAuthorizationToken
              - Resource: !Sub arn:aws:s3:::${ArtifactBucket}/*
                Effect: Allow
                Action:
                  - s3:GetObject
                  - s3:PutObject
                  - s3:GetObjectVersion
              - Resource: !Sub arn:aws:ecr:${AWS::Region}:${AWS::AccountId}:repository/${Repository}
                Effect: Allow
                Action:
                  - ecr:GetDownloadUrlForLayer
                  - ecr:BatchGetImage
                  - ecr:BatchCheckLayerAvailability
                  - ecr:PutImage
                  - ecr:InitiateLayerUpload
                  - ecr:UploadLayerPart
                  - ecr:CompleteLayerUpload

  CodePipelineServiceRole:
    Type: AWS::IAM::Role
    Properties:
      Path: /
      AssumeRolePolicyDocument: |
        {
            "Statement": [{
                "Effect": "Allow",
                "Principal": { "Service": [ "codepipeline.amazonaws.com" ]},
                "Action": [ "sts:AssumeRole" ]
            }]
        }
      Policies:
        - PolicyName: root
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Resource:
                  - !Sub arn:aws:s3:::${ArtifactBucket}/*
                  - !Sub arn:aws:s3:::${TemplateBucket}
                  - !Sub arn:aws:s3:::${TemplateBucket}/*
                Effect: Allow
                Action:
                  - s3:PutObject
                  - s3:GetObject
                  - s3:GetObjectVersion
                  - s3:GetBucketVersioning
              - Resource: "*"
                Effect: Allow
                Action:
                  - codebuild:StartBuild
                  - codebuild:BatchGetBuilds
                  - cloudformation:*
                  - iam:PassRole

  ArtifactBucket:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain

  CodeBuildProject:
    Type: AWS::CodeBuild::Project
    Properties:
      Artifacts:
        Location: !Ref ArtifactBucket
        Type: "S3"
      Source:
        Location: !Sub ${ArtifactBucket}/source.zip
        Type: "S3"
        BuildSpec: |
          version: 0.2
          phases:
            pre_build:
              commands:
                - $(aws ecr get-login)
                - TAG="$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | head -c 8)"
            build:
              commands:
                - docker build --tag "${REPOSITORY_URI}:${TAG}" .
            post_build:
              commands:
                - docker push "${REPOSITORY_URI}:${TAG}"
                - printf '{"tag":"%s"}' $TAG > build.json
          artifacts:
            files: build.json
      Environment:
        ComputeType: "BUILD_GENERAL1_SMALL"
        Image: "aws/codebuild/docker:1.12.1"
        Type: "LINUX_CONTAINER"
        EnvironmentVariables:
          - Name: AWS_DEFAULT_REGION
            Value: !Ref AWS::Region
          - Name: REPOSITORY_URI
            Value: !Sub ${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com/${Repository}
      Name: !Ref AWS::StackName
      ServiceRole: !Ref CodeBuildServiceRole

  Pipeline:
    Type: AWS::CodePipeline::Pipeline
    Properties:
      RoleArn: !GetAtt CodePipelineServiceRole.Arn
      ArtifactStore:
        Type: S3
        Location: !Ref ArtifactBucket
      Stages:
        - Name: Source
          Actions:
            - Name: App
              ActionTypeId:
                Category: Source
                Owner: ThirdParty
                Version: 1
                Provider: GitHub
              Configuration:
                Owner: !Ref GitHubUser
                Repo: !Ref GitHubRepo
                Branch: !Ref GitHubBranch
                OAuthToken: !Ref GitHubToken
              OutputArtifacts:
                - Name: App
              RunOrder: 1
            - Name: Template
              ActionTypeId:
                Category: Source
                Owner: AWS
                Version: 1
                Provider: S3
              OutputArtifacts:
                - Name: Template
              RunOrder: 1
              Configuration:
                S3Bucket: !Ref TemplateBucket
                S3ObjectKey: templates.zip
        - Name: Build
          Actions:
            - Name: Build
              ActionTypeId:
                Category: Build
                Owner: AWS
                Version: 1
                Provider: CodeBuild
              Configuration:
                ProjectName: !Ref CodeBuildProject
              InputArtifacts:
                - Name: App
              OutputArtifacts:
                - Name: BuildOutput
              RunOrder: 1
        - Name: Deploy
          Actions:
            - Name: Deploy
              ActionTypeId:
                Category: Deploy
                Owner: AWS
                Version: 1
                Provider: CloudFormation
              Configuration:
                ChangeSetName: Deploy
                ActionMode: CREATE_UPDATE
                StackName: !Ref Name
                Capabilities: CAPABILITY_NAMED_IAM
                TemplatePath: Template::templates/service.yaml
                RoleArn: !GetAtt CloudFormationExecutionRole.Arn
                ParameterOverrides: !Sub |
                  {
                    "Tag" : { "Fn::GetParam" : [ "BuildOutput", "build.json", "tag" ] },
                    "Name": "${Name}",
                    "ContainerName": "${ContainerName}",
                    "ContainerPort": "${ContainerPort}",
                    "DesiredCount": "${DesiredCount}",
                    "RDS_DB_NAME": "${RDS_DB_NAME}",
                    "RDS_HOSTNAME": "${RDS_HOSTNAME}",
                    "RDS_USERNAME": "${RDS_USERNAME}",
                    "RDS_PASSWORD": "${RDS_PASSWORD}",
                    "AwslogsGroup": "${AwslogsGroup}",
                    "AwslogsRegion": "${AwslogsRegion}",
                    "AwslogsStreamPrefix": "${AwslogsStreamPrefix}",
                    "DesiredCount": "1",
                    "Cluster": "${Cluster}",
                    "LoadBalancerName": "${LoadBalancerName}",
                    "Repository": "${Repository}"
                  }
              InputArtifacts:
                - Name: Template
                - Name: BuildOutput
              RunOrder: 1


Outputs:
  PipelineUrl:
    Value: !Sub https://console.aws.amazon.com/codepipeline/home?region=${AWS::Region}#/view/${Pipeline}
STACK

  parameters {
    GitHubRepo = "${var.source_repo}"
    GitHubBranch = "${var.source_branch}"
    GitHubToken = "${var.oauth_token}"
    GitHubUser = "${var.source_owner}"
    LoadBalancerName = "${module.elb.name}"
    Cluster = "${var.cluster}"
    TemplateBucket = "${aws_s3_bucket.main.bucket}"
    Name = "${var.name}-${var.environment}"
    ContainerName = "${var.name}-${var.environment}"
    ContainerPort = "${var.container_port}"
    Port = "${var.port}"
    DesiredCount = "${var.desired_count}"
    LoadBalancerName = "${module.elb.id}"
    RDS_DB_NAME = "${var.rds_db_name}"
    RDS_HOSTNAME = "${var.rds_hostname}"
    RDS_USERNAME = "${var.rds_username}"
    RDS_PASSWORD = "${var.rds_password}"
    AwslogsGroup = "${var.environment}"
    AwslogsRegion = "${data.aws_region.current.name}"
    AwslogsStreamPrefix = "${var.name}"
  }
}

//resource "aws_ecs_service" "main" {
//  name = "${module.task.family}"
//  cluster = "${var.cluster}"
//  task_definition = "${module.task.arn}"
//  desired_count = "${var.desired_count}"
//  iam_role = "${var.iam_role}"
//  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
//  deployment_maximum_percent = "${var.deployment_maximum_percent}"
//
//  load_balancer {
//    elb_name = "${module.elb.id}"
//    container_name = "${module.task.family}"
//    container_port = "${var.container_port}"
//  }
//
//  lifecycle {
//    create_before_destroy = true
//  }
//}

module "api_gateway" {
  source = "../api-gateway"
  environment = "${var.environment}"
  api_id = "${var.api_id}"
  api_root_id = "${var.api_root_id}"
  api_endpoint = "${var.api_endpoint}"
  api_stage = "${var.api_stage}"
  resource_name = "${var.api_resource_name}"
  elb_dns = "${module.elb.dns}"
}

//module "codebuild" {
//  source = "./codebuild"
//  iam_role_id = "${var.codebuild_iam_role_role_id}"
//  name = "${coalesce(var.name, replace(var.image, "/", "-"))}"
//  environment = "${var.environment}"
//  image = "${var.image}"
//  repo_url = "${var.source_repo}"
//  github_oauth_token = "${var.oauth_token}"
//  policy_arn = "${var.codebuild_policy}"
//  rds_db_name = "${var.rds_db_name}"
//  rds_hostname = "${var.rds_hostname}"
//  rds_password = "${var.rds_password}"
//  rds_username = "${var.rds_username}"
//}
//
//module "codepipeline" {
//  source = "./codepipeline"
//  name = "${coalesce(var.name, replace(var.image, "/", "-"))}"
//  environment = "${var.environment}"
//  image_version = "${var.version}"
//  memory = "${var.memory}"
//  cpu = "${var.cpu}"
//  ecs_container_env_vars = "${var.env_vars}"
//  elb_id = "${module.elb.id}"
//  cluster = "${var.cluster}"
//  role_arn = "${var.codepipeline_role_arn}"
//  ecs_iam_role = "${var.iam_role}"
//  port = "${var.port}"
//  container_port = "${var.container_port}"
//  codebuild_project_name = "${module.codebuild.name}"
//  codebuild_migration_project_name = "${module.codebuild.migration_name}"
//  source_owner = "${var.source_owner}"
//  source_repo = "${var.source_repo}"
//  source_branch = "${var.source_branch}"
//  repository_url = "${module.repository.repository_url}"
//  oauth_token = "${var.oauth_token}"
//  codebuild_iam_role_role_id = "${var.codebuild_iam_role_role_id}"
//}

//module "repository" {
//  source = "../repository"
//  image = "${var.image}"
//}

//module "task" {
//  source = "../ecs-cluster/task"
//
//  name = "${coalesce(var.name, replace(var.image, "/", "-"))}"
//  image = "${var.image}"
//  image_version = "${var.version}"
//  command = "${var.command}"
//  env_vars = "${var.env_vars}"
//  memory = "${var.memory}"
//  cpu = "${var.cpu}"
//  log_group = "${var.name}"
//  log_prefix = "${var.environment}"
////  role = "${var.iam_role}"
//
//  ports = <<EOF
//  [
//    {
//      "containerPort": ${var.container_port},
//      "hostPort": ${var.port}
//    }
//  ]
//EOF
//}

module "elb" {
  source = "./elb"

  name = "${var.name}"
  port = "${var.port}"
  environment = "${var.environment}"
  subnet_ids = "${var.subnet_ids}"
  external_dns_name = "${coalesce(var.external_dns_name, var.name)}"
  internal_dns_name = "${coalesce(var.internal_dns_name, var.name)}"
  healthcheck = "${var.healthcheck}"
  external_zone_id = "${var.external_zone_id}"
  internal_zone_id = "${var.internal_zone_id}"
  security_groups = "${var.security_groups}"
  log_bucket = "${var.log_bucket}"
  ssl_certificate_id = "${var.ssl_certificate_id}"
}