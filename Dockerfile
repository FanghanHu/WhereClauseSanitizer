# Dockerfile
# Builds a SQL Server 2025 Express image pre-loaded with the
# example database migrations.
#
# The MSSQL_SA_PASSWORD environment variable MUST be provided at
# runtime (see docker-compose.yml or the start.sh script).

FROM mcr.microsoft.com/mssql/server:2025-latest

# Run as root to install tools; SQL Server drops privileges internally
USER root

# Set the edition to Express
ENV MSSQL_PID=Express

# Copy migration scripts, seed data, and the custom entrypoint
COPY migrations/ /migrations/
COPY seed_data/ /seed_data/
COPY docker/entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

# SQL Server default port
EXPOSE 1433

ENTRYPOINT ["/entrypoint.sh"]
