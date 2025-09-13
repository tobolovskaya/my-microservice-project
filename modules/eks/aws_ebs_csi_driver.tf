# Встановлення AWS EBS CSI Driver для EKS

# IAM роль для EBS CSI Driver
resource "aws_iam_role" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  name = "${var.cluster_name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.cluster.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Прикріплення політики до ролі EBS CSI Driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver[0].name
}

# Додаткова політика для EBS CSI Driver (для кастомних KMS ключів)
resource "aws_iam_role_policy" "ebs_csi_driver_kms" {
  count = var.enable_ebs_csi_driver && var.ebs_csi_kms_key_id != "" ? 1 : 0

  name = "${var.cluster_name}-ebs-csi-driver-kms-policy"
  role = aws_iam_role.ebs_csi_driver[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = [var.ebs_csi_kms_key_id]
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = [var.ebs_csi_kms_key_id]
      }
    ]
  })
}

# EKS Add-on для EBS CSI Driver
resource "aws_eks_addon" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.ebs_csi_driver_version
  service_account_role_arn = aws_iam_role.ebs_csi_driver[0].arn
  resolve_conflicts        = "OVERWRITE"

  tags = var.tags

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_driver
  ]
}

# Storage Class для gp3 (рекомендований)
resource "kubernetes_storage_class" "gp3" {
  count = var.enable_ebs_csi_driver && var.create_storage_classes ? 1 : 0

  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = var.set_gp3_as_default_storage_class ? "true" : "false"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [aws_eks_addon.ebs_csi_driver]
}

# Storage Class для gp2 (для сумісності)
resource "kubernetes_storage_class" "gp2" {
  count = var.enable_ebs_csi_driver && var.create_storage_classes ? 1 : 0

  metadata {
    name = "gp2"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = var.set_gp3_as_default_storage_class ? "false" : "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp2"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [aws_eks_addon.ebs_csi_driver]
}

# Storage Class для io1 (високопродуктивний)
resource "kubernetes_storage_class" "io1" {
  count = var.enable_ebs_csi_driver && var.create_storage_classes ? 1 : 0

  metadata {
    name = "io1"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "io1"
    iops      = "1000"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [aws_eks_addon.ebs_csi_driver]
}

# Storage Class з кастомним KMS ключем
resource "kubernetes_storage_class" "encrypted_gp3" {
  count = var.enable_ebs_csi_driver && var.create_storage_classes && var.ebs_csi_kms_key_id != "" ? 1 : 0

  metadata {
    name = "encrypted-gp3"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
    kmsKeyId  = var.ebs_csi_kms_key_id
    fsType    = "ext4"
  }

  depends_on = [aws_eks_addon.ebs_csi_driver]
}

# Видалення старого storage class (якщо потрібно)
resource "kubernetes_annotations" "default_storageclass" {
  count = var.enable_ebs_csi_driver && var.remove_default_gp2_storage_class ? 1 : 0

  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  
  metadata {
    name = "gp2"
  }
  
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }

  depends_on = [aws_eks_addon.ebs_csi_driver]
}