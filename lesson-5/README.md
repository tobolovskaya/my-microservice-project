# Terraform Infrastructure для AWS (Lesson 5)

Цей проєкт містить Terraform-конфігурацію для розгортання базової інфраструктури AWS, включаючи:

- **S3 Backend**: Централізоване зберігання стейт-файлів Terraform
- **VPC**: Мережева інфраструктура з публічними та приватними підмережами
- **ECR**: Elastic Container Registry для зберігання Docker-образів

## Структура проєкту

```
lesson-5/
│
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf               # Загальне виведення ресурсів
│
├── modules/                 # Каталог з усіма модулями
│   │
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   │   ├── s3.tf            # Створення S3-бакета
│   │   ├── dynamodb.tf      # Створення DynamoDB
│   │   ├── variables.tf     # Змінні для S3
│   │   └── outputs.tf       # Виведення інформації про S3 та DynamoDB
│   │
│   ├── vpc/                 # Модуль для VPC
│   │   ├── vpc.tf           # Створення VPC, підмереж, Internet Gateway
│   │   ├── routes.tf        # Налаштування маршрутизації
│   │   ├── variables.tf     # Змінні для VPC
│   │   └── outputs.tf       # Виведення інформації про VPC
│   │
│   └── ecr/                 # Модуль для ECR
│       ├── ecr.tf           # Створення ECR репозиторію
│       ├── variables.tf     # Змінні для ECR
│       └── outputs.tf       # Виведення URL репозиторію ECR
│
└── README.md                # Документація проєкту
```

## Модулі

### 1. S3 Backend (`modules/s3-backend`)

Цей модуль створює:
- **S3 Bucket**: Для зберігання стейт-файлів Terraform з увімкненим версіюванням та шифруванням
- **DynamoDB Table**: Для блокування стейтів під час виконання операцій

**Особливості:**
- Версіювання S3 для збереження історії стейтів
- Шифрування AES256
- Блокування публічного доступу
- DynamoDB з оплатою за запит (PAY_PER_REQUEST)

### 2. VPC (`modules/vpc`)

Цей модуль створює повну мережеву інфраструктуру:
- **VPC**: Віртуальна приватна хмара з CIDR блоком 10.0.0.0/16
- **Public Subnets**: 3 публічні підмережі в різних зонах доступності
- **Private Subnets**: 3 приватні підмережі в різних зонах доступності
- **Internet Gateway**: Для доступу публічних підмереж до інтернету
- **NAT Gateways**: По одному для кожної приватної підмережі
- **Route Tables**: Налаштування маршрутизації для публічних та приватних підмереж

**Мережева архітектура:**
- Public Subnets: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
- Private Subnets: 10.0.4.0/24, 10.0.5.0/24, 10.0.6.0/24
- Availability Zones: us-west-2a, us-west-2b, us-west-2c

### 3. ECR (`modules/ecr`)

Цей модуль створює:
- **ECR Repository**: Для зберігання Docker-образів
- **Lifecycle Policy**: Автоматичне видалення старих образів
- **Repository Policy**: Налаштування доступу до репозиторію

**Особливості:**
- Автоматичне сканування образів на вразливості
- Шифрування AES256
- Політика життєвого циклу (зберігання останніх 30 тегованих образів)
- Видалення нетегованих образів старше 1 дня

## Команди для роботи з проєктом

### Ініціалізація проєкту

```bash
cd lesson-5
terraform init
```

### Планування змін

```bash
terraform plan
```

### Застосування змін

```bash
terraform apply
```

### Знищення інфраструктури

```bash
terraform destroy
```

### Форматування коду

```bash
terraform fmt -recursive
```

### Валідація конфігурації

```bash
terraform validate
```

## Налаштування AWS

Перед використанням переконайтеся, що у вас налаштовані AWS credentials:

```bash
aws configure
```

Або встановіть змінні середовища:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

## Налаштування Backend

**Важливо**: Перед першим запуском `terraform init` з backend конфігурацією, вам потрібно:

1. Закоментувати блок `backend "s3"` в `backend.tf`
2. Запустити `terraform init` та `terraform apply` для створення S3 bucket та DynamoDB table
3. Розкоментувати блок `backend "s3"`
4. Запустити `terraform init` знову для міграції стейту в S3

## Виходи (Outputs)

Після успішного застосування конфігурації ви отримаєте:

### S3 Backend
- `s3_bucket_name`: Ім'я S3 bucket для стейтів
- `s3_bucket_arn`: ARN S3 bucket
- `dynamodb_table_name`: Ім'я DynamoDB таблиці

### VPC
- `vpc_id`: ID створеної VPC
- `public_subnet_ids`: ID публічних підмереж
- `private_subnet_ids`: ID приватних підмереж
- `internet_gateway_id`: ID Internet Gateway
- `nat_gateway_ids`: ID NAT Gateways

### ECR
- `ecr_repository_url`: URL ECR репозиторію
- `ecr_repository_arn`: ARN ECR репозиторію

## Безпека

Проєкт включає наступні заходи безпеки:

- Шифрування S3 bucket та ECR repository
- Блокування публічного доступу до S3 bucket
- Приватні підмережі з NAT Gateway для вихідного трафіку
- Lifecycle policies для ECR для оптимізації витрат
- Теги для всіх ресурсів для кращого управління

## Вартість

Основні компоненти, що впливають на вартість:

- **NAT Gateways**: ~$45/місяць за кожен (3 шт.)
- **Elastic IPs**: ~$3.6/місяць за кожен невикористаний
- **DynamoDB**: Оплата за запит
- **S3**: Оплата за зберігання та запити
- **ECR**: Оплата за зберігання образів

## Подальші кроки

Цю інфраструктуру можна розширити додаванням:

- ECS/EKS кластерів
- RDS баз даних
- Load Balancers
- Auto Scaling Groups
- CloudWatch моніторингу
- Security Groups та NACLs

## Підтримка

Для питань та пропозицій створюйте issues в репозиторії проєкту.