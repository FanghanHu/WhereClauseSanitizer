#!/bin/bash
# start.sh
# One-command launcher for the WhereClauseSanitizer SQL Server environment.
#
# Usage:
#   ./start.sh                     # uses default SA password
#   ./start.sh --dev               # also inserts seed data into the database
#   MSSQL_SA_PASSWORD=MyPass ./start.sh   # override SA password

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Parse flags
DEV_MODE=false
for arg in "$@"; do
    case "$arg" in
        --dev)
            DEV_MODE=true
            ;;
    esac
done

# Default SA password (override via environment variable)
export MSSQL_SA_PASSWORD="${MSSQL_SA_PASSWORD:-Str0ng!Passw0rd}"

# Export SEED_DATA so docker-compose passes it through to the container
if [ "$DEV_MODE" = "true" ]; then
    export SEED_DATA=true
    echo "Dev mode enabled — seed data will be inserted."
else
    export SEED_DATA=false
fi

echo "=============================================="
echo " WhereClauseSanitizer — SQL Server 2025 Express"
echo "=============================================="
echo ""
echo "Building image and starting container..."
echo ""

docker compose up --build --detach

echo ""
echo "Container started. Waiting for SQL Server to be healthy..."

# Poll until the healthcheck passes, with failure detection and timeout.
MAX_WAIT=300
ELAPSED=0
until [ "$(docker inspect --format='{{.State.Health.Status}}' where_clause_sanitizer_db 2>/dev/null)" = "healthy" ]; do
    STATUS="$(docker inspect --format='{{.State.Status}}' where_clause_sanitizer_db 2>/dev/null || true)"
    RESTARTING="$(docker inspect --format='{{.State.Restarting}}' where_clause_sanitizer_db 2>/dev/null || true)"

    if [ "$STATUS" = "exited" ] || [ "$STATUS" = "dead" ] || [ "$RESTARTING" = "true" ]; then
        echo ""
        echo "Container failed to become healthy (status=$STATUS, restarting=$RESTARTING)."
        echo "Recent container logs:"
        docker compose logs --tail=80 sqlserver || true
        exit 1
    fi

    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo ""
        echo "Timed out after ${MAX_WAIT}s waiting for a healthy SQL Server container."
        echo "Recent container logs:"
        docker compose logs --tail=80 sqlserver || true
        exit 1
    fi

    echo "  ... waiting (${ELAPSED}s elapsed, status=${STATUS:-unknown})"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

echo ""
echo "✔  SQL Server 2025 Express is ready."
echo ""
echo "  Host    : localhost"
echo "  Port    : 1433"
echo "  Database: ExampleDB"
echo "  User    : sa"
echo "  Password: ${MSSQL_SA_PASSWORD}"
echo ""
echo "Node web server is starting (depends on SQL Server health)..."
echo "  Web UI  : http://localhost:3000"
echo ""
echo "To stop all services run:  docker compose down"
echo "To view logs run:          docker compose logs -f"
echo "To view web logs run:      docker compose logs -f web"
