# Checklist: Migratie van PVCs naar NFS

Gebruik deze checklist om je bestaande PersistentVolumeClaims (PVCs) te migreren van local-path (of default) storage naar dynamische NFS-storage.

## Te migreren PVCs

- [ ] **happyminds/wp-content-pvc**
  - Bestand: cluster/happyminds/wp-content-pvc.yaml
  - Huidige storageClass: local-path
- [ ] **mysite/images-pvc**
  - Bestand: cluster/mysite/images-pvc.yaml
  - Huidige storageClass: local-path
- [ ] **mysite/db-pvc**
  - Bestand: cluster/mysite/db-pvc.yaml
  - Huidige storageClass: local-path
- [ ] **mysite/logs-pvc**
  - Bestand: cluster/mysite/logs-pvc.yaml
  - Huidige storageClass: local-path
- [ ] **mysql/mysql-pvc**
  - Bestand: cluster/mysql/mysql-pvc.yaml
  - Huidige storageClass: (default, waarschijnlijk local-path)

## Stappen per PVC

1. Applicatie stoppen (deployment/statefulset schalen naar 0)
2. Data veiligstellen (kopiëren van oude naar nieuwe PVC/NFS-share)
3. Oude PVC verwijderen
4. Nieuwe PVC aanmaken met `storageClassName: nfs`
5. Data terugplaatsen (indien nodig)
6. Applicatie weer starten
7. Werking controleren

> Vink per PVC de stappen af en documenteer eventuele bijzonderheden.
