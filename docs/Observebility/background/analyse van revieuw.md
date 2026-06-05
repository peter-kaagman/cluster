# Analyse – Observability Values Review (Checklist + values.yaml)

## Context
Dit document analyseert de inhoud van [values-review-checklist.md]
Doel: bepalen waar de checklist en configuratie logisch consistent zijn, waar impliciete aannames zitten en waar risico’s ontstaan richting implementatie en runtime gedrag.

De focus ligt expliciet op:
- consistentie binnen dit document (nog los van ontwerpdocs)
- impliciete aannames die later problemen geven
- volgorde / semantiek van de pipeline (belangrijkste risicogebied)

---

# 1. Structuur en volwassenheid van de checklist

## Observatie
De checklist is logisch opgebouwd:

1. Loki storage/retentie
2. limits
3. Fluent Bit pipeline
4. redactie
5. buffering
6. multiline
7. labels
8. deploy/runbook 

## Analyse
Dit volgt correct de keten:

storage → ingest → processing → output

Voor Fluent Bit is de operationele lifecycle explicieter:

raw log → multiline → parse → filter → redact → label → output

Die volgorde is hier niet cosmetisch, maar bepalend voor wat downstream nog beschikbaar is.

`Validate` hoort hier niet in; dat is een runbook- en oplevercriterium, geen transformatiestap in de pipeline.

## Sterk
- duidelijke scheiding van onderwerpen
- bewust gebruik van “beslissen” en “valideren”
- runtime-validatie expliciet opgenomen (zeldzaam goed)

## Zwak
- hoofdstukken zijn logisch, maar **onderling afhankelijkheden zijn impliciet**
- vooral:
  - pipeline volgorde (3) ↔ redactie (4) ↔ multiline (6)
  - labels (7) ↔ Loki limits (2)

## Rationale
De checklist werkt goed als werklijst, maar:

> De interactie tussen onderdelen (met name Fluent Bit filters) is niet expliciet gemaakt

Dit is precies waar later fouten ontstaan.

---

# 2. Fluent Bit pipeline – impliciet maar cruciaal

## Observatie

Checklist zegt:


Controleren of Merge_Log On + Keep_Log Off parser/grep niet breekt
Beslissen: Keep_Log On tot na parser/grep, of filtervolgorde aanpassen


## Analyse

Dit is feitelijk het belangrijkste punt in het hele document.

Wat hier impliciet zit:

- parsing gebeurt op `log`
- `Merge_Log` verandert structuur
- `Keep_Log` bepaalt of parsing nog mogelijk is
- alle vervolgfilters zijn afhankelijk van dit gedrag

Maar:
👉 deze afhankelijkheid is nergens expliciet gemaakt

Hiermee beschrijft de checklist nu nog vooral een configuratievraag, terwijl dit in de praktijk een pipeline-contract is.

---

## Risico

Zonder expliciete keuze:

- parser kan silently niet werken
- grep filters werken niet of half
- redactie werkt op verkeerde structuur
- debugging wordt extreem lastig

---

## Conclusie

Dit punt is terecht “open”, maar:

> Het is geen implementatiedetail → het is een **architectuurkeuze in disguise**

Die keuze moet expliciet maken:

- op welk moment `log` nog beschikbaar is
- of `Merge_Log` de bronstructuur wijzigt vóór filters draaien
- of multiline voor of na parsing wordt toegepast
- of redactie alleen op top-level velden werkt of ook op geneste paden

---

# 3. Redactie – conflict tussen security en observability

## Observatie

Checklist zegt:

- Remove_key alleen top-level
- nested redactie via pipeline-first
- testcases voor nested velden (incl `payload.email`, `user.name`) 

## Analyse

Hier zit een impliciet spanningsveld:

### Aan de ene kant
- “geen secrets zichtbaar” → hard requirement

### Aan de andere kant
- testcases bevatten:
  - email
  - name

