{{/*
Expand the name of the chart.
*/}}
{{- define "ibkr-gateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ibkr-gateway.fullname" -}}
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
{{- define "ibkr-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Extract version of IB Gateway
*/}}
{{- define "ibkr-gateway.version" -}}
{{- if .Values.image.tag }}
{{- printf "%s" .Values.image.tag | replace "." "" | trunc 4 }}
{{- else }}
{{- printf "%s" .Chart.AppVersion | replace "." "" | trunc 4 }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ibkr-gateway.labels" -}}
helm.sh/chart: {{ include "ibkr-gateway.chart" . }}
{{ include "ibkr-gateway.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ibkr-gateway.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ibkr-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ibkr-gateway.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ibkr-gateway.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
