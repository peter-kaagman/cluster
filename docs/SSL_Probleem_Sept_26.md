# SSL-probleem MySite - september 2026

**Status:** opgelost op 27 september 2026.

## Samenvatting

Het TLS-certificaat van MySite verliep op 24 september 2026. cert-manager had de vernieuwing al op 25 augustus gestart, maar de ACME HTTP-01-aanvraag bleef hangen. Er waren twee samenwerkende oorzaken: Kubernetes had door een te hoge geheugenreservering te weinig planbare ruimte voor de ACME-solver-pods, en een server-level NGINX-redirect onderschepte challenge-requests voor de niet-canonieke hostnamen.

## Oorzaken

### Geheugenreservering

De Loki `chunks-cache` reserveerde `9830Mi` geheugen voor een cache die op dat moment ongeveer `443Mi` gebruikte. De node had daardoor `11403Mi` van circa `11445Mi` allocatable geheugen gereserveerd (99%), hoewel het daadwerkelijke geheugengebruik lager lag. De vier HTTP-01-solver-pods vroegen elk `64Mi` en bleven `Pending` met `Insufficient memory`. Daardoor ontbrak een beschikbare backend; MySite gaf onder meer `503` terug en andere challenge-routes `404`.

### Ingress-redirect

De MySite-ingress redirectte elk hostname behalve `mysite.prjv.nl` naar die canonical host. Het certificaat bevatte ook `prjv.nl`, `www.prjv.nl` en `www.mysite.prjv.nl`. Een ACME-token hoort bij de hostname waarvoor de challenge is uitgegeven; na een redirect naar de canonical host kon de solver daar niet het juiste token voor teruggeven.

De redirect is op 26 juni 2026 toegevoegd, na de uitgifte van het vorige certificaat die ochtend. Daardoor werkte de eerste uitgifte nog, maar liep de latere vernieuwing tegen de gewijzigde routing aan.

## Oplossing

1. In `argocd/apps/application-loki.yaml` is `chunksCache.allocatedMemory` verlaagd van de chartwaarde `8192` naar `2048` MiB. De Loki-chart genereert daarmee een request en limit van `2458Mi` in plaats van `9830Mi`.
2. In `mysite/ingress-mysite.yaml` is de canonical redirect aangepast: requests onder `/.well-known/acme-challenge/` worden niet omgeleid; normaal verkeer blijft naar `mysite.prjv.nl` redirecten.
3. Beide wijzigingen zijn door ArgoCD gesynchroniseerd. De node-reservering daalde naar `4223Mi` (36%) en alle vier solver-pods konden starten.
4. Met `cmctl renew` is een nieuwe uitgifte gestart. cert-manager en Let’s Encrypt valideerden alle vier hostnamen met HTTP `200`.

## Verificatie

Certificate `mysite-tls` is `Ready=True`, revision 4. Het certificaat in Kubernetes en dat van de publieke MySite-endpoint zijn gelijk en geldig van 27 september tot 26 december 2026. De nieuwe challenge-resources en solver-pods zijn na succesvolle uitgifte opgeruimd; de geslaagde CertificateRequest en Order blijven als cert-manager-resources zichtbaar. Oude verlopen MySite-challenge-objecten waren nog aanwezig.

## Clusterbrede geheugencontrole - 27 september 2026

Na de Loki-aanpassing waren de totale geheugen-requests `4031Mi` (35% van allocatable) en limits `5321Mi` (46%). Er waren geen pods `Pending` en de node meldde `MemoryPressure=False`; er was dus geen tweede actieve schedulerblokkade zoals voor de aanpassing. `kubectl top node` meldde wel `8644Mi` gebruik (75%). Dit is een momentopname van nodegebruik en is niet rechtstreeks gelijk aan de som van containerrequests.

Meerdere relatief grote containers hebben geen memory request of limit ingesteld. Op het meetmoment waren de grootste voorbeelden Prometheus (`910Mi`), MySQL (`701Mi`), HappyMinds (`575Mi`), Argo CD application-controller (`490Mi`), MySite (`449Mi`) en Authentik server (`434Mi`). Dit is geen te hoge reservering: Kubernetes reserveert er juist niets voor. Daardoor kan de scheduler de werkelijke geheugenvraag onderschatten en kunnen deze containers bij groei nodegeheugen verdringen of door OOM worden beeindigd. Stel requests en limits pas vast na het bekijken van piekgebruik over een representatieve periode.

De aparte Loki `results-cache` reserveert `1229Mi` en heeft een gelijke memory limit; Memcached is ingesteld op `-m 1024`. Het gemeten gebruik was `9Mi`, maar dat is slechts een momentopname terwijl de cache capaciteit heeft om te groeien. Dit is een kandidaat voor evaluatie, geen bewezen verspilling of actuele overcommit. Beoordeel hem op basis van cache-hit ratio, querylatentie en filesystembelasting.

## Nazorg

- Alle huidige Certificates zijn `Ready=True` en beide ACME ClusterIssuers zijn `Ready=True`.
- Er staat nog een oude HappyMinds HTTP-01-challenge uit 25 juli op `pending` met `404`. Het actieve HappyMinds-certificaat is inmiddels via DNS-01 uitgegeven en is geldig tot 5 november 2026. De oude challenge lijkt niet aan een actieve Order te hangen; ruim deze apart op nadat is bevestigd dat hij stale is.
- Inspiration gebruikt nog HTTP-01. Het certificaat is geldig tot 2 november 2026 en de geplande vernieuwing is 3 oktober. De ingressredirect is daar niet van hetzelfde type; controleer die vernieuwing wel.
- Monitor na de verkleining van Loki's cache de cache-hit ratio, querylatentie en filesystembelasting. De gemeten `443Mi` was een momentopname; controleer of `2048Mi` ook bij piekbelasting voldoende is.
- Houd certificaatverval, lang pending ACME-challenges en node-geheugenrequests in de monitoring. De relevante schedulermaat is de gereserveerde `requests`-ruimte, niet alleen het actuele geheugengebruik.
