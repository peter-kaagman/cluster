# Semantic Conventions — Mprjv65

## Doel

Dit document beschrijft de minimale semantische metadata voor workloads binnen het Mprjv65 platform.

Het doel is om:

- Relaties tussen services expliciet te maken
- Context toe te voegen bovenop Kubernetes runtime state
- Observability te verrijken met betekenis (semantic layer)
- Een fundament te leggen voor AI/AIOps use-cases

De semantic layer is nadrukkelijk een **overlay**:
- Kubernetes = runtime truth
- Declaratieve metadata = betekenis / intentie

---

## Ontwerpprincipes

- Declaratief (Git is source of truth)
- Zo dicht mogelijk bij de bron (Argo Application / manifests)
- Geen duplicatie van runtime-informatie
- Consistent naming (canonical names)
- Minimalistisch (start small, expand later)

---

## Core Labels

Alle semantiek wordt vastgelegd via labels (en optioneel annotations).

Pragmatische richtlijn:

- Labels: alleen velden die stabiel zijn en query-waarde hebben
- Annotations: governance/contextvelden met mogelijk hogere cardinality

Prefix:
`mprjv65/*`

---

## 1. service (verplicht)

Canonical naam van de service.

`mprjv65/service=`

### Voorbeeld

`mprjv65/service=wordpress`
`mprjv65/service=mysql`

### Regels

- lowercase
- geen varianten (mysql ≠ mysql-db ≠ db-mysql)
- één naam per service

---

## 2. type (verplicht)

Functionele laag in de stack.

`mprjv65/type=`

### Toegestane waarden

- `infrastructure`
- `platform`
- `service`
- `edge`

### Betekenis

| Type | Omschrijving |
|------|-------------|
| infrastructure | Compute, storage, netwerk |
| platform | Databases, middleware, shared services |
| service | Business/logische services |
| edge | Entry points (ingress, frontend, API gateway) |

---

## 3. role (optioneel maar aanbevolen)

Specifieke functie binnen het type.

`mprjv65/role=`

### Voorbeelden

- `frontend`
- `backend`
- `database`
- `ingress`
- `cache`
- `queue`
- `storage`

---

### 4. depends_on (optioneel maar belangrijk)

Beschrijft logische afhankelijkheden tussen services inclusief hun scope (relationele context).

Formaat:

mprjv65/depends_on=<service>:<scope>[,<service>:<scope>]

#### Voorbeelden

mprjv65/depends_on=mysql:shared
mprjv65/depends_on=mysql:shared
mprjv65/depends_on=weather-api:external

#### Regels

- Gebruik canonical service namen
- Alleen directe afhankelijkheden
- Geen transitive dependencies modelleren
- Iedere dependency MOET een scope hebben
- Waarden alfabetisch sorteren op servicenaam (deterministisch)
- Geen duplicaten
- Geen spaties in de expressie
- Maximaal 5 dependencies per service (startfase)
- Als dit structureel te krap is: model uitbreiden, niet ad-hoc omzeilen
- Services zonder dependencies mogen het label niet bevatten

#### Scope definitie

Scope beschrijft de aard van de dependency (de relatie tussen services), en is onderdeel van de dependency.

De volgende waarden zijn toegestaan:

- shared  
  Resource binnen het cluster, gedeeld door meerdere services

- external  
  Resource buiten het cluster of buiten beheer (bijv. externe API)

#### Belangrijke principes

- Scope hoort bij de relatie, niet bij de service zelf
- Een service kan meerdere dependencies hebben met verschillende scopes
- Toegestane scopes zijn bewust beperkt tot: shared, external
- `local` is gereserveerd voor een latere use-case, maar mag voorlopig niet gebruikt worden
- Nieuwe scopes alleen toevoegen bij meerdere concrete use-cases (geen theoretische uitbreidingen)


---

## 5. storage (optioneel)

Storage backend (indien relevant).

`mprjv65/storage=`

### Voorbeelden

- `nfs`
- `local`
- `ceph`

