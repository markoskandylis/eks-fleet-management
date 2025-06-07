# GitOps Fleet Management Documentation

## Overview

The GitOps Fleet Management system is a comprehensive solution for managing multiple Kubernetes clusters using ArgoCD. It provides a flexible approach to cluster management with support for both centralized and distributed (agent) deployment models.

This mono-repo establishes a GitOps-based fleet management system using ArgoCD, enabling both centralized and distributed management of multiple Kubernetes clusters. The idea is that this repo can be split depending on renspocibility model and teams.

## Core Components

### Application-Sets Chart

The `application-sets` chart is the foundation of the fleet management system. It serves as a wrapper/template generator for creating multiple ArgoCD ApplicationSets based on different configurations.

**Key Features:**
- Dynamic value merging from component files
- Support for different release types and versions
- Flexible deployment models (centralized or distributed)
- Hierarchical configuration with tenant/environment/cluster overrides

### Fleet Structure

The fleet management system is organized into two main components:

#### 1. Fleet Bootstrap (`fleet/bootstrap`)

This directory contains the core ApplicationSets for initializing the hub cluster:

- **addons.yaml**: 
  - Manages cluster add-ons deployment across the fleet
  - Uses application-sets helm chart wrapper
  - Deploys core controllers for 'Agent' model (ArgoCD, ALB, etc.)
  - References configurations in `addons/bootstrap/default` to overwirte default values

- **resources.yaml**: 
  - Handles fleet-wide resource deployments
  - Follows similar structure to addons.yaml
  - Supports separate team management
  - Independent resource lifecycle

- **fleetv2.yaml**: 
  - Manages spoke cluster registration process
  - References fleet-bootstrap configurations
  - Controls cluster onboarding

- **monitoring.yaml**: 
  - An example of seperation of applciation sets dipending on teams
  - Configures monitoring solutions across the fleet

The bootstrap process uses the `versions/applicationSets.yaml` file to determine which version of the application-sets chart to deploy for each component (addons, resources, monitoring, fleet).

#### 2. Fleet Bootstrap (`fleet/fleet-bootstrap`)

This directory handles the registration and initialization of spoke clusters:

- **fleet-hub-external-secrets.yaml**: 
  - Creates external secrets on hub cluster
  - Pulls spoke registration from AWS Secrets Manager
  - Configures tenant repository connections
  - References fleet-members configurations

