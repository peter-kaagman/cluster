# Semantiek voor observability

In mijn vorige blogpost sloot ik af met de verwachting dat ik met observability aan de slag zou gaan. Dat heb ik ook gedaan. Ik ben gaan plannen hoe ik dit zou aanpakken: logstreams, labeling van data en uiteindelijk visualisatie in dashboards.

Toen stelde ik mezelf de vraag: "Hebben deze metrics en signalen betekenis?" In eerste instantie was mijn antwoord "ja". Tot ik me afvroeg of die betekenis ook duidelijk is voor iemand anders, of voor AI. Het antwoord was toen duidelijk: "nee".

Neem dit voorbeeld: de performance van MySQL is slecht. Welke componenten hebben daar last van? Het antwoord is: alle componenten die MySQL gebruiken. Ik weet welke dat zijn, want ik heb het cluster ontworpen. Maar toen ik dit aan AI vroeg (GitHub Copilot), kreeg ik terug dat MySite daaronder zou lijden. Ik weet dat MySite geen database op MySQL gebruikt, maar de AI veronderstelde dat een blogsite meestal wel MySQL gebruikt. Die aanname is logisch, maar in dit geval fout.

Binnen de clusterconfiguratie die ik via GitOps expliciet heb vastgelegd, bestaat die relatie niet. Die staat nergens beschreven en is niet af te leiden uit de runtime-state.

Wat ontbreekt, is de expliciete betekenis van de dienst MySQL: welke componenten zijn afhankelijk van die dienst? Die afhankelijkheden zijn niet zichtbaar in de runtime-state van het cluster en ook niet apart omschreven.

Wat ontbreekt, is een semantische laag die de betekenis van componenten expliciet maakt. Zonder die laag blijft observability beperkt tot het tonen van signalen zonder context: vooral ruis. De betekenis zit dan niet alleen meer in mijn hoofd, maar is expliciet vastgelegd. Dat is een harde voorwaarde voor overdracht aan derden en voor analyse door tooling of AI-systemen.

> **Observability meet wat er gebeurt, maar weet niet waarom het gebeurt of welke impact het heeft.**

Die semantische laag moet expliciet vastgelegd worden in het systeem zelf, niet alleen in documentatie of impliciete kennis.

# Semantische labeling

In mijn cluster gebruik ik Argo CD om het cluster declaratief te beschrijven. Voor elke app in het cluster is er een manifest dat beschrijft:

- Welke Git-repository de app beschrijft (waar de manifesten staan)
- Op welke namespace de app actief moet worden

Argo CD bevat dus al metadata over de applicaties in het cluster. Dat maakt dit een logische plek om manifesten uit te breiden met semantische labels.

De semantic layer bestaat uit een kleine, consistente set labels, elk met een duidelijk doel: classificatie, relaties, eigenschappen, impact en governance.

Ik heb daarom gekozen voor een beperkte labelset. Met deze labels kan ik relaties tussen services expliciet vastleggen.

| Label | Doel | Verplicht | Voorbeeld |
|------|------|----------|----------|
| mprjv65/service | unieke identificatie van de service | ja | wordpress |
| mprjv65/type | architectuurlaag van de service | ja | service |
| mprjv65/role | functionele rol binnen het type | nee | frontend |
| mprjv65/depends_on | logische afhankelijkheden tussen services | nee | mysql:shared |
| mprjv65/storage | semantische storage-eigenschap | nee | nfs |
| mprjv65/criticality | impact bij uitval | nee | high |
| mprjv65/owner | verantwoordelijke partij | nee | team-web |

Het concept als geheel staat beschreven in [Conventions.md](https://github.com/peter-kaagman/cluster/blob/main/docs/SemanticLayer/Conventions.md){target='_blank'}, een document in de repository.

Daarin staan afspraken die ik voor mezelf heb vastgesteld en die ik ook als context aan Copilot kan meegeven. Een volgende stap is om deze afspraken afdwingbaar te maken in de CI/CD-flow: geen geldige labels, geen build. Zo maak ik die afspraak bindend voor mezelf.

# Ter afsluiting

Dit betekent dat ik de plannen voor de observability-laag opnieuw moet bekijken. 
Niet om meer te meten, maar om beter te begrijpen wat er gemeten wordt.

Dit blog sluit daarom opnieuw af met:

Next stop… observability.