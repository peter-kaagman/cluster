# Architectuur: Vault & External Secrets Operator (ESO) in Kubernetes

## Overzicht
Deze architectuur beschrijft een veilige en flexibele manier om secrets te beheren in Kubernetes clusters met behulp van HashiCorp Vault en de External Secrets Operator (ESO).

## Componenten
- **Vault**: Centrale, externe secret server. Beheert en bewaart gevoelige data (wachtwoorden, API keys, etc.). Kan buiten het cluster draaien.
- **ESO**: Kubernetes controller die secrets uit Vault ophaalt en als Kubernetes secrets beschikbaar stelt voor workloads.
- **Cluster-repo**: Bevat alleen declaratieve configuratie voor het cluster (geen Vault data of config).

## Workflow
1. **Vault opzetten**
   - Deploy Vault als centrale service (buiten het cluster of als aparte workload).
   - Initialiseer Vault en voeg handmatig of via een beveiligde pipeline de benodigde secrets toe.
2. **Cluster opzetten**
   - Zet het Kubernetes cluster op, inclusief ESO (en eventueel ArgoCD/GitOps).
   - Cluster-repo bevat alleen manifests/Helm charts voor cluster resources, geen Vault secrets.
3. **Secrets beschikbaar maken**
   - Maak ExternalSecret resources aan in het cluster die verwijzen naar Vault.
   - ESO haalt de secrets op en maakt Kubernetes secrets aan voor gebruik door pods/applicaties.

## Voordelen
- Volledige scheiding tussen secret management en cluster lifecycle.
- Secrets nooit in Git of cluster-repo.
- Eén centrale Vault voor meerdere clusters en applicaties.
- Volledig GitOps- en CI/CD-vriendelijk.

## Best Practices
- Gebruik TLS en netwerk policies voor veilige communicatie tussen ESO en Vault.
- Beheer Vault policies, roles en paths declaratief (zonder gevoelige waarden in Git).
- Voeg gevoelige waarden éénmalig handmatig of via een beveiligde pipeline toe aan Vault.
- Documenteer de workflow en verantwoordelijkheden in je team.

---

*Laat deze documentatie in de repo staan als naslag voor beheer en onboarding!*