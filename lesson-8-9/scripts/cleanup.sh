#!/bin/bash

# Скрипт для очищення всіх ресурсів CI/CD

set -e

echo "🧹 Початок очищення ресурсів CI/CD..."

# Видалення Argo CD applications
echo "📋 Видалення Argo CD applications..."
kubectl delete applications --all -n argocd 2>/dev/null || echo "Argo CD applications вже видалено"

# Видалення Django застосунку якщо він існує
echo "📋 Видалення Django застосунку..."
kubectl delete deployment django-app 2>/dev/null || echo "Django deployment не існує"
kubectl delete service django-app 2>/dev/null || echo "Django service не існує"
kubectl delete hpa django-app 2>/dev/null || echo "Django HPA не існує"
kubectl delete configmap django-app-config 2>/dev/null || echo "Django ConfigMap не існує"

# Очікування видалення LoadBalancer сервісів
echo "📋 Очікування видалення LoadBalancer сервісів..."
sleep 30

# Видалення Helm releases
echo "📋 Видалення Helm releases..."
helm uninstall argocd-apps -n argocd 2>/dev/null || echo "argocd-apps release не існує"
helm uninstall argocd -n argocd 2>/dev/null || echo "argocd release не існує"
helm uninstall jenkins -n jenkins 2>/dev/null || echo "jenkins release не існує"

# Видалення namespaces
echo "📋 Видалення namespaces..."
kubectl delete namespace argocd 2>/dev/null || echo "argocd namespace не існує"
kubectl delete namespace jenkins 2>/dev/null || echo "jenkins namespace не існує"

# Очікування повного видалення
echo "📋 Очікування повного видалення ресурсів..."
sleep 60

# Видалення інфраструктури Terraform
echo "📋 Видалення інфраструктури Terraform..."
terraform destroy -auto-approve

echo "🎉 Очищення завершено!"