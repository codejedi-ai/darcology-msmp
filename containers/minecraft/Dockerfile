# Minecraft Server-only Dockerfile
# Build: docker build -f containers/minecraft/Dockerfile -t minecraft-base:latest .

FROM azul/zulu-openjdk:21

# Install base system dependencies
RUN apt-get update && \
    apt-get install -y bash curl screen wget zip python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Install ttyd for web terminal
RUN wget -O /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 && \
    chmod +x /usr/local/bin/ttyd

WORKDIR /minecraft

# Copy Minecraft server files
COPY containers/minecraft/forge-1.20.1-47.4.0-installer.jar /minecraft/
COPY containers/minecraft/eula.txt /minecraft/
COPY containers/minecraft/server.properties /minecraft/server.properties

# Copy mods.zip and extract into mods folder
COPY containers/minecraft/mods.zip /minecraft/mods.zip
RUN mkdir -p /minecraft/mods /data && \
    unzip -q /minecraft/mods.zip -d /minecraft/mods && \
    cp /minecraft/mods.zip /data/mods.zip

# Copy startup script and event logger
COPY containers/minecraft/start-server.sh /minecraft/start-server.sh
COPY containers/minecraft/event_logger.py /minecraft/event_logger.py
RUN chmod +x /minecraft/start-server.sh /minecraft/event_logger.py

# Create /data directory for shared data
RUN mkdir -p /data && chmod 777 /data

WORKDIR /minecraft

# Expose ports
# 25565 - Minecraft server
# 24454 - Voice chat mod
# 7681 - ttyd web terminal
EXPOSE 25565 24454 7681

# Run the server start script
CMD ["/minecraft/start-server.sh"]
