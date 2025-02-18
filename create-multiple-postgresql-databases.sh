#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Function to create a user and a database
function create_user_and_database() {
    local user=$1
    local password=$2
    local db=$3

    # Check if password is provided, create user accordingly
    if [ -z "$password" ]; then
        echo "CREATE USER ${user};"
    else
        echo "CREATE USER ${user} WITH PASSWORD '${password}';"
    fi
    echo "CREATE DATABASE ${db};"
    echo "GRANT ALL PRIVILEGES ON DATABASE ${db} TO ${user};"
}

# Convert comma-separated strings to arrays
IFS=',' read -r -a users <<< "$LIST_USER"
IFS=',' read -r -a passwords <<< "$LIST_PASSWORD"
IFS=',' read -r -a databases <<< "$LIST_DATABASE"

# Create users and databases
for i in "${!users[@]}"; do
    user="${users[$i]}"
    password=${passwords[$i]}
    db="${databases[$i]}"

    # Execute the SQL commands to create user and database and create temporary permissions
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        $(create_user_and_database "$user" "$password" "$db")
EOSQL
    # Create permissions on each database for the corresponding user
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" <<EOSQL
        GRANT ALL PRIVILEGES ON SCHEMA public TO "$user";
EOSQL
done