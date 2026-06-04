# Observability Values Review Checklist

Doel: open punten uit de Fluent Bit en Loki values review gestructureerd afwerken.
Status: nog te bespreken en te implementeren.

## 1) Loki retentie en storage pad

- [ ] Bevestigen dat retentie via compactor loopt (en niet via table_manager).
- [ ] `table_manager` verwijderen als compactor-only strategie gekozen is.
- [ ] Retentie expliciet vastleggen: 30 dagen (of aangepast besluit).
- [ ] Verifiëren dat delete/retentie ook echt uitgevoerd wordt in runtime.
- [ ] Vastleggen hoe we retentie valideren na deployment (bijv. periodieke check).

## 2) Loki query en ingest limits

- [ ] Beslissen of `max_query_length: 168h` bewust is bij 30 dagen retentie.
- [ ] `max_query_series` toetsen met echte dashboards (mogelijk verhogen).
- [ ] `ingestion_rate_mb` en burst toetsen op piekbelasting.
- [ ] Limieten documenteren als bewuste trade-off (kosten vs bruikbaarheid).

## 3) Fluent Bit pipeline volgorde

- [ ] Controleren of `Merge_Log On` + `Keep_Log Off` parser/grep niet breekt.
- [ ] Beslissen: `Keep_Log On` tot na parser/grep, of filtervolgorde aanpassen.
- [ ] Healthcheck drop-filter valideren met echte records.
- [ ] Bevestigen dat `log_level` -> `level` rename in praktijk altijd werkt.

## 4) Fluent Bit redactie van gevoelige data

- [ ] Vastleggen dat huidige `Remove_key` alleen top-level keys raakt.
- [ ] Nested secret redactie aanpak kiezen (pipeline of applicatiezijde).
- [ ] Testcases toevoegen met nested velden (`payload.password`, `auth.token`).
- [ ] Validatie opnemen: geen secrets zichtbaar in Loki/Grafana.

## 5) Fluent Bit buffering en failover gedrag

- [ ] Bevestigen dat gedrag bij `Loki down` voldoet (disk buffer actief).
- [ ] Bevestigen van drop-strategie bij volle buffer (prioriteit audit/security).
- [ ] Alertdrempels valideren: 70% warning, 90% critical.
- [ ] Beslissen over `storage.checksum` (off laten of aanzetten).

## 6) Multiline logging

- [ ] Concrete multiline parserconfig toevoegen (niet alleen conceptueel benoemen).
- [ ] Stacktrace test uitvoeren (bijv. Java/Python).
- [ ] Valideren dat multiline events als 1 record in Loki landen.

## 7) Labels en cardinality

- [ ] Bevestigen dat alleen stabiele labels gebruikt worden.
- [ ] Controleren dat hoge-cardinality velden in payload blijven.
- [ ] Query performance check doen na eerste echte workload.

## 8) Deploy en validatie (ArgoCD runbook)

- [ ] Loki readiness check opnemen (`/ready` = 200).
- [ ] Testquery check opnemen na rollout.
- [ ] Fluent Bit retries en ingest errors checken na deployment.
- [ ] Dashboard smoke test uitvoeren (namespace/app views).

## Besluitlog (kort)

- [ ] Definitieve keuzes vastleggen per onderwerp.
- [ ] Openstaande risico's noteren.
- [ ] Eventuele vervolgactie naar v3.2 docs plannen.

---

# values.yaml (Fluent Bit Helm chart, relevante stukken)

config:
  service: |
    [SERVICE]
        Flush         1
        Grace         30
        Daemon        Off
        Log_Level     info
        Parsers_File  parsers.conf
        storage.path  /var/log/flb-storage
        storage.sync  normal
        storage.checksum  off
        storage.backlog.mem_limit 64M

  inputs: |
    [INPUT]
        Name              tail
        Path              /var/log/containers/*.log
        Parser            cri
        Tag               kube.*
        Mem_Buf_Limit     10MB
        Skip_Long_Lines   On
        storage.type      filesystem

  filters: |
    # Kubernetes metadata (namespace, labels)
    [FILTER]
        Name                kubernetes
        Match               kube.*
        Merge_Log           On
        Keep_Log            Off
        K8S-Logging.Parser  On
        K8S-Logging.Exclude Off

    # JSON detectie (app logs)
    [FILTER]
        Name        parser
        Match       kube.*
        Key_Name    log
        Parser      json
        Reserve_Data On

    # Drop healthchecks
    [FILTER]
        Name   grep
        Match  kube.*
        Exclude log healthcheck

    # Redactie (basic example)
    [FILTER]
        Name   modify
        Match  kube.*
        Remove_key password
        Remove_key token
        Remove_key api_key

    # Default enrichment
    [FILTER]
        Name    modify
        Match   kube.*
        Add     cluster mprjv65

    # Level label normalisatie
    [FILTER]
        Name    modify
        Match   kube.*
        Rename  log_level level

  outputs: |
    [OUTPUT]
        Name            loki
        Match           kube.*
        Host            loki.observability.svc.cluster.local
        Port            3100
        Labels          cluster=mprjv65, namespace=$kubernetes['namespace_name'], app=$kubernetes['labels']['app']
        Line_Format     json
        Retry_Limit     False

parsers: |
  [PARSER]
      Name        json
      Format      json

  [PARSER]
      Name        cri
      Format      regex
      Regex       ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<log>.*)$

# values.yaml (grafana/loki chart)


loki:
  auth_enabled: false

  commonConfig:
    replication_factor: 1

  storage:
    type: filesystem
    filesystem:
      directory: /var/loki/chunks

  schemaConfig:
    configs:
      - from: 2024-01-01
        store: boltdb-shipper
        object_store: filesystem
        schema: v13
        index:
          prefix: index_
          period: 24h

  compactor:
    working_directory: /var/loki/compactor
    shared_store: filesystem

  limits_config:
    retention_period: 720h    # 30 dagen

    ingestion_rate_mb: 4
    ingestion_burst_size_mb: 8

    max_streams_per_user: 10000
    max_entries_limit_per_query: 5000
    max_query_parallelism: 8

    reject_old_samples: true
    reject_old_samples_max_age: 168h

    max_query_length: 168h
    max_query_series: 1000

  chunk_store_config:
    max_look_back_period: 720h

  table_manager:
    retention_deletes_enabled: true
    retention_period: 720h

---

singleBinary:
  replicas: 1

read:
  replicas: 0
write:
  replicas: 0
backend:
  replicas: 0

---

persistence:
  enabled: true
  size: 20Gi

---

service:
  type: ClusterIP
``