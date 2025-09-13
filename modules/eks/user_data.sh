#!/bin/bash

# User data script для EKS node groups
# Цей скрипт виконується при запуску EC2 інстансів в node group

set -o xtrace

# Змінні з template
CLUSTER_NAME="${cluster_name}"
CLUSTER_ENDPOINT="${cluster_endpoint}"
CLUSTER_CA="${cluster_ca}"
BOOTSTRAP_ARGUMENTS="${bootstrap_arguments}"

# Логування
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting user data script for EKS node"
echo "Cluster Name: $CLUSTER_NAME"
echo "Bootstrap Arguments: $BOOTSTRAP_ARGUMENTS"

# Оновлення системи
yum update -y

# Встановлення додаткових пакетів
yum install -y \
    awscli \
    jq \
    htop \
    tree \
    wget \
    curl \
    unzip

# Налаштування CloudWatch агента (опціонально)
if [ "${enable_cloudwatch_agent}" = "true" ]; then
    yum install -y amazon-cloudwatch-agent
    
    # Конфігурація CloudWatch агента
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "metrics": {
        "namespace": "EKS/NodeGroup",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/aws/eks/$CLUSTER_NAME/node-group/system",
                        "log_stream_name": "{instance_id}/messages"
                    },
                    {
                        "file_path": "/var/log/dmesg",
                        "log_group_name": "/aws/eks/$CLUSTER_NAME/node-group/system",
                        "log_stream_name": "{instance_id}/dmesg"
                    }
                ]
            }
        }
    }
}
EOF

    # Запуск CloudWatch агента
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config \
        -m ec2 \
        -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
        -s
fi

# Налаштування Docker (якщо потрібно)
# EKS використовує containerd за замовчуванням, але Docker може бути корисний для налагодження
if [ "${install_docker}" = "true" ]; then
    yum install -y docker
    systemctl enable docker
    systemctl start docker
    usermod -a -G docker ec2-user
fi

# Встановлення kubectl для налагодження
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.28.3/2023-11-14/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/

# Встановлення helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Налаштування SSH ключів (якщо потрібно)
if [ -n "${ssh_public_key}" ]; then
    echo "${ssh_public_key}" >> /home/ec2-user/.ssh/authorized_keys
fi

# Налаштування додаткових змінних середовища
cat >> /etc/environment << EOF
CLUSTER_NAME=$CLUSTER_NAME
AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
EOF

# Налаштування профілю для ec2-user
cat >> /home/ec2-user/.bashrc << 'EOF'
# EKS aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'

# AWS CLI автодоповнення
complete -C '/usr/local/bin/aws_completer' aws

# Kubectl автодоповнення
source <(kubectl completion bash)
complete -F __start_kubectl k
EOF

# Налаштування логротації
cat > /etc/logrotate.d/user-data << 'EOF'
/var/log/user-data.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF

# Запуск bootstrap скрипта EKS
/etc/eks/bootstrap.sh $CLUSTER_NAME $BOOTSTRAP_ARGUMENTS

echo "User data script completed successfully"