#!/bin/bash

# Скрипт для автоматичного розгортання повного CI/CD процесу

set -e

echo "🚀 Початок розгортання CI/CD процесу для lesson-8-9..."

# Перевірка необхідних інструментів
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform не встановлено"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl не встановлено"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ Helm не встановлено"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI не встановлено"; exit 1; }

# Змінні
AWS_REGION="us-west-2"
CLUSTER_NAME="lesson-8-9-eks-cluster"

echo "📋 Крок 1: Розгортання інфраструктури через Terraform..."
terraform init
terraform plan
terraform apply -auto-approve

echo "📋 Крок 2: Налаштування kubectl..."
aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME

echo "📋 Крок 3: Перевірка підключення до кластера..."
kubectl get nodes

echo "📋 Крок 4: Очікування готовності Jenkins..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=jenkins -n jenkins --timeout=600s

echo "📋 Крок 5: Очікування готовності Argo CD..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=600s

echo "📋 Крок 6: Отримання інформації про сервіси..."
echo ""
echo "🔧 Jenkins:"
echo "URL: $(kubectl get service jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):8080"
echo "Admin Password: $(kubectl get secret jenkins -n jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 --decode)"
echo ""
echo "🔧 Argo CD:"
echo "URL: $(kubectl get service argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "Admin Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo ""
echo "🔧 ECR Repository:"
echo "URL: $(terraform output -raw ecr_repository_url)"

echo "🎉 Розгортання завершено успішно!"
echo ""
echo "📊 Наступні кроки:"
echo "1. Увійдіть в Jenkins UI та налаштуйте pipeline"
echo "2. Увійдіть в Argo CD UI та перевірте applications"
echo "3. Створіть Jenkins job з Jenkinsfile з репозиторію"
echo "4. Запустіть pipeline для тестування CI/CD процесу"
echo ""
echo "📚 Корисні команди:"
echo "  kubectl get pods --all-namespaces     # Перегляд всіх подів"
echo "  kubectl get applications -n argocd    # Перегляд Argo CD applications"
echo "  kubectl logs -f deployment/jenkins -n jenkins  # Логи Jenkins"