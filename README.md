# Мій власний мікросервісний проєкт
Це репозиторій для навчального проєкту в межах курсу "DevOps CI/CD".

## Terraform RDS Module

Цей проєкт містить універсальний Terraform-модуль для створення баз даних AWS, який підтримує як звичайні RDS інстанси, так і Aurora кластери.

### Структура проєкту

```
Project/
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
│   ├── argo_cd/             # Модуль для Argo CD
│   └── rds/                 # 🆕 Універсальний модуль для RDS/Aurora
│       ├── rds.tf           # Створення RDS інстансу
│       ├── aurora.tf        # Створення Aurora кластера
│       ├── shared.tf        # Спільні ресурси
│       ├── variables.tf     # Змінні модуля
│       └── outputs.tf       # Виводи модуля
│
└── charts/
    └── django-app/          # Helm chart для Django застосунку
```

### Функціонал RDS модуля

Модуль `rds` є універсальним рішенням для створення баз даних в AWS:

#### Основні можливості:
- **Гнучкий вибір типу БД**: `use_aurora = true/false`
- **Підтримка різних движків**: PostgreSQL, MySQL, MariaDB
- **Автоматичне створення мережевих ресурсів**: Subnet Group, Security Group
- **Налаштування параметрів**: Parameter Groups з оптимізованими налаштуваннями
- **Безпека**: Шифрування, мережева ізоляція, контроль доступу

#### Типи розгортання:

1. **Aurora Cluster** (`use_aurora = true`):
   - Створює Aurora кластер з writer та reader інстансами
   - Автоматичне масштабування
   - Висока доступність
   - Оптимізовано для продакшену

2. **RDS Instance** (`use_aurora = false`):
   - Створює звичайний RDS інстанс
   - Підтримка Multi-AZ
   - Економічно ефективно для розробки

### Приклади використання

#### 1. Aurora PostgreSQL кластер для продакшену

```hcl
module "aurora_postgres" {
  source = "./modules/rds"
  
  # Основні налаштування
  use_aurora   = true
  engine       = "aurora-postgresql"
  engine_version = "15.4"
  
  # База даних
  db_name  = "production_db"
  username = "admin"
  password = "super_secure_password_123!"
  
  # Мережа
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Безпека
  allowed_cidr_blocks = ["10.0.0.0/16"]
  
  # Aurora налаштування
  aurora_cluster_instances = 3
  aurora_instance_class   = "db.r5.xlarge"
  
  # Продакшн налаштування
  multi_az               = true
  backup_retention_period = 30
  deletion_protection    = true
  storage_encrypted      = true
  
  # Теги
  project_name = "my-app"
  environment  = "production"
  
  tags = {
    Project     = "MyApp"
    Environment = "Production"
    Component   = "Database"
  }
}
```

#### 2. RDS MySQL для розробки

```hcl
module "dev_mysql" {
  source = "./modules/rds"
  
  # Основні налаштування
  use_aurora   = false
  engine       = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.micro"
  
  # База даних
  db_name  = "dev_db"
  username = "developer"
  password = "dev_password_123"
  
  # Мережа
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Безпека
  allowed_cidr_blocks = ["10.0.0.0/16"]
  
  # Розробницькі налаштування
  multi_az               = false
  backup_retention_period = 1
  deletion_protection    = false
  storage_encrypted      = false
  
  # Теги
  project_name = "my-app"
  environment  = "development"
}
```

#### 3. Використання в основному проєкті

```hcl
# main.tf
module "rds" {
  source = "./modules/rds"
  
  # Основні налаштування
  use_aurora   = var.use_aurora
  engine       = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class
  
  # База даних
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  
  # Мережа
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Безпека
  allowed_cidr_blocks = ["10.0.0.0/16"]  # VPC CIDR
  
  # Aurora налаштування
  aurora_cluster_instances = var.aurora_cluster_instances
  aurora_instance_class   = var.aurora_instance_class
  
  # Загальні налаштування
  multi_az               = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  deletion_protection    = var.db_deletion_protection
  storage_encrypted      = true
  
  # Теги
  project_name = "lesson-8-9"
  environment  = "dev"
  
  depends_on = [module.vpc]
}
```

### Змінні модуля

#### Основні змінні

| Змінна | Тип | Опис | За замовчуванням |
|--------|-----|------|------------------|
| `use_aurora` | `bool` | Використовувати Aurora кластер замість RDS | `false` |
| `engine` | `string` | Движок БД (mysql, postgres, aurora-mysql, aurora-postgresql) | `"postgres"` |
| `engine_version` | `string` | Версія движка БД | `""` (автоматично) |
| `instance_class` | `string` | Клас RDS інстансу | `"db.t3.micro"` |
| `db_name` | `string` | Назва бази даних | `"mydb"` |
| `username` | `string` | Ім'я користувача адміністратора | `"admin"` |
| `password` | `string` | Пароль адміністратора | - |

#### Мережеві змінні

| Змінна | Тип | Опис |
|--------|-----|------|
| `vpc_id` | `string` | ID VPC для створення БД |
| `subnet_ids` | `list(string)` | Список ID підмереж для DB Subnet Group |
| `allowed_cidr_blocks` | `list(string)` | CIDR блоки з доступом до БД |
| `allowed_security_groups` | `list(string)` | Security Groups з доступом до БД |

