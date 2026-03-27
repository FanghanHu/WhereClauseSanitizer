#!/bin/bash
# entrypoint.sh
# Starts SQL Server, waits until it is ready, runs all migrations,
# then keeps the process running in the foreground.

set -e

# Start SQL Server in the background
/opt/mssql/bin/sqlservr &
MSSQL_PID=$!

echo "SQL Server starting (PID $MSSQL_PID) — waiting for it to be ready..."

# Wait until sqlcmd can connect (up to 90 seconds)
MAX_WAIT=90
ELAPSED=0
until /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U sa \
        -P "${MSSQL_SA_PASSWORD}" \
        -C \
        -Q "SELECT 1" \
        > /dev/null 2>&1; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "ERROR: SQL Server did not become ready within ${MAX_WAIT}s — aborting."
        kill "$MSSQL_PID"
        exit 1
    fi
    echo "  ... still waiting (${ELAPSED}s elapsed)"
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

echo "SQL Server is ready. Running migrations..."

# Execute each migration script in alphabetical order
for SQL_FILE in /migrations/*.sql; do
    [ -f "$SQL_FILE" ] || continue
    echo "  → Applying $(basename "$SQL_FILE")"
    /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U sa \
        -P "${MSSQL_SA_PASSWORD}" \
        -C \
        -i "$SQL_FILE"
done

echo "Migrations complete."

# Hand off to the SQL Server process
wait "$MSSQL_PID"
