# SimpleCP Docker Image
# Multi-stage build for optimal image size

# Build stage
FROM python:3.11-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Runtime stage
FROM python:3.11-slim

WORKDIR /app

# Create non-root user
RUN useradd -m -u 1000 simplecp && \
    chown -R simplecp:simplecp /app

# Copy Python dependencies from builder
COPY --from=builder /root/.local /home/simplecp/.local

# Copy application code
COPY --chown=simplecp:simplecp . .

# Set environment variables
ENV PATH=/home/simplecp/.local/bin:$PATH
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Create data and logs directories
RUN mkdir -p data logs && \
    chown -R simplecp:simplecp data logs

# Switch to non-root user
USER simplecp

# Expose API port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Run daemon
CMD ["python", "daemon.py", "--host", "0.0.0.0", "--port", "8000"]
