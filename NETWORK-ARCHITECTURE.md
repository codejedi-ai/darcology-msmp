# Network Architecture

## Overview

All containers run in a **private isolated network** called `minecraft-network` with subnet `172.25.0.0/16`.

## Container IP Addresses

### Static IP Assignments

| Container | Service Name | Static IP | Purpose |
|-----------|-------------|-----------|---------|
| Minecraft Server | `minecraft-server` | 172.25.0.10 | Runs Minecraft Forge, ttyd terminal |
| Web Server (nginx) | `server-site` | 172.25.0.20 | Serves web UI, proxies terminal |

### Network Gateway
- Gateway: `172.25.0.1`
- Subnet: `172.25.0.0/16` (65,534 available IPs)

## How Containers Communicate

### Docker DNS Resolution
Containers can reach each other using **service names** - Docker automatically resolves them to IPs:

```bash
# From server-site container, these all work:
ping minecraft-server          # Resolves to 172.25.0.10
curl http://minecraft-server:7681  # Access ttyd terminal

# From minecraft-server container:
ping server-site               # Resolves to 172.25.0.20
curl http://server-site        # Access nginx
```

### Environment Variables
Each container has environment variables with network information:

**minecraft-server container:**
```bash
SERVER_SITE_HOST=server-site
SERVER_SITE_IP=172.25.0.20
```

**server-site container:**
```bash
MINECRAFT_SERVER_HOST=minecraft-server
MINECRAFT_SERVER_IP=172.25.0.10
MINECRAFT_SERVER_TERMINAL_PORT=7681
```

## Network Flow Diagrams

### Web Terminal Access
```
User Browser
    ↓ (HTTP)
    → server-site:80 (172.25.0.20)
         ↓ (nginx proxy)
         → /server-terminal
              ↓ (internal network)
              → minecraft-server:7681 (172.25.0.10)
                   ↓ (ttyd)
                   → Minecraft console
```

### Minecraft Game Connection
```
Minecraft Client
    ↓ (TCP)
    → Host Port 25565
         ↓ (Docker port mapping)
         → minecraft-server:25565 (172.25.0.10)
              ↓
              → Forge Server
```

### Voice Chat
```
Voice Chat Client
    ↓ (UDP/TCP)
    → Host Port 24454
         ↓ (Docker port mapping)
         → minecraft-server:24454 (172.25.0.10)
              ↓
              → Voice Chat Mod
```

## Exposed Ports (External Access)

Only these ports are accessible from outside the Docker network:

| Host Port | Container | Container Port | Service |
|-----------|-----------|----------------|---------|
| 80 | server-site | 80 | Web UI (nginx) |
| 25565 | minecraft-server | 25565 | Minecraft Server |
| 24454 | minecraft-server | 24454 | Voice Chat Mod |

**Note:** Port 7681 (ttyd) is **NOT** exposed to the host - it's only accessible via nginx proxy at `/server-terminal`.

## Security Features

### Network Isolation
✅ Private subnet isolated from other Docker networks
✅ Containers can only communicate within `minecraft-network`
✅ No direct access to container ports except through exposed ports

### Port Security
✅ Only 3 ports exposed to external network (80, 25565, 24454)
✅ ttyd terminal only accessible through authenticated nginx proxy
✅ Internal services (7681) not accessible from outside

### Outbound Access
✅ Containers can make outbound connections (for Mojang authentication, updates)
✅ Inbound connections blocked except through exposed ports

## Nginx Proxy Configuration

The nginx server proxies requests to internal services:

```nginx
# Terminal proxy (line 29-39 in nginx.conf)
location /server-terminal {
    proxy_pass http://minecraft-server:7681;  # Uses Docker DNS
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;   # WebSocket support
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 86400;
}
```

**How it works:**
1. User accesses `http://yourserver/server-terminal`
2. Nginx receives request on 172.25.0.20:80
3. Docker DNS resolves `minecraft-server` → 172.25.0.10
4. Nginx proxies to http://172.25.0.10:7681
5. WebSocket connection established for terminal

## Testing Network Connectivity

### From Host Machine
```bash
# Test web server
curl http://localhost/

# Test Minecraft server (requires mc client)
nc -zv localhost 25565

# View container IPs
docker inspect minecraft-server | grep IPAddress
docker inspect minecraft-server-site | grep IPAddress
```

### From Inside Containers
```bash
# Enter server-site container
docker exec -it minecraft-server-site sh

# Test connectivity to minecraft-server
ping minecraft-server
curl http://minecraft-server:7681
nslookup minecraft-server

# Check environment variables
env | grep MINECRAFT
```

```bash
# Enter minecraft-server container
docker exec -it minecraft-server bash

# Test connectivity to server-site
ping server-site
curl http://server-site
nslookup server-site

# Check environment variables
env | grep SERVER_SITE
```

## Network Troubleshooting

### Container can't reach another container
```bash
# Verify both containers are on the same network
docker network inspect darcology-msmp_minecraft-network

# Check DNS resolution
docker exec minecraft-server-site nslookup minecraft-server

# Check routing
docker exec minecraft-server-site ping 172.25.0.10
```

### Terminal proxy not working
```bash
# Check nginx is running
docker exec minecraft-server-site nginx -t

# Check if minecraft-server:7681 is accessible
docker exec minecraft-server-site curl http://minecraft-server:7681

# Check ttyd is running
docker exec minecraft-server ps aux | grep ttyd
```

### View network details
```bash
# List all networks
docker network ls

# Inspect minecraft network
docker network inspect darcology-msmp_minecraft-network

# Show all containers in network
docker network inspect darcology-msmp_minecraft-network | grep -A 10 Containers
```

## Changing Network Configuration

### Modify subnet or IPs
Edit `docker-compose.yml`:
```yaml
networks:
  minecraft-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.25.0.0/16  # Change subnet here
          gateway: 172.25.0.1     # Change gateway here

services:
  minecraft-server:
    networks:
      minecraft-network:
        ipv4_address: 172.25.0.10  # Change container IP here
```

Then recreate network:
```bash
docker-compose down
docker-compose up -d
```

**Important:** Changing IPs requires updating environment variables to match!
