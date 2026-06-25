# k3s Kubernetes Cluster Setup – GitOps met ArgoCD (Mprjv65)

Dit repository beschrijft de opzet van een k3s Kubernetes cluster dat beheerd wordt via GitOps met ArgoCD.

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
