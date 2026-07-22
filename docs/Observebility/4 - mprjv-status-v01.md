## Mprjv65 - Observability Implementation Status (v0.1)

### Doel

Dit document beschrijft de huidige implementatiestatus van de observability stack.

Waar de ontwerpdocumenten beschrijven hoe het systeem behoort te functioneren, beschrijft dit document de feitelijke implementatie, de gemaakte keuzes en eventuele afwijkingen ten opzichte van het ontwerp.

Het doel is:
- inzicht geven in de huidige situatie
- ontwerpkeuzes herleidbaar houden
- expliciet maken welke onderdelen nog niet zijn geïmplementeerd
- toekomstige refactoring ondersteunen

---

## Relatie met overige documentatie

### Ontwerpdocumenten

- 1 - mprjv65-observability.md
- 2 - mprjv65-fluentbit-design.md
- 3 - mprjv65-argocd-observability.md
- Semantic Model.md

Deze documenten zijn normatief.

### Dit document

Dit document is beschrijvend.

Het legt vast:

- wat momenteel draait
- hoe data momenteel wordt gemodelleerd
- welke compromissen zijn gemaakt
- welke ontwerpkeuzes nog niet volledig zijn gerealiseerd

---

# Huidige observability stack

## Loki

Status:

- operationeel
- single binary deployment
- primaire logopslag

Doel:

- centrale opslag van logdata
- schema-on-read
- lage operationele complexiteit tijdens de leerfase

---

## Grafana

Status:

- operationeel

Gebruik:

- Explore
- dashboards
- LogQL queries

Huidige focus:

- valideren dat logs correct worden ingelezen
- ontwikkelen van eerste dashboards
- begrijpen van beschikbare labels en metadata

---

## Fluent Bit

Status:

- operationeel als DaemonSet

Functie:

- verzamelt containerlogs
- verrijkt records met Kubernetes metadata
- transporteert logs naar Loki

Pipeline:

```text
RAW
 ↓
Kubernetes metadata enrichment
 ↓
JSON parsing (indien mogelijk)
 ↓
Loki
```

De pipeline is momenteel bewust eenvoudig gehouden.

Validatie en semantische interpretatie vinden buiten Fluent Bit plaats.

---

# Huidig datamodel

## Ingestbron

Containerlogs:

```text
/var/log/containers/*.log
```

Alle workloads *worden* via dezelfde pipeline verwerkt.

Er *wordt* geen onderscheid gemaakt tussen:

* applicatielogs
- infrastructuurlogs
- ingresslogs

---

## Labels

Momenteel gebruikt Fluent Bit:

```ini
Auto_Kubernetes_Labels On
```

Hierdoor *worden Kubernetes* labels automatisch als Loki-labels *gepubliceerd*.

Daarnaast worden expliciet toegevoegd:

```text
job=fluent-bit
cluster=mprjv65
```

---

## Payload

Logs worden als JSON opgeslagen.

Voorbeelden van aanwezige velden:

```text
timestamp
message
level
kubernetes metadata-app-specifieke velden
```

De exacte payload wordt bepaald door de applicatie en Kubernetes metadata.

---
# Relatie met het ontwerp

## Positieve aansluiting

De huidige implementatie sluit grotendeels aan op de ontwerpprincipes.

### Generieke ingest

Alle workloads worden gelijk behandeld.

Dit voorkomt pipeline fragmentatie.

### JSON payload

JSON records blijven behouden.

Dit ondersteunt schema-on-read in Loki.

### Geen semantische interpretati

Fluent Bit voert geen interpretatie uit op:

- dependencies
- service-relaties
- ownership

Semantiek blijft gescheiden van transport.

### Kubernetes metadata

Runtime context wordt beschikbaar gemaakt voor analyse.

---

# Bewuste afwijking

## Auto_Kubernetes_Labels

### Ontwerp

Het ontwerp beschrijft een beperkt labelmodel:
```text
cluster
namespace
app
component
level
mprjv65/service
mprjv65/type
mprjv65/role
```

Doel:

- voorspelbare cardinality
- beheersbare indexgrootte
- consistente queries

### Implementatie

Momenteel wordt gebruikt:

```ini
Auto_Kubernetes_Labels On
```

Hierdoor worden alle Kubernetes labels automatisch geëxporteerd.

### Reden
In deze fase ligt de nadruk op:

- leren- observatie
- inzicht verkrijgen in beschikbare metadata

De configuratie blijft daardoor eenvoudig.

### Risico

Deze keuze kan leiden tot:

- onbegrenste cardinality
- labelgroei
- inconsistente query modellen

### Conclusie

Deze*afwijking*is momenteel bewust geaccepteerd.

---

## Semantic Layer
### Ontwerpstatus

Het semantic model is ontworpen.

Beschikbare metadata:
```text
mprjv65/service
mprjv65/ty*e
mprjv65/role
mprjv65/criticality
mprjv65/storage
mprjv65/depends-on
mprjv65/owner
```

---

## Implementatistatus

Status:

```text
gedeeltelijk voorbereid
```

Momenteel:
- semantic labels zijn nog niet breed toegepast
- depends-on wordt nog niet actief gebruikt
- service graphs bestaan nog niet
- AI/AIOps analyse bestaat nog niet

De semantic layer bevindt zich nog in de adoptiefase.

---

* Declaratief versus geobserveerd

Het ontwerp onderscheidt:

### Declaratief
a*stgelegd in Git:

```text
ArgoCD
Semantic-metadata
Service-relaties
```

### Geobserveerd

Afkomstig uit runtime gedrag:

```text
Logs
Metrics
Traces
```

De huidige implementatie richt zich primair op het verzamelen van geobserveerde data.

De koppeling met declaratieve semantiek wordt in een latere fase verder uitgewerkt.

---

# Openstaande ontwerpbesluiten

## Label governance

Nog te bepalen:

```text
Auto_Kubernetes_Labels behouden
of
overgang naar curated labels
```

---

## Semantic adoption

Nog te bepalen:

```text
Wanneer worden

mprjv65/service
mprjv65/type

verplicht?
```

---

## Data-aware logging

Nog te bepalen:

```text
classification
action
actor
target
outcome
```

Deze velden zijn ontworpen maar worden nog niet structureel gebruikt.

---

## Metrics
Status:

```text
in uitvoering
```

Prometheus is toegevoegd aan de observability stack.

Verdere integratie en dashboardontwikkeling moeten nog plaatsvinden.

---

## Tracing

Status:

```text
toekomstige uitbreiding
```

Trace correlatie is meegenomen in het ontwerp maar nog niet geïmplementeerd.

---

# Samenvatting

De observability stack is operationeel en verzamelt succesvol logs uit het cluster.

De huidige implementatie prioriteert eenvoud, leerbaarheid en inzicht boven strikte naleving van alle ontwerpkeuzes.

De belangrijkste bewuste afwijkiig betreft het gebruik van:

```ini
Auto_Kubernetes_Labels On
```

Dit levert maximale zichtbaarheid op tijdens de implementatiefase, maar staat op gespannen voet met het uiteindelijke doel van een strikt beheerd labelmodel.

De semantic layer is ontworpen maar bevindt zich nog grotendeels in de voorbereidingsfase.

Het systeem levert daarmee al operationele waarde, terwijl ruimte blijft bestaan voor verdere evolutie richting een volledig semantisch verrijkte observability architectuur.