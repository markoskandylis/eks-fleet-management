################################################################################
# External Secrets EKS Access
################################################################################
module "external_secrets_pod_identity" {
  count   = local.aws_resources.enable_external_secrets ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12.0"

  name = "external-secrets"

  external_secrets_create_permission  = false
  attach_external_secrets_policy      = true
  external_secrets_kms_key_arns       = ["arn:aws:kms:*:*:key/*"]
  external_secrets_ssm_parameter_arns = ["arn:aws:ssm:${local.region}:*:parameter/${local.cluster_info.cluster_name}/*"]
  external_secrets_secrets_manager_arns = [
    "arn:aws:secretsmanager:${local.region}:*:secret:hub/${local.cluster_info.cluster_name}*",
    "arn:aws:secretsmanager:${local.region}:*:secret:${local.cluster_info.cluster_name}/*",
    "arn:aws:secretsmanager:${local.region}:*:secret:github*"
  ]

  additional_policy_arns = {
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = local.cluster_info.cluster_name
      namespace       = local.external_secrets.namespace
      service_account = local.external_secrets.service_account
    }
  }

  tags = local.tags
}

################################################################################
# Adding the secret arn in parameter store so we can share it with the hub account
################################################################################
resource "aws_ssm_parameter" "external_secret_role" {
  name  = "/${local.cluster_name}/external-secret-role"
  type  = "String"
  value = module.external_secrets_pod_identity[0].iam_role_arn
}
################################################################################
# CloudWatch Observability EKS Access
################################################################################
module "aws_cloudwatch_observability_pod_identity" {
  count   = local.aws_resources.enable_aws_cloudwatch_observability ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12.0"

  name = "aws-cloudwatch-observability"

  attach_aws_cloudwatch_observability_policy = true

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = local.cluster_info.cluster_name
      namespace       = "amazon-cloudwatch"
      service_account = "cloudwatch-agent"
    }
  }

  tags = local.tags
}

################################################################################
# EBS CSI EKS Access
################################################################################
module "aws_ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12.0"

  name = "aws-ebs-csi"

  attach_aws_ebs_csi_policy = true
  aws_ebs_csi_kms_arns      = ["arn:aws:kms:*:*:key/*"]

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = local.cluster_info.cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = local.tags
}

################################################################################
# AWS ALB Ingress Controller EKS Access
################################################################################
module "aws_lb_controller_pod_identity" {
  count   = local.aws_resources.enable_aws_load_balancer_controller || local.enable_automode ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12.0"

  name = "aws-lbc"

  attach_aws_lb_controller_policy = true


  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = local.cluster_info.cluster_name
      namespace       = local.aws_load_balancer_controller.namespace
      service_account = local.aws_load_balancer_controller.service_account
    }
  }

  tags = local.tags
}

################################################################################
# Karpenter EKS Access
################################################################################

module "argocd_hub_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12.0"

  name = "argocd"

  attach_custom_policy = true
  policy_statements = [
    {
      sid       = "ArgoCD"
      actions   = ["sts:AssumeRole", "sts:TagSession"]
      resources = ["arn:aws:iam::*:role/*-argocd-spoke"]
    }
  ]

  # Pod Identity Associations
  association_defaults = {
    namespace = "argocd"
  }
  associations = {
    controller = {
      cluster_name    = local.cluster_info.cluster_name
      service_account = "argocd-application-controller"
    }
    server = {
      cluster_name    = local.cluster_info.cluster_name
      service_account = "argocd-server"
    }
  }

  tags = local.tags
}

################################################################################
# Karpenter EKS Access
################################################################################

module "karpenter" {
  count   = local.aws_resources.enable_karpenter ? 1 : 0
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.23.0"

  cluster_name = local.cluster_info.cluster_name

  enable_pod_identity             = true
  create_pod_identity_association = true

  iam_role_name                 = "${local.cluster_info.cluster_name}-karpenter"
  node_iam_role_use_name_prefix = false
  namespace                     = local.karpenter.namespace
  service_account               = local.karpenter.service_account

  # Used to attach additional IAM policies to the Karpenter node IAM role
  # Adding IAM policy needed for fluentbit
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  tags = local.tags
}

