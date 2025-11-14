# Minecraft Forge Server - Docker Setup

A Docker setup for running a Minecraft Forge 1.20.1 server with a player guide website. The server runs in one container, and a static player guide site runs in another.

## Features

- **Minecraft Forge 1.20.1 Server** - Full-featured modded Minecraft server
- **Player Guide Site** - Static HTML site accessible at `http://localhost:80`
  - Complete player guide for connecting to the server
  - Instructions for Prism Launcher, MultiMC, and ManyMC
  - Offline bypass guide
  - Download all server mods as a zip file
- **Web Terminal** - ttyd-based web terminal accessible at `http://localhost:7681`
- **Azul Zulu Java 21** - Optimized Java runtime
- **Optimized JVM Flags** - Aikar's flags for better performance
- **Configurable Memory Allocation** - Adjust RAM allocation via environment variables
- **Voice Chat Mod Support** - Port 24454 for voice chat mods
- **Persistent Storage** - World and logs folders mounted from host

## Requirements

- Docker
- Docker Compose (recommended)
- At least 6GB RAM available for the container (4GB for Minecraft + 2GB overhead)

## Quick Start

### Using Docker Compose (Recommended)

1. Build and start the container:
```bash
docker compose up -d --build
```

2. View logs:
```bash
docker compose logs -f
```

       3. Access the services:
          - **Player Guide Site**: http://localhost:80
          - **Web Terminal**: http://localhost:7681
          - **Minecraft Server**: localhost:25565

4. Stop the server:
```bash
docker compose down
```

### Using Docker CLI

1. Build the image:
```bash
docker build -t minecraft-forge .
```

2. Run the container:
```bash
docker run -d \
  --name minecraft-server \
  -p 25565:25565 \
  -p 24454:24454 \
  -p 80:80 \
  -p 7681:7681 \
  -v $(pwd)/world:/minecraft/world \
  -v $(pwd)/logs:/minecraft/logs \
  -e MAX_RAM=4G \
  -e MIN_RAM=4G \
  -e ONLINE_MODE=true \
  minecraft-forge
```

**Note:** `level-name` is already set to `"world"` in `server.properties` and should not be changed. It refers to the container's internal folder name (`/minecraft/world`), regardless of what host folder you map to it. You can map any host folder (e.g., `/path/to/my-world:/minecraft/world`), but the `level-name` property must always be `"world"`.

## Services

### Player Guide Site (Port 80)

The **server-site** is a static HTML player guide that provides:

- **Player Instructions**: Complete guide for connecting to the server
- **Launcher Guides**: Instructions for Prism Launcher, MultiMC, and ManyMC
- **Offline Bypass**: Guide for using offline accounts
- **Mods Download**: Download all server mods as a zip file
- **Server Information**: Connection details and troubleshooting

Access at: `http://localhost:80`

### Web Terminal (Port 7681)

Full server console access via web browser using ttyd. Connect to the Minecraft server's screen session to run commands, view logs, and manage the server.

Access at: `http://localhost:7681`

### Minecraft Server (Port 25565)