👉 impliciete aanname:
> deze velden worden mogelijk als secret behandeld

Dat is te sterk geformuleerd. Email en name zijn niet automatisch secrets; het zijn wel privacy- en contextgevoelige velden.

De checklist moet daarom expliciet scheiden tussen:

- secrets: altijd maskeren of verwijderen
- PII: alleen redacten als dat functioneel of juridisch nodig is
- operationele context: bij voorkeur behouden

---

## Risico

Als je dit letterlijk doorzet:

- verlies van semantische context
- observability degradeert
- audit logging wordt minder bruikbaar

---

## Conclusie

Checklist is correct in aanpak (pipeline-first), maar mist:

> duidelijk onderscheid tussen:
- secrets (moeten weg)
- PII (contextafhankelijk)

Zonder dat onderscheid krijg je of te harde redactie, of juist onvoldoende masking.

---

# 4. Multiline – correct maar afhankelijk van pipeline

## Observatie

Checklist:

- parser toegevoegd
- testaanpak duidelijk
- focus op Python traceback  

## Analyse

Dit is goed uitgewerkt, maar:

👉 afhankelijk van eerdere stappen:

- CRI parser gedrag
- log veld beschikbaarheid
- Merge_Log interactie

---

## Impliciete aanname

> multiline parser ziet “pure log lines”

Maar in werkelijkheid:

- logs kunnen al gemerged zijn
- of al JSON-parsed zijn

Multiline ziet dus alleen de vorm die na eerdere pipeline-stappen nog over is; dezelfde regelset kan daardoor anders of helemaal niet werken.

---

## Risico

- multiline werkt niet (stil falen)
- of verkeerd (records samengevoegd)

---

## Conclusie

Technisch correct, maar:

> afhankelijkheden met pipeline zijn niet benoemd

---

# 5. Labels en cardinality – inhoudelijk goed, implementatie impliciet

## Observatie

Checklist:

- alleen stabiele labels
- hoge cardinality in payload
- performance check na workload  

## Analyse

Dit is inhoudelijk sterk en consistent.

Maar:

👉 bron van labels wordt niet besproken

---

## Impliciete aanname

> labels zijn betrouwbaar en bestaan

Maar in values.yaml staat:


app=$kubernetes['labels']['app']

  

---

## Risico

- label bestaat niet → inconsistente data
- queries worden onbetrouwbaar
- dashboards breken

Daar hoort nog een praktische keuze bij: is er een fallback als een label ontbreekt, of wordt de bron eerst genormaliseerd?

Voor dit document is de richting: labels alleen gebruiken als ze stabiel zijn, en bij ontbrekende bronwaarden eerst normaliseren of een expliciete fallback kiezen.

---

## Conclusie

Labelstrategie is goed,
maar:

> implementatie-afhankelijkheden zijn niet meegenomen in de checklist

---

# 6. Buffering en failover – sterk en volwassen

## Observatie

- disk buffer verplicht
- drop-strategie bewust gekozen
- alertdrempels gedefinieerd
- root-cause analyse verplicht  

## Analyse

Dit is een van de sterkste onderdelen:

- denkt in failure scenarios
- onderscheid tussen oorzaken (Loki down vs piek)
- duidelijke operational intent

---

## Belangrijk inzicht

Hier zit al een architectuurprincipe:

> observability moet zichzelf observeerbaar maken

---

## Conclusie

Goed ontworpen, geen grote hiaten.

---

# 7. Deploy en validatie – goed, maar functioneel

## Observatie

Validatie omvat:

- readiness
- testquery
- errors/retries
- dashboards
- bufferdruk-analyse
- secrets check  

## Analyse

Dit gaat vooral over:

> “werkt het systeem”

Maar minder over:

> “werkt de semantiek correct”

---

## Ontbreekt impliciet

- parsing validatie
- redactie validatie op veldniveau
- multiline correctheid

---

## Risico

Systeem kan “groen” zijn terwijl:

