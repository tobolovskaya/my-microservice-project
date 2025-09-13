# Lesson 8-9: Complete CI/CD with Jenkins and Argo CD

Цей проєкт реалізує повний CI/CD процес з використанням Jenkins, Terraform, ECR, Helm та Argo CD для автоматичного розгортання Django-застосунку в Kubernetes.

## Архітектура CI/CD

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │     Jenkins     │    │    Argo CD      │
│   Push Code     │───▶│   CI Pipeline   │───▶│  CD Deployment  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │                        │
                              ▼                        ▼
                       ┌─────────────┐         ┌─────────────┐
                       │     ECR     │         │ Kubernetes  │
                       │   Registry  │         │   Cluster   │
                       └─────────────┘         └─────────────┘
```

## Структура проєкту

```
lesson-8-9/
│
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів
├── outputs.tf               # Загальні виводи ресурсів
├── variables.tf             # Глобальні змінні
│
├── modules/                 # Каталог з усіма модулями
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   ├── vpc/                 # Модуль для VPC
│   ├── ecr/                 # Модуль для ECR
│   ├── eks/                 # Модуль для EKS кластера
│   ├── jenkins/             # Модуль для Jenkins
│   └── argo_cd/             # Модуль для Argo CD
│
├── charts/
│   └── django-app/          # Helm chart для Django застосунку
│
├── jenkins/
│   ├── Jenkinsfile          # Pipeline для CI/CD
│   └── kaniko-config/       # Конфігурація для Kaniko
│
└── scripts/
    ├── deploy.sh            # Скрипт розгортання
    └── cleanup.sh           # Скрипт очищення
```

## Компоненти системи

### 1. Jenkins CI Pipeline
- Автоматична збірка Docker образів з Kaniko
- Публікація в Amazon ECR
- Оновлення Helm chart з новим тегом
- Git commit та push змін

### 2. Argo CD Deployment
- Моніторинг Git репозиторію
- Автоматична синхронізація Helm charts
- Розгортання в Kubernetes кластер

### 3. Infrastructure as Code
- Terraform модулі для всіх компонентів
- Helm charts для Jenkins та Argo CD
- Автоматизоване налаштування

## Кроки розгортання

### 1. Підготовка інфраструктури

```bash
cd lesson-8-9

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
aws eks --region us-west-2 update-kubeconfig --name lesson-8-9-eks-cluster

# Перевірте підключення
kubectl get nodes
```

### 3. Доступ до Jenkins

```bash
# Отримання пароля адміністратора
kubectl get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode

# Отримання URL Jenkins
kubectl get service jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 4. Доступ до Argo CD

```bash
# Отримання початкового пароля
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Отримання URL Argo CD
kubectl get service argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 5. Налаштування Jenkins Pipeline

1. Увійдіть в Jenkins UI
2. Створіть новий Pipeline job
3. Налаштуйте Git repository з Jenkinsfile
4. Додайте необхідні credentials (AWS, Git)

### 6. Налаштування Argo CD Application

1. Увійдіть в Argo CD UI
2. Створіть нову Application
3. Налаштуйте Git repository з Helm chart
4. Встановіть автоматичну синхронізацію

## CI/CD Workflow

### Jenkins Pipeline (CI)

1. **Checkout Code**: Отримання коду з Git
2. **Build Image**: Збірка Docker образу з Kaniko
3. **Push to ECR**: Публікація образу в Amazon ECR
4. **Update Helm Chart**: Оновлення values.yaml з новим тегом
5. **Commit Changes**: Commit та push змін в Git

### Argo CD (CD)

1. **Monitor Git**: Моніторинг змін в Git репозиторії
2. **Sync Detection**: Виявлення нових змін в Helm chart
3. **Deploy Application**: Розгортання оновленого застосунку
4. **Health Check**: Перевірка стану застосунку

## Моніторинг та управління

### Jenkins

```bash
# Перегляд подів Jenkins
kubectl get pods -l app.kubernetes.io/name=jenkins

