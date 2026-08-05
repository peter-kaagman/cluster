#! /bin/bash
kubectl port-forward -n observability svc/loki 3100:3100