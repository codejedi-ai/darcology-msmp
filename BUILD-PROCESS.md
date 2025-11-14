# Build Process

This project uses a two-stage Docker build process to optimize build times.

## Build Structure

### 1. Forge Base Image (Built Once)
**File:** `containers/minecraft/Dockerfile.forge-base`
**Image:** `minecraft-forge-base:1.20.1-47.4.0`

This image contains:
- OpenJDK 21
- System dependencies (bash, curl, screen, wget, zip, python3)
- ttyd web terminal
- **Forge 1.20.1-47.4.0 (pre-installed)**

This image is built **once** and reused. It only needs to be rebuilt when:
- Upgrading Forge version
- Upgrading Java version
- Changing system dependencies

### 2. Minecraft Server Image (Built Frequently)
**File:** `containers/minecraft/Dockerfile`
**Base:** `FROM minecraft-forge-base:1.20.1-47.4.0`

This image adds:
- Server configuration (eula.txt, server.properties)
- Mods (extracted from mods.zip)
- Startup scripts (start-server.sh, event_logger.py)

This image is rebuilt whenever you change:
- Mods
- Server configuration
- Startup scripts

## Build Commands

### Automatic Build (Recommended)
```bash
./build.sh
```
This script automatically:
1. Checks if base image exists
2. Builds base image if needed (one-time operation)
3. Builds and starts all services

### Manual Build Process

#### First Time Setup
```bash
# Build the Forge base image (one-time, takes ~3-5 minutes)
docker build -f containers/minecraft/Dockerfile.forge-base -t minecraft-forge-base:1.20.1-47.4.0 .

# Build and start all services
docker compose up -d --build
```

#### Subsequent Builds (Fast)
```bash
# Only rebuilds server image with new mods/configs (takes ~30 seconds)
docker compose up -d --build minecraft-server
```

#### Rebuild Forge Base (Rare)
```bash
# Only needed when upgrading Forge version
docker build -f containers/minecraft/Dockerfile.forge-base -t minecraft-forge-base:1.20.1-47.4.0 .
docker compose up -d --build minecraft-server
```

## Build Time Comparison

| Scenario | Old Build Time | New Build Time |
|----------|---------------|----------------|
| First build (Forge installation) | ~5 minutes | ~5 minutes |
| Rebuild after mod changes | ~5 minutes | **~30 seconds** ⚡ |
| Rebuild after script changes | ~5 minutes | **~10 seconds** ⚡ |
| Rebuild after config changes | ~5 minutes | **~10 seconds** ⚡ |

## Benefits

✅ **90% faster rebuilds** - Forge installation is cached in base image
✅ **Efficient development** - Change mods/configs without waiting for Forge
✅ **Disk space efficient** - Base image is reused across multiple builds
✅ **Version control** - Base image tags track Forge version
✅ **Easy upgrades** - Clear separation between Forge and server config

## Troubleshooting

### Base image not found error
If you get an error about missing base image:
```bash
docker build -f containers/minecraft/Dockerfile.forge-base -t minecraft-forge-base:1.20.1-47.4.0 .
```

### Force rebuild everything
```bash
docker build --no-cache -f containers/minecraft/Dockerfile.forge-base -t minecraft-forge-base:1.20.1-47.4.0 .
docker compose build --no-cache
docker compose up -d
```

### List Docker images
```bash
docker images | grep minecraft
```

You should see:
- `minecraft-forge-base:1.20.1-47.4.0` - Base image with Forge
- `darcology-msmp-minecraft-server` - Your server image
