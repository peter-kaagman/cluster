# Mprjv65 - Observability via ArgoCD (v3.1)

## Doel
Volledige observability stack declaratief beheren via Git,
met reproduceerbare deployments en gecontroleerde wijzigingen.

---

## Namespace

observability

---

## Repository structuur

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

---

## Deployment volgorde

sync-waves:

- Loki (0)
- Grafana (1)
- Fluent Bit (2)

---

## ArgoCD instellingen

- auto sync: enabled (na initiële validatie)
- prune: enabled
- self-heal: enabled

### Initiële rollout

- eerste deployment handmatig syncen
- validatie uitvoeren (Loki/Grafana/Fluent Bit checks)
- daarna auto-sync inschakelen

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
- dashboards:
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

---

## Security

- geen secrets in Git
- Grafana credentials extern beheren
- netwerktoegang beperken

---

## Rollback strategie

- per component via ArgoCD history
- volgorde:
  1. Fluent Bit
  2. Grafana
  3. Loki (laatste redmiddel)

---

## Validatie na deployment

- ArgoCD status: Healthy + Synced
- Loki bereikbaar: /ready geeft HTTP 200 en een testquery geeft resultaat
- logs zichtbaar in Grafana
- geen crashloops

---

## Observability van observability (minimaal)

Controleren:

- Fluent Bit retries
- Loki ingest errors
- backlog gedrag

Geen aparte monitoring stack vereist in startfase,
maar zicht op fouten is verplicht.