#### Aurora специфічні змінні

| Змінна | Тип | Опис | За замовчуванням |
|--------|-----|------|------------------|
| `aurora_cluster_instances` | `number` | Кількість інстансів в Aurora кластері | `2` |
| `aurora_instance_class` | `string` | Клас Aurora інстансів | `"db.r5.large"` |
| `aurora_backup_retention_period` | `number` | Період зберігання бекапів (дні) | `7` |

#### Налаштування безпеки та надійності

| Змінна | Тип | Опис | За замовчуванням |
|--------|-----|------|------------------|
| `multi_az` | `bool` | Увімкнути Multi-AZ розгортання | `false` |
| `storage_encrypted` | `bool` | Шифрувати сховище | `true` |
| `deletion_protection` | `bool` | Захист від видалення | `false` |
| `backup_retention_period` | `number` | Період зберігання бекапів | `7` |
| `publicly_accessible` | `bool` | Публічний доступ до БД | `false` |

### Виводи модуля

#### Загальні виводи
- `connection_info` - Інформація для підключення до БД
- `security_group_id` - ID Security Group БД
- `db_subnet_group_name` - Назва DB Subnet Group
- `port` - Порт БД
- `engine` - Движок БД

#### RDS специфічні виводи
- `rds_instance_endpoint` - Endpoint RDS інстансу
- `rds_instance_id` - ID RDS інстансу
- `rds_instance_arn` - ARN RDS інстансу

#### Aurora специфічні виводи
- `aurora_cluster_endpoint` - Writer endpoint Aurora кластера
- `aurora_cluster_reader_endpoint` - Reader endpoint Aurora кластера
- `aurora_cluster_id` - ID Aurora кластера
- `aurora_instance_endpoints` - Список endpoints всіх інстансів

### Як змінити налаштування

#### 1. Зміна типу БД (RDS ↔ Aurora)

```hcl
# Для Aurora кластера
use_aurora = true
aurora_cluster_instances = 2
aurora_instance_class = "db.r5.large"

# Для звичайного RDS
use_aurora = false
instance_class = "db.t3.medium"
multi_az = true
```

#### 2. Зміна движка БД

```hcl
# PostgreSQL
engine = "postgres"           # або "aurora-postgresql" для Aurora
engine_version = "15.4"

# MySQL
engine = "mysql"              # або "aurora-mysql" для Aurora
engine_version = "8.0.35"

# MariaDB (тільки для RDS)
engine = "mariadb"
engine_version = "10.6.14"
```

#### 3. Налаштування продуктивності

```hcl
# Для розробки
instance_class = "db.t3.micro"
multi_az = false
backup_retention_period = 1

# Для продакшену
instance_class = "db.r5.xlarge"
multi_az = true
backup_retention_period = 30
deletion_protection = true
```

#### 4. Кастомні параметри БД

```hcl
custom_parameters = {
  max_connections = {
    value        = "500"
    apply_method = "pending-reboot"
  }
  shared_preload_libraries = {
    value        = "pg_stat_statements,pg_hint_plan"
    apply_method = "pending-reboot"
  }
  work_mem = {
    value        = "8192"
    apply_method = "immediate"
  }
}
```

### Розгортання

1. **Ініціалізація Terraform:**
```bash
terraform init
```

2. **Планування змін:**
```bash
terraform plan
```

3. **Застосування змін:**
```bash
terraform apply
```

4. **Отримання інформації про БД:**
```bash
terraform output database_connection_info
```

### Моніторинг та обслуговування

#### Корисні команди AWS CLI

```bash
# Перегляд статусу RDS інстансу
aws rds describe-db-instances --db-instance-identifier my-rds-instance

# Перегляд статусу Aurora кластера
aws rds describe-db-clusters --db-cluster-identifier my-aurora-cluster

# Створення snapshot
aws rds create-db-snapshot --db-instance-identifier my-rds --db-snapshot-identifier my-snapshot

# Перегляд метрик
aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name CPUUtilization
```

### Безпека

#### Рекомендації:
1. **Мережева безпека**: Розміщуйте БД в приватних підмережах
2. **Шифрування**: Завжди вмикайте `storage_encrypted = true`
3. **Паролі**: Використовуйте складні паролі та зберігайте їх в AWS Secrets Manager
4. **Доступ**: Обмежуйте доступ через Security Groups
5. **Бекапи**: Налаштуйте регулярні бекапи з достатнім періодом зберігання

### Troubleshooting

#### Поширені проблеми:

1. **Помилка підключення**: Перевірте Security Groups та CIDR блоки
2. **Повільна продуктивність**: Збільште клас інстансу або налаштуйте параметри
3. **Проблеми з бекапами**: Перевірте налаштування backup window
4. **Помилки Aurora**: Переконайтеся, що використовуєте правильні класи інстансів

### Вартість оптимізації

#### Поради для зменшення витрат:
1. Використовуйте Reserved Instances для продакшену
2. Для розробки використовуйте `db.t3.micro` або `db.t4g.micro`
3. Налаштуйте автоматичне зупинення для dev середовищ
4. Використовуйте Aurora Serverless для нерегулярних навантажень

Цей модуль забезпечує гнучке та надійне рішення для управління базами даних в AWS з підтримкою як простих RDS інстансів, так і високодоступних Aurora кластерів.