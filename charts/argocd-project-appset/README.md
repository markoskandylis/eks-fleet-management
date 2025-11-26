# argocd-project-appset

A simple Helm chart to create ArgoCD Projects and ApplicationSets for spoke clusters, allowing you to connect each spoke to specific repositories for workload deployment.

## Usage

1. Customize `values.yaml` to define your ArgoCD Projects and ApplicationSets, specifying the repositories and paths for each spoke cluster.
2. Install the chart on your spoke cluster:
   ```sh
   helm install my-argocd-project-appset ./argocd-project-appset -n argocd
   ```

## Example `values.yaml`

### Minimal configuration (uses all defaults):

```yaml
applicationsets:
  - name: my-app
    repoURL: https://github.com/org/my-repo.git
    paths:
      - path: workloads/app1
      - path: workloads/app2
```

### Full configuration with custom projects:

```yaml
projectDefaults:
  description: 'Custom default project description'
  destinations:
    - namespace: '*'
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  namespaceResourceWhitelist:
    - group: '*'
      kind: '*'

applicationsetDefaults:
  targetRevision: develop
  destination:
    server: https://kubernetes.default.svc
    namespace: my-namespace
  syncPolicy:
    automated:
      selfHeal: true
    retry:
      limit: 3

projects:
  - name: spoke1-project
    description: Project for Spoke 1
    sourceRepos:
      - https://github.com/org/spoke1-repo.git
      - https://github.com/org/spoke1-other-repo.git

applicationsets:
  - name: spoke1-applicationset
    project: spoke1-project
    repoURL: https://github.com/org/spoke1-repo.git
    targetRevision: main
    paths:
      - path: workloads/app1
      - path: workloads/app2
    destination:
      server: https://kubernetes.default.svc
      namespace: spoke1-namespace
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
```

## Notes

- This chart is intended for use in spoke clusters bootstrapped from a hub, following a GitOps approach.
- Each ApplicationSet can deploy multiple workloads from the specified repo paths.
