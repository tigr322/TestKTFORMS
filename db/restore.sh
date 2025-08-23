#!/usr/bin/env bash
set -euo pipefail

BAK_LOCAL="./db/backup/KTFOMS_TEST.bak"

if [ ! -f "$BAK_LOCAL" ]; then
  echo "Положи бэкап сюда: $BAK_LOCAL"
  exit 1
fi

docker cp "$BAK_LOCAL" mssql:/var/opt/mssql/backup/KTFOMS_TEST.bak
docker exec -it mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Strong!Passw0rd" -i /var/opt/mssql/backup/restore.sql
