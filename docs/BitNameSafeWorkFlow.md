MySQL deployment met Helm zonder Bitnami image afhankelijkheid
Doel
Stabiele, reproduceerbare MySQL deployment in Kubernetes via ArgoCD, zonder afhankelijkheid van Bitnami container images.

Basis workflow
1. Gebruik Bitnami Helm chart (alleen voor templating en lifecycle)
2. Override container image → official MySQL image
3. Mirror image naar eigen Docker Hub repository
4. Gebruik eigen repository + tag in values.yaml
5. Deploy via ArgoCD (GitOps)


Helm configuratie (basis)
YAMLimage:  registry: docker.io  repository: jouwdockerhub/mysql  tag: 8.4architecture: standaloneprimary:  persistence:    enabled: true    mountPath: /var/lib/mysqlauth:  rootPassword: "rootpass"  database: "appdb"  username: "appuser"  password: "apppass"Minder weergeven

Belangrijk: verschillen Bitnami vs official MySQL
1. Datadir


Bitnami verwacht:
/bitnami/mysql



Official MySQL gebruikt:
/var/lib/mysql



👉 Verplicht aanpassen:
YAMLprimary:  persistence:    mountPath: /var/lib/mysql``Meer regels weergeven

2. Environment variables
Gelukkig compatible:
MYSQL_ROOT_PASSWORD
MYSQL_DATABASE
MYSQL_USER
MYSQL_PASSWORD

👉 Geen aanpassingen nodig voor basisgebruik.

3. Health checks
Bitnami gebruikt soms custom scripts (bijv. /opt/bitnami/...), die niet bestaan in officiële images.
👉 Indien problemen:
YAMLprimary:  customLivenessProbe:    exec:      command:        - mysqladmin        - ping        - -h        - localhostMeer regels weergeven

4. Init scripts
Beide gebruiken:
/docker-entrypoint-initdb.d

👉 Compatibel zolang je geen Bitnami-specifieke scripts gebruikt.

Eigen registry (Docker Hub)
Waarom
Voorkomt:

verdwijnende images (zoals Bitnami)
niet-reproduceerbare deployments
afhankelijkheid van externe lifecycle


Minimale aanpak
Shelldocker pull mysql:8.4docker tag mysql:8.4 jouwdockerhub/mysql:8.4docker push jouwdockerhub/mysql:8.4Meer regels weergeven
Helm:
YAMLimage:  repository: jouwdockerhub/mysql  tag: 8.4Meer regels weergeven

Optioneel (later)

digest pinning
image signing
vulnerability scanning


Belangrijke checks (na deployment)
1. Persistence
Test:
- write data
- restart pod
- verify data still exists

2. Health
Check:
kubectl get pods
kubectl describe pod


geen crashloop
probes OK

3. Logs
kubectl logs <pod>

Let op:

datadir warnings
permission issues
init failures


Beperkingen van deze aanpak

Bitnami chart blijft assumptions maken (filesystem, scripts)
Niet elke feature werkt out-of-the-box (replication, clustering)
Upgrade pad kan afwijken van Bitnami defaults

👉 Daarom:

Deze aanpak is pragmatisch, niet “clean architecture”


Richting op termijn
Overweeg later:
- volledig eigen manifests
of
- chart zonder image assumptions


Kerninzicht
Bitnami chart = deployment tooling
MySQL image = jouw verantwoordelijkheid


Samenvatting (één zin)

Gebruik Helm voor gemak, maar beheer je eigen images voor controle en stabiliteit.


Voorbeeld ArgoCD application manifest:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mysql
  namespace: argocd
spec:
  project: default

  source:
    repoURL: registry-1.docker.io/bitnamicharts
    chart: mysql
    targetRevision: 14.0.3   # kies een stabiele chart versie

    helm:
      values: |
        image:
          registry: docker.io
          repository: jouwdockerhub/mysql
          tag: 8.4

        architecture: standalone

        auth:
          rootPassword: "changeme"
          database: "appdb"
          username: "appuser"
          password: "apppass"

        primary:
          persistence:
            enabled: true
            size: 8Gi
            mountPath: /var/lib/mysql

          # fallback probe als Bitnami scripts niet werken
          customLivenessProbe:
            exec:
              command:
                - mysqladmin
                - ping
                - -h
                - localhost

  destination:
    server: https://kubernetes.default.svc
    namespace: mysql

  syncPolicy:
    automated:
      prune: true
      selfHeal: true

    syncOptions:
      - CreateNamespace=true
```