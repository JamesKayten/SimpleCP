# SimpleCP Docker Deployment

This directory contains documentation for Docker-based deployment of SimpleCP.

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Build and start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

### Using Docker CLI

```bash
# Build image
docker build -t simplecp:latest .

# Run container
docker run -d \
  --name simplecp \
  -p 8000:8000 \
  -v $(pwd)/data:/app/data \
  -v $(pwd)/logs:/app/logs \
  simplecp:latest

# View logs
docker logs -f simplecp

# Stop container
docker stop simplecp
docker rm simplecp
```

## Configuration

### Environment Variables

Pass configuration via environment variables:

```bash
docker run -d \
  --name simplecp \
  -p 8000:8000 \
  -e API_HOST=0.0.0.0 \
  -e API_PORT=8000 \
  -e LOG_LEVEL=DEBUG \
  -e CHECK_INTERVAL=2.0 \
  simplecp:latest
```

### Using .env File

Create a `.env` file:

```env
API_HOST=0.0.0.0
API_PORT=8000
LOG_LEVEL=INFO
CHECK_INTERVAL=1.0
```

Then use it with Docker Compose:

```yaml
services:
  simplecp:
    env_file:
      - .env
```

## Data Persistence

Mount volumes to persist data:

```bash
docker run -d \
  --name simplecp \
  -p 8000:8000 \
  -v simplecp-data:/app/data \
  -v simplecp-logs:/app/logs \
  simplecp:latest
```

## Health Checks

The container includes built-in health checks:

```bash
# Check health status
docker inspect --format='{{.State.Health.Status}}' simplecp

# View health check logs
docker inspect --format='{{json .State.Health}}' simplecp | jq
```

## Production Deployment

### With Reverse Proxy (Nginx)

```nginx
server {
    listen 80;
    server_name clipboard.example.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### With Docker Swarm

```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml simplecp

# View services
docker stack services simplecp

# View logs
docker service logs simplecp_simplecp -f
```

### With Kubernetes

Create `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: simplecp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: simplecp
  template:
    metadata:
      labels:
        app: simplecp
    spec:
      containers:
      - name: simplecp
        image: simplecp:latest
        ports:
        - containerPort: 8000
        env:
        - name: API_HOST
          value: "0.0.0.0"
        - name: API_PORT
          value: "8000"
        volumeMounts:
        - name: data
          mountPath: /app/data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: simplecp-data
---
apiVersion: v1
kind: Service
metadata:
  name: simplecp
spec:
  selector:
    app: simplecp
  ports:
  - port: 80
    targetPort: 8000
  type: LoadBalancer
```

## Troubleshooting

### Container won't start

```bash
# View logs
docker logs simplecp

# Run interactively
docker run -it --rm simplecp:latest /bin/bash
```

### Port conflicts

```bash
# Use different port
docker run -d -p 8080:8000 simplecp:latest
```

### Permission issues

Ensure mounted volumes have correct permissions:

```bash
chown -R 1000:1000 ./data ./logs
```

## Monitoring

### View metrics

```bash
# Container stats
docker stats simplecp

# Resource usage
docker top simplecp
```

### Health monitoring

```bash
# Health check endpoint
curl http://localhost:8000/health

# Stats endpoint
curl http://localhost:8000/api/stats
```
