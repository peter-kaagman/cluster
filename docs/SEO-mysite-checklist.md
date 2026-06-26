# SEO-checklist MySite (praktisch en afvinkbaar)

Doel: structureel verbeteren van indexatie, zichtbaarheid en verkeer voor `mysite.prjv.nl`.

## 0) Samenvatting van huidige bevindingen

- [x] HTTPS werkt en HTTP redirect naar HTTPS werkt.
- [x] `robots.txt` staat indexatie toe.
- [x] `sitemap.xml` bestaat en bevat meerdere URLs (31).
- [x] Performance lijkt goed (snelle TTFB).
- [ ] Homepage title is nu te generiek (`Index`).
- [ ] Social metadata (Open Graph/Twitter) is beperkt of ontbreekt.
- [ ] `www.mysite.prjv.nl` bestaat niet; verkeer naar `www` gaat verloren.
- [ ] Ingress-verkeer op mysite is erg laag (weinig bezoek in de laatste 7 dagen).

## 1) Prioriteit Hoog (deze week)

### 1.1 Indexatie en eigenaarschap

- [ ] Verifieer domein in Google Search Console (domeinproperty).
- [ ] Dien `https://mysite.prjv.nl/sitemap.xml` handmatig in bij Search Console.
- [ ] Controleer in Search Console: pagina-status `Geïndexeerd` vs `Ontdekt, momenteel niet geïndexeerd`.
- [ ] Gebruik URL-inspectie op homepage en 3 belangrijke artikelen, vraag indexering aan.
- [ ] Controleer `Coverage`/`Indexing` op soft-404, duplicate without user-selected canonical, crawl anomalies.

### 1.2 Hostname consistentie (`www` en non-`www`)

- [ ] Kies 1 canonical host (advies: `mysite.prjv.nl`).
- [ ] Maak DNS-record voor `www.mysite.prjv.nl`.
- [ ] Voeg redirect toe van `www.mysite.prjv.nl` -> `https://mysite.prjv.nl` (301/308).
- [ ] Controleer dat canonical tags op alle pagina's naar `mysite.prjv.nl` wijzen.

### 1.3 Snippet-kwaliteit (CTR)

- [ ] Vervang homepage `<title>Index</title>` met een inhoudelijke titel (merk + onderwerp + intent).
- [ ] Schrijf unieke meta description voor homepage (130-160 chars).
- [ ] Controleer per top-artikel: unieke title + description zonder duplicaten.

## 2) Prioriteit Middel (komende 2-4 weken)

### 2.1 Social/preview metadata

- [ ] Voeg Open Graph tags toe op homepage en artikelen:
  - [ ] `og:title`
  - [ ] `og:description`
  - [ ] `og:url`
  - [ ] `og:type`
  - [ ] `og:image` (vaste afmeting, publiek bereikbaar)
- [ ] Voeg Twitter Card metadata toe (`summary_large_image`).
- [ ] Test previews met social debugger tools.

### 2.2 Interne structuur en topical authority

- [ ] Kies 1 hoofdniche voor de komende 6-8 weken (bijv. cloud governance / k3s / observability).
- [ ] Publiceer 1-2 artikelen per week binnen die niche.
- [ ] Voeg per nieuw artikel 2-4 interne links toe naar gerelateerde bestaande artikelen.
- [ ] Maak 1 pillar-pagina die de belangrijkste artikelen logisch bundelt.

### 2.3 Structured data

- [ ] Voeg `Article` schema toe aan artikelpagina's.
- [ ] Voeg `BreadcrumbList` schema toe.
- [ ] Voeg `Organization` of `Person` schema toe op home/about.
- [ ] Valideer met Rich Results Test.

## 3) Prioriteit Laag maar nuttig

### 3.1 Crawlbudget en kwaliteit

- [ ] Verminder thin/overlappende content waar mogelijk.
- [ ] Controleer of categoriepagina's voldoende unieke inhoud hebben.
- [ ] Voeg duidelijke `lastmod` in sitemap toe indien nog niet aanwezig.

### 3.2 Backlinks en distributie

- [ ] Publiceer elke nieuwe post ook via LinkedIn/Mastodon/communities.
- [ ] Bouw 3-5 relevante backlinks (guest posts, communities, projectpagina's).
- [ ] Voeg links naar je beste artikelen toe in profielen/bio's.

## 4) Meetplan (wekelijks)

- [ ] Monitor Search Console:
  - [ ] Totaal geïndexeerde pagina's
  - [ ] Impressions
  - [ ] Clicks
  - [ ] Gemiddelde positie
- [ ] Monitor in Grafana/Loki:
  - [ ] Requests op `mysite.prjv.nl`
  - [ ] Ratio bots vs echte users (op basis van user-agent indien beschikbaar)
- [ ] Houd een changelog bij: welke SEO-wijziging op welke datum.

## 5) Definitie van succes (eerste 30 dagen)

- [ ] Homepage en minimaal 10 artikelen zichtbaar als `Geïndexeerd` in Search Console.
- [ ] Minimaal 2x zoveel impressions t.o.v. startmeting.
- [ ] Eerste stabiele organische kliks per week.

## 6) Snelle startvolgorde (aanbevolen)

1. Search Console verificatie + sitemap submit.
2. Homepage title/description herschrijven.
3. `www` DNS + redirect fixen.
4. URL-inspectie en indexering aanvragen voor 5 prioriteitspagina's.
5. Volgende 2 weken: 3 niche-artikelen met sterke interne links.


Second opinion:

# Phase 1: zichtbaar worden (nu)

- Search Console actief monitoren
- Homepage + 3 artikelen: title + description fixen
- Query mapping toevoegen aan 3 artikelen
- www redirect fixen

# Phase 2: context bouwen

- 1 topic cluster (3 artikelen)
- interne links expliciet maken
- lichte JSON-LD (Article + Person)

# Phase 3: signalen versterken

- delen via LinkedIn
- links vanuit eigen projecten
- aanpassen op basis van impressions (GSC)

