{{/*
Expand the name of the chart.
*/}}
{{- define "acm-certificates-resources.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "acm-certificates-resources.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "acm-certificates-resources.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "acm-certificates-resources.labels" -}}
helm.sh/chart: {{ include "acm-certificates-resources.chart" . }}
{{ include "acm-certificates-resources.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "acm-certificates-resources.selectorLabels" -}}
app.kubernetes.io/name: {{ include "acm-certificates-resources.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "acm-certificates-resources.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "acm-certificates-resources.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
# templates/_helpers.tpl
{{- define "acm-certificates-resources.validateValues" -}}
{{- if not .Values.baseDomain -}}
{{- fail "baseDomain is required" -}}
{{- end -}}
{{- if not .Values.subdomains -}}
{{- fail "subdomains list is required" -}}
{{- end -}}
{{- end -}}
