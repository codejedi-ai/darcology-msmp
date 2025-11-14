# Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the Minecraft server.

## Quick Start

1. **Build and push images to your registry**:
   ```bash
   docker build -f containers/minecraft/Dockerfile -t your-registry/minecraft-server:latest .
   docker build -f containers/server-site/Dockerfile -t your-registry/minecraft-server-site:latest .
   docker push your-registry/minecraft-server:latest
   docker push your-registry/minecraft-server-site:latest
   ```

2. **Update image references** in `minecraft-deployment.yaml`:
   ```yaml
   image: your-registry/minecraft-server:latest
   image: your-registry/minecraft-server-site:latest
   ```

3. **Adjust storage classes** based on your cluster:
   - For ReadWriteMany (shared data), you need NFS, EFS, or similar
   - For ReadWriteOnce (world/logs), standard storage classes work

4. **Deploy**:
   ```bash
   kubectl apply -f minecraft-deployment.yaml
   ```

5. **Check status**:
   ```bash
   kubectl get pods -n minecraft
   kubectl get pvc -n minecraft
   kubectl get svc -n minecraft
   ```

## Storage Configuration

### For Cloud Providers

**AWS (EKS)**:
- Use `efs-sc` for ReadWriteMany
- Use `gp3` for ReadWriteOnce

**Google Cloud (GKE)**:
- Use `nfs` for ReadWriteMany
- Use `standard-rwo` for ReadWriteOnce

**Azure (AKS)**:
- Use `azurefile` for ReadWriteMany
- Use `managed-premium` for ReadWriteOnce

### For On-Premises

You'll need to set up an NFS server or use a distributed filesystem like Ceph/GlusterFS.

## Accessing Services

After deployment, get the external IPs:

```bash
kubectl get svc -n minecraft
```

- Minecraft Server: `<EXTERNAL-IP>:25565`
- Web Terminal: `<EXTERNAL-IP>:7681`
- Player Guide: `<EXTERNAL-IP>:80` (or via Ingress)

## Backup

See `KUBERNETES.md` in the root directory for backup strategies using CronJobs.

## Troubleshooting

- **PVCs not binding**: Check storage class availability
- **ReadWriteMany not working**: Ensure you have NFS or similar configured
- **Pods not starting**: Check resource limits and PVC status
- **Can't access services**: Verify Service type and firewall rules

