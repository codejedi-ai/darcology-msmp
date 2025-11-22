# Minecraft Server Dockerfile - Runtime environment only
# Minecraft folder is pre-mounted as volume, this just provides Java + tools + scripts

FROM azul/zulu-openjdk:21

# Install base system dependencies
RUN apt-get update && \
    apt-get install -y bash curl screen wget zip python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Install ttyd for web terminal
RUN wget -O /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 && \
    chmod +x /usr/local/bin/ttyd

WORKDIR /minecraft

# Copy startup scripts from separate scripts folder (not in minecraft mount)
COPY containers/scripts/start-server.sh /scripts/start-server.sh
COPY containers/scripts/event_logger.py /scripts/event_logger.py
RUN chmod +x /scripts/start-server.sh /scripts/event_logger.py

# Expose ports
# 25565 - Minecraft server
# 24454 - Voice chat mod
# 7681 - ttyd web terminal
EXPOSE 25565 24454 7681

# Run the server start script
CMD ["/scripts/start-server.sh"]
