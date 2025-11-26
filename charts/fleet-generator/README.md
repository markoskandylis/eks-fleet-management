# Fleet Generator Chart

## Overview

The Fleet Generator creates a hierarchical ApplicationSet structure for managing fleet deployments. It implements a parent-child ApplicationSet pattern where parent ApplicationSets group and manage related child ApplicationSets.

## Architecture

```
auto.yaml (fleet/bootstrap/hub-cluster-np/)
    ↓ (deploys)
fleet-generator chart
    ↓ (creates)
Parent ApplicationSets (cluster-addons, fleet-members-registration, fleet-members-bootstrap)
    ↓ (each parent deploys)
fleet-common chart
    ↓ (creates)
Child ApplicationSets (addons, monitoring, resources, hub-secret-store, etc.)
    ↓ (deploy)
Actual Applications
```

## Parent ApplicationSets

### cluster-addons
Groups ApplicationSets for hub cluster add-ons:
- `addons` - Core cluster add-ons
- `monitoring` - Monitoring stack
- `resources` - Cluster resources

### fleet-members-registration
Groups ApplicationSets for fleet member registration:
- `hub-secret-store` - Secret store configuration
- `fleet-hub-secrets` - Hub cluster secrets

### fleet-members-bootstrap
Groups ApplicationSets for spoke cluster bootstrap:
- `spoke-addons` - Spoke cluster add-ons
- `fleet-spoke-secrets` - Spoke cluster secrets

## Configuration

### Main Configuration
- `values.yaml` - Default parent ApplicationSet configuration
- `fleet/bootstrap/hub-cluster-np/tests/generator-config.yaml` - Environment-specific overrides

### Key Configuration Sections

#### parentApplicationSets
Defines the parent ApplicationSets and their children:
```yaml
parentApplicationSets:
  cluster-addons:
    enabled: true
    children: ["addons", "monitoring", "resources"]
    sharedValues:
      valuesPath: "application-sets"
      useVersionSelectors: "true"
```

#### bootstrap
Child-specific configurations that merge with parent sharedValues:
```yaml
bootstrap:
  addons:
    enabled: true
    mergeValues:
      addons:
        use: true
```

## Value Inheritance

1. **Global values** (from `global.reposConfig`)
2. **Parent sharedValues** (from `parentApplicationSets.*.sharedValues`)
3. **Child-specific values** (from `bootstrap.*`)
4. **Environment overrides** (from bootstrap folder configs)

## Deployment Flow

1. ArgoCD reads `fleet/bootstrap/hub-cluster-np/auto.yaml`
2. `auto.yaml` deploys the `fleet-generator` chart
3. `fleet-generator` creates parent ApplicationSets
4. Parent ApplicationSets deploy `fleet-common` chart with child configurations
5. `fleet-common` creates child ApplicationSets
6. Child ApplicationSets deploy actual applications

## Files Structure

```
fleet-generator/
├── Chart.yaml                           # Chart metadata
├── values.yaml                          # Default configuration
├── templates/
│   └── parent-applicationsets.yaml      # Parent ApplicationSet generator
└── fleet-common/                        # Subchart for child ApplicationSets
    ├── Chart.yaml
    └── templates/
        ├── application-sets.yaml        # Child ApplicationSet templates
        ├── _helpers.tpl                 # Helper templates
        ├── _matrix-generators.tpl       # Matrix generator helpers
        ├── _release-helpers.tpl         # Release processing helpers
        └── _template_generator.tpl      # Source generator helpers
```

## Testing

```bash
# Test template rendering
helm template test-fleet . -f /path/to/generator-config.yaml

# Test with debug
helm template test-fleet . --debug
```
