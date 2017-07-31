#cloud-config

write_files:
  - path: /etc/environment
    content: |
        SERVER_ENVIRONMENT=${environment}
        SERVER_GROUP=${name}
        SERVER_REGION=${region}
  - path: /etc/ecs/ecs.config
    content: |
        # http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html
        ECS_CLUSTER=${name}
        ECS_AVAILABLE_LOGGING_DRIVERS=['awslogs', 'json-file', 'syslog']
    owner: root:root
  - path: /etc/awslogs/awslogs.conf
    content: |
        [general]
        region = ${region}
        state_file = /var/lib/awslogs/agent-state

        [/var/log/dmesg]
        file = /var/log/dmesg
        log_group_name = ${cloudwatch_prefix}/var/log/dmesg
        log_stream_name = ${cluster_name}/{container_instance_id}

        [/var/log/messages]
        file = /var/log/messages
        log_group_name = ${cloudwatch_prefix}/var/log/messages
        log_stream_name = ${cluster_name}/{container_instance_id}
        datetime_format = %b %d %H:%M:%S

        [/var/log/docker]
        file = /var/log/docker
        log_group_name = ${cloudwatch_prefix}/var/log/docker
        log_stream_name = ${cluster_name}/{container_instance_id}
        datetime_format = %Y-%m-%dT%H:%M:%S.%f

        [/var/log/ecs/ecs-init.log]
        file = /var/log/ecs/ecs-init.log.*
        log_group_name = ${cloudwatch_prefix}/var/log/ecs/ecs-init.log
        log_stream_name = ${cluster_name}/{container_instance_id}
        datetime_format = %Y-%m-%dT%H:%M:%SZ

        [/var/log/ecs/ecs-agent.log]
        file = /var/log/ecs/ecs-agent.log.*
        log_group_name = ${cloudwatch_prefix}/var/log/ecs/ecs-agent.log
        log_stream_name = ${cluster_name}/{container_instance_id}
        datetime_format = %Y-%m-%dT%H:%M:%SZ

        [/var/log/ecs/audit.log]
        file = /var/log/ecs/audit.log.*
        log_group_name = ${cloudwatch_prefix}/var/log/ecs/audit.log
        log_stream_name = ${cluster_name}/{container_instance_id}
        datetime_format = %Y-%m-%dT%H:%M:%SZ
    owner: root:root
  - path: /etc/awslogs/awscli.conf
    content: |
        #upstart-job
        description "Configure and start CloudWatch Logs agent on Amazon ECS container instance"
        author "Amazon Web Services"
        start on started ecs

        script
        	exec 2>>/var/log/ecs/cloudwatch-logs-start.log
        	set -x

        	until curl -s http://localhost:51678/v1/metadata
        	do
        		sleep 1
        	done

        	service awslogs start
        	chkconfig awslogs on
        end script

    owner: root:root


package_upgrade: true
packages:
  - awslogs
  - jq
  - aws-cli

runcmd:
  - service awslogs start
  - chkconfig awslogs on
  - sed -i '/region = us-east-1/c\region = eu-west-1' /etc/awslogs/awscli.conf
  - service awslogs restart
  - service docker restart
  - start ecs
