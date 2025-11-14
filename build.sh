#!/bin/bash

# Build and start script for Minecraft Docker setup
# This builds both images and starts the containers

set -e

echo "=========================================="
echo "Building and Starting Services"
echo "=========================================="
echo ""

# Build and start using docker compose
echo "Building images and starting containers..."
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

