# System Dashboard - Quick Start Guide

## Prerequisites

- Ruby 2.7.2
- Bundler 2.1.4
- Node.js and Yarn (for webpacker)

## Setup

1. Install Ruby dependencies:
```bash
bundle install
```

2. Install JavaScript dependencies:
```bash
yarn install
```

3. (Optional) Precompile assets:
```bash
bundle exec rails assets:precompile
```

## Running the Dashboard

Start the Rails server on localhost:

```bash
bundle exec rails server -b 0.0.0.0 -p 5000
```

Or for development with auto-reload:

```bash
bundle exec rails server -b 127.0.0.1 -p 3000
```

## Access the Dashboard

Once the server is running, open your browser and navigate to:

- **http://localhost:5000** (if using port 5000)
- **http://localhost:3000** (if using port 3000)

## Features

The dashboard displays:
- **Memory Usage**: Total, used, available, and free memory with a visual progress bar
- **CPU Usage**: Current CPU usage percentage and number of CPU cores
- **Real-time Updates**: Automatically refreshes every 2 seconds

## Notes

- The dashboard reads system information from `/proc/meminfo` and `/proc/stat`
- CPU usage calculation requires two readings to compute accurate percentages
- The dashboard is optimized for Linux systems

