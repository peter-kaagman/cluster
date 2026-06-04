# Mprjv65 - Observability and Data-Aware Logging Design (v3.1)

## Doel
Een observability stack neerzetten die:
- operationeel stabiel is
- bruikbaar is voor operations, auditing en security
- data governance ondersteunt via classificatie

## Scope
Focus op logs.

Metrics en tracing volgen later, maar:
- correlatie (request_id / trace_id) wordt nu al meegenomen
- logstructuur voorkomt latere refactor

## Architectuur
Workloads -> Fluent Bit -> Loki -> Grafana

## Ontwerpprincipes
- logs zijn events met context
- JSON waar mogelijk
- schema-on-read (Loki)
- lage cardinality labels
- data-aware velden in payload (niet als label)
- logging is een contract, geen best effort

---

## Logdomeinen
- infra
- app
- identity
- audit
- security

---

## Labelbeleid

### Toegestaan (lage cardinality)
- cluster
- namespace
- app
- component
- level

### Niet toegestaan als label (wel in JSON)
- classification
- action
- actor
- target
- user
- request_id
- trace_id

---

## Data-aware logmodel

### Standaardvelden (aanbevolen)
- ts
- level
- message
- app

### Data-aware velden
- classification: public | internal | confidential | restricted
- action: create | read | update | delete | login | download
- actor_type: user | service | system
- actor_id: identifier
- target_type: internal | external | system
- target_id: resource
- outcome: success | denied | error

### Correlatie
- request_id (verplicht voor app logs)
- trace_id (optioneel, future tracing)

---

## Logging contract (minimaal)

Elke applicatie logt minimaal:
- timestamp
- level
- message

Aanbevolen:
- app naam

Normatief verplicht voor applicatie logs (soft enforcement in startfase):
- request_id

Data-aware logging:
- verplicht voor audit en security domeinen

Fallback gedrag:
- ontbrekende velden worden gemarkeerd als "unknown"
- ontbreken van request_id wordt gelogd als waarschuwing (policy breach), maar blokkeert ingest niet


---

## Retentie en kosten

Startwaarden:
- public: 14 dagen
- internal: 30 dagen
- confidential: 30-60 dagen
- restricted: 60+ dagen (of extern archief)

Globaal:
- ingest limieten instellen
- query limits instellen
- cardinality beperken via labelbeleid

---

## Security baseline

- namespace isolation via NetworkPolicies
- Grafana achter auth
- secrets via External Secrets
- TLS op ingress

### Log integrity (minimaal)
- apps schrijven logs, niet muteren
- logging pipeline (Fluent Bit) is enige forwarder
- geen directe app -> Loki route

---

## Operationele SLO

### Log ingest availability
- Doel: 99.9%
- SLI: percentage succesvolle log deliveries naar Loki
- Bron: Fluent Bit output status / retries
- Meetvenster: rolling 30 dagen

### Log latency
- Doel: < 60 seconden
- SLI: tijd tussen log creatie en zichtbaarheid in Grafana
- Bron: timestamp verschil (event vs ingest)
- Meetvenster: rolling 24 uur

### Dropped logs
- Doel: < 1% per 24 uur
- SLI: aantal dropped records vs totaal aantal records
- Bron: Fluent Bit metrics
- Meetvenster: rolling 24 uur

---

## Acceptatiecriteria

- alle namespaces leveren logs
- geen label explosion
- basis dashboards werken (namespace/app)
- geen plaintext secrets
- Fluent Bit blijft stabiel onder load