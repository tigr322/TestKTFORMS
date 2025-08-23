#!/usr/bin/env bash
set -euo pipefail

docker exec -i mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "Strong!Passw0rd" -d KTFOMS_TEST \
  -i /var/opt/mssql/backup/procedures.sql
