{{/*
Template to generate additional resources configuration
*/}}
{{- define "application-sets.additionalResources" -}}
{{- $chartName := .chartName -}}
{{- $chartConfig := .chartConfig -}}
{{- $valueFiles := .valueFiles -}}
{{- $additionalResourcesType := .additionalResourcesType -}}
{{- $additionalResourcesPath := .path -}}
{{- $values := .values -}}
{{- if $chartConfig.additionalResources.path }}
- repoURL: {{ $values.repoURLGit | squote }}
  targetRevision: {{ $values.repoURLGitRevision | squote }}
  path: {{- if eq $additionalResourcesType "manifests" }}
    '{{ $values.repoURLGitBasePath }}{{ if $values.useValuesFilePrefix }}{{ $values.valuesFilePrefix }}{{ end }}clusters/{{`{{.nameNormalized}}`}}/{{ $chartConfig.additionalResources.manifestPath }}'
  {{- else }}
    {{ $chartConfig.additionalResources.path | squote }}
  {{- end}}
{{- end }}
{{- if $chartConfig.additionalResources.chart }}
- repoURL: '{{$chartConfig.additionalResources.repoURL}}'
  chart: '{{$chartConfig.additionalResources.chart}}'
  targetRevision: '{{$chartConfig.additionalResources.chartVersion }}'
{{- end }}
{{- if $chartConfig.additionalResources.helm }}
  helm:
    releaseName: '{{`{{ .name }}`}}-{{ $chartConfig.additionalResources.helm.releaseName }}'
    {{- if or $values.globalValuesObject $chartConfig.additionalResources.helm.valuesObject }}
    {{/* Create a fresh copy for this component only */}}
    {{- $chartValuesObject := dict }}
    {{- if $values.globalValuesObject }}
      {{- $chartValuesObject = deepCopy $values.globalValuesObject }}
    {{- end }}
    {{- if $chartConfig.additionalResources.helm.valuesObject }}
      {{- $chartValuesObject = mergeOverwrite $chartValuesObject $chartConfig.additionalResources.helm.valuesObject }}
    {{- end }}
    valuesObject:
      {{- toYaml $chartValuesObject | nindent 12 }}
    {{- end }}
    ignoreMissingValueFiles: true
    valueFiles:
    {{- include "application-sets.valueFiles" (dict 
      "nameNormalize" $chartName 
      "valueFiles" $valueFiles 
      "values" $values 
      "chartType" $additionalResourcesType) | nindent 6 }}
{{- end }}
{{- end }}

{{/*
Define the values path for reusability
*/}}
{{- define "application-sets.valueFiles" -}}
{{- $nameNormalize := .nameNormalize -}}
{{- $chartConfig := .chartConfig -}}
{{- $valueFiles := .valueFiles -}}
{{- $chartType := .chartType -}}
{{- $values := .values -}}
{{- $valuesFileName := default "values.yaml" $chartConfig.valuesFileName -}}
{{- $applicationSetGroup := default "" $values.applicationSetGroup -}}

{{- with .valueFiles }}
{{- range . }}
{{/* Path with applicationSetGroup if available */}}
{{- if ne $values.repoURLGitBasePath "" }}
- $values/{{$values.repoURLGitBasePath}}
{{- else}}
- $values{{$values.repoURLGitBasePath}}
{{- end }}
{{- if $values.useValuesFilePrefix -}}/{{$values.valuesFilePrefix}}{{- end -}}/{{.}}
{{- if $applicationSetGroup -}}/{{$applicationSetGroup}}{{- end -}}/{{$nameNormalize}}
{{- if $chartType -}}/{{$chartType}}{{- end -}}
{{- if $chartConfig.valuesFileName -}}/{{$chartConfig.valuesFileName}}
{{- else -}}/values.yaml{{- end -}}
{{- end }}
{{- end }}
{{- end }}
