#!/bin/bash
# start.sh
# One-command launcher for the WhereClauseSanitizer SQL Server environment.
#
# Usage:
#   ./start.sh                     # uses default SA password
#   MSSQL_SA_PASSWORD=MyPass ./start.sh   # override SA password

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Default SA password (override via environment variable)
export MSSQL_SA_PASSWORD="${MSSQL_SA_PASSWORD:-Str0ng!Passw0rd}"

echo "=============================================="
echo " WhereClauseSanitizer — SQL Server 2025 Express"
echo "=============================================="
echo ""
echo "Building image and starting container..."
echo ""

docker compose up --build --detach

echo ""
echo "Container started. Waiting for SQL Server to be healthy..."

# Poll until the healthcheck passes
until [ "$(docker inspect --format='{{.State.Health.Status}}' where_clause_sanitizer_db 2>/dev/null)" = "healthy" ]; do
    echo "  ... waiting"
    sleep 5
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
echo "To stop the server run:  docker compose down"
echo "To view logs run:        docker compose logs -f"
