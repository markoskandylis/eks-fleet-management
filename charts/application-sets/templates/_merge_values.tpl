{{/*
Merge imported values and bootstrap values with proper precedence
*/}}
{{- define "application-sets.mergeValues" -}}
{{- $importedValues := dict }}

{{/* Only import values if mergeValues is defined */}}
{{- if .Values.mergeValues }}
  {{- $importedValues = include "application-sets.importValues" . | fromYaml }}
{{- end }}

{{/* Create a merged values structure with proper precedence */}}
{{- $defaultValues := dict }}
{{- $mergedValues := dict }}

{{/* First, add all imported values as defaults */}}
{{- $defaultValues = merge $defaultValues $importedValues }}

{{/* Then, for each component in bootstrap values, check if it should override or use default */}}
{{- range $key, $value := .Values }}
  {{- if and (kindIs "map" $value) (hasKey $value "enabled") }}
    {{/* If component is defined in bootstrap, use that value */}}
    {{- $_ := set $mergedValues $key $value }}
  {{- else if hasKey $defaultValues $key }}
    {{/* Otherwise, if it exists in defaults, use that */}}
    {{- $_ := set $mergedValues $key (index $defaultValues $key) }}
  {{- else }}
    {{/* For non-component values, just copy them */}}
    {{- $_ := set $mergedValues $key $value }}
  {{- end }}
{{- end }}

{{/* Add any components from defaults that aren't in bootstrap */}}
{{- range $key, $value := $defaultValues }}
  {{- if not (hasKey $mergedValues $key) }}
    {{- $_ := set $mergedValues $key $value }}
  {{- end }}
{{- end }}

{{/* Return the merged values */}}
{{- $mergedValues | toYaml }}
{{- end -}}