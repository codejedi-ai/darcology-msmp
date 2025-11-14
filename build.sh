#!/bin/bash

# Build and start script for Minecraft Docker setup
# This builds both images and starts the containers

set -e

echo "=========================================="
echo "Building and Starting Services"
echo "=========================================="
echo ""

# Check if Forge base image exists
if ! docker image inspect minecraft-forge-base:1.20.1-47.4.0 >/dev/null 2>&1; then
    echo "Forge base image not found. Building base image (this is a one-time operation)..."
    echo "This may take a few minutes..."
    docker build -f containers/minecraft/Dockerfile.forge-base -t minecraft-forge-base:1.20.1-47.4.0 .
    echo "✓ Forge base image built successfully!"
    echo ""
else
    echo "✓ Forge base image already exists (skipping Forge installation)"
    echo ""
fi

# Build and start using docker compose
echo "Building server images and starting containers..."
docker compose up -d --build

echo ""
echo "=========================================="
echo "Build and Start Complete!"
echo "=========================================="
echo ""
echo "Services are now running:"
docker compose ps
echo ""
echo "To view logs:"
echo "  docker compose logs -f"
echo ""
echo "To stop services:"
echo "  docker compose down"
echo ""
echo "To rebuild only server site (after HTML changes):"
echo "  docker compose up -d --build server-site"
echo ""
echo "To rebuild only minecraft server (after mod/config changes):"
echo "  docker compose up -d --build minecraft-server"
echo ""
echo "To rebuild Forge base image (only needed when upgrading Forge version):"
echo "  docker build -f containers/minecraft/Dockerfile.forge-base -t minecraft-forge-base:1.20.1-47.4.0 ."

