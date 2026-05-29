# Reboot Checklist

Gebruik deze checklist om te zorgen dat het cluster na een reboot automatisch en betrouwbaar herstelt. Vink de punten af voor een robuuste infrastructuur.

## Reboot Checklist

- [ ] **Persistent storage**: Alle data staat op PersistentVolumes of externe storage (NFS, Ceph, cloud disks).
- [ ] **Declaratieve configuratie**: Secrets, credentials en configuraties zijn vastgelegd in Git (bijv. met ArgoCD, External Secrets Operator).
- [ ] **GitOps herstel**: Het cluster wordt automatisch uitgerold en hersteld na een reboot (bijv. met ArgoCD of Flux).
- [ ] **Readiness/liveness probes**: Pods hebben readiness en liveness probes voor automatische herstart bij problemen.
- [ ] **Automatisering handmatige stappen**: Handmatige herstelacties zijn gescript (bijv. met bash, Ansible).
- [ ] **Node auto-join**: Nodes joinen automatisch het cluster na een reboot (kubelet/systemd correct ingesteld).
- [ ] **Control plane backup**: Er is een goede backup/restore van etcd of een managed control plane.
- [ ] **Regelmatige reboot-test**: Het reboot-proces wordt regelmatig getest (rolling reboots).
- [ ] **Documentatie up-to-date**: Deze checklist en andere documentatie zijn actueel.

> Voeg eigen punten toe indien nodig!
