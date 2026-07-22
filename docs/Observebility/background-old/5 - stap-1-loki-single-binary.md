# Stap 1 - Loki Single Binary (kleine start)

## Doel

Eerste echte bouwsteen in de observability-keten:

Workloads -> Fluent Bit -> Loki -> Grafana

In deze stap zetten we alleen Loki neer als centrale logopslag.

## Waarom eerst Loki

- pod-rollouts resetten lokale podlogs
- centrale opslag voorkomt verlies van recente historie
- kleine, beheersbare start zonder direct alle componenten tegelijk

## Wat is gedeployed

ArgoCD Application:

- argocd/apps/application-loki.yaml

Met:

- deploymentMode: SingleBinary
- 1 replica
- persistence: 20Gi
- retention: 14 dagen
- basis ingest/query limits
- gateway/canary/tests uitgeschakeld (kleine footprint)

## Validatie

1. ArgoCD app bestaat en is gesynced/healthy.
2. Loki pod draait in namespace observability.
3. Loki readiness endpoint geeft HTTP 200.

Voorbeeld checks:

```bash
kubectl -n argocd get application loki
kubectl -n observability get pods
kubectl -n observability port-forward svc/loki 3100:3100
curl -sS http://127.0.0.1:3100/ready
```

## Opmerking schaalbaarheid

SingleBinary is prima voor start en learning, maar beperkt schaalbaar.
Migratie naar SimpleScalable/Distributed blijft later mogelijk.

## Volgende stap

Stap 2: Fluent Bit koppelen naar Loki, eerst alleen ingress logs.
