# Rebuilding Dashboard After Ruby Code Changes

## Quick Rebuild (Dashboard Only)

When you make changes to Ruby code in the `dashboard/` folder, rebuild the dashboard image:

```bash
# Rebuild dashboard image (includes all Ruby code changes)
docker build -f dashboard/Dockerfile -t minecraft-dashboard:latest .

# Rebuild final combined image (uses the updated dashboard)
docker build -f Dockerfile -t minecraft-server:latest .
```

## Full Rebuild

To rebuild everything from scratch:

```bash
./build.sh
```

## Why Rebuild is Needed

Docker caches layers to speed up builds. When you change Ruby files:

1. **The `COPY dashboard/ ./` step** in `dashboard/Dockerfile` will detect file changes
2. **All subsequent layers are invalidated** (including asset precompilation)
3. **The new code is included** in the rebuilt image

## Verification

After rebuilding, verify your changes are included:

```bash
# Check if container has your changes
docker run --rm minecraft-server:latest cat /dashboard/app/models/data_logger.rb | head -20
```

## Migration on Startup

The migration script runs automatically when the container starts via `start.sh`:

- **Deletes old `player_playtime.json`** (deprecated schema)
- **Creates new folder structure**: `/data/online/` and `/data/player_playtime/`
- **Migrates data** from old format to new UUID-based format

The old schema files are **permanently deleted** - no backups are kept.

