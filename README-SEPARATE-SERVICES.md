# Separate Services Architecture

The Minecraft server and dashboard are now split into two separate Docker services that run independently but share data.

## Architecture

### Services

1. **`minecraft-server`** - Minecraft Forge server container
   - Runs the Minecraft server
   - Runs ttyd web terminal (port 7681)
   - Exposes ports: 25565 (Minecraft), 24454 (Voice chat), 7681 (ttyd)

2. **`dashboard`** - Rails dashboard container
   - Runs the Rails dashboard (port 80)
   - Runs Python player logger script
   - Monitors the server via shared volumes
   - Exposes port: 80 (Dashboard)

### Shared Volumes

Both services share the following volumes:

- **`./logs:/minecraft/logs`** - Server logs (dashboard reads from this)
- **`./data:/data`** - Shared data directory
  - `mods.zip` - Created by server, accessible by dashboard
  - `usercache.json` - Synced from server, used by dashboard for UUID resolution
  - `player_events.csv` - Created by dashboard's Python logger
  - Other dashboard data files

## Usage

### Start Both Services

```bash
docker compose up -d --build
```

This will:
1. Build both `minecraft-server` and `dashboard` images
2. Start both services
3. Dashboard will wait for server to be ready (via `depends_on`)

### View Logs

```bash
# View all logs
docker compose logs -f

# View server logs only
docker compose logs -f minecraft-server

# View dashboard logs only
docker compose logs -f dashboard
```

### Stop Services

```bash
docker compose down
```

### Rebuild Individual Services

```bash
# Rebuild dashboard only (after Ruby code changes)
docker compose build dashboard
docker compose up -d dashboard

# Rebuild server only (after mod/config changes)
docker compose build minecraft-server
docker compose up -d minecraft-server
```

## How Dashboard Monitors Server

The dashboard monitors the server through:

1. **Log File Access**: Dashboard reads `/minecraft/logs/latest.log` (mounted from host)
2. **Player Tracking**: Python logger polls logs every second and writes to CSV
3. **Server Status**: Rails app checks log file for server ready/initializing status
4. **UUID Resolution**: Dashboard accesses `usercache.json` from shared `/data` volume

## Benefits

- **Independent Scaling**: Can scale dashboard separately from server
- **Independent Updates**: Update dashboard without restarting server
- **Resource Isolation**: Each service has its own memory limits
- **Easier Debugging**: Separate logs and processes
- **Flexibility**: Can run services on different hosts if needed

## Ports

- **25565** - Minecraft server (server service)
- **24454** - Voice chat mod (server service)
- **7681** - ttyd web terminal (server service)
- **80** - Rails dashboard (dashboard service)

## Data Flow

```
Server Container:
  - Writes logs to /minecraft/logs/latest.log (mounted from ./logs)
  - Creates /data/mods.zip
  - Syncs /minecraft/usercache.json → /data/usercache.json

Dashboard Container:
  - Reads /minecraft/logs/latest.log (mounted from ./logs)
  - Reads /data/usercache.json for UUID resolution
  - Writes /data/player_events.csv (Python logger)
  - Serves /data/mods.zip for download
```

