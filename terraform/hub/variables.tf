################################################################################
# Infrastructure Variables
################################################################################
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "cross_account_role_name" {
  description = "If the deployment is multiaccount thats the defined name of the remote role"
  type        = string
  default     = ""
}

variable "vpc_name" {
  description = "VPC name to be used by pipelines for data"
  type        = string
}

variable "ecr_account" {
  description = "The account the the ECR images for the gitops bridge are hosted"
  type        = string
  default     = ""
}

variable "accounts_config" {
  description = "Map of objects for per environment configuration"
  type = map(object({
    account_id = string
  }))
}

variable "kms_key_admin_roles" {
  description = "list of role ARNs to add to the KMS policy"
  type        = list(string)
  default     = []
}

variable "enable_efs" {
  description = "Creating EFS File sustem"
  type        = bool
  default     = false
}

################################################################################
# Cluster Realted Variables
################################################################################
variable "eks_cluster_endpoint_public_access" {
  description = "Deploying public or private endpoint for the cluster"
  type        = bool
  default     = true
}

variable "managed_node_group_ami" {
  description = "The ami type of managed node group"
  type        = string
  default     = "BOTTLEROCKET_x86_64"
}

variable "managed_node_group_instance_types" {
  description = "List of managed node group instances"
  type        = list(string)
  default     = ["m5.large"]
}

variable "ami_release_version" {
  description = "The AMI version of the Bottlerocket worker nodes"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "tenant" {
  type        = string
  description = "Type of Tenancy of the clusrer this can be in our Case Control plane for Hub cluster and Name of tenant group if its spoke"
}

variable "fleet_member" {
  description = "Defining the fleet membership type of the cluster can be a hub or spoke cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
  default     = "hub-cluster"
}

variable "enable_hub_external_secrets" {
  description = "Value to enable hub cluster to update deployiments using external secrets operator this is a string values buecause its added to the lables of argocd secret"
  type        = string
  default     = "false"
}

variable "enable_ack_pod_identity" {
  description = "Defining to use ack or terraform for pod identity if this is true then we will use this label to deploy resouces with ack"
  type        = bool
  default     = false
}

variable "enable_automode" {
  description = "Enabling Automode Cluster"
  type        = bool
  default     = false
}

variable "aws_resources" {
  description = "Resources to be creative for addons"
  type        = any
  default     = {}
}

variable "environment" {
  description = "The environment of the Hub cluster"
  type        = string
}

variable "route53_zone_name" {
  description = "The route53 zone for external dns"
  default     = ""
}
# Github Repos Variables
variable "git_creds_secret" {
  description = "The name of the secret that is used to strore git credentions of argocd to connect"
  type        = string
  default     = ""
}
variable "git_org_name" {
  description = "The name of Github organisation"
  default     = ""
}

variable "gitops_addons_repo_name" {
  description = "The name of Github organisation"
  default     = ""
}

variable "gitops_addons_repo_path" {
  description = "The name of Github organisation"
  default     = ""
}

variable "gitops_addons_repo_base_path" {
  description = "The name of Github organisation"
  default     = ""
}

variable "gitops_addons_repo_revision" {
  description = "The name of Github organisation"
  default     = ""
}
# Fleet
variable "gitops_fleet_repo_name" {
  description = "The name of Github organisation"
  default     = ""
}

variable "gitops_fleet_repo_path" {
  description = "The name of Github organisation"
  default     = ""
}

variable "gitops_fleet_repo_base_path" {
  description = "The name of Github organisation"
  default     = ""
}

variable "gitops_fleet_repo_revision" {
  description = "The name of Github organisation"
  default     = ""
}

variable "gitops_resources_repo_name" {
  description = "The name of Github organisation"
  default     = ""
}

variable "gitops_resources_repo_path" {
  description = "The name of Github organisation"
  default     = ""
}

variable "gitops_resources_repo_base_path" {
  description = "The name of Github organisation"
  default     = ""
}

variable "gitops_resources_repo_revision" {
  description = "The name of Github organisation"
  default     = ""
}
