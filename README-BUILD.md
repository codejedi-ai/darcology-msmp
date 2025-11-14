# Separate Build Process

This project supports building the dashboard and Minecraft server separately, allowing you to update one without rebuilding the other.

## Quick Start

**Build everything (first time):**
```bash
./build.sh
```

This will:
1. Build `minecraft-dashboard:latest` (dashboard only)
2. Build `minecraft-base:latest` (Minecraft server only)
3. Build `minecraft-server:latest` (combined final image)

## Updating Dashboard Only

When you change dashboard code, rebuild only the dashboard:

```bash
# Rebuild dashboard
docker build -f dashboard/Dockerfile -t minecraft-dashboard:latest .

# Rebuild final combined image (uses cached minecraft-base)
docker build -f Dockerfile -t minecraft-server:latest .
```

## Updating Minecraft Server Only

When you change mods, configs, or server files:

```bash
# Rebuild minecraft base
docker build -f containers/minecraft/Dockerfile -t minecraft-base:latest .

# Rebuild final combined image (uses cached minecraft-dashboard)
docker build -f Dockerfile -t minecraft-server:latest .
```

## Docker Compose

Docker Compose will use the main `Dockerfile` which expects the separate images to exist. Make sure to build them first:

```bash
# Build separate images first
./build.sh

# Then use docker compose
docker compose up -d
```

## File Structure

- `containers/server-site/Dockerfile` - Builds server site image using Nginx base
- `containers/minecraft/Dockerfile` - Builds Minecraft base image using Azul Zulu Java base (`minecraft-base:latest`)
- `Dockerfile` - Combines both images into final image (`minecraft-server:latest`)
- `build.sh` - Script to build all three images

## Benefits

- **Faster rebuilds**: Update dashboard without rebuilding Minecraft server
- **Independent caching**: Each component has its own build cache
- **Flexibility**: Can update dashboard and Minecraft server independently
- **Smaller rebuild scope**: Only rebuild what changed

