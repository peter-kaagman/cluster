# Observability Values Review Checklist

Doel: open punten uit de Fluent Bit en Loki values review gestructureerd afwerken.
Status: nog te bespreken en te implementeren.

## 1) Loki retentie en storage pad

- [x] Bevestigen dat retentie via compactor loopt (en niet via table_manager).
- [x] `table_manager` verwijderen als compactor-only strategie gekozen is.
- [x] Retentie expliciet vastleggen: 30 dagen (of aangepast besluit).
- [ ] Verifiëren dat delete/retentie ook echt uitgevoerd wordt in runtime.
- [x] Vastleggen hoe we retentie valideren na deployment (bijv. periodieke check).

## 2) Loki query en ingest limits

- [x] Beslissen of `max_query_length: 168h` bewust is bij 30 dagen retentie.
- [x] `max_query_series` voorlopig vastgesteld op 2000; toetsen met echte dashboards en zo nodig verhogen.
- [x] `ingestion_rate_mb` voorlopig vastgesteld op 4 (burst 8); toetsen op piekbelasting en zo nodig verhogen.
- [x] Limieten documenteren als bewuste trade-off (kosten vs bruikbaarheid).

## 3) Fluent Bit pipeline volgorde

- [ ] Controleren of `Merge_Log On` + `Keep_Log Off` parser/grep niet breekt.
- [ ] Beslissen: `Keep_Log On` tot na parser/grep, of filtervolgorde aanpassen.
- [ ] Healthcheck drop-filter valideren met echte records.
- [ ] Bevestigen dat `log_level` -> `level` rename in praktijk altijd werkt.
- [ ] Vastleggen dat dit een pipeline-contract is: raw → multiline → parse → filter → redact → label → output.

## 4) Fluent Bit redactie van gevoelige data

- [x] Vastleggen dat huidige `Remove_key` alleen top-level keys raakt.
- [x] Nested secret redactie aanpak kiezen: pipeline-first (applicatiezijde aanvullend, niet leidend).
- [ ] Testcases toevoegen tijdens implementatie met nested velden en PII/secret onderscheid (`payload.password`, `auth.token`, `payload.email`, `user.name`).
- [x] Validatie opnemen: geen secrets zichtbaar in Loki/Grafana; verplicht controleren in productie.

## 5) Fluent Bit buffering en failover gedrag

- [ ] Bevestigen dat gedrag bij `Loki down` voldoet (disk buffer actief).
- [x] Bevestigen van drop-strategie bij volle buffer (prioriteit audit/security).
- [x] Alertdrempels valideren: 70% warning, 90% critical.
- [x] Beslissen over `storage.checksum`: aanzetten.
- [x] Root-cause signalering opnemen: onderscheid maken tussen bufferdruk door `Loki down` vs. piekbelasting.

## 6) Multiline logging

- [x] Concrete multiline parserconfig toevoegen (niet alleen conceptueel benoemen).
- [ ] Stacktrace test uitvoeren (bijv. Java/Python).
- [ ] Valideren dat multiline events als 1 record in Loki landen.
- [ ] Verifiëren dat multiline op de post-parse logvorm werkt, niet op ruwe input.

Voorbereide parser (Python traceback, tijdens implementatie activeren):

```ini
[MULTILINE_PARSER]
  name          multiline_python
  type          regex
  flush_timeout 1000

  # Start van Python traceback
  rule      "start_state"  "/^Traceback \(most recent call last\):$/"  "cont"

  # Vervolgregels (ingesprongen File/stack regels)
  rule      "cont"         "/^\s+File \".*\", line \d+, in .*$/"      "cont"
  rule      "cont"         "/^\s+.*$/"                                    "cont"

  # Exception-eindregel (bijv. ValueError: ...)
  rule      "cont"         "/^[A-Za-z_][A-Za-z0-9_\.]*: .*$/"             "start_state"
```

Koppelen aan tail input (voorbeeld):

```ini
[INPUT]
  Name              tail
  Path              /var/log/containers/*.log
  Parser            cri
  multiline.parser  multiline_python
```

Testaanpak (uitvoering tijdens implementatie):

1. Genereer een echte Python traceback in een testpod.
2. Controleer in Loki/Grafana dat de volledige traceback als 1 record binnenkomt.
3. Herhaal met een tweede exceptiontype (bijv. KeyError) om patroon te valideren.
4. Controleer dat normale single-line logs niet onterecht worden samengevoegd.

## 7) Labels en cardinality

- [x] Bevestigen dat alleen stabiele labels gebruikt worden (minimale vaste set).
- [x] Controleren dat hoge-cardinality velden in payload blijven.
- [ ] Query performance check doen na eerste echte workload.
- [ ] Vastleggen wat gebeurt als een label ontbreekt: normaliseren of `unknown`.

## 8) Deploy en validatie (ArgoCD runbook)

