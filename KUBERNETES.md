# Kubernetes Deployment Guide

This guide explains how to deploy the Minecraft Docker setup on Kubernetes, including how to handle persistent storage for shared files and local server data.

## Overview

The setup consists of two main services:
1. **minecraft-server**: Minecraft server with ttyd web terminal
2. **server-site**: Static player guide website

## Storage Requirements

### Persistent Data (Must Survive Pod Restarts)

These need PersistentVolumes (PVs) or PersistentVolumeClaims (PVCs):

1. **World Data** (`/minecraft/world`)
   - Minecraft world files
   - Must persist across restarts
   - Can be large (GBs)

2. **Server Logs** (`/minecraft/logs`)
   - Server log files
   - Shared between containers if needed
   - Grows over time

3. **Shared Data** (`/data`)
   - `player_events.csv` - Player join/leave events
   - `usercache.json` - Player UUID cache
   - `mods.zip` - Pre-zipped mods for download
   - `cpu_stats.csv`, `memory_stats.csv` - Historical stats (if used)
   - Shared between minecraft-server and server-site

4. **Minecraft Libraries** (`/minecraft/libraries`)
   - Forge libraries and dependencies
   - Can be large but doesn't change often
   - Can be in image or persistent volume

### Configuration Files (Can be in ConfigMap)

These can be stored in Kubernetes ConfigMaps:

1. **server.properties** - Server configuration
2. **eula.txt** - EULA acceptance
3. **Mods** (`/minecraft/mods/`) - Can be in ConfigMap or PersistentVolume
4. **Config files** (`/minecraft/config/`) - Mod configurations

## Kubernetes Deployment Structure

### Option 1: Using PersistentVolumeClaims (Recommended)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: minecraft-world
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi  # Adjust based on your world size
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: minecraft-logs
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: minecraft-data
spec:
  accessModes:
    - ReadWriteMany  # Shared between pods
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: minecraft-config
data:
  server.properties: |
    # Server properties content here
    server-port=25565
    online-mode=true
    # ... etc
  eula.txt: |
    eula=true
```

### Option 2: Using NFS or Shared Storage

For shared access between pods (especially for `/data`):

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: minecraft-data-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany  # Allows multiple pods to mount
  nfs:
    server: your-nfs-server.example.com
    path: /exports/minecraft-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: minecraft-data
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
```

## Deployment Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minecraft-server
spec:
  replicas: 1  # Only one Minecraft server instance
  selector:
    matchLabels:
      app: minecraft-server
  template:
    metadata:
      labels:
        app: minecraft-server
    spec:
      containers:
      - name: minecraft
        image: your-registry/minecraft-server:latest
        ports:
        - containerPort: 25565
          name: minecraft
        - containerPort: 24454
          name: voicechat
        - containerPort: 7681
          name: terminal
        env:
        - name: MAX_RAM
          value: "4G"
        - name: MIN_RAM
          value: "4G"
        - name: ONLINE_MODE
          value: "true"
        volumeMounts:
        - name: world-data
          mountPath: /minecraft/world
        - name: logs-data
          mountPath: /minecraft/logs
        - name: shared-data
          mountPath: /data
        - name: libraries
          mountPath: /minecraft/libraries
        - name: config
          mountPath: /minecraft/server.properties
          subPath: server.properties
        resources:
          requests:
            memory: "4Gi"
            cpu: "2"
          limits:
            memory: "6Gi"
            cpu: "4"
      volumes:
      - name: world-data
        persistentVolumeClaim:
          claimName: minecraft-world
      - name: logs-data
        persistentVolumeClaim:
          claimName: minecraft-logs
      - name: shared-data
        persistentVolumeClaim:
          claimName: minecraft-data
      - name: libraries
        emptyDir: {}  # Or use PVC if you want persistence
      - name: config
        configMap:
          name: minecraft-config
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: server-site
spec:
  replicas: 1
  selector:
    matchLabels:
      app: server-site
  template:
    metadata:
      labels:
        app: server-site
    spec:
      containers:
      - name: nginx
        image: your-registry/minecraft-server-site:latest
        ports:
        - containerPort: 80
          name: http
        volumeMounts:
        - name: shared-data
          mountPath: /usr/share/nginx/html/data
          readOnly: true
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
      volumes:
      - name: shared-data
        persistentVolumeClaim:
          claimName: minecraft-data
---
apiVersion: v1
kind: Service
metadata:
  name: minecraft-server
