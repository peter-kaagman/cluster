# Reboot Checklist

Gebruik deze checklist als operationeel draaiboek voor een veilige cluster reboot.

## 0. Hypervisor-gestuurde reboot (VM/vHost)

- [ ] **Graceful signaal, geen hard reset**: Hypervisor gebruikt ACPI shutdown/reboot en niet `power off`/`reset`.
- [ ] **Guest agent actief**: QEMU guest agent of VMware Tools draait in de VM zodat shutdown-signalen netjes landen.
- [ ] **Shutdown grace period**: Hypervisor wacht lang genoeg voor guest shutdown (aanbevolen: minimaal 120s, liever 180s).
- [ ] **Autostart na host reboot**: VM start automatisch op na reboot van de hypervisor host.
- [ ] **k3s autostart**: k3s service staat op `enabled` zodat cluster zonder handwerk terugkomt.
	- Controle: `systemctl is-enabled k3s`
- [ ] **Noodpad getest**: Test 1x per kwartaal een host-reboot vanuit de hypervisor om te verifiëren dat de guest clean afsluit en terugkomt.

## 1. Pre-check (voor reboot)

- [ ] **GitOps status schoon**: ArgoCD apps staan op `Synced` en `Healthy`.
- [ ] **Geen storage mutaties actief**: Geen PVC migraties, restore jobs of handmatige file-copy acties bezig.
- [ ] **PVC status OK**: Geen PVC's in `Pending` of `Terminating`.
	- Controle: `kubectl get pvc -A`
- [ ] **Pods stabiel**: Geen onverwachte `CrashLoopBackOff` of `Error` in kritieke namespaces.
	- Controle: `kubectl get pods -A`
- [ ] **Backup aanwezig**: Recente dump/backup van kritieke data (minimaal MySQL) aanwezig.

## 2. Reboot volgorde

- [ ] **Graceful reboot**: Reboot gecontroleerd uitvoeren op node(s), liefst rolling waar mogelijk.
- [ ] **Node terug online**: Node komt terug op `Ready`.
	- Controle: `kubectl get nodes`
- [ ] **k3s/systemd services gestart**: Control plane + agents draaien weer.

## 3. Post-check (direct na reboot)

- [ ] **ArgoCD hersteld**: ArgoCD pods draaien, apps blijven `Synced`/`Healthy`.
- [ ] **Ingress werkt**: Externe endpoints geven geen 502/503.
	- Controle: `curl -k -I https://mysite.prjv.nl`
- [ ] **Services hebben endpoints**: Geen lege endpoints voor kritieke services.
	- Controle: `kubectl get endpoints -A`
- [ ] **NFS PVC's gebonden**: Verwachte PVC's staan op `Bound` met `storageClassName: nfs`.
	- Controle: `kubectl get pvc -A`

## 4. Applicatie checks

- [ ] **MySite**: Pod `Running`, site bereikbaar, geen 5xx via ingress.
- [ ] **MySQL**: Pod `Running`, server `alive`, database/tabel checks OK.
	- Controle: `kubectl exec -n mysql deploy/mysql -- sh -lc 'mysqladmin -u root -p"$MYSQL_ROOT_PASSWORD" ping'`
	- Controle: `kubectl exec -n mysql deploy/mysql -- sh -lc 'mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;"'`
- [ ] **Vault**: Pods `Running`, unseal en secret access werkt.

## 5. Bekende valkuilen

- [ ] **Niet op alleen pod-status vertrouwen**: `Running` kan nog steeds app-fouten verbergen, check altijd logs en endpoint gedrag.
- [ ] **Replica drift controleren**: Bij Deployment updates kunnen meerdere ReplicaSets actief lijken; check desired/current.
	- Controle: `kubectl get rs -A`
- [ ] **NFS permissies valideren bij errors**: Als root wel schrijft en UID 999 niet, ligt het vaak aan NFS mapping/ACL.

## 6. Afronding

- [ ] **Incidenten noteren**: Eventuele afwijkingen vastleggen in docs.
- [ ] **Checklist bijwerken**: Nieuwe lessons learned opnemen in deze file.