- parsing stuk is
- labels incompleet zijn
- redactie verkeerd werkt

Met andere woorden: een geslaagde deployment is hier nog niet automatisch een correcte observability-payload.

---

## Conclusie

Validatie is operationeel goed,
maar:

> semantische validatie ontbreekt

---

# 8. values.yaml – belangrijke observaties

## Fluent Bit

### Observatie


Merge_Log On
Keep_Log Off



👉 conflicteert met checklist-vraag

---

### Observatie


Mem_Buf_Limit 10MB

 

👉 relatief laag voor bursts

---

### Observatie


multiline.parser cri,multiline_python


👉 combinatie van parsing-lagen → potentieel complex gedrag

---

## Loki

### Observatie

- compactor-only retention ✅
- filesystem storage ✅
- singleBinary ✅
- retention 30 dagen ✅ 

---

### Impliciete risico’s

- geen HA (replication_factor=1)
- storage limit (20Gi) vs retention

Die risico’s zijn voor een eerste versie verdedigbaar, maar ze moeten later expliciet terugkomen in de review of runbook; anders verdwijnen ze uit beeld.

---

# 9. Samenvattende analyse

## Wat klopt

- structuur checklist
- bewuste keuzes (retentie, limits)
- buffering en failover
- redactie als first-class concern
- expliciete validatiecriteria

---

## Waar de echte risico’s zitten

### 1. Pipeline semantiek (grootste)
- volgorde filters
- lifecycle van `log` veld
- afhankelijkheid parsing → filter → redactie

Dit is de primaire correctheidslaag; als hier iets misgaat, zijn downstream conclusies discutabel.

### 2. Redactie scope
- onduidelijk onderscheid secrets vs context

Hier zit de kans op te harde redactie of juist onvoldoende masking.

### 3. Impliciete aannames
- labels bestaan altijd
- multiline werkt generiek
- parsing gebeurt automatisch correct

Deze aannames moeten expliciet gemaakt of uit de checklist gehaald worden.

### 4. Validatie
- controleert aanwezigheid, niet correctheid

De checklist moet dus niet alleen zeggen dat er data is, maar ook dat de data de verwachte semantiek heeft.

---

# 10. Belangrijkste conclusie

Deze checklist is inhoudelijk sterk, maar:

> De meeste risico’s zitten niet in de afzonderlijke keuzes, maar in de **interactie tussen die keuzes**

Meer concreet:

- pipeline gedrag is niet expliciet gemodelleerd
- sommige keuzes worden nu pas “beslist” terwijl ze invloed hebben op alles downstream
- validatie controleert systeemstatus, niet datakwaliteit

Daarom zou de volgende iteratie de documentenset moeten laten aansluiten op één expliciet contract:

raw → multiline → parse → filter → redact → label → output

Als dat contract eenmaal scherp is, kun je per document bepalen wat ontwerpbesluit, implementatiebesluit of runtime-validatiebesluit is.

Ontwerpen geven richting, maar zijn niet in beton gegoten: voortschrijdend inzicht mag en moet leiden tot gerichte bijsturing.

---

# 11. Richting voor volgende iteratie (nog geen oplossing, alleen analyse)

De volgende bespreking zou zich moeten richten op:

1. expliciet maken van pipeline lifecycle:
   - raw log → parsed → filtered → redacted → output

2. scherpe definitie van redactie:
   - wat is secret vs context

3. expliciteren van labelbron:
   - waar komen labels vandaan en wat als ze ontbreken

4. uitbreiden van validatie:
   - niet alleen “werkt het”, maar “klopt de data”

---

# Eindconclusie

Dit document is solide als werkbasis.

De complexiteit zit niet in losse onderdelen, maar in:
> **de verborgen semantiek van de Fluent Bit pipeline**

En dat is precies het punt dat je in de volgende stap scherp moet trekken voordat je ontwerpdocumenten verandert.