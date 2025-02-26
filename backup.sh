#!/bin/bash
# Source the variables from the .vars file
. ./.vars

# Create a backup of all PostgreSQL databases
pg_dumpall -c -U ${POSTGRES_USER} > ${BACKUP_DIR}/db_`date +%Y-%m-%d"_"%H_%M_%S`.sql

# If BACKUP_LIMIT is set to 0, exit the script
if [ ${BACKUP_LIMIT} -eq 0 ]; then
    exit 0
fi

# Count the number of backup files in the backup directory
backup_count=$(ls ${BACKUP_DIR}/*.sql 2>/dev/null | wc -l)

# If the number of backups exceeds the limit, delete the oldest backup
if [ ${backup_count} -gt ${BACKUP_LIMIT} ]; then
    oldest_backup=$(ls -t ${BACKUP_DIR}/*.sql | tail -1)
    rm ${oldest_backup}
fi