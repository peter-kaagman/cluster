# Semantic Model

## Doel

Dit document beschrijft de minimale semantische metadata voor workloads binnen het Mprjv65 platform.

Het doel is om:

- Relaties tussen services expliciet te maken  
- Context toe te voegen bovenop Kubernetes runtime state  
- Observability te verrijken met betekenis (semantic layer)  
- Een fundament te leggen voor AI/AIOps use cases  

De semantic layer is nadrukkelijk een **overlay**:

- Kubernetes = runtime truth  
- Declaratieve metadata = betekenis en intentie  

Met "semantiek" wordt bedoeld: metadata die betekenis en relaties toevoegt,
en niet alleen dient voor technische identificatie.

### Rol van Semantiek

Semantische labels en annotaties beschrijven de context, intentie en relaties van services.

De huidige focus van dit model ligt op observability:

- Verrijken van runtime data met betekenis  
- Expliciet maken van relaties tussen services  
- Ondersteunen van analyse en interpretatie  

Observability is hiermee een eerste en concrete toepassing van de semantische laag, maar niet de enige.

Semantiek fungeert als een generieke informatielaag en kan gebruikt worden als input voor andere toepassingen, zoals policy enforcement en platform governance.

Deze toepassingen vallen buiten de scope van dit document en worden op dit moment niet verder uitgewerkt. Indien nodig worden aanvullende labels of annotaties toegevoegd op het moment dat deze use-cases zich aandienen.

Vuistregel:

Semantiek informeert; interpretatie en gedrag worden bepaald door andere lagen.


## Ontwerpprincipes

- Declaratief (Git is source of truth)
- Zo dicht mogelijk bij de bron (Argo Application / manifests)
- Geen duplicatie van runtime-informatie
- Consistent naming (canonical names)
- Minimalistisch (start small, expand later)


## Core Labels

Alle semantiek wordt vastgelegd via labels (en optioneel annotations).

Pragmatische richtlijn:

- Labels: alleen velden die stabiel zijn en query-waarde hebben
- Annotations: governance/contextvelden met mogelijk hogere cardinality

Prefix:
`mprjv65/*`


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

### 4. depends-on (optioneel maar belangrijk)

Beschrijft functionele afhankelijkheden tussen services.

Formaat:

mprjv65/depends-on=<service>[,<service>]

#### Voorbeelden

mprjv65/depends-on=mysql  
mprjv65/depends-on=memcached,mysql  

#### Semantiek

Dependencies representeren relaties die:
- noodzakelijk zijn voor het functioneren van een service
- niet direct afleidbaar zijn uit Kubernetes runtime state

Dependencies modelleren daarmee **functionele afhankelijkheden**, geen technische of infrastructurele wiring.

#### Regels

- Is een annotation (geen label)
- Bevat alleen canonical service namen
- Alleen directe afhankelijkheden (geen transitieve relaties)
- Geen duplicaten
- Geen spaties
- Alfabetisch gesorteerd (deterministisch)
- Richtlijn: maximaal 5 dependencies per service
- Services zonder afhankelijkheden hebben deze annotation niet

#### Niet modelleren als dependency

De volgende relaties worden **niet** gemodelleerd, omdat deze al onderdeel zijn van Kubernetes runtime state of infrastructuurgedrag:

- Ingress / routing (edge-relaties)
- Netwerkconnectiviteit
- Storage binding (PVC ↔ storage backend)
- Kubernetes-native relaties (Pods, Services, Nodes, etc.)

#### Vuistregel

"Als Kubernetes de relatie al kent, wordt deze niet opnieuw semantisch vastgelegd."

#### Scope

Scope is verwijderd uit het model omdat deze geen onderscheidende waarde bood.
Dependencies worden uitsluitend op servicenaam gemodelleerd.

## 5. storage (optioneel)

Semantische classificatie van de storage-gedragingen van een service.

`mprjv65/storage=`

### Voorbeelden

- `nfs`
- `local`
- `ceph`

### Doel

Dit veld beschrijft de *karakteristiek* van storage
vanuit het perspectief van de service:

- performance eigenschappen (latency, throughput)
- availability implicaties (shared vs node-local)
- architectuurkeuzes

### Belangrijk onderscheid

De feitelijke storageconfiguratie (PVC, StorageClass, binding)
is onderdeel van Kubernetes runtime state.

Dit veld is geen duplicatie van die configuratie,
maar een vereenvoudigde semantische representatie
voor interpretatie en correlatie.

### Relatie tot dependencies

Storage is geen `depends-on` relatie.

Reden:
- storage backends zijn niet altijd gemodelleerd als services
- storage is een eigenschap van een service, geen logische dependency tussen services

## 6. criticality (optioneel)

Impact bij failure.

`mprjv65/criticality=`

### Waarden

- `low`
- `medium`
- `high`

## 7. owner (optioneel)

Verantwoordelijke partij.

Voorkeur: annotation i.p.v. label (cardinality beperken).

`mprjv65/owner=`

## Waar toepassen

### 1. Argo Application (voorkeur)

Service-level semantiek:

```yaml
metadata:
  labels:
    mprjv65/service: wordpress
    mprjv65/type: service
    mprjv65/role: frontend
  annotations:
    mprjv65/depends-on: mysql
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
- Aanbevolen annotation: `mprjv65/depends-on`
- Optioneel annotation: `mprjv65/owner`

Voorbeeld (MVP):

```yaml
metadata:
  labels:
    mprjv65/service: wordpress
    mprjv65/type: service
  annotations:
    mprjv65/depends-on: redis,mysql
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
    mprjv65/criticality: medium
  annotations:
    mprjv65/depends-on: memcached,mysql
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
- `mprjv65/depends-on` bevat alleen canonical service namen
- `mprjv65/depends-on` is alfabetisch gesorteerd en zonder duplicaten en zonder spaties
- `mprjv65/depends-on` is optioneel, er kan ook geen dependency zijn 
- owner staat bij voorkeur als annotation

Start simpel:

1. Handmatige review met checklist
2. Daarna policy/lint in CI (bijv. OPA/Kyverno of script)
