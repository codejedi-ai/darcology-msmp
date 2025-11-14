# Minecraft Container Data Usage

This document describes how the **minecraft-server** container uses the shared `/data` directory.

## Overview

The minecraft container primarily **reads** from the `/data` directory and **writes** event logs. It does not manage player tracking or system statistics (those are handled by the server-site service).

## Data Files Written by Minecraft Container

### 1. Player Events: `/data/player_events.csv`

**Service:** minecraft (event_logger.py)  
**Type:** CSV (Comma-Separated Values)  
**Purpose:** Logs player logon/logoff events parsed from Minecraft server logs  
**Retention:** Unlimited (grows over time)

#### Schema

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `timestamp` | ISO8601 String | Event timestamp | `2025-11-14T01:00:00Z` |
| `uuid` | UUID String | Player's Minecraft UUID | `550e8400-e29b-41d4-a716-446655440000` |
| `name` | String | Player's username | `"Steve"` |
| `state` | String | Event type: `"logon"`, `"logoff"`, or `"startup"` | `"logon"` |

#### Example

```csv
timestamp,uuid,name,state
2025-11-14T01:00:00Z,550e8400-e29b-41d4-a716-446655440000,Steve,logon
2025-11-14T01:30:00Z,550e8400-e29b-41d4-a716-446655440000,Steve,logoff
```

#### Notes

- Parsed from Minecraft server log files (`/minecraft/logs/latest.log`)
- Uses UUID resolution from usercache.json
- Different from `player_sessions.csv` (which is managed by server-site)
- Includes server startup events with UUID `00000000-0000-0000-0000-000000000000`

---

### 2. Entity Deaths: `/data/entity_deaths.csv`

**Service:** minecraft (event_logger.py)  
**Type:** CSV (Comma-Separated Values)  
**Purpose:** Logs entity death events parsed from Minecraft server logs  
**Retention:** Unlimited (grows over time)

#### Schema

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `timestamp` | ISO8601 String | Event timestamp | `2025-11-14T01:00:00Z` |
| `entity_name` | String | Name of the entity that died | `"Zombie"` |
| `entity_type` | String | Type of entity | `"minecraft:zombie"` |
| `killer` | String | Player or entity that killed it | `"Steve"` |
| `X` | Float | X coordinate | `123.5` |
| `Y` | Float | Y coordinate | `64.0` |
| `Z` | Float | Z coordinate | `-456.7` |

#### Example

```csv
timestamp,entity_name,entity_type,killer,X,Y,Z
2025-11-14T01:00:00Z,Zombie,minecraft:zombie,Steve,123.5,64.0,-456.7
```

#### Notes

- Parsed from Minecraft server log files
- Includes coordinates where the death occurred
- Can track player deaths, mob deaths, etc.

---

## Data Files Read by Minecraft Container

### 1. User Cache: `/data/usercache.json` (or `/minecraft/usercache.json`)

**Service:** minecraft (event_logger.py - UuidResolver)  
**Type:** JSON  
**Purpose:** UUID-to-username mappings for player identification  
**Source:** Maintained by Minecraft server

#### Schema

```json
[
  {
    "name": "string",
    "uuid": "UUID string",
    "expiresOn": "ISO8601 string"
  }
]
```

#### Notes

- Primary source for UUID resolution
- Falls back to `/minecraft/usercache.json` if `/data/usercache.json` doesn't exist
- If UUID not found, generates deterministic UUID v5 as fallback
- Used by `event_logger.py` to resolve player UUIDs from usernames in log files

---

### 2. Mods Archive: `/data/mods.zip`

**Service:** minecraft (read by server-site for serving)  
**Type:** ZIP archive  
**Purpose:** Archive of all server mods for player download  
**Source:** Created during Docker build process

#### Notes

- Contains all mods from `containers/minecraft/mods/` directory
- Served by server-site at `/download_mods` endpoint
- Allows players to download all required mods as a single file

---

## Event Logger Script

The `event_logger.py` script runs continuously in the minecraft container and:

1. **Polls** `/minecraft/logs/latest.log` every second
2. **Parses** log lines for player events and entity deaths
3. **Resolves** player UUIDs using `UuidResolver`
4. **Writes** events to CSV files in `/data/`

### Architecture

- **UuidResolver**: Handles UUID resolution from usercache.json with fallback generation
- **LogTimestampExtractor**: Extracts timestamps from log lines
- **EventParser**: Base class for parsing different event types
  - `PlayerEventParser`: Parses player join/leave events
  - `EntityDeathParser`: Parses entity death events
- **CsvWriter**: Base class for writing CSV files
  - `PlayerEventWriter`: Writes player events
  - `EntityDeathWriter`: Writes entity deaths

### Usage

The script is started automatically when the minecraft container starts. It runs in the background and continuously monitors the server logs.

---

## Data Persistence

All files in the `/data` directory are:
- **Mounted from host**: `./data:/data` in `docker-compose.yml`
- **Persistent across restarts**: Data survives container restarts
- **Shared between containers**: Both minecraft and server-site can access `/data`

## File Locations

- **Container path**: `/data/`
- **Host path**: `./data/` (relative to docker-compose.yml location)

## Notes

- The minecraft container focuses on **parsing and logging events** from server logs
- Player tracking and statistics are managed by the **server-site** service
- UUID resolution uses usercache.json maintained by the Minecraft server
- Event logs are written in CSV format for easy analysis
- All timestamps use ISO 8601 format

