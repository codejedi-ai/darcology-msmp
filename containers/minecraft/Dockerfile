# Minecraft Server Dockerfile - Builds on top of Forge base image
# Build base image first: docker build -f containers/minecraft/Dockerfile.forge-base -t minecraft-forge-base:1.20.1-47.4.0 .
# Then build this: docker build -f containers/minecraft/Dockerfile -t minecraft-server:latest .

FROM minecraft-forge-base:1.20.1-47.4.0

# Copy configuration files
COPY containers/minecraft/eula.txt /minecraft/
COPY containers/minecraft/server.properties /minecraft/server.properties

# Copy and extract mods
COPY containers/minecraft/mods.zip /minecraft/mods.zip
RUN unzip -q /minecraft/mods.zip -d /minecraft/mods && \
    cp /minecraft/mods.zip /data/mods.zip && \
    rm /minecraft/mods.zip

# Copy startup scripts
COPY containers/minecraft/start-server.sh /minecraft/start-server.sh
COPY containers/minecraft/event_logger.py /minecraft/event_logger.py
RUN chmod +x /minecraft/start-server.sh /minecraft/event_logger.py

WORKDIR /minecraft

# Expose ports
# 25565 - Minecraft server
# 24454 - Voice chat mod
# 7681 - ttyd web terminal
EXPOSE 25565 24454 7681

# Run the server start script
CMD ["/minecraft/start-server.sh"]
