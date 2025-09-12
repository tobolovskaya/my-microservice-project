# lesson-5: Terraform Infrastructure on AWS

## Структура проекту

```
lesson-5/
│
├── main.tf     <- Головний файл для підключення модулів
├── backend.tf  <- Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf  <- Загальне виведення ресурсів
├── terraform.tfvars.example <- Приклад файлу з змінними
├── .gitignore  <- Файли для ігнорування Git
│
├── modules/    <- Каталог з усіма модулями
│ │
│ ├── s3-backend/    <- Модуль для S3 та DynamoDB
│ │ ├── s3.tf        <- Створення S3-бакета
│ │ ├── dynamodb.tf  <- Створення DynamoDB
│ │ ├── variables.tf <- Змінні для S3
│ │ └── outputs.tf   <- Виведення інформації про S3 та DynamoDB
│ │
│ ├── vpc/           <- Модуль для VPC
│ │ ├── vpc.tf       <- Створення VPC, підмереж, Internet Gateway, NAT Gateway
│ │ ├── routes.tf    <- Налаштування маршрутизації
│ │ ├── variables.tf <- Змінні для VPC
│ │ └── outputs.tf   <- Виведення інформації про VPC
│ │
│ └── ecr/          <- Модуль для ECR
│ ├── ecr.tf        <- Створення ECR репозиторію
│ ├── variables.tf  <- Змінні для ECR
│ └── outputs.tf    <- Виведення URL репозиторію ECR
│
└── README.md   <- Документація проєкту
```

## Початкове налаштування

1. **Створіть файл terraform.tfvars**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Відредагуйте terraform.tfvars** та вкажіть унікальне ім'я для S3 бакета:
   ```hcl
   backend_bucket_name = "your-unique-terraform-state-bucket-name-12345"
   region = "us-west-2"
   ```

3. **Налаштуйте AWS CLI** (якщо ще не налаштовано):
   ```bash
   aws configure
   ```

## Terraform-команди

### Крок 1: Створення S3 та DynamoDB для бекенду

Спочатку потрібно створити S3 бакет та DynamoDB таблицю:

```bash
# Ініціалізація без бекенду
terraform init

# Перевірка плану
terraform plan

# Створення ресурсів
terraform apply
```

### Крок 2: Налаштування бекенду

Після створення S3 та DynamoDB, розкоментуйте блок у `backend.tf` та оновіть ім'я бакета:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-unique-bucket-name"     # те ж саме, що backend_bucket_name
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Потім повторно ініціалізуйте Terraform:

```bash
# Повторна ініціалізація з бекендом
terraform init
```

### Крок 3: Основні команди

1. **Ініціалізація Terraform** (завантаження модулів, підключення до бекенду):
```
terraform init
```

2. **Перевірка та попередній перегляд змін** в інфраструктурі:

```
terraform plan
```

3. **Застосування змін, створення ресурсів**:

```
terraform apply
```

4. **Видалення всіх створених ресурсів**:

```
terraform destroy
```

### Додаткові корисні команди

```bash
# Перегляд поточного стану
terraform show

# Форматування коду
terraform fmt -recursive

# Валідація конфігурації
terraform validate

# Перегляд виходів
terraform output
```

## Огляд модулів

### Модуль `s3-backend/`

Цей модуль створює інфраструктуру для збереження **стану Terraform (tfstate)**:

- **`aws_s3_bucket`** - бакет з увімкненим версіюванням та шифруванням
- **`aws_s3_bucket_versioning`** - увімкнення версіювання для збереження історії стейтів
- **`aws_s3_bucket_server_side_encryption_configuration`** - шифрування AES256
- **`aws_s3_bucket_public_access_block`** - блокування публічного доступу
- **`aws_dynamodb_table`** - таблиця для **lock-файлів**, яка запобігає одночасному оновленню стану

Використовується в `backend.tf` для зберігання стану інфраструктури.

### Модуль `vpc/`

Цей модуль створює базову мережеву інфраструктуру:

- **`aws_vpc`** - основна мережа з зазначеним CIDR-блоком
- **`aws_subnet`** - 3 публічні та 3 приватні підмережі у різних зонах доступності
- **`aws_internet_gateway`** - дає доступ в інтернет публічним підмережам
- **`aws_nat_gateway`** - дозволяє вихід в інтернет для приватних підмереж (з опцією single NAT для економії)
- **`aws_eip`** - еластичні IP для NAT Gateway
- **`aws_route_table`**, **`aws_route`**, **`aws_route_table_association`** - для маршрутизації трафіку

#### Особливості VPC модуля:
- Підтримка single NAT Gateway для економії коштів
- Автоматичне призначення публічних IP для публічних підмереж
- DNS підтримка увімкнена за замовчуванням
- Гнучке налаштування через змінні
### Модуль `ecr/`

Модуль створює **ECR-репозиторій**, у якому можна зберігати Docker-образи:

- **`aws_ecr_repository`** - з увімкненим скануванням на безпеку (`scan_on_push = true`)
- **`aws_ecr_lifecycle_policy`** - автоматичне видалення старих образів (зберігає останні 30 тегованих образів)
- **`aws_ecr_repository_policy`** - дозволяє EC2 (або іншим сервісам) тягнути образи (pull policy)

#### Особливості ECR модуля:
- Шифрування AES256 за замовчуванням
- Автоматичне сканування образів на вразливості
- Lifecycle політика для оптимізації зберігання
- Політика доступу для EC2 інстансів

## Безпека та найкращі практики

### Файл .gitignore
Проєкт включає `.gitignore` файл, який запобігає випадковому коміту:
- Terraform стейт файлів (*.tfstate)
- Файлів зі змінними (*.tfvars)
- Локальних .terraform директорій
- Планів Terraform

### Рекомендації з безпеки:
1. **Ніколи не комітьте** `.tfvars` файли з чутливими даними
2. **Використовуйте** IAM ролі з мінімальними правами
3. **Увімкніть** шифрування для всіх ресурсів
4. **Регулярно оновлюйте** Terraform та провайдери
5. **Використовуйте** remote state з блокуванням

## Моніторинг витрат

Для контролю витрат AWS рекомендується:
- Використовувати `single_nat_gateway = true` для dev середовищ
- Налаштувати AWS Cost Alerts
- Регулярно переглядати lifecycle політики ECR
- Видаляти невикористовувані ресурси через `terraform destroy`

## Troubleshooting

### Поширені помилки:

1. **"Bucket name already exists"**
   - Змініть `backend_bucket_name` на унікальне значення

2. **"Access Denied"**
   - Перевірте AWS credentials: `aws sts get-caller-identity`
   - Переконайтеся, що у вас є необхідні IAM права

3. **"State lock"**
   - Зачекайте завершення попередньої операції
   - Або примусово розблокуйте: `terraform force-unlock LOCK_ID`

4. **"Backend initialization required"**
   - Запустіть `terraform init` після зміни backend конфігурації

## Розширення проєкту

Цю базову інфраструктуру можна розширити додатковими модулями:
- **ECS/EKS** для контейнерних додатків
- **RDS** для баз даних
- **ALB/NLB** для балансування навантаження
- **Route53** для DNS
- **CloudFront** для CDN
- **WAF** для веб-безпеки