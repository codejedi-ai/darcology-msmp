# Running Dashboard on Port 80

The dashboard is configured to run directly on port 80 (no proxy needed).

## Setup Steps

### 1. Stop nginx (if running)

```bash
sudo systemctl stop nginx
# OR
sudo service nginx stop
# OR
sudo pkill nginx
```

### 2. Start Rails on Port 80

Since port 80 requires root privileges, run:

```bash
cd /home/darcy/minecraft-docker/dashboard
sudo -E bundle exec rails server -b 0.0.0.0 -p 80
```

The `-E` flag preserves your environment variables.

### 3. Access the Dashboard

- **Dashboard**: http://localhost/
- **ttyd Terminal**: http://localhost:7681 (link in dashboard header)
- **Dashboard API**: http://localhost/dashboard/stats

## Running in Production Mode

For production, set the environment variable:

```bash
sudo -E RAILS_ENV=production bundle exec rails server -b 0.0.0.0 -p 80
```

## Alternative: Use a Different Port (No sudo needed)

If you prefer not to use sudo, you can run on a different port:

```bash
bundle exec rails server -b 0.0.0.0 -p 3000
```

Then access at: http://localhost:3000

