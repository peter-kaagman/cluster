#!/usr/bin/env bash
set -euo pipefail

lq='logcli query -q -o raw --addr=http://localhost:3100'

SINCE="${1:-720h}"

echo "== Bing /article hits =="
$lq --since="$SINCE" --limit=5000 '
{job="fluent-bit",service_name="nginx-ingress"}
| json
| line_format "{{.message}}"
| json
| host="mysite.prjv.nl"
| uri=~"/article/.*"
| user_agent=~"(?i).*bing.*"
| line_format "{{.time}}\t{{.remote_addr}}\t{{.uri}}"
' | wc -l

echo
echo "== Google /article hits, UA contains google =="
$lq --since="$SINCE" --limit=5000 '
{job="fluent-bit",service_name="nginx-ingress"}
| json
| line_format "{{.message}}"
| json
| host="mysite.prjv.nl"
| uri=~"/article/.*"
| user_agent=~"(?i).*google.*"
| line_format "{{.time}}\t{{.remote_addr}}\t{{.uri}}"
' | wc -l

echo
echo "== Verified Googlebot /article hits =="
$lq --since="$SINCE" --limit=5000 '
{job="fluent-bit",service_name="nginx-ingress"}
| json
| line_format "{{.message}}"
| json
| host="mysite.prjv.nl"
| uri=~"/article/.*"
| remote_addr=~"66\\.249\\.75\\.(196|197)"
| line_format "{{.time}}\t{{.remote_addr}}\t{{.uri}}"
' | wc -l

echo
echo "== Verified Googlebot /article hits =="
$lq --since="$SINCE" --limit=5000 '
{job="fluent-bit",service_name="nginx-ingress"}
| json
| line_format "{{.message}}"
| json
| host="mysite.prjv.nl"
| uri=~"/article/.*"
| remote_addr=~"66\\.249\\.75\\.(196|197)"
| line_format "{{.time}}\t{{.remote_addr}}\t{{.uri}}"
'