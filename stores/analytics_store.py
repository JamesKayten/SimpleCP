"""
Analytics Store for SimpleCP
Tracks usage patterns, statistics, and insights
"""

import json
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime, timedelta
from collections import defaultdict, Counter


class AnalyticsStore:
    """
    Tracks and analyzes clipboard usage patterns
    """

    def __init__(self, data_dir: str = "./data"):
        """
        Initialize analytics store

        Args:
            data_dir: Directory for data storage
        """
        self.data_dir = Path(data_dir)
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.analytics_file = self.data_dir / "analytics.json"

        # Analytics data structure
        self.data = {
            "copy_events": [],  # List of copy events
            "most_copied": {},  # clip_id -> count
            "app_stats": {},  # source_app -> count
            "type_stats": {},  # content_type -> count
            "daily_stats": {},  # date -> count
            "hourly_stats": {},  # hour -> count
            "search_queries": [],  # Recent searches
        }

        self._load_analytics()

    def _load_analytics(self):
        """Load analytics from file"""
        if self.analytics_file.exists():
            try:
                with open(self.analytics_file, 'r') as f:
                    loaded = json.load(f)
                    self.data.update(loaded)
            except Exception as e:
                print(f"Error loading analytics: {e}")

    def _save_analytics(self):
        """Save analytics to file"""
        try:
            with open(self.analytics_file, 'w') as f:
                json.dump(self.data, f, indent=2)
        except Exception as e:
            print(f"Error saving analytics: {e}")

    def track_copy_event(
        self,
        clip_id: str,
        content_type: str,
        source_app: Optional[str] = None,
        action: str = "copy"  # copy, paste, create, delete
    ):
        """
        Track a clipboard event

        Args:
            clip_id: Clipboard item ID
            content_type: Type of content
            source_app: Source application
            action: Action performed
        """
        now = datetime.now()

        # Record event
        event = {
            "clip_id": clip_id,
            "content_type": content_type,
            "source_app": source_app,
            "action": action,
            "timestamp": now.isoformat()
        }
        self.data["copy_events"].append(event)

        # Update most copied
        if clip_id not in self.data["most_copied"]:
            self.data["most_copied"][clip_id] = 0
        self.data["most_copied"][clip_id] += 1

        # Update app stats
        if source_app:
            if source_app not in self.data["app_stats"]:
                self.data["app_stats"][source_app] = 0
            self.data["app_stats"][source_app] += 1

        # Update type stats
        if content_type not in self.data["type_stats"]:
            self.data["type_stats"][content_type] = 0
        self.data["type_stats"][content_type] += 1

        # Update daily stats
        date_key = now.strftime("%Y-%m-%d")
        if date_key not in self.data["daily_stats"]:
            self.data["daily_stats"][date_key] = 0
        self.data["daily_stats"][date_key] += 1

        # Update hourly stats
        hour_key = str(now.hour)
        if hour_key not in self.data["hourly_stats"]:
            self.data["hourly_stats"][hour_key] = 0
        self.data["hourly_stats"][hour_key] += 1

        # Limit event history to recent events (keep last 10000)
        if len(self.data["copy_events"]) > 10000:
            self.data["copy_events"] = self.data["copy_events"][-10000:]

        self._save_analytics()

    def track_search(self, query: str):
        """Track a search query"""
        now = datetime.now()

        search_event = {
            "query": query,
            "timestamp": now.isoformat()
        }

        self.data["search_queries"].append(search_event)

        # Keep last 1000 searches
        if len(self.data["search_queries"]) > 1000:
            self.data["search_queries"] = self.data["search_queries"][-1000:]

        self._save_analytics()

    def get_most_copied(self, limit: int = 10) -> List[Tuple[str, int]]:
        """
        Get most copied items

        Args:
            limit: Number of items to return

        Returns:
            List of (clip_id, count) tuples
        """
        sorted_items = sorted(
            self.data["most_copied"].items(),
            key=lambda x: x[1],
            reverse=True
        )
        return sorted_items[:limit]

    def get_app_statistics(self) -> Dict[str, int]:
        """Get statistics by source application"""
        return dict(sorted(
            self.data["app_stats"].items(),
            key=lambda x: x[1],
            reverse=True
        ))

    def get_type_statistics(self) -> Dict[str, int]:
        """Get statistics by content type"""
        return dict(sorted(
            self.data["type_stats"].items(),
            key=lambda x: x[1],
            reverse=True
        ))

    def get_daily_statistics(self, days: int = 30) -> Dict[str, int]:
        """
        Get daily statistics for recent days

        Args:
            days: Number of days to include

        Returns:
            Dictionary of date -> count
        """
        cutoff_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")
        return {
            date: count
            for date, count in sorted(self.data["daily_stats"].items())
            if date >= cutoff_date
        }

    def get_hourly_distribution(self) -> Dict[int, int]:
        """Get hourly usage distribution"""
        return {
            int(hour): count
            for hour, count in sorted(
                self.data["hourly_stats"].items(),
                key=lambda x: int(x[0])
            )
        }

    def get_usage_summary(self, period: str = "week") -> Dict[str, Any]:
        """
        Get usage summary for a period

        Args:
            period: "day", "week", "month", or "all"

        Returns:
            Summary statistics
        """
        now = datetime.now()

        # Calculate date range
        if period == "day":
            start_date = now - timedelta(days=1)
        elif period == "week":
            start_date = now - timedelta(days=7)
        elif period == "month":
            start_date = now - timedelta(days=30)
        else:  # all
            start_date = datetime.min

        # Filter events in period
        start_iso = start_date.isoformat()
        period_events = [
            event for event in self.data["copy_events"]
            if event["timestamp"] >= start_iso
        ]

        # Calculate statistics
        total_events = len(period_events)

        # Type breakdown
        type_counter = Counter(event["content_type"] for event in period_events)

        # App breakdown
        app_counter = Counter(
            event["source_app"]
            for event in period_events
            if event.get("source_app")
        )

        # Action breakdown
        action_counter = Counter(event["action"] for event in period_events)

        # Average per day
        days_in_period = max(1, (now - start_date).days)
        avg_per_day = total_events / days_in_period if days_in_period > 0 else 0

        return {
            "period": period,
            "start_date": start_date.isoformat(),
            "end_date": now.isoformat(),
            "total_events": total_events,
            "average_per_day": round(avg_per_day, 2),
            "type_breakdown": dict(type_counter.most_common()),
            "app_breakdown": dict(app_counter.most_common(10)),
            "action_breakdown": dict(action_counter.most_common()),
            "most_active_hour": self._get_most_active_hour(period_events),
        }

    def _get_most_active_hour(self, events: List[Dict]) -> Optional[int]:
        """Get most active hour from events"""
        if not events:
            return None

        hour_counter = Counter(
            datetime.fromisoformat(event["timestamp"]).hour
            for event in events
        )

        if not hour_counter:
            return None

        return hour_counter.most_common(1)[0][0]

    def get_popular_searches(self, limit: int = 10) -> List[Tuple[str, int]]:
        """
        Get most popular search queries

        Args:
            limit: Number of queries to return

        Returns:
            List of (query, count) tuples
        """
        query_counter = Counter(
            search["query"]
            for search in self.data["search_queries"]
        )
        return query_counter.most_common(limit)

    def get_recent_searches(self, limit: int = 10) -> List[Dict[str, str]]:
        """Get recent search queries"""
        return self.data["search_queries"][-limit:][::-1]

    def cleanup_old_data(self, retention_days: int = 90):
        """
        Remove analytics data older than retention period

        Args:
            retention_days: Number of days to retain
        """
        cutoff_date = datetime.now() - timedelta(days=retention_days)
        cutoff_iso = cutoff_date.isoformat()

        # Filter events
        self.data["copy_events"] = [
            event for event in self.data["copy_events"]
            if event["timestamp"] >= cutoff_iso
        ]

        # Filter searches
        self.data["search_queries"] = [
            search for search in self.data["search_queries"]
            if search["timestamp"] >= cutoff_iso
        ]

        # Recalculate statistics from remaining events
        self._recalculate_stats()

        self._save_analytics()

    def _recalculate_stats(self):
        """Recalculate all statistics from events"""
        # Reset stats
        self.data["most_copied"] = {}
        self.data["app_stats"] = {}
        self.data["type_stats"] = {}
        self.data["daily_stats"] = {}
        self.data["hourly_stats"] = {}

        # Rebuild from events
        for event in self.data["copy_events"]:
            clip_id = event["clip_id"]
            content_type = event["content_type"]
            source_app = event.get("source_app")
            timestamp = datetime.fromisoformat(event["timestamp"])

            # Most copied
            if clip_id not in self.data["most_copied"]:
                self.data["most_copied"][clip_id] = 0
            self.data["most_copied"][clip_id] += 1

            # App stats
            if source_app:
                if source_app not in self.data["app_stats"]:
                    self.data["app_stats"][source_app] = 0
                self.data["app_stats"][source_app] += 1

            # Type stats
            if content_type not in self.data["type_stats"]:
                self.data["type_stats"][content_type] = 0
            self.data["type_stats"][content_type] += 1

            # Daily stats
            date_key = timestamp.strftime("%Y-%m-%d")
            if date_key not in self.data["daily_stats"]:
                self.data["daily_stats"][date_key] = 0
            self.data["daily_stats"][date_key] += 1

            # Hourly stats
            hour_key = str(timestamp.hour)
            if hour_key not in self.data["hourly_stats"]:
                self.data["hourly_stats"][hour_key] = 0
            self.data["hourly_stats"][hour_key] += 1

    def export_analytics(self) -> Dict[str, Any]:
        """Export all analytics data"""
        return self.data.copy()

    def clear_analytics(self):
        """Clear all analytics data"""
        self.data = {
            "copy_events": [],
            "most_copied": {},
            "app_stats": {},
            "type_stats": {},
            "daily_stats": {},
            "hourly_stats": {},
            "search_queries": [],
        }
        self._save_analytics()

    def get_insights(self) -> Dict[str, Any]:
        """
        Generate insights and recommendations

        Returns:
            Dictionary of insights
        """
        insights = {
            "total_copies": len(self.data["copy_events"]),
            "unique_items": len(self.data["most_copied"]),
            "top_app": None,
            "top_type": None,
            "most_active_hour": None,
            "average_daily_copies": 0,
            "trends": []
        }

        # Top app
        if self.data["app_stats"]:
            insights["top_app"] = max(
                self.data["app_stats"].items(),
                key=lambda x: x[1]
            )[0]

        # Top type
        if self.data["type_stats"]:
            insights["top_type"] = max(
                self.data["type_stats"].items(),
                key=lambda x: x[1]
            )[0]

        # Most active hour
        if self.data["hourly_stats"]:
            insights["most_active_hour"] = int(max(
                self.data["hourly_stats"].items(),
                key=lambda x: x[1]
            )[0])

        # Average daily copies
        if self.data["daily_stats"]:
            total_days = len(self.data["daily_stats"])
            total_copies = sum(self.data["daily_stats"].values())
            insights["average_daily_copies"] = round(total_copies / total_days, 2)

        return insights
