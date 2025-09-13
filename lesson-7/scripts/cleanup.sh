#!/bin/bash

# Скрипт для очищення всіх ресурсів

set -e

echo "🧹 Початок очищення ресурсів..."

# Видалення Helm release
echo "📋 Видалення Django застосунку..."
helm uninstall django-app 2>/dev/null || echo "Django застосунок вже видалено"

# Видалення cert-manager якщо встановлено
echo "📋 Видалення cert-manager..."
helm uninstall cert-manager -n cert-manager 2>/dev/null || echo "cert-manager не встановлено"
kubectl delete namespace cert-manager 2>/dev/null || echo "Namespace cert-manager не існує"

# Видалення NGINX Ingress якщо встановлено
echo "📋 Видалення NGINX Ingress..."
helm uninstall ingress-nginx -n ingress-nginx 2>/dev/null || echo "NGINX Ingress не встановлено"
kubectl delete namespace ingress-nginx 2>/dev/null || echo "Namespace ingress-nginx не існує"

# Очікування видалення LoadBalancer сервісів
echo "📋 Очікування видалення LoadBalancer сервісів..."
sleep 30

# Видалення інфраструктури Terraform
echo "📋 Видалення інфраструктури Terraform..."
terraform destroy -auto-approve

echo "🎉 Очищення завершено!"