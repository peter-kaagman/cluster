# Mprjv65 - Observability and Data-Aware Logging Design (v3.2)

## Doel

Een observability stack neerzetten die:
- operationeel stabiel is
- bruikbaar is voor operations, auditing en security
- data governance ondersteunt via classificatie
- semantische context integreert voor interpretatie en correlatie

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
- validatie gebeurt in runbook / oplevercriteria, niet als pipeline-transform

### Semantic enrichment

Naast runtime metadata (labels, namespace, app) wordt observability verrijkt met declaratieve semantiek uit de semantic layer.

Bron:
- Kubernetes labels (laag-cardinality metadata)
- Kubernetes annotations (semantische context, zoals mprjv65/depends-on)

Doel:
- logs interpreteerbaar maken in context van service-relaties
- correlatie mogelijk maken tussen events en systeemgedrag
- voorbereiding op service graph analyse en AI/AIOps use-cases

## Logdomeinen
- infra
- app
- identity
- audit
- security

## Labelbeleid

### Toegestaan (lage cardinality)
- cluster
- namespace
- app
- component
- level
- mprjv65/service
- mprjv65/type
- mprjv65/role

### Niet toegestaan als label (wel in JSON)
- classification
- action
- actor
- target
- user
- request_id
- trace_id
- mprjv65/depends-on

Semantische annotations (zoals mprjv65/depends-on) mogen niet als label worden gemapt,
om cardinality en query-complexiteit te beperken.

app en mprjv65/service kunnen gelijk zijn, maar hebben een verschillende rol:
- app: runtime identificatie uit logs
- mprjv65/service: canonieke semantische identiteit

Waar mogelijk worden deze gelijk gehouden om complexiteit te beperken.

### Label fallback
- labels worden alleen gebruikt als ze stabiel en aanwezig zijn
- ontbrekende labelwaarden worden genormaliseerd of expliciet als unknown behandeld

## Data-aware logmodel

### Standaardvelden (aanbevolen)
- ts
- level
- message
- app

### Data-aware velden
- classification: public  internal  confidential  restricted
- action: create  read  update  delete  login  download
- actor_type: user  service  system
- actor_id: identifier
- target_type: internal  external  system
- target_id: resource
- outcome: success  denied  error

### Semantische context (extern)

De volgende context komt niet uit de log zelf, maar uit declaratieve metadata:

- service (mprjv65/service)
- type (mprjv65/type)
- afhankelijkheden (mprjv65/depends-on)

Deze worden niet als label gebruikt, maar kunnen door tooling worden gebruikt voor interpretatie en correlatie.

Deze context wordt niet uit de log zelf gehaald, maar uit Kubernetes metadata.

### Correlatie
- request_id (verplicht voor app logs)
- trace_id (optioneel, future tracing)
- service-level correlatie via mprjv65/service
- relationele correlatie via mprjv65/depends-on (semantic layer)

### Gevoelige data
- secrets: altijd maskeren of verwijderen
- PII: contextafhankelijk redacten
- operationele context: bij voorkeur behouden

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
- labels mogen niet afhankelijk zijn van ongestructureerde of instabiele bronwaarden

## Declarative vs observed gedrag

Het systeem kent twee vormen van relatie-informatie:

Declaratief:
- gedefinieerd via mprjv65/depends-on (Git)

Geobserveerd:
- zichtbaar via logs, metrics en traces (runtime gedrag)

Verschillen tussen beide zijn relevante signalen:

- ontbrekende dependency -> configuratiefout
- extra dependency -> onverwachte koppeling
- afwijkend gedrag -> mogelijk incident of security issue

Deze vergelijking vormt de basis voor geavanceerde analyse en AI/AIOps use-cases.

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

## Security baseline
- namespace isolation via NetworkPolicies
- Grafana achter auth
- secrets via External Secrets
- TLS op ingress

### Log integrity (minimaal)
- apps schrijven logs, niet muteren
- logging pipeline (Fluent Bit) is enige forwarder
- geen directe app -> Loki route

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

## Acceptatiecriteria
- alle namespaces leveren logs
- geen label explosion
- basis dashboards werken (namespace/app)
- geen plaintext secrets
- Fluent Bit blijft stabiel onder load
