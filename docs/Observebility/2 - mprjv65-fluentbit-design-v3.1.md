# Mprjv65 - Fluent Bit Logging Pipeline (v3.1)

## Doel
Betrouwbare en controleerbare log pipeline naar Loki,
met data-aware verrijking en gecontroleerde resource usage.

---

## Pipeline

RAW -> MULTILINE -> PARSE -> FILTER -> REDACT -> LABEL -> ENRICH -> BUFFER -> OUTPUT

Validatie hoort niet in de dataflow zelf; dat is een runbook- en opleverstap.

---

## Inputs

- /var/log/containers/*.log
- /var/log/syslog (optioneel, beperkt)

Voorkeur:
- container logs prioriteit
- syslog alleen bij noodzaak

---

## Parsing

- JSON detectie (app logs)
- CRI parser (Kubernetes logs)
- syslog parser
- multiline (stacktraces)

Multiline werkt alleen op de logvorm die na eerdere stappen nog beschikbaar is; volgorde en inputstructuur zijn dus bepalend.

---

## Filtering

- drop healthcheck noise
- drop debug logs (optioneel per namespace)
- redact gevoelige patronen:
  - password
  - token
  - api_key

Redactie onderscheidt:
- secrets: altijd maskeren of verwijderen
- PII: alleen redacten als dat functioneel of juridisch nodig is
- operationele context: bij voorkeur behouden

---

## Enrichment

### Labels (lage cardinality)
- cluster
- namespace
- app
- component
- level

Labelwaarden moeten stabiel zijn; ontbrekende waarden worden genormaliseerd of als `unknown` gezet.

### Payload verrijking
- namespace (altijd)
- app (indien mogelijk)
- default values:
  - classification: unknown
  - actor_type: system

---

## Correlatie

- request_id doorgeven indien aanwezig
- niet genereren in Fluent Bit (app verantwoordelijkheid)

---

## Buffering en betrouwbaarheid

Gedrag:

- Loki tijdelijk down:
  -> buffer op disk

- buffer vol:
  -> laag-prioriteit logs eerst droppen (bijv. debug / healthcheck)
  -> audit en security logs behouden indien mogelijk

- disk vol:
  -> oldest data drop als laatste fallback

### Prioriteit logcategorieën

- hoog:
  - audit
  - security

- middel:
  - app

- laag:
  - infra debug
  - healthchecks

### Alerting (minimaal)

- waarschuwing bij >70% buffer gebruik
- kritische alert bij >90% buffer gebruik
- alert bij langdurige retries naar Loki (>5 min)

---

## Richtwaarden

- Flush: 1s
- Grace: 30s
- storage.backlog.mem_limit: 64MB
- Retry_Limit: False

---

## Output

- Loki endpoint in observability namespace
- JSON payload behouden
- labels strikt beperken

## Validatie

- parser/grep gedrag expliciet testen met echte records
- multiline test per logformat of app uitvoeren
- redactie verifiëren op veldniveau
- labels verifiëren op stabiliteit en cardinality

---

## Performance en SLO checks

- geen langdurige retries
- stabiel memory gebruik
- log delivery < 60 sec

---

## Validatie

- Fluent Bit pods blijven stabiel
- geen crashloops
- geen label explosion
- logs zichtbaar in Grafana