- **fleet-members/**: 
  - Spoke cluster configurations
  - Deployment model selection
  - Tenant and environment settings
  - Repository access configurations
  - AWS Secrets Manager references

- **fleet-hub-secret-store.yaml**: 
  - Hub cluster secret store configuration
  - AWS Secrets Manager connection settings
  - Core secrets management

- **fleet-members-bootstrap.yaml**: 
  - Spoke cluster initialization for distributed setup
  - Triggers members-init-v2 configurations
  - Enabled for remote ArgoCD deployments

- **members-application-sets/**: 
  - Spoke cluster ApplicationSet templates
  - Used in distributed ArgoCD setup
  - Referenced by spoke ArgoCD instances
  - Resource deployment definitions

- **members-init-v2/**: 
  - Spoke initialization configurations
  - ApplicationSet deployment settings
  - Remote ArgoCD management setup

## Deployment Models

### Centralized Management

In this model, the hub cluster directly manages all spoke clusters. This is configured by setting `use_remote_argo: "false"` in the spoke cluster configuration.

**Characteristics:**
- Hub cluster's ArgoCD instance manages all resources on spoke clusters
- Single point of control and visibility
- Suitable for smaller fleets or environments requiring centralized governance

### Distributed ("Agent") Model

In this model, the hub deploys ArgoCD to spoke clusters, which then manage their own resources. This is configured by setting `use_remote_argo: "true"` in the spoke cluster configuration.

**Characteristics:**
- Improved scalability for large fleets
- Spoke clusters can operate independently
- Reduced load on the hub cluster
- Configurable with `enable_remote_resources` and `enable_remote_addons` flags

## Configuration Hierarchy

The system uses a hierarchical approach to configuration:

1. **Default values**: Base configurations for all clusters
2. **Tenant values**: Configurations specific to a tenant
3. **Environment values**: Configurations specific to an environment (dev, prod, etc.)
4. **Cluster values**: Configurations specific to individual clusters

This hierarchy allows for flexible configuration management while maintaining consistency across the fleet.

## Release Management

The system supports multiple release types through the `versions/applicationSets.yaml` file:

- **Default release**: The standard version to deploy when no specific version is requested
- **Named releases**: Specific versions that can be deployed to selected clusters

The `useVersionSelectors` flag enables version-specific deployments by adding version labels to cluster secrets.

## Registration Process

### Spoke Cluster Registration

1. Store spoke credentials in AWS Secrets Manager
2. Create a fleet member configuration in `fleet-bootstrap/fleet-members/`
3. The hub cluster's external-secrets operator pulls the credentials
4. Based on the configuration flags (`use_remote_argo`, `enable_remote_resources`, etc.), the appropriate resources are deployed to the spoke cluster

### Distributed Model Initialization

When using the distributed model (`use_remote_argo: "true"`):

1. ArgoCD is deployed to the spoke cluster
2. External secrets operator is deployed to the spoke cluster
3. The spoke cluster's ArgoCD instance is configured to connect to the Git repositories
4. ApplicationSets from `members-application-sets/` are deployed to the spoke cluster
5. The spoke cluster begins managing its own resources based on the `enable_remote_resources` and `enable_remote_addons` flags

## Value Merging Logic

The `_import_values.tpl` template dynamically merges values from component files based on the `mergeValues` configuration. This allows for modular configuration of different components (addons, resources, monitoring, etc.) while maintaining a single source of truth.

## Selector Logic

The system uses several types of selectors to determine which resources to deploy:

- **Global selectors**: Applied to all ApplicationSets
- **Component-specific selectors**: Applied to specific components (e.g., addons, resources)
- **Version selectors**: Used to deploy specific versions of components

The selector logic in `addons.yaml` handles three cases:
1. When `useSelectors` is true, include all group releases
2. When a specific group release is defined, only include matching releases
3. Otherwise, use the default release

## Best Practices

1. **Modular Configuration**: Use the hierarchical configuration approach to maintain consistency while allowing for customization
2. **Version Control**: Manage releases through the `versions/applicationSets.yaml` file
3. **Deployment Model Selection**: Choose the appropriate deployment model based on fleet size and governance requirements
4. **Secret Management**: Use AWS Secrets Manager and external-secrets operator for secure credential management
5. **Tenant Isolation**: Use the tenant structure to isolate configurations between different teams or environments
### Additional Repository Components

#### 📁 Addons
- Shared cluster add-ons
- Common controllers
- Reusable components
- Default configurations

#### 📁 Charts
- Fleet-wide Helm charts
- Shared configurations
- Reusable templates

#### 📁 Resources
- Common resource definitions
- Shared configurations
- Fleet-wide settings
## Registration Flow

### 1. Hub Cluster Initial Setup
- External-secrets operator deployed
- Fleet bootstrap components configured
- Secret store established for AWS Secrets Manager access

### 2. Spoke Cluster Registration
#### Configuration in fleet-members/
```yaml
# Example spoke cluster configuration
tenant: "eks-auto"
clusterName: "spoke-auto-workload1"
secretManagerSecretName: "hub-cluster/spoke-workload1"

# Management Model Selection
use_remote_argo: "false"          # Distributed ArgoCD deployment
enable_remote_resources: "false"   # Spoke self-management
enable_remote_addons: "false"     # Spoke addon management
use_external_secrets: "false"     # External secrets on spoke
push_argo_secrets: "false"        # Push secrets to spoke
```
## Configuration and Values Structure

### Addons and Resources Folders

The `addons` and `resources` folders serve two critical purposes in the GitOps Fleet Management system:

1. **Override Default Values**: They provide a hierarchical structure to override default values from the application-sets helm chart that is versioned and pushed to ECR.

2. **Define Cluster Labels**: They contain configuration files that define labels applied to cluster secrets, which control what components are deployed to each cluster.

#### Folder Structure

```
addons/
├── bootstrap/       # Bootstrap configurations
├── control-plane/   # Control plane specific configurations
├── defaults/        # Default configurations for all clusters
│   ├── addons/      # Default addon configurations
│   ├── fleet/       # Default fleet configurations
│   ├── monitoring/  # Default monitoring configurations
│   └── application-sets/ # Default application-sets configurations
└── tenants/         # Tenant-specific configurations
    ├── defaults/    # Default configurations for all tenants
    │   ├── addons/
    │   ├── fleet/
    │   │   └── fleet-secret/
    │   │       └── values.yaml  # Defines cluster labels and releases
    │   └── monitoring/
    └── tenant1/     # Specific tenant configurations
```

#### Label Configuration Example

The file `addons/tenants/defaults/fleet/fleet-secret/values.yaml` defines which releases and components will be deployed on clusters:

```yaml
externalSecret:
  labels:
    fleetRelease: default
    addonsRelease: release1
    monitoringRelease: default
    enable_metrics_server: "true"
    enable_external_secrets: "true"
```

These labels are applied to the cluster secrets and determine:
- Which version of each component group (fleet, addons, monitoring) to deploy
- Which specific components to enable (metrics-server, external-secrets, etc.)

### Integration with fleet-hub-external-secrets.yaml

The `fleet-hub-external-secrets.yaml` ApplicationSet in the `fleet/fleet-bootstrap` folder uses these configurations to:

1. Read the cluster registration information from AWS Secrets Manager
2. Apply the labels defined in the values.yaml files
3. Create ArgoCD secrets for cluster registration
4. Configure the deployment model (centralized or distributed) based on the labels

The ApplicationSet uses a matrix generator to:
- Find all registered clusters in the fleet-members directory
- Read the version information from fleetSecrets.yaml
- Combine this information to create properly labeled secrets

The labels on these secrets are then used by other ApplicationSets (addons.yaml, resources.yaml, etc.) to determine what to deploy to each cluster based on selector matching.
## Configuration Hierarchy and Override Mechanism

The GitOps Fleet Management system uses a configuration hierarchy that allows for flexible overrides at multiple levels:

### Configuration Levels (from highest to lowest priority)

1. **Cluster-specific configurations**
   - Path: `addons/tenants/{tenant}/clusters/{cluster-name}/{component}`
   - Most specific configurations that apply to a single cluster

2. **Environment-specific configurations**
   - Path: `addons/tenants/{tenant}/environments/{environment}/{component}`
   - Configurations shared by all clusters in a specific environment

3. **Tenant-specific configurations**
   - Path: `addons/tenants/{tenant}/defaults/{component}`
   - Configurations shared by all clusters belonging to a tenant

4. **Global tenant defaults**
   - Path: `addons/tenants/defaults/{component}`
   - Default configurations for all tenants

5. **System-wide defaults**
   - Path: `addons/defaults/{component}`
   - Base configurations for the entire system

### Value File Resolution

When deploying components to a cluster, the system resolves values by merging files from the hierarchy above. This is handled in the ApplicationSet templates, which include value files from each level in the hierarchy.

For example, in the `fleet-hub-external-secrets.yaml` ApplicationSet:

```yaml
valueFiles:
  - $values/{{ .metadata.annotations.addons_repo_basepath }}/bootstrap/defaults/{{.values.applicationSetGroup}}.yaml
  - $values/{{ .metadata.annotations.addons_repo_basepath }}/{{ .metadata.labels.tenant }}/defaults/{{ .values.chartName }}/{{.values.applicationSetGroup}}.yaml
  - $values/{{ .metadata.annotations.addons_repo_basepath }}/{{ .metadata.labels.tenant }}/clusters/{{ .name }}/{{ .values.chartName }}/{{.values.applicationSetGroup}}.yaml
  - $values/{{ .metadata.annotations.addons_repo_basepath }}/{{ .metadata.labels.tenant }}/environments/{{ .metadata.labels.environment }}/{{ .values.chartName }}/{{.values.applicationSetGroup}}.yaml
```

This approach allows for:
- Common configurations to be defined once at a higher level
- Specific overrides to be applied only where needed
- Consistent base configurations across the fleet
- Flexibility to customize at any level of the hierarchy
## Workflow: Adding a New Cluster to the Fleet

The following steps outline the process of adding a new cluster to the GitOps Fleet Management system:

### 1. Run Terraform to create the spoke cluster with AWS secret manager


### 2. Create Cluster Registration Configuration

Create a new YAML file in the appropriate tenant directory:
`fleet/fleet-bootstrap/fleet-members/{hub-cluster}/{spoke-cluster}.yaml`

```yaml
tenant: "tenant1"
clusterName: "spoke-dev-workload1"
# If you geting a secret from remote account use arn or from the same account we can just use the nae of the secret
secretManagerSecretName: "arn:aws:secretsmanager:region:account:secret:hub-cluster/spoke-dev-workload1" 

# GitHub repository access (if needed)
githubSecret: "true"
githubSecretName: "github/gitops/app-creds"

# Deployment model selection
use_remote_argo: "true"           # Use distributed ArgoCD
enable_remote_resources: "true"   # Enable spoke self-management for resources
enable_remote_addons: "true"      # Enable spoke self-management for addons
use_fleet_ack: "false"            # Don't use fleet ACK controllers
use_argocd_ingress: "false"       # Don't create ArgoCD ingress
```

### 3. Configure Cluster Labels (Optional)

Create or modify values files to customize the cluster's configuration:

```yaml
# addons/tenants/tenant1/clusters/spoke-dev-workload1/fleet-secret/values.yaml
externalSecret:
  labels:
    fleetRelease: default
    addonsRelease: release1
    monitoringRelease: default
    enable_metrics_server: "true"
    enable_external_secrets: "true"
    enable_aws_load_balancer_controller: "true"
```

### 4. Commit and Push Changes

Commit the changes to the Git repository and push to trigger the GitOps workflow.

### 5. Automatic Registration Process

1. The `fleet-hub-external-secrets.yaml` ApplicationSet detects the new cluster configuration
2. It creates an external secret that pulls the cluster's kubeconfig from AWS Secrets Manager
3. The external secret creates an ArgoCD cluster secret with the appropriate labels
4. Based on the `use_remote_argo` flag:
   - If `false`: The hub's ArgoCD begins managing the cluster directly
   - If `true`: The hub deploys ArgoCD to the spoke cluster, which then manages its own resources

### 6. Component Deployment

Based on the labels applied to the cluster secret:
1. The appropriate version of each component group (fleet, addons, monitoring) is deployed
2. Specific components are enabled or disabled according to the labels
3. Configuration values are applied following the hierarchy described earlier
## Infrastructure Provisioning with Terraform

The GitOps Fleet Management system includes Terraform configurations for provisioning both hub and spoke clusters. These configurations handle the initial infrastructure setup before the GitOps processes take over.

### Hub Cluster Provisioning

The hub cluster is the central management cluster that orchestrates the fleet. Its Terraform configuration:

1. **Creates the EKS Cluster**
   - Sets up the hub cluster with appropriate node groups
   - Configures VPC and networking components
   - Establishes IAM roles and permissions

2. **Installs Initial Components**
   - Deploys ArgoCD as the GitOps engine
   - Sets up external-secrets operator for secret management
   - Configures repository access using GitHub App credentials

3. **Establishes GitOps Bridge**
   - Creates Kubernetes secrets for Git repository access
   - Bootstraps the initial ApplicationSet that will manage the fleet
   - Points to the fleet repository and bootstrap directory

4. **Registers the Hub Cluster**
   - Creates an AWS Secrets Manager secret for the hub cluster
   - Stores cluster metadata and connection information
   - Sets up IAM roles for ArgoCD to manage spoke clusters

5. **Configures Pod Identity**
   - Sets up AWS IAM roles for service accounts
   - Creates roles for external-secrets, ArgoCD, and other components
   - Stores role ARNs in SSM parameters for cross-account access

### Spoke Cluster Provisioning

Spoke clusters are the workload clusters managed by the hub. Their Terraform configuration:

1. **Creates the EKS Cluster**
   - Sets up the spoke cluster with appropriate node groups
   - Configures VPC and networking components
   - Establishes IAM roles and permissions

2. **Establishes Hub-Spoke Connection**
   - Creates an IAM role that allows the hub's ArgoCD to access the spoke
   - Sets up trust relationships between hub and spoke accounts
   - Configures cross-account access policies

3. **Registers the Spoke Cluster**
   - Creates an AWS Secrets Manager secret containing the spoke's connection information
   - Includes cluster metadata, endpoint, and certificate data
   - Sets up a KMS key for encrypting the secret
   - Configures a resource policy allowing the hub's external-secrets to access the secret

4. **Optional: Configures Distributed ArgoCD**
   - When using the distributed model, sets up IAM roles for the spoke's ArgoCD
   - Configures pod identity for the spoke's components
   - Establishes permissions for the spoke to manage its own resources

### Cross-Account Security

The Terraform configurations implement a secure cross-account access model:

1. **Hub Account**
   - ArgoCD uses pod identity to assume a role for managing spoke clusters
   - External-secrets uses pod identity to access secrets in spoke accounts
   - Role ARNs are stored in SSM parameters for reference

2. **Spoke Accounts**
   - Create IAM roles that trust the hub's ArgoCD role
   - Set up resource policies on secrets to allow access from the hub
   - Use KMS encryption for secure secret storage

### Infrastructure to GitOps Handoff

After Terraform provisions the infrastructure:

1. The hub cluster's ArgoCD instance is bootstrapped with an initial ApplicationSet
2. This ApplicationSet points to the fleet bootstrap directory in the Git repository
3. ArgoCD applies the configurations from the repository, setting up the fleet management system
4. The system transitions from infrastructure-as-code to GitOps for ongoing management

This approach provides a clean separation between initial infrastructure provisioning (Terraform) and ongoing configuration management (GitOps), while ensuring secure cross-account access between hub and spoke clusters.
## End-to-End Cluster Onboarding Process

The complete process for onboarding a new cluster to the GitOps Fleet Management system involves both Terraform infrastructure provisioning and GitOps configuration. Here's the end-to-end workflow:

### 1. Infrastructure Provisioning (Terraform)

#### Hub Cluster (One-time Setup)
1. Deploy the hub cluster using the Terraform configuration in `terraform/hub/`
2. This installs ArgoCD and bootstraps the initial ApplicationSet
3. The hub cluster is registered in AWS Secrets Manager
4. IAM roles and pod identity are configured for cross-account access

#### Spoke Cluster
1. Deploy the spoke cluster using the Terraform configuration in `terraform/spokes/`
2. Configure cross-account access between hub and spoke
3. Register the spoke cluster in AWS Secrets Manager
4. Set up resource policies to allow the hub to access the spoke's secret

### 2. GitOps Configuration (ArgoCD)

#### Hub Cluster Configuration
1. The bootstrapped ApplicationSet on the hub discovers the fleet bootstrap directory
2. It applies the configurations from `fleet/bootstrap/`
3. This sets up the core ApplicationSets for addons, resources, and fleet management

#### Spoke Cluster Registration
1. Create a spoke cluster configuration file in `fleet/fleet-bootstrap/fleet-members/{hub-cluster}/{spoke-cluster}.yaml`
2. Configure the deployment model (centralized or distributed) and other settings
3. Commit and push the changes to the Git repository

#### Automatic Registration Process
1. The `fleet-hub-external-secrets.yaml` ApplicationSet detects the new configuration
2. It creates an external secret that pulls the spoke's connection information from AWS Secrets Manager
3. The external secret creates an ArgoCD cluster secret with labels from the configuration
4. ArgoCD registers the spoke cluster and begins managing it according to the deployment model

### 3. Component Deployment

#### Centralized Model
1. The hub's ArgoCD directly deploys components to the spoke cluster
2. ApplicationSets for addons and resources select the spoke based on its labels
3. Components are deployed according to the configuration hierarchy

#### Distributed Model
1. The hub deploys ArgoCD to the spoke cluster
2. The hub configures the spoke's ArgoCD with repository access
3. The spoke's ArgoCD deploys components based on ApplicationSets from `members-application-sets/`
4. The spoke manages its own resources according to the `enable_remote_resources` and `enable_remote_addons` flags

### 4. Ongoing Management

#### Configuration Updates
1. Update values files in the appropriate location in the configuration hierarchy
2. Commit and push changes to the Git repository
3. ArgoCD automatically applies the changes to the affected clusters

#### Release Management
1. Update the `versions/applicationSets.yaml` file to change component versions
2. Update cluster labels in `addons/tenants/defaults/fleet/fleet-secret/values.yaml` or cluster-specific overrides
3. Commit and push changes to the Git repository
4. ArgoCD automatically updates components to the specified versions

This end-to-end process combines infrastructure-as-code for initial provisioning with GitOps for ongoing management, providing a scalable and maintainable approach to managing a fleet of Kubernetes clusters.
