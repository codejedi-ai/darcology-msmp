#!/bin/bash

set -e

echo "Starting Minecraft Forge Server with ttyd web terminal..."

# Function to update server.properties from environment variables
update_server_properties() {
    PROPS_FILE="/minecraft/server.properties"
    
    # Function to update a property if environment variable is set
    update_property() {
        local env_var=$1
        local prop_name=$2
        local value=${!env_var}

        if [ ! -z "$value" ]; then
            echo "Setting $prop_name=$value"
            if grep -q "^${prop_name}=" "$PROPS_FILE"; then
                sed -i "s|^${prop_name}=.*|${prop_name}=${value}|" "$PROPS_FILE"
            else
                echo "${prop_name}=${value}" >> "$PROPS_FILE"
            fi
        fi
    }

    # Update properties from environment variables if they exist
    update_property "SERVER_PORT" "server-port"
    update_property "SERVER_IP" "server-ip"
    update_property "MOTD" "motd"
    update_property "MAX_PLAYERS" "max-players"
    update_property "ONLINE_MODE" "online-mode"
    update_property "PVP" "pvp"
    update_property "DIFFICULTY" "difficulty"
    update_property "GAMEMODE" "gamemode"
    update_property "HARDCORE" "hardcore"
    update_property "WHITE_LIST" "white-list"
    update_property "ENFORCE_WHITELIST" "enforce-whitelist"

    # World Settings
    update_property "LEVEL_NAME" "level-name"
    update_property "LEVEL_SEED" "level-seed"
    update_property "LEVEL_TYPE" "level-type"
    update_property "SPAWN_PROTECTION" "spawn-protection"
    update_property "MAX_WORLD_SIZE" "max-world-size"
    update_property "ALLOW_NETHER" "allow-nether"
    update_property "ALLOW_FLIGHT" "allow-flight"
    update_property "ENABLE_COMMAND_BLOCK" "enable-command-block"

    # Performance Settings
    update_property "VIEW_DISTANCE" "view-distance"
    update_property "SIMULATION_DISTANCE" "simulation-distance"
    update_property "MAX_TICK_TIME" "max-tick-time"

    # Network Settings
    update_property "NETWORK_COMPRESSION_THRESHOLD" "network-compression-threshold"
    update_property "PLAYER_IDLE_TIMEOUT" "player-idle-timeout"

    # RCON
    update_property "ENABLE_RCON" "enable-rcon"
    update_property "RCON_PORT" "rcon.port"
    update_property "RCON_PASSWORD" "rcon.password"

    # Query
    update_property "ENABLE_QUERY" "enable-query"
    update_property "QUERY_PORT" "query.port"

    # Other Settings
    update_property "SPAWN_ANIMALS" "spawn-animals"
    update_property "SPAWN_MONSTERS" "spawn-monsters"
    update_property "SPAWN_NPCS" "spawn-npcs"
    update_property "FORCE_GAMEMODE" "force-gamemode"
    update_property "RESOURCE_PACK" "resource-pack"
    update_property "REQUIRE_RESOURCE_PACK" "require-resource-pack"

    echo "Server properties updated from environment variables"
}

# Update server.properties from environment variables
if [ -f "/minecraft/server.properties" ]; then
    echo "Updating server.properties from environment variables..."
    update_server_properties
fi

# Forge is already installed at build time, no need to install at runtime
echo "Forge installation already completed during Docker build"

# Create data directory if it doesn't exist
mkdir -p /minecraft/data

# Zip the mods folder at startup (save to data folder)
echo "Creating mods.zip archive..."
if [ -d "/minecraft/mods" ] && [ "$(ls -A /minecraft/mods/*.jar 2>/dev/null)" ]; then
    cd /minecraft/mods
    zip -q /minecraft/data/mods.zip *.jar 2>/dev/null || true
    if [ -f "/minecraft/data/mods.zip" ]; then
        echo "mods.zip created successfully in /minecraft/data"
    else
        echo "Warning: Failed to create mods.zip"
    fi
else
    echo "Warning: No mods found to zip"
fi
cd /minecraft

# Copy usercache.json to data folder for dashboard access (if it exists)
# Also sync it periodically in the background
if [ -f "/minecraft/usercache.json" ]; then
    cp /minecraft/usercache.json /minecraft/data/usercache.json 2>/dev/null || true
fi

# Sync usercache.json periodically (every 30 seconds) in the background
(
    while true; do
        sleep 30
        if [ -f "/minecraft/usercache.json" ]; then
            cp /minecraft/usercache.json /minecraft/data/usercache.json 2>/dev/null || true
        fi
    done
) &
USERCACHE_SYNC_PID=$!

# Start Python event logger script in the background
echo "Starting Python event logger..."
if [ -f "/scripts/event_logger.py" ]; then
    python3 /scripts/event_logger.py &
    EVENT_LOGGER_PID=$!
    echo "Event logger started (PID: $EVENT_LOGGER_PID)"
else
    echo "Warning: event_logger.py not found, skipping event logging"
    EVENT_LOGGER_PID=""
fi

# Check for existing minecraft screen sessions
SCREEN_NAME="minecraft"
EXISTING_SCREEN_LINE=$(screen -list | grep -i minecraft | head -1)

