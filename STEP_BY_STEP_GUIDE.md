# 🚀 Покрокова інструкція виконання фінального проєкту

## 📋 Технічні вимоги

**Інфраструктура:** AWS з використанням Terraform  
**Компоненти:** VPC, EKS, RDS, ECR, Jenkins, Argo CD, Prometheus, Grafana

---

## 🎯 Етапи виконання

### 📁 **Етап 0: Підготовка проєкту**

1. **Клонування репозиторію:**
```bash
git clone <your-repository-url>
cd final-devops-project
git checkout -b final-project
```

2. **Перевірка структури проєкту:**
```bash
tree -L 3
# Переконайтеся, що структура відповідає вимогам
```

3. **Налаштування AWS CLI:**
```bash
aws configure
# Введіть ваші AWS credentials
aws sts get-caller-identity  # Перевірка
```

---

### 🔧 **Етап 1: Підготовка середовища**

#### 1.1 Налаштування S3 Backend (перший раз)

```bash
# 1. Створіть конфігурацію backend
cp terraform.tfvars.example terraform.tfvars

# 2. Відредагуйте terraform.tfvars з унікальними значеннями
# ОБОВ'ЯЗКОВО змініть:
# - backend_bucket_name на унікальну назву
# - db_password на безпечний пароль
# - jenkins_admin_password на безпечний пароль
# - argocd_admin_password на безпечний пароль
# - grafana_admin_password на безпечний пароль
```

#### 1.2 Створення S3 Backend

```bash
# 1. Ініціалізація Terraform
terraform init

# 2. Створення S3 та DynamoDB для backend
terraform apply -target=module.s3_backend -auto-approve

# 3. Отримання конфігурації backend
terraform output backend_configuration

# 4. Додайте виведену конфігурацію в backend.tf
# 5. Повторна ініціалізація з backend
terraform init -migrate-state
```

#### 1.3 Перевірка змінних

```bash
# Перевірте всі необхідні змінні
terraform validate
terraform plan
```

---

### 🏗️ **Етап 2: Розгортання інфраструктури**

#### 2.1 Розгортання базової інфраструктури

```bash
# Розгортання VPC, RDS, ECR
terraform apply -target=module.vpc -auto-approve
terraform apply -target=module.rds -auto-approve  
terraform apply -target=module.ecr -auto-approve
```

#### 2.2 Розгортання EKS кластера

```bash
# Розгортання EKS (може зайняти 10-15 хвилин)
terraform apply -target=module.eks -auto-approve

# Налаштування kubectl
aws eks update-kubeconfig --region us-west-2 --name $(terraform output -raw eks_cluster_name)

# Перевірка кластера
kubectl get nodes
kubectl get pods --all-namespaces
```

#### 2.3 Розгортання CI/CD інструментів

```bash
# Розгортання Jenkins
terraform apply -target=module.jenkins -auto-approve

# Розгортання Argo CD
terraform apply -target=module.argocd -auto-approve

# Розгортання моніторингу
terraform apply -var-file=terraform.tfvars setup-monitoring.tf
```

#### 2.4 Фінальне розгортання

```bash
# Застосування всіх змін
terraform apply -auto-approve
```

---

### ✅ **Етап 3: Перевірка доступності**

#### 3.1 Перевірка стану ресурсів

```bash
# Перевірка Jenkins
kubectl get all -n jenkins
kubectl get pvc -n jenkins

# Перевірка Argo CD
kubectl get all -n argocd
kubectl get applications -n argocd

# Перевірка моніторингу
kubectl get all -n monitoring
kubectl get pvc -n monitoring
```

#### 3.2 Доступ до Jenkins

```bash
# Port-forward для Jenkins
kubectl port-forward svc/jenkins-jenkins 8080:8080 -n jenkins

# В іншому терміналі отримайте пароль
terraform output jenkins_admin_password

# Відкрийте браузер: http://localhost:8080
# Логін: admin
# Пароль: з виводу terraform
```

**Перевірка Jenkins:**
- [ ] Веб-інтерфейс доступний
- [ ] Можна залогінитися
- [ ] Kubernetes плагін встановлений
- [ ] Agents підключаються

#### 3.3 Доступ до Argo CD

