# ArgoCD Bootstrap & Self-Management

## Bootstrap-proces
1. **Handmatige installatie**
   - Installeer ArgoCD éénmalig handmatig in je cluster:
     ```sh
     kubectl create namespace argocd
     kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
     ```
2. **Koppel je Git-repo**
   - Maak een ArgoCD Application resource aan die verwijst naar je cluster-configuratie repo (bijvoorbeeld met een `app-of-apps` patroon).

## Self-managing ArgoCD (App of Apps)
- Laat ArgoCD zichzelf beheren door een Application resource te maken die de ArgoCD installatie (manifests/Helm chart) uit je repo laadt.
- Hierdoor kun je upgrades en configuratie van ArgoCD declaratief beheren via GitOps.

### Voorbeeld Application resource
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-self
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/jouw-org/cluster-config.git
    targetRevision: main
    path: argocd
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Samenvatting
- Eerste installatie van ArgoCD doe je handmatig.
- Daarna beheert ArgoCD zichzelf en de rest van je cluster declaratief vanuit Git.
- Dit is veilig, schaalbaar en volledig GitOps-gestuurd.

*Zie ook de officiële ArgoCD docs voor meer details en geavanceerde scenario’s.*
