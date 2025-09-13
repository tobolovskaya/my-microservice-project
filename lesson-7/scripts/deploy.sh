#!/bin/bash

# Скрипт для автоматичного розгортання Django застосунку в EKS

set -e

echo "🚀 Початок розгортання Django застосунку в EKS..."

# Перевірка необхідних інструментів
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform не встановлено"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl не встановлено"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ Helm не встановлено"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI не встановлено"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker не встановлено"; exit 1; }

# Змінні
AWS_REGION="us-west-2"
CLUSTER_NAME="lesson-7-eks-cluster"
DJANGO_APP_PATH="../dockerized-django"

echo "📋 Крок 1: Розгортання інфраструктури через Terraform..."
terraform init
terraform plan
terraform apply -auto-approve

echo "📋 Крок 2: Налаштування kubectl..."
aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME

echo "📋 Крок 3: Перевірка підключення до кластера..."
kubectl get nodes

echo "📋 Крок 4: Отримання URL ECR репозиторію..."
ECR_URL=$(terraform output -raw ecr_repository_url)
echo "ECR URL: $ECR_URL"

echo "📋 Крок 5: Авторизація в ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL

echo "📋 Крок 6: Збірка та завантаження Docker образу..."
if [ -d "$DJANGO_APP_PATH" ]; then
    cd $DJANGO_APP_PATH
    docker build -t django-app .
    docker tag django-app:latest $ECR_URL:latest
    docker push $ECR_URL:latest
    cd - > /dev/null
else
    echo "⚠️  Директорія $DJANGO_APP_PATH не знайдена. Пропускаємо збірку образу."
fi

echo "📋 Крок 7: Оновлення Helm values з ECR URL..."
sed -i.bak "s|repository: \"\"|repository: \"$ECR_URL\"|g" charts/django-app/values.yaml

echo "📋 Крок 8: Встановлення Django застосунку через Helm..."
helm upgrade --install django-app ./charts/django-app

echo "📋 Крок 9: Очікування готовності подів..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=django-app --timeout=300s

echo "📋 Крок 10: Отримання інформації про сервіс..."
kubectl get services django-app

echo "🎉 Розгортання завершено успішно!"
echo ""
echo "📊 Корисні команди:"
echo "  kubectl get pods                    # Перегляд подів"
echo "  kubectl get services               # Перегляд сервісів"
echo "  kubectl get hpa                    # Перегляд автомасштабування"
echo "  kubectl logs -f deployment/django-app  # Перегляд логів"
echo ""
echo "🌐 Для отримання зовнішньої адреси:"
echo "  kubectl get service django-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"