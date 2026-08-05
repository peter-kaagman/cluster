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
STEP="${STEP:-24h}"

if ! [[ "$SINCE_DAYS" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 [since_days] [host_regex]" >&2
  echo "Example: $0 30 'happyminds.nl|mysite.prjv.nl'" >&2
  exit 1
fi

START="$(date -u -d "${SINCE_DAYS} days ago" +%s)000000000"
END="$(date -u +%s)000000000"

query_for_bot() {
  local bot="$1"
  cat <<EOF
sum(count_over_time({job="fluent-bit",service_name="nginx-ingress"}
| json
| line_format "{{.message}}"
| json
| host=~"${HOST_REGEX}"
| user_agent=~"(?i).*${bot}.*"
[24h]))
EOF
}

run_query() {
  local name="$1"
  local q="$2"

  echo "### ${name}"
  curl -sG "$LOKI_URL/loki/api/v1/query_range" \
    --data-urlencode "query=$q" \
    --data-urlencode "start=$START" \
    --data-urlencode "end=$END" \
    --data-urlencode "step=$STEP" \
  | jq -r '
      if .status != "success" then
        .error // "Loki query failed"
      else
        (.data.result[0].values // [])[]
        | ([.[0], .[1]] | @tsv)
      end
    ' \
  | awk -F'\t' '
      BEGIN { OFS="\t"; print "date", "count" }
      {
        cmd = "date -u -d @" int($1/1000000000) " +%F"
        cmd | getline d
        close(cmd)
        print d, $2
      }
    '
  echo
}

run_query "Googlebot per day" "$(query_for_bot googlebot)"
run_query "Bingbot per day" "$(query_for_bot bingbot)"