# Перегляд логів Jenkins
kubectl logs -f deployment/jenkins

# Перегляд сервісів
kubectl get services jenkins
```

### Argo CD

```bash
# Перегляд подів Argo CD
kubectl get pods -n argocd

# Перегляд applications
kubectl get applications -n argocd

# Синхронізація через CLI
argocd app sync django-app
```

### Django Application

```bash
# Перегляд подів застосунку
kubectl get pods -l app.kubernetes.io/name=django-app

# Перегляд статусу HPA
kubectl get hpa django-app

# Перегляд сервісу
kubectl get service django-app
```

## Безпека

### Jenkins
- RBAC налаштування для Kubernetes
- Secure credentials storage
- Pipeline security scanning

### Argo CD
- RBAC для applications
- Git repository access control
- TLS encryption

### ECR
- Image vulnerability scanning
- Access policies
- Encryption at rest

## Troubleshooting

### Jenkins Issues

```bash
# Перевірка статусу Jenkins
kubectl describe deployment jenkins

# Перегляд подій
kubectl get events --sort-by=.metadata.creationTimestamp

# Перевірка persistent volume
kubectl get pv,pvc
```

### Argo CD Issues

```bash
# Перевірка статусу Argo CD
kubectl get pods -n argocd

# Перегляд логів server
kubectl logs -n argocd deployment/argocd-server

# Перевірка application status
kubectl describe application django-app -n argocd
```

### Pipeline Issues

```bash
# Перевірка Kaniko pods
kubectl get pods -l app=kaniko

# Перегляд логів збірки
kubectl logs -f <kaniko-pod-name>

# Перевірка ECR access
aws ecr describe-repositories --region us-west-2
```

## Очищення ресурсів

```bash
# Видалення Argo CD applications
kubectl delete applications --all -n argocd

# Видалення Jenkins jobs
# (через UI або CLI)

# Видалення інфраструктури
terraform destroy
```

## Корисні команди

### Git Operations

```bash
# Клонування репозиторію
git clone <repository-url>

# Створення нової гілки
git checkout -b feature/new-feature

# Commit та push
git add .
git commit -m "Update application version"
git push origin main
```

### Docker Operations

```bash
# Локальна збірка для тестування
docker build -t django-app:test .

# Запуск локально
docker run -p 8000:8000 django-app:test
```

### Kubernetes Operations

```bash
# Перегляд всіх ресурсів
kubectl get all

# Перегляд конфігурації
kubectl describe deployment django-app

# Підключення до поду
kubectl exec -it <pod-name> -- /bin/bash
```

## Метрики та моніторинг

### Jenkins Metrics
- Build success rate
- Build duration
- Queue time
- Agent utilization

### Argo CD Metrics
- Sync frequency
- Application health
- Deployment success rate
- Drift detection

### Application Metrics
- Pod resource usage
- HPA scaling events
- Service response time
- Error rates

## Розширення функціональності

### Додаткові можливості
- Multi-environment deployments
- Blue-green deployments
- Canary releases
- Automated testing integration
- Slack/Teams notifications
- Prometheus monitoring
- Grafana dashboards

### Інтеграції
- SonarQube для якості коду
- Trivy для сканування безпеки
- Vault для управління секретами
- Istio для service mesh

## Висновки

Цей проєкт демонструє повний цикл CI/CD з використанням сучасних DevOps інструментів:

1. **Автоматизація**: Повна автоматизація від коду до продакшену
2. **Безпека**: Впровадження кращих практик безпеки
3. **Масштабованість**: Готовність до роботи з великими проєктами
4. **Моніторинг**: Повний контроль над процесами
5. **Відновлення**: Швидке виявлення та усунення проблем

Цей підхід забезпечує швидке, надійне та передбачуване доставлення змін у продакшн середовище.