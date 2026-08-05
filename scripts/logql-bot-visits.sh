#!/usr/bin/env bash
set -euo pipefail

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required but not installed." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but not installed." >&2
  exit 1
fi

LOKI_URL="${LOKI_URL:-http://loki.observability.svc.cluster.local:3100}"
SINCE_DAYS="${1:-30}"
HOST_REGEX="${2:-.*}"
BOT_REGEX="${BOT_REGEX:-googlebot|bingbot}"
LIMIT="${LIMIT:-5000}"

if ! [[ "$SINCE_DAYS" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 [since_days] [host_regex]" >&2
  echo "Example: $0 30 'happyminds.nl|mysite.prjv.nl'" >&2
  exit 1
fi

if ! [[ "$LIMIT" =~ ^[0-9]+$ ]]; then
  echo "LIMIT must be a positive integer." >&2
  exit 1
fi

START="$(date -u -d "${SINCE_DAYS} days ago" +%s)000000000"
END="$(date -u +%s)000000000"

QUERY="{job=\"fluent-bit\",service_name=\"nginx-ingress\"} \
| json \
| line_format \"{{.message}}\" \
| json \
| host=~\"${HOST_REGEX}\" \
| user_agent=~\"(?i).*(${BOT_REGEX}).*\" \
| line_format \"{{.time}}\\thost={{.host}}\\tstatus={{.status}}\\turi={{.uri}}\\tua={{.user_agent}}\""

curl -sG "$LOKI_URL/loki/api/v1/query_range" \
  --data-urlencode "query=$QUERY" \
  --data-urlencode "start=$START" \
  --data-urlencode "end=$END" \
  --data-urlencode "limit=$LIMIT" \
| jq -r '
    if .status != "success" then
      .error // "Loki query failed"
    else
      .data.result[].values[]?[1]
    end
  ' \
| sort
