# AWStats-lite bezoekersanalyse (kleine start)

## Doel

Een kleine observability-stap voor je drie sites, zonder eerst een complete Loki/Grafana stack uit te rollen.

Met dit script kun je direct uit de NGINX ingress logs een AWStats-achtige samenvatting maken:

- hits totaal
- unieke IP's
- bot versus mens (heuristiek)
- statuscode-overzicht
- top pagina's
- top user agents

Het script ondersteunt zowel:

- klassiek NGINX access logformaat
- JSON access logformaat

Daardoor kun je veilig overstappen naar JSON zonder je rapportage te breken.

## Wat is toegevoegd

Script:

- `scripts/awstats-lite.sh`

Dit script analyseert ingress-verkeer voor:

- happyminds.nl
- inspiration.prjv.nl
- mysite.prjv.nl

Op basis van upstream-namen:

- happyminds-wordpress-happyminds-80
- inspiration-wordpress-inspiration-80
- mysite-mysite-service-5000

## Gebruik

Voer het script uit vanaf de repository root.

Standaardperiode: 24 uur.

```bash
./scripts/awstats-lite.sh
```

Voorbeeld voor 72 uur:

```bash
./scripts/awstats-lite.sh 72
```

Toplijst grootte aanpassen (default: 10):

```bash
TOP_N=20 ./scripts/awstats-lite.sh 24
```

## Voorwaarden

- `kubectl` toegang tot je cluster
- toegang tot namespace `nginx-ingress`
- een ingress controller pod met label:
  - `app.kubernetes.io/component=controller`

## Wat je hiermee wint

- snelle trendanalyse op verkeer per site
- zicht op bots en login/scanner gedrag
- direct bruikbaar voor kleine operationele checks
- betere machine-leesbaarheid bij JSON logs (past bij je observability-principe "JSON waar mogelijk")

## Beperkingen (bewust)

- geen historische opslag buiten de ingestelde logretentie
- unieke bezoekers op basis van IP (niet user/session)
- botdetectie is heuristiek
- geen dashboard UI; output is CLI-rapport

## Logische volgende kleine stap

Draai dit script dagelijks via cron op je beheerhost en schrijf output naar een map in `docs/Observebility/reports/`.
Dan heb je al een eenvoudige tijdlijn zonder extra platformcomponenten.
