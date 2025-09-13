# Гнучкий Terraform-модуль для баз даних

Універсальний Terraform-модуль для створення баз даних AWS RDS або Aurora кластерів з повною автоматизацією інфраструктури.

## 🎯 Особливості

- **Універсальність**: Підтримка як звичайних RDS інстансів, так і Aurora кластерів
- **Гнучкість движків**: PostgreSQL, MySQL, MariaDB з автоматичним налаштуванням
- **Безпека**: Автоматичне шифрування, Security Groups, мережева ізоляція
- **Продакшн готовність**: Multi-AZ, бекапи, моніторинг, Performance Insights
- **Простота використання**: Мінімальна конфігурація з розумними значеннями за замовчуванням

## 📁 Структура проєкту

```
Project/
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів
├── outputs.tf               # Загальні виводи ресурсів
├── terraform.tfvars.example # Приклад конфігурації
├── README.md               # Документація
└── modules/
    ├── vpc/                # Модуль для VPC
    │   ├── vpc.tf
    │   ├── routes.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── rds/                # Модуль для RDS/Aurora
        ├── rds.tf          # Звичайна RDS
        ├── aurora.tf       # Aurora кластер
        ├── shared.tf       # Спільні ресурси
        ├── variables.tf    # Змінні
        └── outputs.tf      # Виводи
```

## 🚀 Швидкий старт

### 1. Клонування та налаштування

```bash
git clone <repository-url>
cd terraform-rds-module
cp terraform.tfvars.example terraform.tfvars
```

### 2. Налаштування змінних

Відредагуйте `terraform.tfvars`:

```hcl
# Основні налаштування
aws_region = "us-west-2"
use_aurora = false  # true для Aurora
db_engine = "postgres"
db_password = "your-secure-password"

# Теги
common_tags = {
  Environment = "dev"
  Project     = "my-project"
  Owner       = "your-name"
}
```

### 3. Розгортання

```bash
terraform init
terraform plan
terraform apply
```

## 📖 Приклади використання

### Звичайна PostgreSQL RDS

```hcl
module "rds" {
  source = "./modules/rds"
  
  # Основні параметри
  use_aurora     = false
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
  
  # Мережа
  vpc_id               = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16"]
  
  # База даних
  database_name = "myapp"
  username     = "dbadmin"
  password     = var.db_password
  
  # Налаштування
  multi_az                = false
  backup_retention_period = 7
  storage_encrypted      = true
  
  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### Aurora PostgreSQL кластер

```hcl
module "aurora" {
  source = "./modules/rds"
  
  # Aurora налаштування
  use_aurora            = true
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.r6g.large"
  aurora_cluster_instances = 2
  
  # Мережа
  vpc_id               = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16"]
  
  # База даних
  database_name = "production_db"
  username     = "admin"
  password     = var.db_password
  