Standard Minecraft server port. Connect using your Minecraft client with the server address `localhost:25565` (or your server's IP address).

## Configuration

### Memory Settings

Edit `docker-compose.yml` to adjust memory allocation:

```yaml
environment:
  - MAX_RAM=4G    # Maximum RAM (adjust based on your system)
  - MIN_RAM=4G   # Minimum RAM (should match MAX_RAM for best performance)
```

**Important:** Set MAX_RAM and MIN_RAM to the same value for best performance. The container memory limit should be ~1.5-2GB more than these values.

### Server Properties

Server properties can be configured in two ways:

1. **Edit `containers/minecraft/server.properties`** directly (requires rebuild)
2. **Use environment variables** in `docker-compose.yml` (see commented options)

Available environment variables include:
- `ONLINE_MODE` - Authentication mode (true/false)
- `MAX_PLAYERS` - Maximum players
- `DIFFICULTY` - Game difficulty
- `GAMEMODE` - Default game mode
- `VIEW_DISTANCE` - Render distance
- And many more (see docker-compose.yml for full list)

## Volume Mappings

The following folders are mounted from your host machine:

- `./world` → `/minecraft/world` - Server world data (your world files)
- `./data` → `/data` - Shared data (mods.zip, usercache.json)
- `./logs` → `/minecraft/logs` - Server logs

**Important:** You can map any host folder to `/minecraft/world` in the container. For example, to use a different host folder:
```yaml
volumes:
  - /path/to/your/world:/minecraft/world
```

The `level-name` property in `server.properties` is already set to `"world"` and should not be changed, as it refers to the container's internal folder name (`/minecraft/world`), regardless of what host folder you map to it.

Mods and configuration files are copied from the `containers/minecraft/` folder during the Docker build process. To update mods or configs, modify files in the `containers/minecraft/` folder and rebuild the container.

## First Run

On first run, the containers will:
1. Update server.properties from environment variables
2. Install Forge server files (if not already installed)
3. Start the player guide site on port 80
4. Start ttyd web terminal on port 7681
5. Start the Minecraft server in a screen session

This may take a few minutes. Monitor progress with:
```bash
docker compose logs -f
```

Once started:
- Access the player guide at `http://localhost:80`
- Access the web terminal at `http://localhost:7681`
- Connect to the Minecraft server at `localhost:25565`

## Accessing Server Console

### Web Terminal (Recommended)

Access the server console via web browser at:
```
http://localhost:7681
```

The web terminal provides full access to the Minecraft server console running in a screen session.

### Player Guide Site

The player guide site at `http://localhost:80` provides complete instructions for players to connect to the server, including launcher setup and mod installation.

### Docker Attach

To run commands in the server console via Docker:
```bash
docker attach minecraft-server
```

To detach without stopping the server: Press `Ctrl+P` then `Ctrl+Q`

### Docker Exec

Or execute commands directly:
```bash
docker exec -it minecraft-server screen -r minecraft
```

## Stopping the Server

Graceful shutdown:
```bash
docker compose down
```

Or send stop command via screen:
```bash
docker exec minecraft-server screen -S minecraft -X stuff "stop\n"
```

## Updating Mods

1. Stop the server
2. Add/remove mods in the `containers/minecraft/mods/` folder
3. Update configs in the `containers/minecraft/config/` folder if needed
4. Rebuild the container: `docker compose build`
5. Start the server: `docker compose up -d`

## Troubleshooting

### Server won't start
- Check logs: `docker compose logs -f`
- Ensure EULA is accepted in `eula.txt`
- Verify sufficient memory is allocated

### Player Guide Site not accessible
- Check if nginx is running: `docker exec minecraft-server-site ps aux | grep nginx`
- Check nginx logs: `docker compose logs server-site`
- Restart the site: `docker compose restart server-site`

### Out of memory errors
- Increase `MAX_RAM` in docker-compose.yml
- Reduce loaded chunks/view distance
- Remove unnecessary mods

### Port already in use
- Change the host port in docker-compose.yml: `"25566:25565"`
- Update `containers/minecraft/server.properties` to match (or use SERVER_PORT environment variable)

### Permission issues
- Ensure folders have correct permissions: `chmod -R 755 world logs containers`

## Container Architecture

The setup uses two separate containers:

### Minecraft Server Container
- **Base Image**: Azul Zulu OpenJDK 21
- **Java**: Azul Zulu OpenJDK 21 (for Minecraft server)
- **Web Terminal**: ttyd 1.7.4
- **Process Manager**: Screen (for Minecraft server session)

### Server Site Container
- **Base Image**: nginx:alpine
- **Web Server**: nginx (serving static HTML)

## Container Sizes

The container images are approximately:
- **Minecraft Server**: ~400MB (Java + Forge + ttyd)
- **Server Site**: ~25MB (nginx:alpine + static HTML)
- **Total: ~425MB**

Server files (libraries, world data) are stored in volumes and not in the containers.

## Advanced Configuration

### Custom JVM Flags

Edit `start.sh` to modify JVM arguments. Current setup uses Aikar's optimized flags.

### Multiple Servers

To run multiple servers, duplicate the directory and change:
1. Container name in docker-compose.yml
2. Host port mappings (e.g., 25566:25565, 81:80, 7682:7681)

## Backup

To backup your world:
```bash
tar -czf backup-$(date +%Y%m%d).tar.gz world/
```

## License

Ensure you comply with Minecraft's EULA: https://aka.ms/MinecraftEULA