```bash
# Port-forward для Argo CD
kubectl port-forward svc/argocd-argocd-server 8081:443 -n argocd --insecure

# В іншому терміналі отримайте пароль
terraform output argocd_admin_password

# Відкрийте браузер: https://localhost:8081
# Логін: admin
# Пароль: з виводу terraform
```

**Перевірка Argo CD:**
- [ ] Веб-інтерфейс доступний
- [ ] Можна залогінитися
- [ ] Кластер підключений
- [ ] Можна створювати Applications

---

### 📊 **Етап 4: Моніторинг та перевірка метрик**

#### 4.1 Доступ до Grafana

```bash
# Port-forward для Grafana
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring

# Отримання пароля Grafana
terraform output grafana_admin_password

# Відкрийте браузер: http://localhost:3000
# Логін: admin
# Пароль: з виводу terraform
```

#### 4.2 Доступ до Prometheus

```bash
# Port-forward для Prometheus
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring

# Відкрийте браузер: http://localhost:9090
```

**Перевірка моніторингу:**
- [ ] Grafana доступна та показує дашборди
- [ ] Prometheus збирає метрики
- [ ] Метрики з Jenkins та Argo CD доступні
- [ ] AlertManager налаштований

---

### 🐳 **Етап 5: Розгортання Django додатку**

#### 5.1 Підготовка Docker образу

```bash
# Перейдіть в директорію Django
cd Django

# Збірка образу локально (для тестування)
docker build -t django-app:test .

# Тестування локально
docker-compose up -d
curl http://localhost:8000/health/
docker-compose down
```

#### 5.2 Завантаження в ECR

```bash
# Отримання команд для ECR
terraform output ecr_docker_push_commands

# Виконайте команди (приклад):
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com

docker build -t django-app .
docker tag django-app:latest <ecr-url>:latest
docker push <ecr-url>:latest
```

#### 5.3 Розгортання через Helm

```bash
# Повернутися в корінь проєкту
cd ..

# Розгортання Django додатку
helm install django-app ./charts/django-app \
  --set image.repository=$(terraform output -raw ecr_repository_url) \
  --set image.tag=latest \
  --set secrets.djangoSecretKey="your-secret-key" \
  --set secrets.dbPassword=$(terraform output -raw database_password) \
  --set django.database.host=$(terraform output -raw database_endpoint) \
  --namespace production \
  --create-namespace

# Перевірка розгортання
kubectl get pods -n production
kubectl get svc -n production
```

---

### 🔄 **Етап 6: Налаштування CI/CD Pipeline**

#### 6.1 Налаштування Jenkins Pipeline

1. **Відкрийте Jenkins UI**
2. **Створіть новий Pipeline job:**
   - New Item → Pipeline
   - Назва: `django-app-pipeline`
   - Pipeline script from SCM
   - Repository URL: ваш Git репозиторій
   - Script Path: `Django/Jenkinsfile`

3. **Налаштуйте credentials:**
   - AWS credentials для ECR
   - Kubeconfig для Kubernetes

#### 6.2 Налаштування Argo CD Application

```bash
# Створення Application через CLI
argocd login localhost:8081 --username admin --password $(terraform output -raw argocd_admin_password) --insecure

# Створення додатку
argocd app create django-app \
  --repo https://github.com/your-username/your-repo \
  --path charts/django-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace production

# Синхронізація
argocd app sync django-app
```

---

### 🧪 **Етап 7: Тестування повного циклу**

#### 7.1 Тест CI/CD Pipeline

1. **Зробіть зміну в коді Django**
2. **Commit та push в Git**
3. **Запустіть Jenkins pipeline**
4. **Перевірте, що Argo CD синхронізує зміни**

#### 7.2 Перевірка автомасштабування

```bash
# Генерація навантаження
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh

# В контейнері:
while true; do wget -q -O- http://django-app.production.svc.cluster.local; done

# В іншому терміналі спостерігайте за HPA:
kubectl get hpa -n production -w
```

---

## 🎯 **Критерії прийняття та оцінювання (100 балів)**

### ✅ **1. Створено середовище з коректною архітектурою (20 балів)**

**Перевірка:**
- [ ] VPC з публічними та приватними підмережами
- [ ] EKS кластер з node groups
- [ ] RDS база даних в приватних підмережах
- [ ] ECR репозиторій для образів
- [ ] Security Groups налаштовані коректно