  # Продакшн налаштування
  backup_retention_period = 30
  deletion_protection    = true
  performance_insights_enabled = true
  
  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### Aurora Serverless v2

```hcl
module "aurora_serverless" {
  source = "./modules/rds"
  
  # Serverless налаштування
  use_aurora           = true
  aurora_serverless_v2 = true
  aurora_serverless_v2_scaling = {
    min_capacity = 0.5
    max_capacity = 4
  }
  
  engine         = "postgres"
  instance_class = "db.serverless"
  
  # Решта налаштувань...
}
```

### MySQL з кастомними параметрами

```hcl
module "mysql_rds" {
  source = "./modules/rds"
  
  use_aurora = false
  engine     = "mysql"
  
  # Кастомні параметри БД
  custom_db_parameters = {
    "innodb_buffer_pool_size" = {
      value        = "{DBInstanceClassMemory*3/4}"
      apply_method = "pending-reboot"
    }
    "max_connections" = {
      value        = "200"
      apply_method = "immediate"
    }
  }
  
  # Решта налаштувань...
}
```

## 🔧 Змінні модуля

### Основні параметри

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `use_aurora` | `bool` | `false` | Використовувати Aurora замість RDS |
| `engine` | `string` | `"postgres"` | Движок БД (postgres, mysql, mariadb) |
| `engine_version` | `string` | `""` | Версія движка (автоматично, якщо пусто) |
| `instance_class` | `string` | `"db.t3.micro"` | Клас інстансу |

### Мережеві параметри

| Змінна | Тип | Опис |
|--------|-----|------|
| `vpc_id` | `string` | ID VPC |
| `subnet_ids` | `list(string)` | ID підмереж для DB subnet group |
| `allowed_cidr_blocks` | `list(string)` | CIDR блоки з доступом до БД |
| `allowed_security_groups` | `list(string)` | Security groups з доступом до БД |

### Параметри бази даних

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `database_name` | `string` | `"myapp"` | Назва БД |
| `username` | `string` | `"dbadmin"` | Головний користувач |
| `password` | `string` | - | Пароль (обов'язково) |
| `port` | `number` | `null` | Порт (автоматично за движком) |

### Налаштування продуктивності

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `allocated_storage` | `number` | `20` | Розмір сховища (ГБ, тільки RDS) |
| `max_allocated_storage` | `number` | `100` | Макс. розмір для автоскейлінгу |
| `storage_type` | `string` | `"gp3"` | Тип сховища |
| `multi_az` | `bool` | `false` | Multi-AZ розгортання |

### Aurora специфічні

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `aurora_cluster_instances` | `number` | `2` | Кількість інстансів в кластері |
| `aurora_serverless_v2` | `bool` | `false` | Використовувати Serverless v2 |
| `aurora_serverless_v2_scaling` | `object` | `{min=0.5, max=1}` | Налаштування масштабування |

### Бекапи та обслуговування

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `backup_retention_period` | `number` | `7` | Період зберігання бекапів (дні) |
| `backup_window` | `string` | `"03:00-04:00"` | Вікно бекапів (UTC) |
| `maintenance_window` | `string` | `"sun:04:00-sun:05:00"` | Вікно обслуговування |
| `deletion_protection` | `bool` | `true` | Захист від видалення |

### Моніторинг

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `monitoring_interval` | `number` | `60` | Інтервал моніторингу (сек) |
| `performance_insights_enabled` | `bool` | `true` | Performance Insights |
| `enabled_cloudwatch_logs_exports` | `list(string)` | `[]` | Типи логів для CloudWatch |

## 📤 Виводи модуля

### Підключення

| Вивід | Опис |
|-------|------|
| `endpoint` | Основний endpoint для підключення |
| `reader_endpoint` | Reader endpoint (тільки Aurora) |
| `port` | Порт бази даних |
| `connection_string` | Повний рядок підключення |

### Ідентифікатори

| Вивід | Опис |
|-------|------|
| `db_instance_id` | ID RDS інстансу |
| `cluster_id` | ID Aurora кластера |
| `security_group_id` | ID Security Group |
| `subnet_group_name` | Назва DB Subnet Group |

## 🔄 Зміна типу БД

### З RDS на Aurora

1. Створіть snapshot поточної БД:
```bash
aws rds create-db-snapshot --db-instance-identifier mydb --db-snapshot-identifier mydb-migration-snapshot
```

2. Змініть конфігурацію:
```hcl
use_aurora = true
# Додайте Aurora-специфічні налаштування
```

3. Застосуйте зміни:
```bash
terraform apply
```

### Зміна движка

⚠️ **Увага**: Зміна движка вимагає міграції даних!

1. Створіть бекап даних
2. Змініть `engine` в конфігурації
3. Застосуйте зміни (створить нову БД)
4. Мігруйте дані з бекапу

### Зміна класу інстансу

```hcl
instance_class = "db.t3.small"  # Збільшення розміру
```

Застосуйте зміни:
```bash
terraform apply
```

## 🛡️ Безпека

### Рекомендації

1. **Паролі**: Використовуйте AWS Secrets Manager або змінні середовища
2. **Мережа**: Розміщуйте БД в приватних підмережах
3. **Шифрування**: Завжди увімкнене за замовчуванням
4. **Доступ**: Обмежуйте через Security Groups

### Приклад з Secrets Manager

```hcl
# Створення секрету
resource "aws_secretsmanager_secret" "db_password" {
  name = "rds-password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

# Використання в модулі
module "rds" {
  # ...
  password = aws_secretsmanager_secret_version.db_password.secret_string
}
```

## 💰 Оптимізація вартості

### Для розробки
```hcl
instance_class = "db.t3.micro"
multi_az = false
backup_retention_period = 1
deletion_protection = false
```

### Для продакшну
```hcl
instance_class = "db.r6g.large"
multi_az = true
backup_retention_period = 30
deletion_protection = true
performance_insights_enabled = true
```

### Aurora Serverless для змінних навантажень
```hcl
use_aurora = true
aurora_serverless_v2 = true
aurora_serverless_v2_scaling = {
  min_capacity = 0.5  # Мінімальна вартість
  max_capacity = 4    # Обмеження максимуму
}
```

## 🔍 Моніторинг та логування

### CloudWatch Logs
```hcl
enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
```

### Enhanced Monitoring
```hcl
monitoring_interval = 60  # Детальний моніторинг кожну хвилину
```

### Performance Insights
```hcl
performance_insights_enabled = true
```

## 🚨 Усунення проблем

### Поширені помилки

1. **Недостатньо підмереж**: Потрібно мінімум 2 підмережі в різних AZ
2. **Неправильний CIDR**: Перевірте, що CIDR блоки не перетинаються
3. **Версія движка**: Використовуйте підтримувані версії AWS

### Корисні команди

```bash
# Перевірка стану
terraform state list
terraform state show module.rds.aws_db_instance.main

# Імпорт існуючих ресурсів
terraform import module.rds.aws_db_instance.main mydb-instance

# Планування змін
terraform plan -target=module.rds
```

## 📚 Додаткові ресурси

- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS Aurora Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🤝 Внесок

1. Fork проєкту
2. Створіть feature branch (`git checkout -b feature/amazing-feature`)
3. Commit змін (`git commit -m 'Add amazing feature'`)
4. Push в branch (`git push origin feature/amazing-feature`)
5. Створіть Pull Request

## 📄 Ліцензія

Цей проєкт ліцензовано під MIT License - дивіться файл [LICENSE](LICENSE) для деталей.

---

**Автор**: DevOps Engineer  
**Проєкт**: Terraform RDS Module  
**Версія**: 1.0.0
