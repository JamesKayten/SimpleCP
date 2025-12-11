# SimpleCP Systemd Deployment

This directory contains systemd service configuration for running SimpleCP as a system service.

## Installation Steps

### 1. Prepare the Application

```bash
# Clone and setup
cd /opt
sudo git clone https://github.com/JamesKayten/SimpleCP.git
cd SimpleCP

# Create virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Configure the Service File

Edit `simplecp.service` and update:

- `User=YOUR_USERNAME` - Your username
- `Group=YOUR_USERNAME` - Your group
- `WorkingDirectory=/path/to/SimpleCP` - Full path to SimpleCP directory
- `Environment="PATH=..."` - Update path to venv
- `ExecStart=...` - Update path to Python and daemon.py

### 3. Install the Service

```bash
# Copy service file
sudo cp deployment/systemd/simplecp.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable service (start on boot)
sudo systemctl enable simplecp

# Start service
sudo systemctl start simplecp
```

### 4. Verify Installation

```bash
# Check status
sudo systemctl status simplecp

# View logs
sudo journalctl -u simplecp -f

# Test API
curl http://localhost:49917/health
```

## Management Commands

```bash
# Start service
sudo systemctl start simplecp

# Stop service
sudo systemctl stop simplecp

# Restart service
sudo systemctl restart simplecp

# View status
sudo systemctl status simplecp

# Enable on boot
sudo systemctl enable simplecp

# Disable on boot
sudo systemctl disable simplecp

# View logs
sudo journalctl -u simplecp -n 50
sudo journalctl -u simplecp -f  # Follow logs
```

## Troubleshooting

### Service won't start

```bash
# Check service status
sudo systemctl status simplecp

# Check logs
sudo journalctl -u simplecp -n 100

# Test manually
cd /path/to/SimpleCP
source venv/bin/activate
python daemon.py
```

### Permission issues

```bash
# Ensure correct ownership
sudo chown -R YOUR_USERNAME:YOUR_USERNAME /path/to/SimpleCP

# Check permissions
ls -la /path/to/SimpleCP
```

### Port already in use

Edit `/etc/systemd/system/simplecp.service` and change the port:

```
ExecStart=... --port 8080
```

Then reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart simplecp
```

## Configuration

Configuration can be done via environment variables in the service file:

```ini
[Service]
Environment="API_HOST=127.0.0.1"
Environment="API_PORT=49917"
Environment="LOG_LEVEL=INFO"
Environment="CHECK_INTERVAL=1.0"
```

Or use a `.env` file:

```ini
[Service]
EnvironmentFile=/path/to/SimpleCP/.env
```
