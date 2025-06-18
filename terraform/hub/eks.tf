module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.36.0"

  cluster_name                   = local.cluster_name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = var.eks_cluster_endpoint_public_access

  vpc_id                   = data.aws_vpc.vpc.id
  subnet_ids               = data.aws_subnets.intra_subnets.ids
  control_plane_subnet_ids = data.aws_subnets.private_subnets.ids

  cluster_security_group_additional_rules = {
    cluster_internal_ingress = {
      description = "Access EKS from VPC."
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    }
  }

  enable_cluster_creator_admin_permissions = true
  access_entries = {
    # access entry with a policy associated for admins
    kube-admins = {
      principal_arn = tolist(data.aws_iam_roles.eks_admin_role.arns)[0]
      policy_associations = {
        admins = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = local.enable_automode ? {} : {
    platform = {
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore    = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        AmazonSSMDirectoryServiceAccess = "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess",
        CloudWatchAgentServerPolicy     = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }
      instance_types = var.managed_node_group_instance_types
      ami_type       = var.managed_node_group_ami
      # In Case you want to control the version of the ami
      ami_release_version            = var.ami_release_version
      use_latest_ami_release_version = var.managed_node_group_ami != "" ? false : true
      min_size                       = 3
      max_size                       = 6
      desired_size                   = 3
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 10
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            delete_on_termination = true
          }
        }
        xvdb = {
          device_name = "/dev/xvdb"
          ebs = {
            volume_size           = 25
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
      labels = {
        type = "criticalAddons"
      }
    }
  }

  cluster_compute_config = local.cluster_compute_config

  # EKS Addons
  # If automode is enabled the following addons are managed by Automode
  cluster_addons = local.enable_automode ? {} : {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
    amazon-cloudwatch-observability = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    vpc-cni = {
      # Specify the VPC CNI addon should be deployed before compute to ensure
      # the addon is configured before data plane compute resources are created
      # See README for further details
      before_compute = true
      most_recent    = true # To ensure access to the latest settings provided
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }
  node_security_group_additional_rules = {
    # Allows Control Plane Nodes to talk to Worker nodes vpc cni metrics port
    vpc_cni_metrics_traffic = {
      description                   = "Cluster API to node 61678/tcp vpc cni metrics"
      protocol                      = "tcp"
      from_port                     = 61678
      to_port                       = 61678
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
  node_security_group_tags = {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.cluster_name
  }
  tags = {
    Blueprint  = local.cluster_name
    GithubRepo = "https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest"
  }
}

locals {
  # Table with BOTH Posiblilities AUTO-Mode on or off
  _cluster_compute_configs = {
    true = { # Auto-Mode ON
      enabled    = true
      node_pools = ["general-purpose", "system"]
    }
    false = {} # Auto-Mode OFF
  }

  # Pick the one we need at runtime
  cluster_compute_config = local._cluster_compute_configs[tostring(local.enable_automode)]
}