- [ ] Loki readiness check opnemen (`/ready` = 200).
- [ ] Testquery check opnemen na rollout.
- [ ] Fluent Bit retries en ingest errors checken na deployment.
- [ ] Dashboard smoke test uitvoeren (namespace/app views).
- [ ] Incident-check toevoegen: bij bufferdruk altijd oorzaak bepalen (`Loki down` vs. ingest-piek) en vervolgactie vastleggen.
- [ ] Semantische validatie opnemen: parsing, redactie, multiline en labels expliciet controleren.

Oplevercriteria (implementatie geslaagd als alles hieronder "ja" is):

1. Loki readiness blijft `200` gedurende minimaal 5 minuten na rollout.
2. Testquery geeft recente logs terug (maximaal 5 minuten oud) voor minimaal 2 workloads.
3. Fluent Bit toont geen structurele output errors/retries richting Loki (geen oplopende fouttrend).
4. Dashboard smoke test slaagt: namespace- en app-weergaven laden en tonen actuele data.
5. Bij bufferdruk is root-cause geclassificeerd als `Loki down` of ingest-piek, met vastgelegde vervolgactie.
6. Geen zichtbare secrets in Loki/Grafana tijdens de validatiecheck.

## Besluitlog (kort)

- [x] Loki retentie-strategie: compactor-only; table_manager niet gebruiken.
- [x] Initiële retentie: 30 dagen; achteraf bijstellen op basis van gebruik en kosten.
- [x] Retentie-validatie: periodieke handmatige check na deployment; later evalueren op nut en automatisering.
- [x] Query defaults: `max_query_length=168h`, `max_query_parallelism=4`, `max_query_series=2000`, `max_entries_limit_per_query=20000`.
- [x] Ingest defaults: `ingestion_rate_mb=4`, `ingestion_burst_size_mb=8`; bijstellen op basis van runtime observaties.
- [x] Punt 3 (Fluent Bit pipeline volgorde) bewust uitgesteld: definitieve keuze en afvinken pas tijdens implementatie en runtime-validatie met echte records.
- [x] Secrets redactie is verplicht: geen secret-keys/waarden zichtbaar in Loki/Grafana; productie-verificatie verplicht na deployment.
- [x] Nested secrets redactie: pipeline-first verplicht; applicatiezijde is alleen aanvullende defense-in-depth.
- [x] Testcases voor nested redactie worden bewust tijdens implementatie toegevoegd en daarna in productie gevalideerd.
- [x] Bufferstrategie: bij overflow mag drop plaatsvinden met prioriteit voor audit/security-logs.
- [x] Failover-instellingen: `storage.checksum` aan; alertdrempels blijven 70% warning en 90% critical.
- [x] Oorzaakanalyse toevoegen: bij bufferdruk expliciet monitoren of oorzaak `Loki down` is.
- [x] Labelstrategie: minimale stabiele set als labels; dynamische/hoge-cardinality velden blijven in payload.
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
        storage.checksum  on
        storage.backlog.mem_limit 64M

  inputs: |
    [INPUT]
        Name              tail
        Path              /var/log/containers/*.log
        Parser            cri
        multiline.parser  cri,multiline_python
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

    # Nested redactie (pipeline-first)
    [FILTER]
      Name   lua
      Match  kube.*
      script /fluent-bit/scripts/redact.lua
      call   redact

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

  [MULTILINE_PARSER]
      Name          multiline_python
      Type          regex
      Flush_Timeout 1000
      Rule          "start_state"  "/^Traceback \(most recent call last\):$/"   "cont"
      Rule          "cont"         "/^\s+File \".*\", line \d+, in .*$/"      "cont"
      Rule          "cont"         "/^\s+.*$/"                                   "cont"
      Rule          "cont"         "/^[A-Za-z_][A-Za-z0-9_\.]*: .*$/"            "start_state"

luaScripts:
  redact.lua: |
    -- Recursively redact sensitive keys in nested JSON structures.
    local sensitive = {
      password = true,
      token = true,
      api_key = true,
      secret = true,
      authorization = true,
      cookie = true,
      email = true,
      name = true
    }

    local function walk(obj)
      if type(obj) ~= "table" then
        return
      end
      for k, v in pairs(obj) do
        local key = tostring(k):lower()
        if sensitive[key] then
          obj[k] = "[REDACTED]"
        elseif type(v) == "table" then
          walk(v)
        end
      end
    end

    function redact(tag, timestamp, record)
      walk(record)
      return 1, timestamp, record
    end

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
    retention_enabled: true

  limits_config:
    retention_period: 720h    # 30 dagen

    ingestion_rate_mb: 4
    ingestion_burst_size_mb: 8

    max_streams_per_user: 10000
    max_entries_limit_per_query: 20000
    max_query_parallelism: 4

    reject_old_samples: true
    reject_old_samples_max_age: 168h

    max_query_length: 168h
    max_query_series: 2000

  chunk_store_config:
    max_look_back_period: 720h

  # table_manager niet gebruiken (compactor-only strategie)

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