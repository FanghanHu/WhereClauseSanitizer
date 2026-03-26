# WhereClauseSanitizer

A MS SQL Server function that will sanitize WHERE-clause input.

---

## Docker — SQL Server 2025 Express

This repository ships a ready-to-run **SQL Server 2025 Express** Docker image that automatically applies all database migrations on first start.

### Prerequisites

| Tool | Minimum version |
|------|-----------------|
| Docker Desktop / Docker Engine | 24+ |
| Docker Compose plugin (`docker compose`) | v2 |

### Quick start (single command)

```bash
./start.sh
```

The script will:

1. Build the custom image (extends `mcr.microsoft.com/mssql/server:2025-latest`)
2. Start the container in the background
3. Wait until SQL Server reports healthy
4. Print the connection details

You can override the SA password:

```bash
MSSQL_SA_PASSWORD='YourStr0ng!Pass' ./start.sh
```

### Manual start with docker compose

```bash
# Start (builds image if needed)
docker compose up --build -d

# Follow logs
docker compose logs -f

# Stop and remove the container (data volume is preserved)
docker compose down

# Stop AND delete all data
docker compose down -v
```

### Connection details

| Setting  | Value |
|----------|-------|
| Host     | `localhost` |
| Port     | `1433` |
| Database | `ExampleDB` |
| User     | `sa` |
| Password | `Str0ng!Passw0rd` (default) |

### Database schema

The migration in `migrations/001_initial_setup.sql` creates the
following tables in the `ExampleDB` database.

#### Shared columns (all three tables)

| Column    | Type              | Notes |
|-----------|-------------------|-------|
| `PrimKey` | `UNIQUEIDENTIFIER`| Primary key, defaults to `NEWID()` |
| `Created` | `DATETIME2`       | Set automatically to `SYSDATETIME()` on insert |
| `Updated` | `DATETIME2`       | Set automatically to `SYSDATETIME()` by an AFTER UPDATE trigger |

#### `atbl_Example_Users`

Stores user accounts. Additional columns: `Username`, `Email`.

#### `atbl_Example_Posts`

Stores blog-style posts. Each post has an author (`AuthorKey → atbl_Example_Users.PrimKey`). Additional columns: `Title`, `Body`.

#### `atbl_Example_Comments`

Stores comments on posts. Each comment belongs to a post
(`PostKey → atbl_Example_Posts.PrimKey`) and has an author
(`AuthorKey → atbl_Example_Users.PrimKey`). Additional columns: `Body`.

#### Entity relationship

```
atbl_Example_Users
    │
    ├─── (AuthorKey) ──► atbl_Example_Posts
    │                         │
    │                         └─── (PostKey) ──► atbl_Example_Comments
    │                                                    │
    └─────────────────── (AuthorKey) ───────────────────┘
```

### Project structure

```
.
├── Dockerfile                  # Extends SQL Server 2025 Express image
├── docker-compose.yml          # Service definition with health-check
├── docker/
│   └── entrypoint.sh           # Waits for SQL Server, then runs migrations
├── migrations/
│   └── 001_initial_setup.sql   # Creates database, tables, and triggers
└── start.sh                    # One-command launcher
```

