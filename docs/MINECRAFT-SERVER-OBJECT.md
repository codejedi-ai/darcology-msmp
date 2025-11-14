## Minecraft Server Object (Future Database Record)

This document defines the structure for a **future database object** that represents a Minecraft server instance managed by this project. It captures everything needed to recreate the server from source control plus runtime state such as the operator list.

### High-Level Shape

```json
{
  "id": "uuid-or-slug",
  "name": "Modded Survival",
  "description": "Forge 1.20.1 server for the community",
  "composeService": "minecraft-server",
  "imageTag": "minecraft-server:latest",
  "network": {
    "host": "172.25.0.10",
    "ports": [
      { "host": 25565, "container": 25565, "protocol": "TCP", "purpose": "Minecraft" },
      { "host": 24454, "container": 24454, "protocol": "TCP/UDP", "purpose": "Voice Chat" }
    ]
  },
  "paths": {
    "world": "./world",
    "logs": "./logs",
    "data": "./data",
    "opsFile": "/minecraft/ops.json",
    "serverProperties": "/minecraft/server.properties"
  },
  "properties": { /* flattened server.properties (see below) */ },
  "ops": [ /* list of operator entries (see below) */ ],
  "metadata": {
    "createdAt": "ISO8601 timestamp",
    "updatedAt": "ISO8601 timestamp",
    "notes": "free-form text"
  }
}
```

### Operator List (`ops`)

This mirrors the data stored in `/minecraft/ops.json`.

```json
{
  "ops": [
    {
      "uuid": "player-uuid-here",
      "name": "playername",
      "level": 4,
      "bypassesPlayerLimit": false
    }
  ]
}
```

**Level meanings**

| Level | Permission                                                     |
|-------|----------------------------------------------------------------|
| 1     | Bypass spawn protection                                        |
| 2     | Commands like `/clear`, `/gamemode`, `/tp`                     |
| 3     | Commands like `/ban`, `/deop`, `/kick`                         |
| 4     | Full administrative access (default for server owners/admins) |

These entries can be kept in the database and synced to `ops.json` during deployment.

### Server Properties (`properties`)

Store the resolved values that will be rendered into `server.properties`. Example:

```json
{
  "allow-flight": true,
  "allow-nether": true,
  "difficulty": "hard",
  "enable-command-block": false,
  "enable-rcon": false,
  "gamemode": "survival",
  "max-players": 10,
  "motd": "Minecraft ModdedSurvival Server",
  "online-mode": true,
  "op-permission-level": 4,
  "pvp": true,
  "server-port": 25565,
  "simulation-distance": 10,
  "view-distance": 10,
  "white-list": false
}
```

* Store only properties you actually override; defaults can be inferred from version control.
* When `docker-compose.yml` gains future fields (e.g., an `OPS` environment variable), this object should be the single source of truth that feeds both `server.properties` and `ops.json`.

### Suggested Database Schema (Document Form)

```json
{
  "_id": "ObjectId or UUID",
  "name": "string",
  "slug": "string",
  "composeService": "string",
  "imageTag": "string",
  "network": {
    "ip": "string",
    "ports": [
      { "host": 25565, "container": 25565, "protocol": "TCP", "label": "minecraft" },
      { "host": 24454, "container": 24454, "protocol": "UDP", "label": "voicechat" }
    ]
  },
  "paths": {
    "world": "string",
    "logs": "string",
    "data": "string"
  },
  "properties": "object",
  "ops": [
    {
      "uuid": "string",
      "name": "string",
      "level": "number",
      "bypassesPlayerLimit": "boolean"
    }
  ],
  "createdAt": "ISO8601 timestamp",
  "updatedAt": "ISO8601 timestamp"
}
```

### Future `docker-compose.yml` Concept

When ready, add an environment variable or mounted JSON file:

```yaml
services:
  minecraft-server:
    environment:
      - OPS_JSON_PATH=/minecraft/ops.json
    volumes:
      - ./ops.json:/minecraft/ops.json:ro
```

That keeps the runtime container aligned with the database representation above.

---

**Next steps (future work):**
1. Build a small sync script that reads the database record, writes `server.properties` and `ops.json`, then runs `docker compose up`.
2. Extend the planned Flask control plane to update this object when players are promoted/demoted via API.