spec:
  type: LoadBalancer  # Or NodePort/ClusterIP
  ports:
  - port: 25565
    targetPort: 25565
    name: minecraft
  - port: 24454
    targetPort: 24454
    name: voicechat
  - port: 7681
    targetPort: 7681
    name: terminal
  selector:
    app: minecraft-server
---
apiVersion: v1
kind: Service
metadata:
  name: server-site
spec:
  type: LoadBalancer  # Or NodePort/ClusterIP
  ports:
  - port: 80
    targetPort: 80
    name: http
  selector:
    app: server-site
```

## Storage Recommendations by Cloud Provider

### AWS (EKS)
- Use **EBS volumes** for ReadWriteOnce (world, logs)
- Use **EFS (Elastic File System)** for ReadWriteMany (shared data)
- Example:
  ```yaml
  storageClassName: efs-sc  # For shared data
  storageClassName: gp3     # For world/logs
  ```

### Google Cloud (GKE)
- Use **Persistent Disks** for ReadWriteOnce
- Use **Filestore (NFS)** for ReadWriteMany
- Example:
  ```yaml
  storageClassName: standard-rwo  # For world/logs
  storageClassName: nfs           # For shared data
  ```

### Azure (AKS)
- Use **Azure Disks** for ReadWriteOnce
- Use **Azure Files (SMB)** for ReadWriteMany
- Example:
  ```yaml
  storageClassName: managed-premium  # For world/logs
  storageClassName: azurefile        # For shared data
  ```

### On-Premises
- Use **NFS** for shared storage
- Use **local storage** or **Ceph/GlusterFS** for persistent volumes

## Handling Mods and Config Files

### Option A: Build into Image (Recommended for Mods)
- Mods are baked into the Docker image
- Pros: Fast startup, version controlled
- Cons: Need to rebuild image to update mods

### Option B: ConfigMap (For Small Configs)
- Small config files can be in ConfigMap
- Pros: Easy to update without rebuilding
- Cons: Limited size (1MB per ConfigMap)

### Option C: PersistentVolume (For Large/Changing Mods)
- Mount mods folder as PVC
- Pros: Can update without rebuilding
- Cons: Slower startup, need to manage mods separately

## Backup Strategy

### World Data Backup
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: minecraft-backup
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: busybox
            command:
            - /bin/sh
            - -c
            - |
              tar -czf /backup/world-$(date +%Y%m%d).tar.gz /minecraft/world
            volumeMounts:
            - name: world-data
              mountPath: /minecraft/world
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: world-data
            persistentVolumeClaim:
              claimName: minecraft-world
          - name: backup-storage
            persistentVolumeClaim:
              claimName: minecraft-backups
          restartPolicy: OnFailure
```

## Important Considerations

1. **ReadWriteMany vs ReadWriteOnce**
   - `/data` needs ReadWriteMany if both pods need write access
   - World and logs can be ReadWriteOnce (only one pod)

2. **Storage Class Selection**
   - Choose based on performance needs
   - SSD for world data (faster I/O)
   - Standard for logs (cheaper)

3. **Resource Limits**
   - Minecraft server needs significant memory
   - Adjust based on player count and mods

4. **Network Policies**
   - Consider restricting access to services
   - Use Ingress for server-site if needed

5. **StatefulSet vs Deployment**
   - Use StatefulSet if you need stable network identities
   - Deployment is simpler for this use case

## Example: Complete Setup Script

```bash
#!/bin/bash
# Deploy Minecraft server to Kubernetes

# Create namespaces
kubectl create namespace minecraft

# Create PVCs
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: minecraft-world
  namespace: minecraft
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 20Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: minecraft-data
  namespace: minecraft
spec:
  accessModes: [ReadWriteMany]
  resources:
    requests:
      storage: 1Gi
EOF

# Apply deployments
kubectl apply -f minecraft-deployment.yaml
kubectl apply -f server-site-deployment.yaml

# Check status
kubectl get pods -n minecraft
kubectl get pvc -n minecraft
```

## Migration from Docker Compose

1. **Export existing data**:
   ```bash
   docker exec minecraft-server tar -czf /tmp/world.tar.gz /minecraft/world
   docker cp minecraft-server:/tmp/world.tar.gz ./world-backup.tar.gz
   ```

2. **Create PVCs** in Kubernetes

3. **Copy data to PVC**:
   ```bash
   kubectl cp world-backup.tar.gz minecraft/minecraft-pod:/tmp/
   kubectl exec -n minecraft minecraft-pod -- tar -xzf /tmp/world-backup.tar.gz -C /minecraft/
   ```

4. **Update image references** in deployment YAMLs

5. **Apply deployments** and verify

