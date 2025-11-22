# Flask Integration for Minecraft Server Control

## Overview

This directory contains components for a **future Flask server** that will provide programmatic control over the Minecraft server. The Flask server will enable external software to interact with the Minecraft world through RCON, allowing for:

- **Block Placement**: Place blocks at specific coordinates
- **Redstone Control**: Activate/deactivate redstone signals
- **Signal Detection**: Detect redstone signal states
- **World Manipulation**: Execute any Minecraft command programmatically
- **Integration**: Connect Minecraft with external software systems

## Status

⚠️ **This is a future addon** - Components are being prepared but not yet integrated into the main server.

## Architecture

```
External Software/API
        ↓
   Flask Server (Future)
        ↓
   RCON Client
        ↓
   Minecraft Server (RCON enabled)
```

## Components

### 1. RCON Client Script (`execute-command-rcon.py`)

A Python utility for executing Minecraft commands via RCON. This will be used by the Flask server to communicate with the Minecraft server.

**Features:**
- Execute any Minecraft command
- Get command responses
- Environment variable configuration
- Error handling

**Usage:**
```bash
python3 execute-command-rcon.py "say Hello World"
python3 execute-command-rcon.py "setblock 0 64 0 minecraft:redstone_block"
```

**Requirements:**
- `pip install mcrcon`
- RCON must be enabled in `server.properties`

### 2. Flask Server (Future)

A Flask web server that will provide REST API endpoints for controlling the Minecraft server.

**Planned Endpoints:**
- `POST /api/command` - Execute arbitrary Minecraft command
- `POST /api/block/place` - Place a block at coordinates
- `POST /api/redstone/activate` - Activate redstone signal
- `POST /api/redstone/detect` - Detect redstone signal state
- `GET /api/status` - Get server status
- `GET /api/players` - List online players

**Example Usage (Future):**
```python
import requests

# Place a redstone block
response = requests.post('http://flask-server:5000/api/block/place', json={
    'x': 0,
    'y': 64,
    'z': 0,
    'block': 'minecraft:redstone_block'
})

# Detect redstone signal
response = requests.post('http://flask-server:5000/api/redstone/detect', json={
    'x': 0,
    'y': 64,
    'z': 0
})
```

## Setup Instructions

### Step 1: Enable RCON

Edit `containers/minecraft-server/server.properties`:

```properties
enable-rcon=true
rcon.port=25575
rcon.password=your_secure_password_here
```

**Security Note:** Use a strong, unique password for RCON. This password will be exposed to the Flask server.

### Step 2: Install Dependencies

The RCON client requires the `mcrcon` Python package:

```bash
pip install mcrcon
```

For the future Flask server, you'll also need:

```bash
pip install flask flask-cors requests
```

### Step 3: Configure Environment Variables

Set RCON connection details:

```bash
export RCON_HOST=localhost  # or minecraft-server container IP (172.25.0.10)
export RCON_PORT=25575
export RCON_PASSWORD=your_secure_password_here
```

### Step 4: Test RCON Connection

Test the RCON client script:

```bash
cd /minecraft/flask-integration
python3 execute-command-rcon.py "say RCON test successful"
```

## Future Flask Server Implementation

### Planned Structure

```
flask-integration/
├── README.md (this file)
├── execute-command-rcon.py (RCON client utility)
├── flask_app.py (Future Flask server)
├── requirements.txt (Python dependencies)
├── config.py (Configuration management)
└── api/
    ├── __init__.py
    ├── commands.py (Command execution endpoints)
    ├── blocks.py (Block manipulation endpoints)
    └── redstone.py (Redstone control endpoints)
```

### Example Flask Endpoints (Future)

```python
from flask import Flask, request, jsonify
from execute_command_rcon import execute_command

app = Flask(__name__)

@app.route('/api/command', methods=['POST'])
def execute_minecraft_command():
    """Execute arbitrary Minecraft command"""
    data = request.json
    command = data.get('command')
    if not command:
        return jsonify({'error': 'Command required'}), 400
    
    response = execute_command(command)
    return jsonify({'response': response})

@app.route('/api/block/place', methods=['POST'])
def place_block():
    """Place a block at specified coordinates"""
    data = request.json
    x = data.get('x')
    y = data.get('y')
    z = data.get('z')
    block = data.get('block', 'minecraft:stone')
    
    command = f"setblock {x} {y} {z} {block}"
    response = execute_command(command)
    return jsonify({'response': response})

@app.route('/api/redstone/detect', methods=['POST'])
def detect_redstone():
    """Detect redstone signal at coordinates"""
    data = request.json
    x = data.get('x')
    y = data.get('y')
    z = data.get('z')
    
    # Use testforblock or data get to check redstone state
    command = f"data get block {x} {y} {z}"
    response = execute_command(command)
    return jsonify({'response': response})
```

