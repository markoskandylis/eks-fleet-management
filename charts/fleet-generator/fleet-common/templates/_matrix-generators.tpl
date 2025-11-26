{{/*
Cluster generator helper
*/}}
{{- define "fleet-common.clusterGenerator" -}}
{{- $ctx := .context }}
{{- $group := .group }}
{{- $valuesPath := .valuesPath }}
- clusters:
    selector:
      matchLabels:
        fleet_member: {{ $ctx.deploymentCluster | default "hub-cluster" }}
        {{- if $ctx.additionalMatchLabels }}
        {{ $ctx.additionalMatchLabels | toYaml }}
        {{- end }}
    values:
      applicationSetGroup: {{ $group }}
      valuesPath: {{ $valuesPath }}
      useSelectors: '{{ $ctx.useSelectors }}'
      useVersionSelectors: '{{ $ctx.useVersionSelectors }}'
      releaseName: '{{ $ctx.releaseName }}'
{{- end }}

{{/*
Git generator helper
*/}}
{{- define "fleet-common.gitGeneratorHelper" -}}
{{- $ctx := .context }}
- git:
    repoURL: '{{ $ctx.gitGenerator.repoURL }}'
    revision: '{{ $ctx.gitGenerator.revision }}'
    files:
      - path: '{{ $ctx.gitGenerator.path }}'
{{- end }}

{{/*
List generator helper
*/}}
{{- define "fleet-common.listGenerator" -}}
{{- $ctx := .context }}
{{- $group := .group }}
{{- $releases := .releases }}
{{- $indent := .indent | default 12 }}
- list:
    elementsYaml: |
{{ include "fleet-common.processReleases" (dict "context" $ctx "group" $group "releases" $releases) | indent $indent }}
{{- end }}

{{/*
Standard matrix generator for bootstrap ApplicationSets
Usage: {{ include "fleet-common.matrixGenerator" (dict "context" . "group" "addons" "releases" .Values.releases "valuesPath" $valuesPath) }}
*/}}
{{- define "fleet-common.matrixGenerator" -}}
{{- $ctx := .context }}
{{- $group := .group }}
{{- $releases := .releases }}
{{- $valuesPath := .valuesPath }}
- matrix:
    generators:
    {{- if $ctx.gitGenerator }}
    - matrix:
        generators:
{{ include "fleet-common.clusterGenerator" (dict "context" $ctx "group" $group "valuesPath" $valuesPath) | indent 8 }}
{{ include "fleet-common.gitGeneratorHelper" (dict "context" $ctx) | indent 8 }}
{{ include "fleet-common.listGenerator" (dict "context" $ctx "group" $group "releases" $releases "indent" 14) | indent 4 }}
    {{- else }}
{{ include "fleet-common.clusterGenerator" (dict "context" $ctx "group" $group "valuesPath" $valuesPath) | indent 4 }}
{{ include "fleet-common.listGenerator" (dict "context" $ctx "group" $group "releases" $releases "indent" 10) | indent 4 }}
    {{- end }}
{{- end }}


