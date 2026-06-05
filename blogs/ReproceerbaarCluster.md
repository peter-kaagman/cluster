title: "Van MicroK8S naar k3s: de weg naar reproduceerbaarheid"

description: >
  Overstap van MicroK8S naar k3s en het belang van reproduceerbare Kubernetes-omgevingen.
  Hoe ArgoCD helpt om een cluster declaratief te beheren en beter begrijpbaar te maken.

summary: >
  Een pragmatische overstap van MicroK8S naar k3s, gevolgd door de introductie van ArgoCD.
  Focus ligt op controle, reproduceerbaarheid en het begrijpen van je eigen platform.

seo_title: "Van MicroK8S naar k3s - reproduceerbare Kubernetes met ArgoCD"

seo_description: >
  Praktische overstap van MicroK8S naar k3s en hoe ArgoCD helpt bij GitOps en
  reproduceerbare Kubernetes-clusters. Ervaringen uit een eigen cloudproject.

tags:
  - kubernetes
  - k3s
  - microk8s
  - argocd
  - gitops
  - observability

category: "Mprjv65"

slug: "microk8s-naar-k3s-reproduceerbaarheid"


# Van MicroK8S naar k3s: de weg naar reproduceerbaarheid


Ik wilde gewoon een Kubernetes-cluster neerzetten waar ik controle over had.
Geen magie, geen verborgen lagen — gewoon iets dat doet wat ik verwacht.

Dat bleek lastiger dan gedacht.

## MicroK8S: goed idee, minder goede fit

De directe aanleiding was dat ik Traefik niet lekker aan de gang kreeg. Ik had ervoor gekozen om niet de “ingebakken” versie van [MicroK8s](https://canonical.com/microk8s){target="_blank"} te gebruiken, maar een eigen implementatie met manifesten te beheren. Dat gaf in theorie meer controle, maar in de praktijk liep ik daarop vast.

Daar kwam bij dat het me vanaf het begin al tegenstond dat MicroK8S een snap-applicatie is. Noem me ouderwets — en waarschijnlijk heb je gelijk — maar daar ben ik geen fan van. Het abstraheert dingen die ik juist expliciet wil zien en beheren.

Daarnaast speelde mee dat ik in mijn achterhoofd heb dat een node in het cluster ook een ARM-apparaat kan zijn. Of dat praktisch goed uitpakt weet ik nog niet, maar ARM en Snap zijn in mijn ervaring geen sterke combinatie. Ubuntu op een Pi 5 is bijvoorbeeld niet vooruit te branden.

Kortom: exit MicroK8S.

## k3s: pragmatischer en voorspelbaarder

Ik ben bij [k3s](https://k3s.io/){target="_blank"} uitgekomen. Lichter, simpeler en — belangrijker — beter te doorgronden. Geen magische lagen waar ik doorheen moet prikken om te begrijpen wat er gebeurt.

Tijdens het opnieuw opbouwen van het cluster kwam ik ook een andere tool tegen die me wél aanspreekt: **ArgoCD**.

## ArgoCD en declaratief werken

[ArgoCD](https://argo-cd.readthedocs.io/en/stable/){target="_blank"} maakt het mogelijk om een Kubernetes-omgeving te beheren op basis van manifesten in een repository — in mijn geval GitHub. Declaratief ontwerpen heet dat: je beschrijft de gewenste state en ArgoCD probeert die werkelijkheid te maken.

Dat betekent:

- geen handmatige kubectl-acties meer  
- geen “snowflake clusters”  
- wijzigingen altijd traceerbaar via Git  
- het cluster reproduceerbaar is  

Vooral die reproduceerbaarheid is voor mij belangrijk. Te vaak schrijf je code of configuratie volgens het principe *“write once, read never”*. Te vaak worden systemen in productie genomen zodra “het functioneert”.

Mprjv65 gaat juist om begrip en reproduceerbaarheid. Door gebruik te maken van een repository met manifesten (voorzien van commentaar) kun je een cluster, of delen daarvan, opnieuw implementeren. Wijzigingen zijn inzichtelijk en herleidbaar.

Wat daar ook bij hoort, en wat ik inmiddels wel herken, is het patroon van bouwen zelf:
probleem → paniek → “dit gaat nooit werken” → frustratie → het begint weer te draaien → oplossing → euforie → en dan het volgende probleem.

Die cyclus herhaalt zich nu vooral in de Kubernetes-laag. Straks gebeurt hetzelfde waarschijnlijk weer in de applicatielaag. Het hoort er blijkbaar bij.

Ik denk alleen wel dat de tijd die ik nu in deze laag steek zich later terugbetaalt. Begrip hier voorkomt frustratie verderop.

Het cluster is nog niet volledig onder beheer van ArgoCD. De tool zelf moet je tijdens een bootstrap handmatig installeren. Voor mij geldt hetzelfde voor:

- secrets  
- Ingress Class  
- initiële clusterconfiguratie  

Dat zijn dingen die je één keer goed neerzet en daarna zoveel mogelijk ongemoeid laat.

## Huidige status van het cluster

ArgoCD beheert nu het grootste deel van mijn cluster. Naast ArgoCD zelf en wat clustercomponenten zoals cert-manager, draait er op dit moment:

- **MySQL** als middleware  
- een oude **WordPress**-site (van een kennis, dus die kan ik niet zomaar uitzetten)  
- mijn eigen CMS: **Mysite**  

De beschrijving van het cluster is daarmee voor zo’n 90% (ruwe schatting) vastgelegd in manifesten in GitHub.

👉 De [repository](https://github.com/peter-kaagman/cluster){target="_blank"} is publiek toegankelijk, dus neem gerust een kijkje. Feedback is welkom.

## Volgende stap: observability

De focus ligt nu op observability.

Dat is nadrukkelijk meer dan alleen logging. Kubernetes-logs zijn grotendeels vluchtig, dus zonder extra tooling ben je informatie snel kwijt.

Wat ik hier wil neerzetten is:

- een **centrale logging-oplossing**  
- gecombineerd met een **analyse-laag**  
- bruikbaar voor:  
  - performance-inzicht  
  - security-analyse  
  - accountability  

Dit is het punt waar het cluster van “het werkt” naar “ik begrijp wat er gebeurt” gaat.

## Afsluitend

Het bouwen van een cluster is uiteindelijk niet het doel. Het gaat om controle, inzicht en reproduceerbaarheid.

De overstap van MicroK8S naar k3s en de introductie van ArgoCD voelen als een stap in die richting: minder abstractie waar het niet nodig is, en juist meer structuur waar het waarde toevoegt.

De interessante fase begint nu pas echt — niet met méér componenten, maar met het begrijpen van wat er al draait. Per slot van rekening is Mprjv65 voornamelijk als leerproject bedoeld.
