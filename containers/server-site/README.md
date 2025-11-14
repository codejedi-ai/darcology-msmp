# Minecraft Server Dashboard

A Ruby on Rails web application that provides monitoring and management capabilities for the Minecraft Forge server. The dashboard displays real-time system statistics, provides access to the server console, and allows downloading server mods.

## Features

- **Real-time System Monitoring**
  - CPU usage percentage and core count
  - Memory usage (total, used, available, free)
  - Auto-refreshing statistics (updates every 2 seconds)

- **Server Console Access**
  - Direct link to the web terminal (ttyd) for server management

- **Mod Management**
  - Download all server mods as a zip file

## Technology Stack

- **Ruby**: 3.2.3
- **Rails**: 7.1.0
- **Web Server**: Puma 6.0
- **Frontend**: Vanilla JavaScript with inline CSS
- **Asset Pipeline**: Webpacker (for legacy compatibility)

## Application Name

The application is named **minecraft-server-dashboard** and is integrated into the Minecraft Forge server Docker container.

## Running Locally (Development)

### Prerequisites

- Ruby 3.2.3
- Bundler 2.4.22
- Node.js 20.x
- Yarn

### Setup

1. Install dependencies:
```bash
bundle install
yarn install
```

2. Start the Rails server:
```bash
bundle exec rails server
```

3. Access at `http://localhost:3000`

## Production Deployment

The dashboard is automatically built and deployed as part of the Minecraft server Docker container. It runs on port 80 alongside the Minecraft server.

### Environment

- **RAILS_ENV**: production
- **Port**: 80
- **Database**: SQLite3 (not actively used, but required by Rails)

## Routes

- `GET /` - Main dashboard page with system statistics
- `GET /stats` - JSON API endpoint for system statistics
- `GET /download_mods` - Download all server mods as a zip file

## System Monitoring

The dashboard reads system statistics from:
- `/proc/meminfo` - Memory information
- `/proc/stat` - CPU statistics

These are standard Linux proc filesystem interfaces available in the Docker container.

## Architecture

The dashboard is a lightweight Rails application that:
1. Serves a single-page dashboard with inline styles
2. Provides a JSON API for real-time statistics
3. Handles mod file zipping for downloads
4. Runs in production mode with minimal dependencies

## Notes

- The dashboard uses inline CSS styles to avoid asset pipeline complications
- Statistics are calculated server-side from `/proc` filesystem
- The mods download feature looks for mods in `/minecraft/mods/` directory
- All functionality is designed to work within the Docker container environment
