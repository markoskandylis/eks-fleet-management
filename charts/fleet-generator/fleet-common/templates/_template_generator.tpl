{{/*
Sources Generator
Usage: {{ include "fleet-common.sourceGenerator" }}
*/}}
{{- define "fleet-common.sourceGenerator" -}}
{{- $connectedRepos := .connectedRepos }}
{{`{{- $repoNames := list `}}{{ range $connectedRepos }}"{{ . }}" {{ end }}{{` -}}`}}
{{`{{- range $repoName := $repoNames }}`}}
  - repoURL: '{{`{{default (index $.metadata.annotations (printf "%s_repo_url" $repoName)) (index $ "repoUrl")}}`}}'
    targetRevision: '{{`{{default (index $.metadata.annotations (printf "%s_repo_revision" $repoName)) (index $ "targetRevision")}}`}}'
    ref: {{`{{$repoName}}`}}Values
{{`{{- end }}`}}

{{`{{- if eq .use_helm_repo_path "false" }}`}}
  - repoURL: '{{`{{.helmChartRepo }}`}}'
    chart: '{{`{{.helmChartName }}`}}'
    targetRevision: '{{`{{.version}}`}}'
{{`{{- else }}`}}
  - repoURL: '{{`{{ .metadata.annotations.addons_repo_url }}`}}'
    path: '{{`{{.chartRepoPath }}`}}'
    targetRevision: '{{`{{ default .metadata.annotations.addons_repo_revision .chartRepoRevision}}`}}'
{{`{{- end }}`}}
{{- end }}

{{/*
Generators the values files for the applicaton set
Usage: {{ include "fleet-common.values-path-generator" (dict 
  "reposConfig" $reposConfig
  "connectedRepos" $connectedRepos
  "applicationSetGroup" $group
  "chartName" "fleet-secret"
) }}
*/}}
{{- define "fleet-common.values-path-generator" -}}
{{- $reposConfig := .reposConfig }}
{{- $connectedRepos := .connectedRepos }}
{{- $applicationSetGroup := .applicationSetGroup }}
{{- $chartName := .chartName | default "values" }}
{{- range $repo, $repoConfig := $reposConfig }}
{{- range $connectedRepo := $connectedRepos }}
{{- if eq $connectedRepo $repo }}
{{- $repoRef := printf "%sValues" $repo }}
{{- $basePath := (printf "{{default (index .metadata.annotations \"%s_repo_basepath\") \"%s\"}}" $repo ($repoConfig.repoPath | default "")) }}
{{- if $repoConfig.valueFiles }}
{{- range $repoConfig.valueFiles }}
- {{ $repoRef }}/{{ $basePath }}/{{ . }}
{{- if $applicationSetGroup }}/{{ $applicationSetGroup }}{{ end }}
{{- if $chartName }}/{{ $chartName }}{{ end }}/values.yaml
{{- end }}
{{- else }}
- {{ $repoRef }}/{{ $basePath }}
{{- if $applicationSetGroup }}/{{ $applicationSetGroup }}{{ end }}
{{- if $chartName }}/{{ $chartName }}{{ end }}/values.yaml
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

