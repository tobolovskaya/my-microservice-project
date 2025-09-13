# Створення DynamoDB таблиці для блокування стану Terraform

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = var.dynamodb_table_name
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "LockID"

  # Налаштування для on-demand billing
  dynamic "attribute" {
    for_each = var.dynamodb_billing_mode == "PAY_PER_REQUEST" ? [1] : []
    content {
      name = "LockID"
      type = "S"
    }
  }

  # Налаштування для provisioned billing
  dynamic "attribute" {
    for_each = var.dynamodb_billing_mode == "PROVISIONED" ? [1] : []
    content {
      name = "LockID"
      type = "S"
    }
  }

  # Provisioned throughput (тільки для PROVISIONED режиму)
  read_capacity  = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_read_capacity : null
  write_capacity = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_write_capacity : null

  # Шифрування
  server_side_encryption {
    enabled = true
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  # Теги
  tags = merge(var.tags, {
    Name        = var.dynamodb_table_name
    Purpose     = "Terraform State Locking"
    Environment = var.environment
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Auto Scaling для DynamoDB (тільки для PROVISIONED режиму)
resource "aws_appautoscaling_target" "dynamodb_table_read_target" {
  count              = var.dynamodb_billing_mode == "PROVISIONED" && var.enable_dynamodb_autoscaling ? 1 : 0
  max_capacity       = var.dynamodb_autoscaling_read_max_capacity
  min_capacity       = var.dynamodb_read_capacity
  resource_id        = "table/${aws_dynamodb_table.terraform_state_lock.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_target" "dynamodb_table_write_target" {
  count              = var.dynamodb_billing_mode == "PROVISIONED" && var.enable_dynamodb_autoscaling ? 1 : 0
  max_capacity       = var.dynamodb_autoscaling_write_max_capacity
  min_capacity       = var.dynamodb_write_capacity
  resource_id        = "table/${aws_dynamodb_table.terraform_state_lock.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_read_policy" {
  count              = var.dynamodb_billing_mode == "PROVISIONED" && var.enable_dynamodb_autoscaling ? 1 : 0
  name               = "${var.dynamodb_table_name}-read-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_read_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_read_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_read_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = var.dynamodb_autoscaling_target_value
  }
}

resource "aws_appautoscaling_policy" "dynamodb_table_write_policy" {
  count              = var.dynamodb_billing_mode == "PROVISIONED" && var.enable_dynamodb_autoscaling ? 1 : 0
  name               = "${var.dynamodb_table_name}-write-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_write_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_write_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_write_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = var.dynamodb_autoscaling_target_value
  }
}

# CloudWatch алерти для моніторингу
resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttle" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.dynamodb_table_name}-read-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottledEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB read throttle events"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    TableName = aws_dynamodb_table.terraform_state_lock.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttle" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.dynamodb_table_name}-write-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteThrottledEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB write throttle events"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    TableName = aws_dynamodb_table.terraform_state_lock.name
  }

  tags = var.tags
}