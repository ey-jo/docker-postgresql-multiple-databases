FROM postgres:17.3

# Set root user credentials
ENV POSTGRES_USER="root"
ENV POSTGRES_DB=${POSTGRES_USER}

# Environment variables for multiple databases with users and passwords
ENV LIST_DATABASE=""
ENV LIST_USER=""
ENV LIST_PASSWORD=""

# Backup configuration
ARG BACKUP_DIR="/backups"

# Days between backups
ENV BACKUP_INTERVAL=0
# Hour of the day the backup process will be executed
ENV BACKUP_HOUR=1
# Number of backup files to keep
ENV BACKUP_LIMIT=5

# Optional: custom cron schedule expression, if provided overwrites the BACKUP_INTERVAL and BACKUP_HOUR
# Expected format: "minute hour day month day-of-week"
ENV BACKUP_TIME_FORMAT=""

# Install cron
RUN apt update -y && apt install -y cron

# Create backup directories and files
RUN mkdir -p "${BACKUP_DIR}"
RUN mkdir -p /opt/backups/
RUN touch /opt/backups/.vars

# Store environment variables in a file for the backup script
RUN echo "POSTGRES_USER=${POSTGRES_USER}" > /opt/backups/.vars && \
    echo "BACKUP_DIR=${BACKUP_DIR}" >> /opt/backups/.vars && \
    echo "BACKUP_LIMIT=${BACKUP_LIMIT}" >> /opt/backups/.vars

# Copy the backup script and make it executable
COPY backup.sh /opt/backups/backup.sh
RUN chmod +x /opt/backups/backup.sh

# Create the cronjob for backups
RUN if [ -n "$BACKUP_TIME_FORMAT" ]; then \
    echo "${BACKUP_TIME_FORMAT} /opt/backups/backup.sh" > /tmp/cronjob.txt; \
    crontab /tmp/cronjob.txt; \
elif [ "$BACKUP_INTERVAL" -ne 0 ]; then \
    echo "0 ${BACKUP_HOUR} */${BACKUP_INTERVAL} * * /opt/backups/backup.sh" > /tmp/cronjob.txt; \
    crontab /tmp/cronjob.txt; \
fi

# Create the users with corresponding databases
RUN mkdir -p /docker-entrypoint-initdb.d/
COPY create-multiple-postgresql-databases.sh /docker-entrypoint-initdb.d/create-multiple-postgresql-databases.sh
RUN chmod +x /docker-entrypoint-initdb.d/create-multiple-postgresql-databases.sh