################################################################################
# VPC CNI Helper
################################################################################
resource "aws_iam_policy" "cni_metrics_helper_pod_identity_policy" {
  count       = local.aws_resources.enable_cni_metrics_helper ? 1 : 0
  name_prefix = "cni_metrics_helper_pod_identity"
  path        = "/"
  description = "Policy to allow cni metrics helper put metcics to cloudwatch"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

module "cni_metrics_helper_pod_identity" {
  count   = local.aws_resources.enable_cni_metrics_helper ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12.0"
  name    = "cni-metrics-helper"

  additional_policy_arns = {
    "cni-metrics-help" : aws_iam_policy.cni_metrics_helper_pod_identity_policy[0].arn
  }

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = local.cluster_info.cluster_name
      namespace       = "kube-system"
      service_account = "cni-metrics-helper"
    }
  }
  tags = local.tags
}

# That will be used later properly for ACK only 
module "ack_iam_eks_identity" {
  count   = local.enable_ack_pod_identity ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12.0"

  name            = "${local.cluster_name}-ack-pod-identity"
  use_name_prefix = false

  attach_custom_policy     = true
  policy_statements        = data.aws_iam_policy_document.iam_management_policy[0].statement
  permissions_boundary_arn = aws_iam_policy.permissions_boundary_eks_ack[0].arn
  # Pod Identity Associations
  association_defaults = {
    namespace = "ack-system"
  }
  associations = {
    iam_controller = {
      cluster_name    = local.cluster_info.cluster_name
      service_account = local.iam_ack.service_account
    }
    eks_controller = {
      cluster_name    = local.cluster_info.cluster_name
      service_account = local.eks_ack.service_account
    }
  }

  tags = local.tags
}

data "aws_iam_policy_document" "iam_management_policy" {
  count = local.enable_ack_pod_identity ? 1 : 0
  statement {
    sid    = "RoleManagement"
    effect = "Allow"
    actions = [
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:PutRolePolicy",
      "iam:PutRolePermissionsBoundary",
      "iam:PassRole",
      "iam:DetachRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:DeleteRole",
      "iam:CreateRole",
      "iam:UntagRole",
      "iam:TagRole",
      "iam:AttachRolePolicy",
      "iam:GetRolePolicy"
    ]
    resources = [
      # Policies with specific prefixes
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.cluster_info.cluster_name}*",
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-ack-bountries"]
    }
  }

  statement {
    sid    = "PolicyManagement"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
      "iam:GetPolicyVersion",
      "iam:GetPolicy"
    ]
    resources = [
      # Policies with specific prefixes
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_info.cluster_name}*",
    ]
  }

  statement {
    sid    = "IAMACKListOperations"
    effect = "Allow"
    actions = [
      "iam:ListRoles",
      "iam:ListPolicies",
      "iam:GetRole",
      "iam:ListRoleTags",
      "iam:ListRolePolicies",
      "iam:ListPolicyVersions",
      "iam:ListPolicyTags",
      "iam:ListAttachedRolePolicies",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_info.cluster_name}*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.cluster_info.cluster_name}*",
    ]
  }
  statement {
    sid    = "eksack"
    effect = "Allow"
    actions = [
      # EKS Pod Identity specific permissions
      "eks:CreatePodIdentityAssociation",
      "eks:DeletePodIdentityAssociation",
      "eks:UpdatePodIdentityAssociation",
      "eks:ListPodIdentityAssociations",
      "eks:DescribePodIdentityAssociation",
      "eks:TagResource",   # For tagging pod identity associations
      "eks:UntagResource", # For untagging pod identity associations

      # Required supporting permissions
      "iam:PassRole",       # Required to pass IAM roles to EKS
      "ec2:DescribeSubnets" # Required for network configuration
    ]
    resources = [
      local.cluster_info.cluster_arn,
      "arn:aws:eks:${local.region}:${data.aws_caller_identity.current.account_id}:podidentityassociation/${local.cluster_info.cluster_name}/*"
    ]
  }
}

