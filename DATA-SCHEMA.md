# Data Folder Schema Documentation

This document describes the schema and structure of each file stored in the `/data` directory (mounted at `./data` on the host machine).

## File Overview

The `/data` folder contains the following structure:

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

**Important:** All player identification is now UUID-based. Player UUIDs are the primary key for all player-related data.

---

## 1. `/data/online/{uuid}.json`

**Type:** JSON  
**Purpose:** Indicates a player is currently online  
**File Naming:** `{uuid}.json` where `{uuid}` is the player's Minecraft UUID  
**Retention:** File is created when player joins, deleted when player leaves

### Schema

```json
{
  "uuid": "string",
  "name": "string",
  "joined_at": "ISO8601 string",
  "session_start": "ISO8601 string"
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `uuid` | String | Player's Minecraft UUID (primary key) |
| `name` | String | Player's current username |
| `joined_at` | String | ISO8601 timestamp when player joined |
| `session_start` | String | ISO8601 timestamp when current session started |

### Example

```json
{
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Steve",
  "joined_at": "2025-11-14T01:00:00Z",
  "session_start": "2025-11-14T01:00:00Z"
}
```

### Notes

- One file per online player
- File is automatically deleted when player leaves
- Used to quickly identify which players are currently online
- UUID is the filename (e.g., `550e8400-e29b-41d4-a716-446655440000.json`)

---

## 2. `/data/player_playtime/{uuid}.json`

**Type:** JSON  
**Purpose:** Stores cumulative playtime statistics for each player  
**File Naming:** `{uuid}.json` where `{uuid}` is the player's Minecraft UUID  
**Retention:** Persistent (updated when player leaves)

### Schema

```json
{
  "uuid": "string",
  "name": "string",
  "total_playtime": number,
  "session_count": number,
  "first_seen": "ISO8601 string or null",
  "last_seen": "ISO8601 string or null",
  "last_session_duration": number,
  "last_session_end": "ISO8601 string or null"
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `uuid` | String | Player's Minecraft UUID (primary key, also filename) |
| `name` | String | Player's current username |
| `total_playtime` | Number (Float) | Total accumulated playtime in seconds (only completed sessions) |
| `session_count` | Number (Integer) | Number of completed sessions |
| `first_seen` | String or null | ISO8601 timestamp of first join, or `null` if not set |
| `last_seen` | String or null | ISO8601 timestamp of last activity, or `null` if not set |
| `last_session_duration` | Number (Float) | Duration of most recent session in seconds |
| `last_session_end` | String or null | ISO8601 timestamp when most recent session ended |

### Example

```json
{
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Steve",
  "total_playtime": 3600.5,
  "session_count": 3,
  "first_seen": "2025-11-13T23:49:50Z",
  "last_seen": "2025-11-14T01:10:20Z",
  "last_session_duration": 1800.0,
  "last_session_end": "2025-11-14T01:10:20Z"
}
```

### Notes

- One file per player (UUID as filename)
- `total_playtime` only includes completed sessions (time saved when player leaves)
- Current active session is NOT included in `total_playtime` (only displayed in real-time)
- File is updated whenever a player leaves the server
- UUID remains constant even if player changes username

---

## 3. `player_sessions.csv`

**Type:** CSV (Comma-Separated Values)  
**Purpose:** Logs all player join and leave events  
**Retention:** Unlimited (grows over time)  
**Primary Key:** `player_uuid` (combined with `timestamp` for uniqueness)

### Schema

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `timestamp` | ISO8601 String | Event timestamp in ISO 8601 format | `2025-11-13T23:49:50Z` |
| `event_type` | String | Type of event: `"join"` or `"leave"` | `"join"` |
| `player_uuid` | UUID String | Player's Minecraft UUID (primary key) | `550e8400-e29b-41d4-a716-446655440000` |
| `player_name` | String | Player's username at time of event | `"Steve"` |

### Example

```csv
timestamp,event_type,player_uuid,player_name
2025-11-13T23:49:50Z,join,550e8400-e29b-41d4-a716-446655440000,Steve
2025-11-13T23:55:30Z,leave,550e8400-e29b-41d4-a716-446655440000,Steve
2025-11-14T00:10:15Z,join,6ba7b810-9dad-11d1-80b4-00c04fd430c8,Alex
```

### Notes

- Header row is written automatically when the file is first created
- Events are appended in chronological order
- `player_uuid` is the primary key for identifying players
- `player_name` may change over time, but `player_uuid` remains constant
- Used for displaying session logs in the dashboard

---

## 4. `player_tracker_state.json`

**Type:** JSON  
**Purpose:** Internal state persistence for the PlayerTracker (runtime state)  
**Retention:** Persistent (updated frequently during runtime)  
**Key Structure:** UUID-based keys

### Schema

```json
{
  "{uuid}": {
    "uuid": "string",
    "name": "string",
    "joined_at": "ISO8601 string or null",
    "last_activity": "ISO8601 string or null",
    "total_playtime": number,
    "current_session_start": "ISO8601 string or null",
    "is_online": boolean,
    "left_at": "ISO8601 string or null"
  }
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `uuid` | String | Player's Minecraft UUID (primary key, also top-level key) |
| `name` | String | Player's current username |
| `joined_at` | String or null | ISO8601 timestamp of most recent join |
| `last_activity` | String or null | ISO8601 timestamp of last activity (chat, command, etc.) |
| `total_playtime` | Number (Float) | Total accumulated playtime in seconds (only completed sessions) |
| `current_session_start` | String or null | ISO8601 timestamp when current session started, or `null` if offline |
| `is_online` | Boolean | `true` if player is currently online, `false` if offline |
| `left_at` | String or null | ISO8601 timestamp of most recent leave, or `null` if never left |

### Example

```json
{
  "550e8400-e29b-41d4-a716-446655440000": {
    "uuid": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Steve",
    "joined_at": "2025-11-14T01:00:00Z",
    "last_activity": "2025-11-14T01:15:30Z",
    "total_playtime": 3600.5,
    "current_session_start": "2025-11-14T01:00:00Z",
    "is_online": true,
    "left_at": null
  },
  "6ba7b810-9dad-11d1-80b4-00c04fd430c8": {
    "uuid": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
    "name": "Alex",
    "joined_at": "2025-11-14T00:10:15Z",
    "last_activity": "2025-11-14T00:40:15Z",
    "total_playtime": 1800.0,
    "current_session_start": null,
    "is_online": false,
    "left_at": "2025-11-14T00:40:15Z"
  }
}
```

### Notes

- This is the internal runtime state used by PlayerTracker
- Top-level keys are UUIDs (not usernames)
- Updated frequently during server operation
- Used to restore player state after container restart
- `current_session_start` is `null` when player is offline
- `total_playtime` only includes completed sessions

---

## 5. `cpu_stats.csv`

**Type:** CSV (Comma-Separated Values)  
**Purpose:** Historical CPU usage statistics  
**Retention:** Last 10,000 entries (auto-trimmed)

### Schema

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `timestamp` | ISO8601 String | Measurement timestamp | `2025-11-14T01:00:00Z` |
| `usage_percent` | Float | CPU usage percentage (0-100) | `45.67` |
| `cores` | Integer | Number of CPU cores | `4` |

### Example

```csv
timestamp,usage_percent,cores
2025-11-14T01:00:00Z,45.67,4
2025-11-14T01:00:01Z,46.23,4
2025-11-14T01:00:02Z,44.89,4
```

### Notes

- Header row is written automatically when the file is first created
- Measurements are logged approximately once per second
- File is automatically trimmed to keep only the last 10,000 entries
- Used for CPU usage charts in the dashboard

---

## 6. `memory_stats.csv`

**Type:** CSV (Comma-Separated Values)  
**Purpose:** Historical memory usage statistics  
**Retention:** Last 10,000 entries (auto-trimmed)

### Schema

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `timestamp` | ISO8601 String | Measurement timestamp | `2025-11-14T01:00:00Z` |
| `total` | Integer | Total memory in bytes | `8589934592` |
| `used` | Integer | Used memory in bytes | `4294967296` |
| `free` | Integer | Free memory in bytes | `2147483648` |
| `available` | Integer | Available memory in bytes | `3221225472` |
| `usage_percent` | Float | Memory usage percentage (0-100) | `50.0` |

### Example

```csv
timestamp,total,used,free,available,usage_percent
2025-11-14T01:00:00Z,8589934592,4294967296,2147483648,3221225472,50.0
2025-11-14T01:00:01Z,8589934592,4300000000,2140000000,3210000000,50.1
```

### Notes

- Header row is written automatically when the file is first created
- All memory values are in bytes
- Measurements are logged approximately once per second
- File is automatically trimmed to keep only the last 10,000 entries
- Used for memory usage charts in the dashboard
- `available` = `free` + `buffers` + `cached` (memory that can be used by applications)

---

## UUID Resolution

Player UUIDs are resolved from `/minecraft/usercache.json` which is maintained by the Minecraft server. The UUID resolver:

1. **Primary Source**: Reads UUID mappings from `/minecraft/usercache.json`
2. **Fallback**: If UUID not found in usercache, generates a deterministic UUID v5 from username
3. **Caching**: UUID mappings are cached for performance
4. **Reloading**: Cache is periodically reloaded to catch new players

### UUID Format

Minecraft UUIDs follow the standard UUID format:
```
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Example: `550e8400-e29b-41d4-a716-446655440000`

---

## Data Persistence

All files in the `/data` directory are:
- **Mounted from host**: `./data:/data` in `docker-compose.yml`
- **Persistent across restarts**: Data survives container restarts
- **Backed up**: Can be backed up by copying the `./data` folder on the host
- **Git ignored**: The `./data` folder is excluded from version control (see `.gitignore`)

## File Locations

- **Container path**: `/data/`
- **Host path**: `./data/` (relative to docker-compose.yml location)

## Notes

- All timestamps use ISO 8601 format (e.g., `2025-11-14T01:00:00Z`)
- CSV files use comma as delimiter
- JSON files are pretty-printed for readability
- CSV files are automatically trimmed to prevent excessive growth
- **Player data is keyed by UUID** (not username) - this ensures data consistency even if players change their usernames
- UUID is the primary key/superkey for all player-related data structures