Opmerking:
Veel storage-relaties zijn al af te leiden vanuit Kubernetes (PVC), dit veld is ondersteunend.

---

## 6. criticality (optioneel)

Impact bij failure.

`mprjv65/criticality=`

### Waarden

- `low`
- `medium`
- `high`

---

## 7. owner (optioneel)

Verantwoordelijke partij.

Voorkeur: annotation i.p.v. label (cardinality beperken).

`mprjv65/owner=`

---

## Waar toepassen

### 1. Argo Application (voorkeur)

Service-level semantiek:

```yaml
metadata:
  labels:
    mprjv65/service: wordpress
    mprjv65/type: service
    mprjv65/role: frontend
    mprjv65/depends_on: mysql:shared
  annotations:
    mprjv65/owner: team-web
```

### 2. Kubernetes manifests (aanvullend)

Voor lokale context:

```yaml
metadata:
  labels:
    mprjv65/role: database
    mprjv65/storage: nfs
  annotations:
    mprjv65/owner: team-data
```

## Implementatieprofiel (MVP)

Voor eerste tests in Argo manifests is dit de minimale set:

- Verplicht labels: `mprjv65/service`, `mprjv65/type`
- Aanbevolen label: `mprjv65/depends_on`
- Optioneel annotation: `mprjv65/owner`

Voorbeeld (MVP):

```yaml
metadata:
  labels:
    mprjv65/service: wordpress
    mprjv65/type: service
    mprjv65/depends_on: redis:shared,mysql:shared
  annotations:
    mprjv65/owner: team-web
```

## Wat NIET modelleren
Niet opnemen in semantiek:

- Pod -> Node relaties (runtime)
- PVC -> Storage binding (runtime)
- Scaling / replica status

Dit zit al in Kubernetes.

## Conceptueel model
De stack bestaat uit:

- Kubernetes:
  - runtime state

- Argo:
  - service grouping

- Semantic labels:
  - relaties + betekenis

- AI / tooling:
  - correlatie + interpretatie


## Voorbeeld (compleet)

```yaml
# WordPress
metadata:
  labels:
    mprjv65/service: wordpress
    mprjv65/type: service
    mprjv65/role: frontend
    mprjv65/depends_on: memcached:shared,mysql:shared
    mprjv65/criticality: medium
  annotations:
    mprjv65/owner: team-web

# MySQL
metadata:
  labels:
    mprjv65/service: mysql
    mprjv65/type: platform
    mprjv65/role: database
    mprjv65/storage: nfs
    mprjv65/criticality: high
  annotations:
    mprjv65/owner: team-data

# NFS
metadata:
  labels:
    mprjv65/service: nfs
    mprjv65/type: infrastructure
  annotations:
    mprjv65/owner: team-platform

# Service zonder dependencies
metadata:
  labels:
    mprjv65/service: standalone-service
    mprjv65/type: service    
```

## Toekomstige uitbreidingen
Mogelijke uitbreiding:

- latency relationships
- network zones
- data sensitivity
- SLA/SLO targets

Niet nu implementeren — alleen als nodig.

## Samenvatting

- Kubernetes vertelt wat er draait
- Semantiek vertelt wat het betekent
- AI gebruikt beide om te redeneren

Dit document beschrijft de minimale basis hiervoor.

## Enforcement (praktisch)

Aanbevolen controles vóór merge:

- `mprjv65/service` en `mprjv65/type` zijn verplicht
- `mprjv65/service` is lowercase en canonical (geen varianten)
- `mprjv65/depends_on` bevat alleen canonical service namen met geldige scope in het format `service:scope`
- `mprjv65/depends_on` is alfabetisch gesorteerd en zonder duplicaten
- `mprjv65/depends_on` is optioneel, er kan ook geen dependency zijn 
- owner staat bij voorkeur als annotation

Start simpel:

1. Handmatige review met checklist
2. Daarna policy/lint in CI (bijv. OPA/Kyverno of script)

---

