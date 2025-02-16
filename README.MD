# GitOps Fleet Management

This mono-repo establishes a GitOps-based fleet management system using ArgoCD, enabling both centralized and distributed management of multiple Kubernetes clusters.

## Core Concepts

### Deployment Models

#### Centralized Management
- Hub cluster directly manages all spoke clusters
- Suitable for smaller fleets
- Single point of control

#### Distributed ("Agent") Model
- Hub deploys ArgoCD to spoke clusters
- Spokes manage their own resources
- Improved scalability for large fleets

## Repository Structure

### 📁 Fleet
Core components for cluster fleet management and registration.

#### Bootstrap Folder
Primary ApplicationSets for fleet initialization:

- **addonsv2.yaml**
  - Manages cluster add-ons deployment
  - Uses application-sets helm chart wrapper
  - Deploys core controllers (ArgoCD, ALB, etc.)
  - References configurations in `addons/bootstrap/default`

- **resourcesv2.yaml**
  - Handles fleet-wide resource deployments
  - Follows similar structure to addonsv2
  - Supports separate team management
  - Independent resource lifecycle

- **fleetv2.yaml**
  - Manages spoke cluster registration process
  - References fleet-bootstrap configurations
  - Controls cluster onboarding

#### Fleet-Bootstrap Folder
Core components for cluster registration and initialization:

- `fleet-hub-external-secrets-appset.yaml`
  - Creates external secrets on hub cluster
  - Pulls spoke registration from AWS Secrets Manager
  - Configures tenant repository connections
  - References fleet-members configurations

- `fleet-members/`
  - Spoke cluster configurations
  - Deployment model selection
  - Tenant and environment settings
  - Repository access configurations
  - AWS Secrets Manager references

- `fleet-hub-secret-store-appset.yaml`
  - Hub cluster secret store configuration
  - AWS Secrets Manager connection settings
  - Core secrets management

- `fleet-members-init.yaml`
  - Spoke cluster initialization for distributed setup
  - Triggers members-init-v2 configurations
  - Enabled for remote ArgoCD deployments

- `members-application-sets/`
  - Spoke cluster ApplicationSet templates
  - Used in distributed ArgoCD setup
  - Referenced by spoke ArgoCD instances
  - Resource deployment definitions

- `members-init-v2/`
  - Spoke initialization configurations
  - ApplicationSet deployment settings
  - Remote ArgoCD management setup

### 📁 Addons
- Shared cluster add-ons
- Common controllers
- Reusable components
- Default configurations

### 📁 Charts
- Fleet-wide Helm charts
- Shared configurations
- Reusable templates

### 📁 Resources
- Common resource definitions
- Shared configurations
- Fleet-wide settings

## Registration Process

**Initial Setup**
- Store spoke credentials in AWS Secrets Manager
- Configure hub cluster with external-secrets operator
- Create fleet member configuration

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
secretManagerSecretName: "hub-cluster-auto/spoke-auto-workload1"

# Management Model Selection
use_remote_argo: "false"          # Distributed ArgoCD deployment
enable_remote_resources: "false"   # Spoke self-management
enable_remote_addons: "false"     # Spoke addon management
use_external_secrets: "false"     # External secrets on spoke
push_argo_secrets: "false"        # Push secrets to spoke
