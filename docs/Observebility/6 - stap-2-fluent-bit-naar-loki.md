# Stap 2 - Fluent Bit naar Loki (ingress eerst)

## Doel

Tweede stap in de keten:

Workloads -> Fluent Bit -> Loki -> Grafana

In deze stap activeer je alleen ingest van nginx-ingress logs naar Loki.

## Waarom klein beginnen

- snelle validatie dat pipeline werkt
- beperkte cardinality en laag risico
- eenvoudig te debuggen voordat alle namespaces meegaan

## Wat is gedeployed

ArgoCD Application:

- argocd/apps/application-fluent-bit.yaml

Configuratiekeuzes:

- Fluent Bit als DaemonSet (1 agent per node)
- Input alleen:
  - /var/log/containers/*_nginx-ingress_*.log
- Kubernetes filter actief (metadata + merge)
- Output naar Loki service:
  - loki.observability.svc.cluster.local:3100
- Labels beperkt gehouden:
  - job
  - cluster
  - namespace
  - component

## Validatie

1. ArgoCD app fluent-bit: Synced + Healthy
2. Fluent Bit pods draaien
3. Loki ontvangt labels/streams (niet leeg)

Voorbeeld checks:

```bash
kubectl -n argocd get application fluent-bit
kubectl -n observability get pods | grep fluent-bit
kubectl -n observability logs ds/fluent-bit -c fluent-bit --since=10m
```

## Volgende stap

Grafana koppelen en 2-3 basisqueries/panels maken voor bezoekersanalyse.