## Integration Use Cases

### 1. Home Automation
- Trigger redstone contraptions from smart home systems
- Monitor player activity and adjust lighting/security

### 2. Data Visualization
- Create visual representations of real-world data in Minecraft
- Build 3D graphs and charts using blocks

### 3. Educational Tools
- Programmatically create structures for teaching
- Simulate real-world scenarios in Minecraft

### 4. Game Development
- Create interactive experiences
- Connect Minecraft to external game engines

### 5. IoT Integration
- Connect physical sensors to Minecraft redstone
- Control real-world devices from Minecraft

## Security Considerations

⚠️ **Important Security Notes:**

1. **RCON Password**: Store securely, never commit to version control
2. **Network Access**: Flask server should only be accessible from trusted networks
3. **Authentication**: Add authentication to Flask API endpoints
4. **Rate Limiting**: Implement rate limiting to prevent abuse
5. **Input Validation**: Validate all coordinates and commands before execution
6. **Permissions**: Consider using command blocks with limited permissions

## Docker Integration (Future)

The Flask server will likely run as a separate container in the `docker-compose.yml`:

```yaml
flask-control:
  build:
    context: .
    dockerfile: containers/flask-control/Dockerfile
  container_name: minecraft-flask-control
  networks:
    minecraft-network:
      ipv4_address: 172.25.0.30
  environment:
    - RCON_HOST=minecraft-server
    - RCON_PORT=25575
    - RCON_PASSWORD=${RCON_PASSWORD}
  ports:
    - "5000:5000"
  depends_on:
    - minecraft-server
```

## Testing

### Test RCON Connection
```bash
docker exec minecraft-server python3 /minecraft/flask-integration/execute-command-rcon.py "say Test"
```

### Test Block Placement (Future)
```bash
curl -X POST http://localhost:5000/api/block/place \
  -H "Content-Type: application/json" \
  -d '{"x": 0, "y": 64, "z": 0, "block": "minecraft:redstone_block"}'
```

## Common Minecraft Commands for Automation

### Block Manipulation
- `setblock <x> <y> <z> <block>` - Place a block
- `fill <x1> <y1> <z1> <x2> <y2> <z2> <block>` - Fill area with blocks
- `clone <x1> <y1> <z1> <x2> <y2> <z2> <x> <y> <z>` - Clone blocks

### Redstone Control
- `setblock <x> <y> <z> minecraft:redstone_block` - Activate redstone
- `setblock <x> <y> <z> minecraft:air` - Deactivate redstone
- `data get block <x> <y> <z>` - Get block data (including redstone state)

### Detection
- `testforblock <x> <y> <z> <block>` - Check if block exists
- `data get block <x> <y> <z> power` - Get redstone power level

## Troubleshooting

### RCON Connection Failed
- Verify RCON is enabled in `server.properties`
- Check RCON password is correct
- Ensure RCON port (25575) is accessible
- Verify environment variables are set

### Command Execution Fails
- Check command syntax
- Verify coordinates are valid
- Ensure player/operator permissions if needed
- Check server logs for errors

## Future Enhancements

- [ ] WebSocket support for real-time updates
- [ ] Command queue system for batch operations
- [ ] Event webhooks (player join/leave, block changes)
- [ ] World backup integration
- [ ] Player management API
- [ ] World generation API
- [ ] Plugin/mod integration endpoints

## References

- [Minecraft RCON Protocol](https://wiki.vg/RCON)
- [mcrcon Python Library](https://github.com/barneygale/MCRcon)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Minecraft Commands](https://minecraft.wiki/w/Commands)

## Notes

- This integration is designed for Forge 1.20.1
- Some commands may vary by Minecraft version
- Test all commands in a development environment first
- Keep backups before automating world changes

