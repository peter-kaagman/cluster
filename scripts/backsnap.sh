#! /bin/bash

 
NOW=$(/bin/date +%Y%m%d-%H%M)
# Deze moet nog opgenomen worden in /etc/fstab
TARGET="/mnt/truenas-k3s/backsnap/"

# MYTARGET="/var/backups/mysql.kali/"
#PGTARGET="/var/backups/psql.pkn/"
# RSYNCTARGET="tux.atlascollege.nl:~/files/"
# RSYNCUSER="backsnap"
me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

echo "Ik ben $me"
declare -A SOURCES=( \
  ["etc"]="/etc/" \
  ["pvcs"]="/var/lib/rancher/k3s/storage/" \
  ["homes"]="/home/" \
  # ["mysql"]=$MYTARGET \
#  ["psql"]=$PGTARGET \
);

#
# Databases worden niet door dit script gedumpt.
#
# Voor database workloads (MySQL, MariaDB, PostgreSQL, etc.)
# wordt aanbevolen een aparte backup PVC te gebruiken.
#
# Een Kubernetes CronJob maakt periodiek consistente dumps
# naar die PVC. Dit script backupt vervolgens alleen de PVC's
# op bestandsniveau.
#


# # mysql backup
# # remove the previous dumps
# /bin/rm ${MYTARGET}/*sql
# # make a dump per database
# DATABASES=`/usr/bin/mysql -u root -pStringent! -BNe "Show databases;"|/bin/grep -v 'information_schema'|/bin/grep -v 'performance_schema'`
# for DATABASE in $DATABASES; do
#   echo $DATABASE
#   /usr/bin/mysqldump \
#   -u root \
#   -pStringent! \
#   --quote-names --dump-date \
#   --quick --single-transaction \
#   --events --routines --triggers \
#   --databases $DATABASE \
#   --result-file="${MYTARGET}/${DATABASE}.sql"
# done

## pgsql backup
## remove the previous dumps
#/bin/rm ${PGTARGET}/*psql
## make a dump per database
#DATABASES=`/usr/bin/psql -a links -c '\t' -c '\l'|grep '|' | grep -v \s\n  | cut -d"|" -f1 | grep '\w'|grep -v postgres|grep -v template`
#for DATABASE in $DATABASES; do
#  echo $DATABASE
#  /usr/bin/pg_dump $DATABASE >> ${PGTARGET}/${DATABASE}.psql
#done
### Use pg_dumpall
##/usr/bin/pg_dumpall >> ${PGTARGET}/all.psql


# mount rw

# create backup.0
if [ ! -d  "${TARGET}/backup.0" ]; then
  /bin/mkdir ${TARGET}/backup.0
fi

# change the timestamp on backup.0
/bin/touch ${TARGET}/backup.0

for SOURCE in "${!SOURCES[@]}"; do
  echo "Doing ${SOURCE} from ${SOURCES["${SOURCE}"]}";
  `/usr/bin/rsync -a --delete ${SOURCES["${SOURCE}"]} ${TARGET}/backup.0/${SOURCE}`;
done

# copy to backup.now
echo "Doing a cp -al"
/bin/cp -al ${TARGET}/backup.0 ${TARGET}/backup.${NOW}

# # rsync to remote
# echo "rsync to remote"
# `/usr/bin/rsync -aH --delete-before -e ssh  ${TARGET}/backup.* ${RSYNCUSER}@${RSYNCTARGET}`
# echo "done"
# /usr/bin/rsync -aH --delete-before -e ssh  /var/backups/backsnap/kali/backup.*  backsnap@tux.atlascollege.nl:~/files
