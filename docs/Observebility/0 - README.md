# Mprjv65 Observability (v3.1)

## Doel
Deze repository bevat een referentie-implementatie van een observability stack op basis van:

- Fluent Bit (log pipeline)
- Loki (log storage)
- Grafana (visualisatie)

Het doel is niet alleen een werkende stack, maar een begrijpbaar en reproduceerbaar ontwerp.

## Voor Wie
Dit project is bedoeld voor:

- systeembeheerders en engineers die observability willen implementeren
- mensen die Loki en Fluent Bit willen gebruiken zonder een black box
- iedereen die wil begrijpen waarom keuzes gemaakt zijn

Niet bedoeld als:

- plug-and-play product
- volledige enterprise oplossing

## Architectuuroverzicht
Workloads -> Fluent Bit -> Loki -> Grafana

- Fluent Bit verzamelt en verwerkt logs
- Loki slaat logs op met lage-cardinality labels
- Grafana wordt gebruikt voor analyse en visualisatie

## Belangrijk Ontwerpprincipe
Logging is een contract, geen best effort.

Dit betekent:

- logs hebben een voorspelbare structuur
- labels zijn bewust beperkt
- gevoelige data wordt gecontroleerd verwerkt
- gedrag van de pipeline is expliciet gedefinieerd

## De Log Pipeline
De volledige lifecycle van een logregel:

RAW -> MULTILINE -> PARSE -> FILTER -> REDACT -> LABEL -> ENRICH -> BUFFER -> OUTPUT

Waarom dit belangrijk is:

- parsing bepaalt structuur
- filtering bepaalt wat overblijft
- redactie bepaalt wat zichtbaar blijft
- labels bepalen hoe data wordt geindexeerd

Fouten in deze volgorde leiden tot:

- verkeerde data
- slechte queries
- onbetrouwbare dashboards

## Documentstructuur
Belangrijkste documenten:

- Architectuur: mprjv65-observability-v3.1.md
	Beschrijft het ontwerp en de principes.
- Fluent Bit design: mprjv65-fluentbit-design-v3.1.md
	Beschrijft de pipeline en verwerking.
- Deployment (ArgoCD): mprjv65-argocd-observability-v3.1.md
	Beschrijft hoe het uitgerold wordt.
- AWStats-lite bezoekersanalyse: 4 - awstats-lite-bezoekersanalyse.md
	Kleine, directe bezoekersanalyse op basis van ingress logs.

### Wat Niet Leidend Is
Deze documenten zijn achtergrond:

- values review
- analyse documenten

Ze bevatten:

- eerdere discussie
- afwegingen
- ontwerpkeuzes

Ze zijn nuttig voor context, maar niet leidend voor implementatie.

## Belangrijke Keuzes
### Labels

- alleen stabiele labels (cluster, namespace, app, component, level)
- ontbrekende waarden worden genormaliseerd of als unknown gezet
- hoge-cardinality data blijft in payload

### Redactie

- secrets worden altijd verwijderd of gemaskeerd
- PII wordt alleen verwijderd indien nodig
- operationele context blijft behouden

### Multiline

- afhankelijk van inputstructuur
- moet per workload gevalideerd worden

### Validatie
Niet alleen "werkt het", maar ook:

- parsing klopt
- redactie klopt
- labels zijn stabiel
- multiline events zijn correct gegroepeerd

## Reproduceerbaarheid
Deze repository is zo opgezet dat:

- configuratie declaratief is
- deployment via ArgoCD gebeurt
- gedrag voorspelbaar is

Maar dit is een referentie-implementatie. Je zult:

- parameters aanpassen
- keuzes heroverwegen
- validaties uitvoeren in je eigen omgeving

## Verwachtingsmanagement
Dit project:

- geeft richting
- maakt keuzes expliciet
- voorkomt bekende valkuilen

Dit project:

- lost niet alle use-cases op
- vervangt geen eigen inzicht
- is niet klaar voor elke organisatie

## Waarom Dit Project Bestaat
Dit is begonnen als leerproject, maar heeft zich ontwikkeld tot een referentie-architectuur voor observability met expliciete ontwerpkeuzes.

De focus ligt op:

- herleidbaarheid
- begrijpelijkheid
- overdraagbaarheid

## Laatste Opmerking
Als iets onduidelijk is:

- ga niet eerst naar de configuratie
- ga eerst naar het ontwerpdocument

De configuratie volgt het ontwerp, niet andersom.