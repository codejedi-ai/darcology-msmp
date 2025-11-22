# Minecraft Server Dockerfile - Uses Java base image
# Minecraft is already installed in the mounted volume, just need Java and tools

FROM azul/zulu-openjdk:21

# Install base system dependencies
RUN apt-get update && \
    apt-get install -y bash curl screen wget zip python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Install ttyd for web terminal
RUN wget -O /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 && \
    chmod +x /usr/local/bin/ttyd

WORKDIR /minecraft

# Copy configuration files from containers/ (initialization files)
COPY containers/eula.txt /minecraft/
COPY containers/server.properties /minecraft/server.properties
# Delete the old config folder
RUN rm -rf /minecraft/config
# Copy the config folder to replace the old config folder
COPY containers/config /minecraft/config
# Create data directory
RUN mkdir -p /minecraft/data

# Copy startup scripts
COPY containers/minecraft/start-server.sh /minecraft/start-server.sh
COPY containers/minecraft/event_logger.py /minecraft/event_logger.py
RUN chmod +x /minecraft/start-server.sh /minecraft/event_logger.py

# Expose ports
# 25565 - Minecraft server
# 24454 - Voice chat mod
# 7681 - ttyd web terminal
EXPOSE 25565 24454 7681

# Run the server start script
CMD ["/minecraft/start-server.sh"]
