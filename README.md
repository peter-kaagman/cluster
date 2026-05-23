# Mprjv65

Deze repository is onderdeel van mijn persoonlijke leertraject Mprjv65. Het project is er op gericht een volledige cloudstack te maken met opensource tooling. De repository gaat voornamelijk over de laag orkestratie en kubernetes. Wat ik in mijn gedachten en artikelen laag 2 ben gaan noemen. 

Mprjv65 is dus niet het simpelweg neerzetten van een NexCloud All In One container in docker, maar gaat in op alle lagen vanaf het fysieke datacentrum tot inderdaad applicaties als NextCloud. Verwacht geen blueprint te vinden voor het opzetten van een cluster, het belangrijkste doel is leren.

Op mijn site https://mysite.prjv.nl/category/mprjv65 staat een reeks artikelen over dit onderwerp. 

# Kubernetes Cluster GitOps (ArgoCD) - Declaratieve Setup

Deze repository beschrijft een Kubernetes cluster op basis van GitOps met ArgoCD. Het doel is een zoveel mogelijk volledig declaratief, reproduceerbaar cluster, waarbij ArgoCD de regie voert over alle applicaties en infrastructuur. Er zijn echter een aantal componenten die horen bij wat je de 'boorstrap' van het cluster zou kunnen noemen. Componenten die niet door ArgoCD of manifesten beheerd word. Deze afhankelijkheden probeer ik hieronder te benoemen.

## Disclaimer
Deze repo komt sowieso zonder ook maar een enkele garantie op correctheid of zelfs gezond verstand. Maar ik heb op dit moment de reproduceerbaarheid van wat hier staan ook niet getest. Zoals je misschien hieronder kun zien maak ik veelvuldig gebruik van GH CoPilot als mentor, en die wil zich nog wel eens vergissen of gewoon belangrijke zaken niet noement. Zoals ik zei: het is mijn leerweg.

---

## Projectstructuur
- `argocd/` : ArgoCD App-of-Apps, applicatie manifests
- `cert-manager/` : ClusterIssuer en andere cert-manager resources (niet de controller zelf)
- `traefik-manifests/` : Traefik deployment, service, RBAC, etc.
- `secrets/` : (Bootstrap) secrets die niet declaratief kunnen of mogen
- `mysql-manifests/` : MySQL deployment, service, PVC, etc.

## Bootstrap/afhankelijkheden buiten ArgoCD
Deze onderdelen moeten handmatig of via een apart bootstrap-proces worden uitgerold vóórdat ArgoCD alles kan beheren:

- **CRDs van operators**
  - cert-manager CRDs
  - Traefik CRDs (indien nodig)
  - ArgoCD CRDs (indien nodig)
- **Cluster-brede controllers/operators**
  - cert-manager controller (namespace: cert-manager)
  - ArgoCD zelf (App-of-Apps)
  - Traefik (optioneel, kan ook via ArgoCD)
- **Bootstrap secrets**
  - Registry secrets, eerste admin wachtwoord, etc. (optioneel)
- **StorageClass/Persistent Volumes**
  - Moeten vooraf aanwezig zijn als je PVC's gebruikt
- **Netwerkcomponenten**
  - CNI, MetalLB, etc. (indien van toepassing)

## Volledig door ArgoCD beheerde resources
- ClusterIssuer (cert-manager/clusterissuer-letsencrypt-prod.yaml)
- ArgoCD zelf (argocd/application-*.yaml)
- Alle applicaties, deployments, services, ingress, enz.

## Installatievolgorde
1. **Installeer CRDs**
   - cert-manager: `kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.crds.yaml`
2. **Installeer cluster-operators/controllers**
   - cert-manager: via Helm of manifest
   - ArgoCD: via manifest of Helm
   - Traefik: via manifest of Helm (optioneel)
3. **(Optioneel) Maak bootstrap secrets aan**
4. **Sync ArgoCD App-of-Apps**
   - ArgoCD neemt nu het beheer over alle declaratieve resources over

## Testen van een schone uitrol
- Volg bovenstaande volgorde op een nieuw cluster
- Controleer of alles "in sync" en "healthy" wordt in ArgoCD
- Controleer of alle certificaten, ingress, en applicaties automatisch worden uitgerold

---

**Let op:**
- Sommige resources (zoals CRDs en cluster-operators) zijn lastig volledig declaratief te beheren met alleen ArgoCD. Overweeg een bootstrap-script of een App-of-Apps setup voor operators als je volledige GitOps wilt.
- Documenteer altijd handmatige stappen en afhankelijkheden in deze README.

---


## Componenten & Doel

- **argocd/**  
  Bevat de ArgoCD App-of-Apps setup en de declaratie van alle applicaties die door ArgoCD beheerd worden. Dit is het centrale GitOps-regiepunt van het cluster.

- **cert-manager/**  
  Bevat resources voor cert-manager, zoals de ClusterIssuer voor Let's Encrypt. Hiermee worden automatisch TLS-certificaten uitgegeven voor Ingress resources. Let op: de cert-manager controller zelf wordt buiten ArgoCD om geïnstalleerd.

- **traefik-manifests/**  
  Bevat de manifests voor Traefik, de Ingress-controller van het cluster. Regelt de routing van extern verkeer naar de juiste services binnen het cluster.

- **secrets/**  
  Bevat (bootstrap) secrets die niet declaratief kunnen of mogen worden beheerd, bijvoorbeeld initiale wachtwoorden of registry credentials.
  In het manifest wordt ook de namespace van de applicatie gemaakt omdat het secret bij de namespace hoort.
  De in de repo opgenomen manifesten bevatten placeholders. De 'productie' versie van deze folder staat om veiligheidsredenen buiten de repo, moet dan ook separaat een backup van gemaakt worden.
  Secrets staan over het algemeen base64 encoded in het manifest: `echo -n "string"|base64 --encode`. Dit is uiteraard niet echt een beveiliging, iedereen kan die strings weer de-coderen.

- **mysql-manifests/**  
  Bevat een MySQL database deployment. Dit is een voorbeeld van een stateful applicatie in het cluster, maar is niet per se een vast onderdeel van de cluster-infrastructuur. Kan gebruikt worden door andere applicaties als backend database.

---

# Workflow
ArgoCD is in princiepe de baas over de componenten. Die vertel je welke repo (GitHub of een andere) hij moet monitoren. Indien auto-sync aanstaat, wat default het geval is, dan zal ArgoCD na een commit/push automatisch de wijzigingen deployen.
Handmatige aanpassingen zullen dan ook verloren gaan

---

Vragen of bijdragen? Open een issue of maak een pull request! Weet je wat? Je kun mij ook gewoon mailen. Mijn email adres staat in het manifest van de cluster issuer ;)
