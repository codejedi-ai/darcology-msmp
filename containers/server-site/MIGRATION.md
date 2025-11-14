# Data Migration Guide

## Overview

The data folder structure has been updated to use UUID-based identification and folder organization. This document explains how to migrate from the old format to the new format.

## Old Structure (Deprecated)

```
/data/
├── player_playtime.json      # Single file with all players (keyed by name)
├── player_sessions.csv
├── cpu_stats.csv
└── memory_stats.csv
```

## New Structure (Current)

```
/data/
├── online/                    # Online players (JSON files)
│   └── {uuid}.json           # One file per online player
├── player_playtime/           # Player playtime data (JSON files)
│   └── {uuid}.json           # One file per player
├── player_sessions.csv       # Player join/leave event logs (CSV with UUID)
├── player_tracker_state.json # Player tracker internal state (JSON)
├── cpu_stats.csv             # CPU usage history (CSV)
└── memory_stats.csv          # Memory usage history (CSV)
```

## Automatic Migration

The migration runs automatically when the container starts. The `start.sh` script executes:

```bash
RAILS_ENV=production bundle exec rake data:migrate
```

This will:
1. Create the new folder structure (`/data/online/` and `/data/player_playtime/`)
2. Convert old `player_playtime.json` to individual UUID-based files
3. Backup the old file to `player_playtime.json.backup`
4. Remove the old `player_playtime.json` file

## Manual Migration

If you need to run the migration manually:

```bash
# Inside the container
cd /dashboard
RAILS_ENV=production bundle exec rake data:migrate
```

## Migration Process

1. **Reads old format**: Parses `player_playtime.json` (keyed by username)
2. **Resolves UUIDs**: Uses `UuidResolver` to get UUID for each player
3. **Creates new files**: Creates `/data/player_playtime/{uuid}.json` for each player
4. **Preserves data**: All playtime data is preserved during migration
5. **Backs up**: Old file is backed up before deletion

## Notes

- The migration is **idempotent** - safe to run multiple times
- Old data is backed up before deletion
- If a UUID file already exists, data is merged (max playtime is preserved)
- The migration only runs if `player_playtime.json` exists

## Verification

After migration, verify the structure:

```bash
# Check folders exist
ls -la /data/online/
ls -la /data/player_playtime/

# Check old file is gone (or backed up)
ls -la /data/player_playtime.json*
```

## Troubleshooting

If migration fails:
1. Check Rails logs for errors
2. Verify `/data` directory is writable
3. Check that `UuidResolver` can access `/minecraft/usercache.json`
4. Old file backup is at `/data/player_playtime.json.backup`

## Related Documentation

- See [DATA-SCHEMA.md](./DATA-SCHEMA.md) for the current data schema documentation

