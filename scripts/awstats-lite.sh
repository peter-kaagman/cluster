#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-nginx-ingress}"
POD_LABEL="${POD_LABEL:-app.kubernetes.io/component=controller}"
SINCE_HOURS="${1:-24}"
TOP_N="${TOP_N:-10}"

if ! [[ "$SINCE_HOURS" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 [hours]" >&2
  echo "Example: $0 24" >&2
  exit 1
fi

if ! [[ "$TOP_N" =~ ^[0-9]+$ ]]; then
  echo "TOP_N must be a positive integer." >&2
  exit 1
fi

POD_NAME="$(kubectl get pod -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
if [[ -z "$POD_NAME" ]]; then
  echo "No ingress controller pod found in namespace '$NAMESPACE' with label '$POD_LABEL'." >&2
  exit 1
fi

kubectl logs -n "$NAMESPACE" "$POD_NAME" --since="${SINCE_HOURS}h" \
| awk -v top_n="$TOP_N" -v since_hours="$SINCE_HOURS" '
function map_site(up) {
  if (up == "happyminds-wordpress-happyminds-80") return "happyminds.nl"
  if (up == "inspiration-wordpress-inspiration-80") return "inspiration.prjv.nl"
  if (up == "mysite-mysite-service-5000") return "mysite.prjv.nl"
  return up
}

function looks_like_bot(ua_lc) {
  return (ua_lc ~ /(bot|crawler|spider|slurp|bingpreview|headless|curl|wget)/)
}

function is_page_request(method, path, status) {
  if (method != "GET") return 0
  if (status !~ /^(2|3)/) return 0
  if (path ~ /\.(css|js|png|jpe?g|gif|svg|ico|woff2?|map|txt|xml|webp|avif)$/) return 0
  return 1
}

function print_top_site_metric(arr, site, title, limit,    key, parts, item, max_item, max_val, i, has_data) {
  print ""
  print title ":"
  has_data = 0

  delete tmp
  for (key in arr) {
    split(key, parts, SUBSEP)
    if (parts[1] == site) {
      tmp[parts[2]] = arr[key]
      has_data = 1
    }
  }

  if (!has_data) {
    print "  (geen data)"
    return
  }

  for (i = 1; i <= limit; i++) {
    max_item = ""
    max_val = -1
    for (item in tmp) {
      if (tmp[item] > max_val) {
        max_val = tmp[item]
        max_item = item
      }
    }

    if (max_val < 0) break

    printf("  - %s: %d\n", max_item, max_val)
    delete tmp[max_item]
  }
}

function json_get(line, key,    p, s, val, tail, q) {
  val = ""
  p = "\"" key "\":\""
  s = index(line, p)
  if (s == 0) return val
  s += length(p)
  tail = substr(line, s)
  q = match(tail, /"/)
  if (q == 0) return val
  val = substr(tail, 1, q - 1)
  return val
}

function json_get_num(line, key,    p, s, t) {
  p = "\"" key "\":"
  s = index(line, p)
  if (s == 0) return ""
  s += length(p)
  t = substr(line, s)
  if (match(t, /^[0-9]+/)) return substr(t, 1, RLENGTH)
  return ""
}

BEGIN {
  print "AWStats-lite bezoekersrapport"
  printf("Periode: laatste %s uur\n", since_hours)
  print "Bron: nginx-ingress access logs"
  print ""
}

{
  method = "-"
  path = "-"
  status = "000"
  ua = "-"
  ip = "-"
  site = ""

  if ($0 ~ /^\{/) {
    upstream = json_get($0, "upstream")
    if (upstream == "") next

    site = map_site(upstream)
    if (site !~ /^(happyminds.nl|inspiration.prjv.nl|mysite.prjv.nl)$/) next

    ip = json_get($0, "remote_addr")
    method = json_get($0, "method")
    path = json_get($0, "uri")
    status = json_get_num($0, "status")
    ua = json_get($0, "user_agent")
    if (status == "") status = "000"
    if (ua == "") ua = "-"
  } else {
    if (!match($0, /\[(happyminds-wordpress-happyminds-80|inspiration-wordpress-inspiration-80|mysite-mysite-service-5000)\]/, u)) {
      next
    }

    site = map_site(u[1])
    ip = $1

    if (match($0, /"([A-Z]+) ([^ ]+) HTTP\/[0-9.]+"/, r)) {
      method = r[1]
      path = r[2]
    }

    if (match($0, /" ([0-9]{3}) [0-9]+ /, s)) {
      status = s[1]
    }

    split($0, q, "\"")
    ua = (length(q) >= 6 ? q[6] : "-")
  }
  sites[site] = 1

  if (!(site SUBSEP ip in unique_ip_seen)) {
    unique_ip_seen[site SUBSEP ip] = 1
    unique_ips[site]++
  }
  ua_lc = tolower(ua)

  # Maak pagina-overzichten leesbaar door querystring te strippen.
  clean_path = path
  sub(/\?.*$/, "", clean_path)

  total_hits[site]++
  status_counts[site SUBSEP status]++
  ua_counts[site SUBSEP ua]++

  if (looks_like_bot(ua_lc)) {
    bot_hits[site]++
  } else {
    human_hits[site]++
  }

  if (is_page_request(method, clean_path, status) && clean_path != "/wp-cron.php") {
    page_hits[site SUBSEP clean_path]++
  }
}

END {
  for (site in sites) {
    print "========================================"
    print "Site: " site
    print "========================================"
    printf("Hits totaal: %d\n", total_hits[site] + 0)
    printf("Unieke IPs: %d\n", unique_ips[site] + 0)
    printf("Bots (heuristiek): %d\n", bot_hits[site] + 0)
    printf("Menselijke hits (heuristiek): %d\n", human_hits[site] + 0)

    print_top_site_metric(status_counts, site, "Status codes", 10)
    print_top_site_metric(page_hits, site, "Top paginas", top_n)
    print_top_site_metric(ua_counts, site, "Top user agents", top_n)
    print ""
  }

  if (length(sites) == 0) {
    print "Geen logregels gevonden voor de drie doel-sites in de gekozen periode."
    exit 1
  }
}
'