```bash
# Команди для перевірки:
terraform output vpc_id
terraform output eks_cluster_endpoint
terraform output database_endpoint
terraform output ecr_repository_url
```

### ✅ **2. Налаштовано безпеку через VPC, IAM, Security Groups (20 балів)**

**Перевірка:**
- [ ] База даних в приватних підмережах
- [ ] Security Groups обмежують доступ
- [ ] IAM ролі з мінімальними правами
- [ ] Шифрування увімкнено

```bash
# Команди для перевірки:
aws ec2 describe-security-groups --group-ids $(terraform output -raw security_group_id)
aws rds describe-db-instances --db-instance-identifier $(terraform output -raw db_instance_id)
```

### ✅ **3. Розгорнуто застосунок в AWS з CI/CD (30 балів)**

**Перевірка:**
- [ ] Jenkins працює та може створювати pipelines
- [ ] Argo CD працює та може розгортати додатки
- [ ] Django додаток розгорнутий через Helm
- [ ] CI/CD pipeline працює end-to-end

```bash
# Команди для перевірки:
kubectl get pods -n jenkins
kubectl get pods -n argocd
kubectl get pods -n production
helm list -n production
```

### ✅ **4. Налаштовано моніторинг та автомасштабування (20 балів)**

**Перевірка:**
- [ ] Prometheus збирає метрики
- [ ] Grafana показує дашборди
- [ ] HPA налаштований для додатку
- [ ] Метрики з усіх компонентів доступні

```bash
# Команди для перевірки:
kubectl get hpa -n production
kubectl get servicemonitor -n monitoring
curl http://localhost:9090/api/v1/targets  # через port-forward
```

### ✅ **5. Коректне оформлення та зрозумілість документації (10 балів)**

**Перевірка:**
- [ ] README.md з повним описом
- [ ] Коментарі в коді
- [ ] terraform.tfvars.example з прикладами
- [ ] Ця покрокова інструкція

---

## ⚠️ **ВАЖЛИВО: Очищення ресурсів**

### 🗑️ **Видалення ресурсів після перевірки**

```bash
# 1. Видалення Helm releases
helm uninstall django-app -n production
helm uninstall prometheus -n monitoring

# 2. Видалення Kubernetes ресурсів
kubectl delete namespace production
kubectl delete namespace monitoring

# 3. Видалення Terraform ресурсів
terraform destroy -auto-approve

# 4. Перевірка, що всі ресурси видалені
aws ec2 describe-instances --filters "Name=tag:ManagedBy,Values=terraform"
aws rds describe-db-instances
aws eks list-clusters
```

### 🔄 **Відновлення після повного видалення**

Якщо ви видалили S3 backend:

```bash
# 1. Видаліть backend конфігурацію з main.tf
# 2. Повторно створіть backend:
terraform init
terraform apply -target=module.s3_backend
# 3. Додайте backend конфігурацію назад
# 4. Мігруйте state:
terraform init -migrate-state
```

---

## 📋 **Чек-лист для здачі проєкту**

### 📁 **Структура проєкту:**
- [ ] Всі модулі присутні та працюють
- [ ] Django додаток з Dockerfile та Jenkinsfile
- [ ] Helm чарти для Django
- [ ] Документація повна та зрозуміла

### 🔧 **Функціональність:**
- [ ] Terraform розгортає всю інфраструктуру
- [ ] Jenkins може створювати та запускати pipelines
- [ ] Argo CD може розгортати додатки
- [ ] Моніторинг працює та показує метрики
- [ ] Django додаток доступний та працює

### 📊 **Моніторинг:**
- [ ] Prometheus збирає метрики з усіх компонентів
- [ ] Grafana показує дашборди
- [ ] Алерти налаштовані
- [ ] HPA працює

### 🔒 **Безпека:**
- [ ] Паролі не в коді (використовуються змінні)
- [ ] Security Groups обмежують доступ
- [ ] Шифрування увімкнено
- [ ] IAM ролі з мінімальними правами

---

## 📤 **Формат здачі**

1. **GitHub репозиторій** з гілкою `final-project`
2. **ZIP архів** з назвою `final_DevOps_ПІБ.zip`
3. **README.md** з інструкціями
4. **Скріншоти** роботи всіх компонентів

**Успіхів у виконанні фінального проєкту! 🚀**