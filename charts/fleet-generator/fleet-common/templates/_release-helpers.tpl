{{/*
Process releases for a given group and return merged releases
Usage: {{ include "fleet-common.processReleases" (dict "context" $ctx "group" $group "releases" .Values.releases) }}
*/}}
{{- define "fleet-common.processReleases" -}}
{{- $ctx := .context }}
{{- $group := .group }}
{{- $releases := .releases }}

{{- /* Find which chart contains this group */ -}}
{{- $chartReleases := dict }}
{{- $found := false }}
{{- range $chart, $chartData := $releases }}
{{- if and (not $found) (index $chartData $group) }}
{{- $chartReleases = $chartData }}
{{- $found = true }}
{{- end }}
{{- end }}

{{- /* Process releases only for the found chart */ -}}
{{- $groupReleases := list }}
{{- if $found }}
{{- $global := $chartReleases.global }}
{{- $releaseNames := index $chartReleases $group }}
{{- if $releaseNames }}
{{- range $groupRelease := $releaseNames }}
  {{- $mergedRelease := merge $groupRelease $global }}
  {{- $mergedRelease = merge $mergedRelease (dict "totalReleases" (len $releaseNames)) }}
  {{- $groupReleases = append $groupReleases $mergedRelease }}
{{- end }}
{{- else }}
{{- $messageRelease := dict 
  "releaseName" "missing-config"
  "error" (printf "Group '%s' has no releases defined in values.yaml" $group)
  "totalReleases" 0
}}
{{- $groupReleases = append $groupReleases $messageRelease }}
{{- end }}
{{- else }}
{{- /* Group not found in any chart */ -}}
{{- $messageRelease := dict 
  "releaseName" "missing-config"
  "error" (printf "Group '%s' not found in any chart releases" $group)
  "totalReleases" 0
}}
{{- $groupReleases = append $groupReleases $messageRelease }}
{{- end }}

{{`{{- $releaseName := .values.releaseName}}`}}
{{`{{- if or (eq $releaseName "") (eq .values.useVersionSelectors "false") -}}`}}
[{{ index $groupReleases 0 | toJson }}]
{{`{{- else }}`}}
{{ $groupReleases | toJson }}
{{`{{- end }}`}}
{{- end }}
