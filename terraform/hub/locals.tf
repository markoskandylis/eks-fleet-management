locals {
  account_config          = var.accounts_config[terraform.workspace]
  cluster_name            = var.cluster_name
  cluster_info            = module.eks
  enable_automode         = var.enable_automode
  enable_ack_pod_identity = var.enable_ack_pod_identity
  enable_efs              = var.enable_efs
  environment             = var.environment
  fleet_member            = var.fleet_member
  tenant                  = var.tenant
  region                  = data.aws_region.current.id
  cluster_version         = var.kubernetes_version

  argocd_namespace          = "argocd"
  gitops_addons_repo_url    = "https://github.com/${var.git_org_name}/${var.gitops_addons_repo_name}.git"
  gitops_fleet_repo_url     = "https://github.com/${var.git_org_name}/${var.gitops_fleet_repo_name}.git"
  gitops_resources_repo_url = "https://github.com/${var.git_org_name}/${var.gitops_resources_repo_name}.git"

  external_secrets = {
    namespace       = "external-secrets"
    service_account = "external-secrets-sa"
  }
  aws_load_balancer_controller = {
    namespace       = "kube-system"
    service_account = "aws-load-balancer-controller-sa"
  }

  karpenter = {
    namespace       = "kube-system"
    service_account = "karpenter"
    role_name       = "karpenter-${terraform.workspace}"
  }

  iam_ack = {
    namespace       = "ack-system"
    service_account = "iam-ack"
  }

  eks_ack = {
    namespace       = "ack-system"
    service_account = "eks-ack"
  }

  aws_resources = {
    enable_external_secrets             = try(var.aws_resources.enable_external_secrets, false)
    enable_aws_lb_controller            = try(var.aws_resources.enable_aws_lb_controller, false)
    enable_aws_efs_csi_driver           = try(var.aws_resources.enable_aws_efs_csi_driver, false)
    enable_eck_stack                    = try(var.aws_resources.enable_eck_stack, false)
    enable_efs                          = try(var.aws_resources.enable_efs, false)
    enable_karpenter                    = try(var.aws_resources.enable_karpenter, false)
    enable_prometheus_scraper           = try(var.aws_resources.enable_prometheus_scraper, false)
    enable_cni_metrics_helper           = try(var.aws_resources.enable_cni_metrics_helper, false)
    enable_karpenter                    = try(var.aws_resources.enable_karpenter, false)
    enable_aws_cloudwatch_observability = try(var.aws_resources.enable_aws_cloudwatch_observability, false)
    enable_aws_load_balancer_controller = try(var.aws_resources.enable_aws_load_balancer_controller, false)
  }

  addons = merge(
    { tenant = local.tenant },
    { fleet_member = local.fleet_member },
    { kubernetes_version = local.cluster_version },
    { aws_cluster_name = local.cluster_info.cluster_name },
    { addonsRelease = "default" }
  )

  addons_metadata = merge(
    {
      tenant = local.tenant
    },
    {
      aws_cluster_name = local.cluster_info.cluster_name
      aws_region       = local.region
      aws_account_id   = data.aws_caller_identity.current.account_id
      aws_vpc_id       = data.aws_vpc.vpc.id
      use_ack          = local.enable_ack_pod_identity
    },
    {
      argocd_namespace        = local.argocd_namespace,
      create_argocd_namespace = false
    },
    {
      addons_repo_url      = local.gitops_addons_repo_url
      addons_repo_path     = var.gitops_addons_repo_path
      addons_repo_basepath = var.gitops_addons_repo_base_path
      addons_repo_revision = var.gitops_addons_repo_revision
    },
    {
      resources_repo_url      = local.gitops_resources_repo_url
      resources_repo_path     = var.gitops_resources_repo_path
      resources_repo_basepath = var.gitops_resources_repo_base_path
      resources_repo_revision = var.gitops_resources_repo_revision
    },
    {
      fleet_repo_url      = local.gitops_fleet_repo_url
      fleet_repo_path     = var.gitops_fleet_repo_path
      fleet_repo_basepath = var.gitops_fleet_repo_base_path
      fleet_repo_revision = var.gitops_fleet_repo_revision
    },
    {
      karpenter_namespace          = local.karpenter.namespace
      karpenter_service_account    = local.karpenter.service_account
      karpenter_node_iam_role_name = try(module.karpenter[0].node_iam_role_name, null)
      karpenter_sqs_queue_name     = try(module.karpenter[0].queue_name, null)
    },
    {
      external_secrets_namespace       = local.external_secrets.namespace
      external_secrets_service_account = local.external_secrets.service_account
    },
    {
      ack_iam_service_account = local.iam_ack.service_account
      ack_iam_namespace       = local.iam_ack.namespace
      ack_eks_service_account = local.eks_ack.service_account
      ack_eks_namespace       = local.eks_ack.namespace
    },
    {
      aws_load_balancer_controller_namespace       = local.aws_load_balancer_controller.namespace
      aws_load_balancer_controller_service_account = local.aws_load_balancer_controller.service_account
    },
    {
      storageclass_file_system_id = try(aws_efs_file_system.efs-eks[0].id, null)
    },
  )

  argocd_apps = {
    applicationsets = file("${path.module}/bootstrap/applicationsets.yaml")
  }
  tags = {
    Blueprint  = local.cluster_name
    GithubRepo = "github.com/gitops-bridge-dev/gitops-bridge"
  }
}


