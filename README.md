# k3s Kubernetes Cluster Setup – GitOps met ArgoCD (Mprjv65)

Deze repository beschrijft de opzet van een k3s Kubernetes cluster dat beheerd wordt via GitOps met ArgoCD, met focus op reproduceerbare infrastructuur en clusterbeheer.


De focus ligt op:
- reproduceerbare clusteropbouw
- duidelijke scheiding tussen bootstrap en GitOps
- inzicht in beperkingen en ontwerpkeuzes

Deze repository is onderdeel van het Mprjv65 project:
→ https://mysite.prjv.nl/category/mprjv65

op dit cluster wordt ook de site gehost:
→ https://mysite.prjv.nl

---

## Doel

Dit document beschrijft hoe een k3s cluster opnieuw opgebouwd kan worden op een nieuwe VM.

Belangrijkste doelen:
- een werkend k3s cluster opzetten
- minimale bootstrap uitvoeren
- daarna ArgoCD het cluster laten beheren (GitOps)

Het doel is niet een volledig declaratief model, maar een reproduceerbare opbouw waarbij duidelijk is:
- wat handmatig gebeurt
- wat door ArgoCD wordt beheerd
- waar de grenzen en afhankelijkheden liggen

---

## Architectuur

```text
Git (repository)
   ↓
ArgoCD
   ↓
k3s cluster
 ├─ applicaties (mysite, mysql)
 ├─ infrastructuur resources
 └─ ingress / TLS

```


## Repository-structuur

De repository volgt een simpel pakketjes-model:

- `argocd/` bevat de ArgoCD control-plane en de App-of-Apps laag.
- `argocd/apps/` bevat alleen de ArgoCD Applications.
- `<workload>/` bevat de manifests en configuratie van één workload of platformcomponent.
- `docs/` bevat toelichting, checklists en ontwerpkeuzes.
- `scripts/` bevat ondersteunende scripts voor analyse en beheer.
- `bootstrap/` blijft bewust buiten de GitOps-grens voor secrets en initiële bootstrap.

Richtlijnen voor deze structuur:

- Houd elke workload zoveel mogelijk als een zelfstandig pakketje.
- Zet losse configuratiebestanden bij elkaar onder de workload-map in plaats van in `argocd/apps/`.
- Gebruik `argocd/apps/` alleen voor de ArgoCD Application-definities.
- Laat infrastructuurcomponenten zoals ArgoCD zelf, ingress-nginx en observability ook als eigen pakketjes leven, maar wel onder de platformlaag.
- Kies per package een duidelijke boundary zodat verhuizen naar een aparte repo later goedkoop blijft.

Praktisch betekent dit voor Grafana:

- `argocd/apps/application-grafana.yaml` blijft dun en declaratief.
- `grafana/` bevat de values en provisioning-config.
- Dashboards, datasources en providers staan los, maar horen functioneel bij dezelfde package.

Dit maakt de repo minder monolithisch en houdt diffs en ownership overzichtelijk.
