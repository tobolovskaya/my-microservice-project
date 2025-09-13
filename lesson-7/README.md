# Lesson 7: Kubernetes Infrastructure with Helm

Цей проєкт містить повну інфраструктуру для розгортання Django-застосунку в Kubernetes з використанням Terraform та Helm.

## Структура проєкту

```
lesson-7/
│
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf               # Загальні виводи ресурсів
│
├── modules/                 # Каталог з усіма модулями
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   ├── vpc/                 # Модуль для VPC
│   ├── ecr/                 # Модуль для ECR
│   └── eks/                 # Модуль для EKS кластера
│
├── charts/
│   └── django-app/          # Helm chart для Django застосунку
│       ├── templates/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── configmap.yaml
│       │   ├── hpa.yaml
│       │   ├── ingress.yaml
│       │   └── _helpers.tpl
│       ├── Chart.yaml
│       └── values.yaml
│
└── README.md
```

## Кроки розгортання

### 1. Підготовка інфраструктури

```bash
cd lesson-7

# Ініціалізація Terraform
terraform init

# Планування змін
terraform plan

# Застосування змін
terraform apply
```

### 2. Налаштування kubectl

```bash
# Отримайте команду з outputs Terraform
aws eks --region us-west-2 update-kubeconfig --name lesson-7-eks-cluster

# Перевірте підключення
kubectl get nodes
```

### 3. Завантаження Docker образу в ECR

```bash
# Отримайте URL ECR з outputs Terraform
ECR_URL=$(terraform output -raw ecr_repository_url)

# Авторизація в ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_URL

# Збірка та завантаження образу (з директорії dockerized-django)
cd ../dockerized-django
docker build -t django-app .
docker tag django-app:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

### 4. Встановлення cert-manager (опціонально)

```bash
# Додавання Helm репозиторію
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Встановлення cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0 \
  --set installCRDs=true

# Створення ClusterIssuer для Let's Encrypt
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

### 5. Встановлення NGINX Ingress Controller (опціонально)

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

### 6. Розгортання Django застосунку

```bash
cd lesson-7

# Оновлення values.yaml з URL ECR
ECR_URL=$(terraform output -raw ecr_repository_url)
sed -i "s|repository: \"\"|repository: \"$ECR_URL\"|g" charts/django-app/values.yaml

# Встановлення Helm chart
helm install django-app ./charts/django-app

# Або з кастомними значеннями
helm install django-app ./charts/django-app \
  --set image.repository=$ECR_URL \
  --set image.tag=latest
```

### 7. Перевірка розгортання

```bash
# Перевірка подів
kubectl get pods

# Перевірка сервісів
kubectl get services

# Перевірка HPA
kubectl get hpa

# Перевірка ConfigMap
kubectl get configmap

# Отримання зовнішньої IP адреси
kubectl get service django-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Налаштування Ingress

Для використання Ingress з доменом, оновіть `values.yaml`:

```yaml
ingress:
  enabled: true
  className: nginx
  host: yourdomain.com
  path: /
  pathType: Prefix
  tls: true
```

Потім оновіть Helm release:

```bash
helm upgrade django-app ./charts/django-app
```

## Моніторинг та масштабування

### Перевірка автомасштабування

```bash
# Генерація навантаження для тестування HPA
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh

# В контейнері виконайте:
while true; do wget -q -O- http://django-app/admin/; done
```

### Перегляд метрик

```bash
# Перегляд використання ресурсів
kubectl top nodes
kubectl top pods

# Перегляд статусу HPA
kubectl describe hpa django-app
```

## Очищення ресурсів

```bash
# Видалення Helm release
helm uninstall django-app

# Видалення cert-manager (якщо встановлено)
helm uninstall cert-manager -n cert-manager

# Видалення NGINX Ingress (якщо встановлено)
helm uninstall ingress-nginx -n ingress-nginx

# Видалення інфраструктури Terraform
terraform destroy
```

## Корисні команди

```bash
# Перегляд логів
kubectl logs -f deployment/django-app

# Підключення до поду
kubectl exec -it deployment/django-app -- /bin/bash

# Перегляд конфігурації
kubectl describe deployment django-app
kubectl describe service django-app
kubectl describe hpa django-app

# Оновлення Helm chart
helm upgrade django-app ./charts/django-app

# Перегляд історії релізів
helm history django-app

# Відкат до попередньої версії
helm rollback django-app 1
```

## Особливості конфігурації

### ConfigMap
Всі змінні середовища зберігаються в ConfigMap і автоматично підключаються до подів через `envFrom`.

### HPA
Автомасштабування налаштовано на:
- Мінімум: 2 поди
- Максимум: 6 подів
- Поріг CPU: 70%

### Service
LoadBalancer забезпечує зовнішній доступ до застосунку.

### Ingress
Підтримує HTTPS з автоматичними сертифікатами через cert-manager.

## Безпека

- ECR репозиторій з шифруванням
- EKS кластер з приватними підмережами
- Security Groups з мінімальними правами
- Secrets для TLS сертифікатів

## Вартість оптимізація

- Використання t3.medium інстансів
- Автомасштабування для оптимізації ресурсів
- Lifecycle policies для ECR
- Spot instances можна налаштувати в node groups