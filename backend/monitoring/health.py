"""Health checking and system monitoring."""
import os
import psutil
import platform
from typing import Dict, List, Optional
from datetime import datetime
from enum import Enum


class HealthStatus(Enum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"


class HealthCheck:
    def __init__(self, name: str, status: HealthStatus, message: str = "", details: Optional[Dict] = None):
        self.name, self.status, self.message = name, status, message
        self.details = details or {}
        self.timestamp = datetime.now()

    def to_dict(self) -> Dict:
        return {"name": self.name, "status": self.status.value, "message": self.message,
                "details": self.details, "timestamp": self.timestamp.isoformat()}


class HealthChecker:
    def __init__(self):
        self.checks: List[HealthCheck] = []

    def check_all(self) -> Dict:
        self.checks = []
        self.check_disk_space()
        self.check_memory()
        self.check_cpu()
        self.check_data_directory()

        if any(c.status == HealthStatus.UNHEALTHY for c in self.checks):
            overall = HealthStatus.UNHEALTHY
        elif any(c.status == HealthStatus.DEGRADED for c in self.checks):
            overall = HealthStatus.DEGRADED
        else:
            overall = HealthStatus.HEALTHY

        return {"status": overall.value, "timestamp": datetime.now().isoformat(),
                "checks": [c.to_dict() for c in self.checks], "system_info": self.get_system_info()}

    def check_disk_space(self, threshold_percent: float = 90.0):
        """
        Check available disk space.

        Args:
            threshold_percent: Percentage threshold for warning
        """
        try:
            disk = psutil.disk_usage("/")
            percent_used = disk.percent

            if percent_used >= threshold_percent:
                status = HealthStatus.UNHEALTHY
                message = f"Disk usage critical: {percent_used}%"
            elif percent_used >= threshold_percent - 10:
                status = HealthStatus.DEGRADED
                message = f"Disk usage high: {percent_used}%"
            else:
                status = HealthStatus.HEALTHY
                message = f"Disk usage normal: {percent_used}%"

            self.checks.append(
                HealthCheck(
                    name="disk_space",
                    status=status,
                    message=message,
                    details={
                        "total_gb": round(disk.total / (1024**3), 2),
                        "used_gb": round(disk.used / (1024**3), 2),
                        "free_gb": round(disk.free / (1024**3), 2),
                        "percent_used": percent_used,
                    },
                )
            )
        except Exception as e:
            self.checks.append(
                HealthCheck(
                    name="disk_space",
                    status=HealthStatus.UNHEALTHY,
                    message=f"Failed to check disk space: {str(e)}",
                )
            )

    def check_memory(self, threshold_percent: float = 90.0):
        """
        Check available memory.

        Args:
            threshold_percent: Percentage threshold for warning
        """
        try:
            memory = psutil.virtual_memory()
            percent_used = memory.percent

            if percent_used >= threshold_percent:
                status = HealthStatus.UNHEALTHY
                message = f"Memory usage critical: {percent_used}%"
            elif percent_used >= threshold_percent - 10:
                status = HealthStatus.DEGRADED
                message = f"Memory usage high: {percent_used}%"
            else:
                status = HealthStatus.HEALTHY
                message = f"Memory usage normal: {percent_used}%"

            self.checks.append(
                HealthCheck(
                    name="memory",
                    status=status,
                    message=message,
                    details={
                        "total_gb": round(memory.total / (1024**3), 2),
                        "available_gb": round(memory.available / (1024**3), 2),
                        "percent_used": percent_used,
                    },
                )
            )
        except Exception as e:
            self.checks.append(
                HealthCheck(
                    name="memory",
                    status=HealthStatus.UNHEALTHY,
                    message=f"Failed to check memory: {str(e)}",
                )
            )

    def check_cpu(self, threshold_percent: float = 90.0):
        """
        Check CPU usage.

        Args:
            threshold_percent: Percentage threshold for warning
        """
        try:
            cpu_percent = psutil.cpu_percent(interval=1)

            if cpu_percent >= threshold_percent:
                status = HealthStatus.DEGRADED
                message = f"CPU usage high: {cpu_percent}%"
            else:
                status = HealthStatus.HEALTHY
                message = f"CPU usage normal: {cpu_percent}%"

            self.checks.append(
                HealthCheck(
                    name="cpu",
                    status=status,
                    message=message,
                    details={
                        "percent_used": cpu_percent,
                        "cpu_count": psutil.cpu_count(),
                    },
                )
            )
        except Exception as e:
            self.checks.append(
                HealthCheck(
                    name="cpu",
                    status=HealthStatus.UNHEALTHY,
                    message=f"Failed to check CPU: {str(e)}",
                )
            )

    def check_data_directory(self, data_dir: str = "data"):
        """
        Check if data directory exists and is writable.

        Args:
            data_dir: Path to data directory
        """
        try:
            if not os.path.exists(data_dir):
                status = HealthStatus.UNHEALTHY
                message = f"Data directory does not exist: {data_dir}"
            elif not os.access(data_dir, os.W_OK):
                status = HealthStatus.UNHEALTHY
                message = f"Data directory not writable: {data_dir}"
            else:
                status = HealthStatus.HEALTHY
                message = f"Data directory accessible: {data_dir}"

            self.checks.append(
                HealthCheck(
                    name="data_directory",
                    status=status,
                    message=message,
                    details={"path": os.path.abspath(data_dir)},
                )
            )
        except Exception as e:
            self.checks.append(
                HealthCheck(
                    name="data_directory",
                    status=HealthStatus.UNHEALTHY,
                    message=f"Failed to check data directory: {str(e)}",
                )
            )

    def get_system_info(self) -> Dict:
        """Get system information."""
        return {
            "platform": platform.system(),
            "platform_release": platform.release(),
            "platform_version": platform.version(),
            "architecture": platform.machine(),
            "hostname": platform.node(),
            "python_version": platform.python_version(),
        }


# Global health checker instance
_health_checker: Optional[HealthChecker] = None


def get_health_checker() -> HealthChecker:
    """Get global health checker instance."""
    global _health_checker
    if _health_checker is None:
        _health_checker = HealthChecker()
    return _health_checker
