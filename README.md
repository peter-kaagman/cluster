
# Kubernetes Cluster – Runbook / GitOps Setup
Doel van dit document
Dit document beschrijft hoe dit cluster opnieuw opgebouwd kan worden op een nieuwe VM.
Het doel is:

**een werkend k3s cluster opzetten**
de minimale bootstrap-stappen uitvoeren
daarna ArgoCD het cluster laten beheren (GitOps)

Het doel is niet een volledig declaratief model, maar een reproduceerbare opbouw waarbij duidelijk is:
wat handmatig moet
wat door GitOps beheerd wordt
waar de beperkingen zitten


## Architectuur (globaal)
Git (repo)
  ↓
ArgoCD
  ↓
k3s cluster
  ├─ applicaties (mysite, mysql)
  ├─ infrastructuur resources
  └─ ingress / TLS

Bootstrap (buiten GitOps):
  ├─ CRDs
  ├─ controllers (cert-manager, ingress)
  ├─ ArgoCD zelf (initieel)
  └─ initiële secrets / storage

ArgoCD is de centrale “controller” van de gewenste cluster state.

## Storage
Het cluster gebruikt momenteel externe storage via NFS (Synology NAS).
Implementatie

NFS share op Synology
gebruikt als backend voor PVC’s (RWX)
gekoppeld via StorageClass / PV

Eigenschappen
+ eenvoudig
+ centraal beheer
+ geschikt voor RWX workloads

Beperkingen
- single point of failure (NAS)
- geen HA op cluster-niveau
- afhankelijk van netwerk/NAS beschikbaarheid

Consequentie
Bij uitval van de NAS:
→ alle stateful workloads stoppen

Toekomstige opties (nog niet geïmplementeerd)

distributed storage (Longhorn / Ceph)
HA op NAS-niveau (replication / HA cluster)


## Bootstrap (niet door ArgoCD beheerd)
Deze onderdelen moeten aanwezig zijn voordat ArgoCD het cluster kan beheren.
1. CRDs
cert-manager CRDs
ArgoCD CRDs (indien nodig)

2. Controllers / operators

cert-manager controller
ArgoCD (initieel)
NGINX ingress controller

3. Netwerk

CNI (default k3s)
eventueel MetalLB (indien gebruikt)

4. Storage

NFS server bereikbaar
StorageClass beschikbaar

5. Bootstrap secrets

registry credentials (GHCR)
initiële wachtwoorden


## Rebuild stappen (samenvatting)
Dit is de “happy path”.
1. Installeer k3s op nieuwe VM

2. Installeer cert-manager CRDs
   kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.crds.yaml

3. Deploy cert-manager controller

4. Deploy ArgoCD (initieel)
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

5. Deploy NGINX ingress controller

6. Maak IngressClass resource aan
   (bootstrap/IngressClassResource.yaml)

7. Maak bootstrap secrets
   (registry, etc.)

8. Configureer storage (NFS / PV / StorageClass)

9. Deploy ArgoCD App-of-Apps

10. Controle:
   - ArgoCD: synced + healthy
   - ingress werkt
   - certificaten worden uitgegeven

Vanaf stap 9 geldt:
ArgoCD is de baas
handmatige wijzigingen worden overschreven


## Volledig door ArgoCD beheerd
Na bootstrap:

applicaties
deployments
services
ingress resources
ClusterIssuer (cert-manager)
ArgoCD config


## Componenten
`argocd/`
App-of-Apps setup. Stuurt alle andere componenten aan.

`cert-manager/`
ClusterIssuer voor Let’s Encrypt.
Controller zelf wordt buiten ArgoCD geïnstalleerd.

`nginx-ingress/`
Ingress controller. Regelt extern verkeer.
Single replica met hostPort (single-node scenario).

`mysql/`
Stateful workload (voorbeeld / middleware).
Niet essentieel voor cluster zelf.

`mysite/`
Perl/Dancer2 applicatie (consumer van cluster).

gebruikt PVC’s (stateful)
vereist GHCR credentials


`bootstrap/`
Cluster-brede resources:

IngressClass
initiële secrets
templates


## Workflow (GitOps)
1. Wijziging in Git
2. Commit / push
3. ArgoCD detecteert wijziging
4. Sync naar cluster

Auto-sync aan:
→ cluster volgt Git
→ handmatige wijzigingen verdwijnen


## Beperkingen / risico's
- storage is extern en niet HA
- bootstrap is deels handmatig
- reproduceerbaarheid niet volledig getest
- afhankelijkheden buiten Git (CRDs / controllers)


## Context (Mprjv65)
Deze repository is onderdeel van het Mprjv65 project:

doel: volledige cloudstack begrijpen
focus: orkestratielaag (kubernetes)

Het project is geen blueprint maar een leertraject.
Artikelen:
https://mysite.prjv.nl/category/mprjv65

## Disclaimer
Deze repository is een werkinstrument binnen een leertraject.
Er zijn geen garanties op:

- correctheid
- volledigheid
- reproduceerbaarheid

Gebruik op eigen risico.