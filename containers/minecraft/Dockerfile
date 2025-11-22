# Minecraft Server Dockerfile - Builds on top of Forge base image
# Build base image first: docker build -f containers/minecraft/Dockerfile.forge-base -t minecraft-forge-base:1.20.1-47.4.0 .
# Then build this: docker build -f containers/minecraft/Dockerfile -t minecraft-server:latest .

FROM minecraft-forge-base:1.20.1-47.4.0

# Copy configuration files from containers/ (initialization files)
COPY containers/eula.txt /minecraft/
COPY containers/server.properties /minecraft/server.properties
# Delete the old config folder
RUN rm -rf /minecraft/config
# Copy the config folder to replace the old config folder
COPY containers/config /minecraft/config
# Mods are already in the base image's /minecraft/mods directory
RUN mkdir -p /minecraft/data

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