# Permission boundaries to restrict access to ACM, SSM and EKS
data "aws_iam_policy_document" "permissions_boundary_eks_ack" {
  count = local.enable_ack_pod_identity ? 1 : 0
  statement {
    sid       = "EKSACKSSMDescribe"
    effect    = "Allow"
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }

  statement {
    sid    = "EKSACKSSMParameterAccess"
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]
    resources = ["arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/*"]
  }

  statement {
    sid    = "EKSACKIAMAllowed"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:PutRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:PutRolePermissionsBoundary",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.cluster_info.cluster_name}*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_info.cluster_name}*",
    ]
  }

  statement {
    sid    = "IAMACKListOperations"
    effect = "Allow"
    actions = [
      "iam:ListRoles",
      "iam:ListPolicies",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:ListRoleTags",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:ListPolicyTags",
      "iam:TagRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.cluster_info.cluster_name}*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_info.cluster_name}*",
    ]
  }

  statement {
    sid       = "EKSACKSecretsManagerList"
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }

  statement {
    sid    = "EKSACKSecretsManagerAccess"
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:GetSecretValue",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["arn:aws:secretsmanager:${local.region}:${data.aws_caller_identity.current.account_id}:secret:*"]
  }

  statement {
    sid       = "EKSACKKMSDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["arn:aws:kms:${local.region}:${data.aws_caller_identity.current.account_id}:key/*"]
  }

  statement {
    sid    = "EKSACKACMCertificateManagement"
    effect = "Allow"
    actions = [
      "acm:AddTagsToCertificate",
      "acm:ExportCertificate",
      "acm:RequestCertificate",
      "acm:DescribeCertificate",
      "acm:GetCertificate",
      "acm:ListCertificates",
      "acm:ListTagsForCertificate",
      "acm:DeleteCertificate",
      "acm:RenewCertificate",
      "acm:UpdateCertificateOptions"
    ]
    resources = ["arn:aws:acm:${local.region}:${data.aws_caller_identity.current.account_id}:certificate/*"]
  }

  statement {
    sid    = "EKSACKACMPCAAccess"
    effect = "Allow"
    actions = [
      "acm-pca:DescribeCertificateAuthority",
      "acm-pca:GetCertificate",
      "acm-pca:GetCertificateAuthorityCertificate"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "EKSACKIssueACMPCAAccess"
    effect = "Allow"
    actions = [
      "acm-pca:IssueCertificate",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EKSACKEKSPodIdentityManagement"
    effect = "Allow"
    actions = [
      "eks:CreatePodIdentityAssociation",
      "eks:DeletePodIdentityAssociation",
      "eks:UpdatePodIdentityAssociation",
      "eks:ListPodIdentityAssociations",
      "eks:DescribePodIdentityAssociation",
      "eks:TagResource",
      "eks:UntagResource",
      "iam:PassRole",
      "ec2:DescribeSubnets"
    ]
    resources = [
      local.cluster_info.cluster_arn,
      "arn:aws:eks:${local.region}:${data.aws_caller_identity.current.account_id}:podidentityassociation/${local.cluster_info.cluster_name}/*"
    ]
  }

  statement {
    sid    = "EKSACKDenyPermBoundaryIAMPolicyAlteration"
    effect = "Deny"
    actions = [
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:CreatePolicyVersion",
      "iam:SetDefaultPolicyVersion"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-ack-bountries"]
  }

  statement {
    sid    = "EKSACKDenyRemovalOfPermBoundaryFromAnyRole"
    effect = "Deny"
    actions = [
      "iam:DeleteRolePermissionsBoundary"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-ack-bountries"]
    }
  }

  statement {
    sid       = "EKSACKNoBoundaryUserDelete"
    effect    = "Deny"
    actions   = ["iam:DeleteUserPermissionsBoundary"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/*"]
  }

  statement {
    sid    = "EKSACKDenyAccessIfRequiredPermBoundaryIsNotBeingApplied"
    effect = "Deny"
    actions = [
      "iam:PutRolePermissionsBoundary"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "iam:PermissionsBoundary"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-ack-bountries"]
    }
  }

  statement {
    sid    = "EKSACKDenyUserAndRoleCreationWithoutPermBoundary"
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:CreateRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "iam:PermissionsBoundary"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-ack-bountries"]
    }
  }

  # deny role modifications without boundary
  statement {
    sid    = "EKSACKDenyRoleModificationWithoutBoundary"
    effect = "Deny"
    actions = [
      "iam:UpdateRole",
      "iam:PutRolePolicy",
      "iam:AttachRolePolicy",
      "iam:UpdateAssumeRolePolicy"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"]
    condition {
      test     = "StringNotEquals"
      variable = "iam:PermissionsBoundary"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-ack-bountries"]
    }
  }

}

resource "aws_iam_policy" "permissions_boundary_eks_ack" {
  count       = local.enable_ack_pod_identity ? 1 : 0
  name        = "${local.cluster_name}-ack-bountries"
  path        = "/"
  description = "Permissions boundary policy for IAM users and roles"
  policy      = data.aws_iam_policy_document.permissions_boundary_eks_ack[0].json
}