# Mprjv65 - Observability via ArgoCD (v3.2)

## Doel

Volledige observability stack declaratief beheren via Git,
met reproduceerbare deployments en gecontroleerde wijzigingen.

Daarnaast fungeert ArgoCD als bron van semantische metadata (semantic layer)
binnen het platform.

## Scope

Dit document beschrijft:

1. Deployment van de observability stack via ArgoCD
2. Toepassing van semantische metadata via ArgoCD manifests

---

## Ontwerpprincipes

- declaratief (Git als source of truth)
- reproduceerbare deployments
- scheiding tussen deployment, transport en interpretatie
- semantiek wordt gedeclareerd, niet afgeleid
- ArgoCD is bron van zowel infrastructuur als intentie

---

## Namespace

observability

---

## Repository structuur

```
observability/
  loki/
    application.yaml
    values.yaml
  grafana/
    application.yaml
    values.yaml
  dashboards/
  datasources/
  fluent-bit/
    application.yaml
    values.yaml
  namespace.yaml
  networkpolicy.yaml
  kustomization.yaml
```

---

## Deployment

### Volgorde

sync-waves:
- Loki (0)
- Grafana (1)
- Fluent Bit (2)

### ArgoCD instellingen

- auto sync: enabled (na initiële validatie)
- prune: enabled
- self-heal: enabled

#### Initiële rollout

- eerste deployment handmatig syncen
- validatie uitvoeren (Loki/Grafana/Fluent Bit checks)
- daarna auto-sync inschakelen

---

## Semantic metadata

ArgoCD is de bron van declaratieve semantiek binnen het platform.

Semantic metadata wordt gedefinieerd in Application manifests via:

### Labels (laag-cardinality)
- mprjv65/service
- mprjv65/type
- mprjv65/role (optioneel)

### Annotations
- mprjv65/depends-on
- mprjv65/owner (optioneel)

Deze metadata wordt:
- meegedeployd naar Kubernetes resources
- gebruikt door observability tooling (labels)
- gebruikt voor interpretatie en analyse (annotations)

---

## Relatie met observability

De via ArgoCD gedeployde metadata wordt gebruikt in observability:

### Labels
- gebruikt voor filtering en aggregatie
- zichtbaar in logs en metrics

### Annotations
- niet gebruikt voor filtering
- gebruikt voor interpretatie en correlatie
- niet verwerkt in de logging pipeline (Fluent Bit)

Dit resulteert in:

- runtime observability (wat gebeurt er)
- + declaratieve semantiek (wat zou moeten gebeuren)

Annotations worden niet via Fluent Bit getransporteerd naar logs.
Ze blijven beschikbaar via Kubernetes metadata en worden gebruikt door tooling
die direct de Kubernetes API raadpleegt.

---

## Declarative vs observed

ArgoCD definieert de intended state van het systeem:

- services
- rollen
- afhankelijkheden (mprjv65/depends-on)

Observability toont de observed state:

- logs
- metrics
- traces

Verschillen tussen beide zijn relevante signalen:

- ontbrekende dependency -> configuratiefout
- extra dependency -> onverwachte koppeling
- afwijkend gedrag -> mogelijk incident of security issue

---

## Verschil tussen sync-waves en depends-on

- sync-waves:
  - bepalen deployment volgorde binnen ArgoCD
  - technisch/infrastructureel

- mprjv65/depends-on:
  - beschrijft logische afhankelijkheden tussen services
  - heeft geen effect op deployment volgorde
  - wordt gebruikt voor observability en analyse

---

## Loki ontwerp

Start:
- SingleBinary mode
- filesystem storage (NFS)

Minimaal configureren:
- retention policies
- ingestion rate limits
- query limits
- stream limits (cardinality bescherming)

---

## Grafana ontwerp

- Loki default datasource

Dashboards:
- cluster logs
- namespace overzicht
- app errors

Gebruik:
- Explore voor adhoc queries
- dashboards voor standaard use cases

---

## Fluent Bit (deployment)

- DaemonSet op alle nodes
- output naar Loki service
- config volgt Fluent Bit design document
- deployment volgt het expliciete pipeline-contract

---

## Security

- geen secrets in Git
- Grafana credentials extern beheren
- netwerktoegang beperken

---

## Rollback strategie

- per component via ArgoCD history

Volgorde:
- Fluent Bit
- Grafana
- Loki (laatste redmiddel)

---

## Validatie na deployment

- ArgoCD status: Healthy + Synced
- Loki bereikbaar: /ready geeft HTTP 200
- testquery geeft resultaat
- logs zichtbaar in Grafana

Technische checks:
- geen crashloops
- parser/grep gedrag klopt met echte records
- multiline vormt 1 logisch event
- redactie verifieerbaar op veldniveau

Semantische checks:
- mprjv65/service en mprjv65/type aanwezig
- labels consistent toegepast
- geen ongewenste labelgroei
- depends-on alleen aanwezig waar relevant

---

## Observability van observability (minimaal)

Controleren:
- Fluent Bit retries
- Loki ingest errors
- backlog gedrag
- semantische correctheid van metadata (labels), niet alleen beschikbaarheid

Geen aparte monitoring stack vereist in startfase,
maar zicht op fouten is verplicht.
