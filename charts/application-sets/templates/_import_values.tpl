{{/*
Import and merge values from component files based on enabled flags
*/}}
{{- define "application-sets.importValues" -}}
{{- $result := dict -}}

{{/* Import addons values if enabled */}}
{{- if and .Values.mergeValues .Values.mergeValues.addons (eq (toString (default false .Values.mergeValues.addons.use)) "true") -}}
  {{- $addonsValues := .Files.Get "values/addons.yaml" | fromYaml -}}
  {{- if $addonsValues -}}
    {{- $result = merge $result $addonsValues -}}
  {{- end -}}
{{- end -}}

{{/* Import monitoring values if enabled */}}
{{- if and .Values.mergeValues .Values.mergeValues.monitoring (eq (toString (default false .Values.mergeValues.monitoring.use)) "true") -}}
  {{- $monitoringValues := .Files.Get "values/monitoring.yaml" | fromYaml -}}
  {{- if $monitoringValues -}}
    {{- $result = merge $result $monitoringValues -}}
  {{- end -}}
{{- end -}}

{{/* Import ACK values if enabled */}}
{{- if and .Values.mergeValues .Values.mergeValues.ack (eq (toString (default false .Values.mergeValues.ack.use)) "true") -}}
  {{- $ackValues := .Files.Get "values/ack.yaml" | fromYaml -}}
  {{- if $ackValues -}}
    {{- $result = merge $result $ackValues -}}
  {{- end -}}
{{- end -}}

{{/* Return the merged values */}}
{{- $result | toYaml -}}
{{- end -}}