# If an existing screen session is found, use it; otherwise create a new one
if [ -n "$EXISTING_SCREEN_LINE" ]; then
    # Extract the full screen session name (e.g., "111.minecraft" from "111.minecraft (Attached)")
    # Screen list format: "PID.name (status)"
    EXISTING_SCREEN_NAME=$(echo "$EXISTING_SCREEN_LINE" | awk '{print $1}' | cut -d'.' -f2-)
    if [ -n "$EXISTING_SCREEN_NAME" ]; then
        SCREEN_NAME="$EXISTING_SCREEN_NAME"
        echo "Found existing screen session: $SCREEN_NAME"
        echo "To attach manually: screen -r $SCREEN_NAME"
        echo "To list all screens: screen -list"
    fi
else
    echo "No existing minecraft screen session found, will create new one"
fi

# Start ttyd in the background on port 7681
# Use a wrapper script that can attach to any minecraft screen session
echo "Starting ttyd web terminal on port 7681..."
cd /minecraft

# Create a helper script for ttyd to attach to the correct screen
# Use screen -x to allow multiple users to view the same session
cat > /tmp/attach-minecraft.sh << 'EOF'
#!/bin/bash
# Find and attach to any minecraft screen session
SCREEN_SESSION=$(screen -list | grep -i minecraft | head -1 | awk '{print $1}' | cut -d'.' -f2-)
if [ -n "$SCREEN_SESSION" ]; then
    # Use screen -x to allow multiple users to attach to the same session
    # -x allows attaching to an already attached session (shared viewing)
    # This enables multiple people to see the same terminal output
    screen -x "$SCREEN_SESSION" 2>/dev/null || screen -r "$SCREEN_SESSION"
else
    echo "No minecraft screen session found. Available screens:"
    screen -list
    echo ""
    echo "To create a new session, use: screen -S minecraft"
fi
EOF
chmod +x /tmp/attach-minecraft.sh

# Start ttyd with unlimited client connections
# Multiple users can connect and all will see the same screen session
ttyd --writable --port 7681 --max-clients 0 /tmp/attach-minecraft.sh &
TTYD_PID=$!

# Give services a moment to start
sleep 3

# Only start a new server if no existing screen session was found
if [ -z "$EXISTING_SCREEN_LINE" ]; then
    # Find the server jar file (Forge creates different file names)
    SERVER_JAR=$(ls -1 forge-*-server.jar 2>/dev/null | head -1)
    
    # Start Minecraft server in a screen session
    # Multiple users can attach using 'screen -x' to view the same session
    echo "Starting Minecraft server in screen session '$SCREEN_NAME'..."
    echo "Multiple users can view this session at http://localhost:7681"
    if [ -z "$SERVER_JAR" ] && [ -f "run.sh" ]; then
        # Newer Forge versions use run.sh
        screen -dmS "$SCREEN_NAME" bash run.sh nogui
    elif [ -n "$SERVER_JAR" ]; then
        # Start with Java directly
        screen -dmS "$SCREEN_NAME" java -Xmx${MAX_RAM:-4G} -Xms${MIN_RAM:-1G} \
            -XX:+UseG1GC \
            -XX:+ParallelRefProcEnabled \
            -XX:MaxGCPauseMillis=200 \
            -XX:+UnlockExperimentalVMOptions \
            -XX:+DisableExplicitGC \
            -XX:+AlwaysPreTouch \
            -XX:G1NewSizePercent=30 \
            -XX:G1MaxNewSizePercent=40 \
            -XX:G1HeapRegionSize=8M \
            -XX:G1ReservePercent=20 \
            -XX:G1HeapWastePercent=5 \
            -XX:G1MixedGCCountTarget=4 \
            -XX:InitiatingHeapOccupancyPercent=15 \
            -XX:G1MixedGCLiveThresholdPercent=90 \
            -XX:G1RSetUpdatingPauseTimePercent=5 \
            -XX:SurvivorRatio=32 \
            -XX:+PerfDisableSharedMem \
            -XX:MaxTenuringThreshold=1 \
            -Dusing.aikars.flags=https://mcflags.emc.gs \
            -Daikars.new.flags=true \
            -jar "$SERVER_JAR" nogui
    else
        echo "ERROR: Could not find server jar or run.sh!"
        exit 1
    fi
else
    echo "Using existing screen session: $SCREEN_NAME"
fi

echo "Minecraft server and ttyd started successfully!"
echo "Access web terminal at: http://localhost:7681"
echo "Minecraft server console is running in screen session '$SCREEN_NAME'"
echo ""
echo "Screen session management:"
echo "  - List all screens: screen -list"
echo "  - Attach to server: screen -r $SCREEN_NAME"
echo "  - Detach (keep running): Press Ctrl+A then D"
echo "  - Create new screen: screen -S <name>"
echo "  - Switch between screens: screen -r <name>"

# Keep the container running by tailing the logs and monitoring processes
tail -f /minecraft/logs/latest.log 2>/dev/null &
TAIL_PID=$!

# Function to cleanup on exit
cleanup() {
    echo "Shutting down..."
    kill $USERCACHE_SYNC_PID 2>/dev/null || true
    [ -n "$EVENT_LOGGER_PID" ] && kill $EVENT_LOGGER_PID 2>/dev/null || true
    kill $TTYD_PID 2>/dev/null || true
    kill $TAIL_PID 2>/dev/null || true
    # Only quit screen session if we created it (not if it was pre-existing)
    if [ -z "$EXISTING_SCREEN_LINE" ]; then
        screen -S "$SCREEN_NAME" -X quit 2>/dev/null || true
    fi
}

trap cleanup EXIT

# Wait for services to exit
while (kill -0 $TTYD_PID 2>/dev/null) && screen -list | grep -qi minecraft; do
    sleep 5
done

echo "Server stopped"
exit 0

