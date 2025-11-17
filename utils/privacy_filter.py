"""
Privacy and Security Filter for SimpleCP
Detects and filters sensitive content
"""

import re
from typing import Optional, List, Dict, Any


class PrivacyFilter:
    """
    Filters and detects sensitive content in clipboard data
    """

    # Regex patterns for sensitive data
    PATTERNS = {
        "credit_card": [
            # Visa, Mastercard, Amex, Discover
            r'\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})\b',
            # Generic 13-16 digit number
            r'\b[0-9]{4}[\s\-]?[0-9]{4}[\s\-]?[0-9]{4}[\s\-]?[0-9]{4}\b'
        ],
        "ssn": [
            # US Social Security Number
            r'\b[0-9]{3}[\-\s]?[0-9]{2}[\-\s]?[0-9]{4}\b'
        ],
        "password_indicators": [
            # Common password field indicators
            r'password[\s:=]+[\S]+',
            r'pwd[\s:=]+[\S]+',
            r'passwd[\s:=]+[\S]+',
            r'api[_\s]?key[\s:=]+[\S]+',
            r'secret[\s:=]+[\S]+',
            r'token[\s:=]+[\S]+',
            r'auth[\s:=]+[\S]+'
        ],
        "email": [
            r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        ],
        "phone": [
            # US phone numbers
            r'\b(?:\+?1[\s.-]?)?\(?([0-9]{3})\)?[\s.-]?([0-9]{3})[\s.-]?([0-9]{4})\b'
        ],
        "ip_address": [
            # IPv4
            r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b',
            # IPv6
            r'\b(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}\b'
        ],
        "api_key": [
            # AWS access key
            r'AKIA[0-9A-Z]{16}',
            # Generic API key patterns
            r'[a-zA-Z0-9]{32,}',
        ],
        "private_key": [
            r'-----BEGIN (?:RSA |EC )?PRIVATE KEY-----',
            r'-----BEGIN OPENSSH PRIVATE KEY-----'
        ]
    }

    def __init__(self, settings_store=None):
        """
        Initialize privacy filter

        Args:
            settings_store: SettingsStore instance for configuration
        """
        self.settings = settings_store

    def is_sensitive_content(
        self,
        content: str,
        check_types: Optional[List[str]] = None
    ) -> bool:
        """
        Check if content contains sensitive data

        Args:
            content: Text to check
            check_types: Specific types to check (None = all)

        Returns:
            True if sensitive content detected
        """
        if check_types is None:
            check_types = list(self.PATTERNS.keys())

        for check_type in check_types:
            if check_type in self.PATTERNS:
                for pattern in self.PATTERNS[check_type]:
                    if re.search(pattern, content, re.IGNORECASE):
                        return True

        return False

    def detect_sensitive_types(self, content: str) -> List[str]:
        """
        Detect which types of sensitive data are present

        Args:
            content: Text to check

        Returns:
            List of detected sensitive data types
        """
        detected = []

        for data_type, patterns in self.PATTERNS.items():
            for pattern in patterns:
                if re.search(pattern, content, re.IGNORECASE):
                    detected.append(data_type)
                    break  # Only add each type once

        return detected

    def should_filter_content(self, content: str, source_app: Optional[str] = None) -> bool:
        """
        Determine if content should be filtered based on settings

        Args:
            content: Content to check
            source_app: Source application

        Returns:
            True if content should be filtered (not stored)
        """
        # Check if filtering is enabled
        if self.settings:
            if not self.settings.get("privacy.enabled", True):
                return False

            # Check privacy mode
            if self.settings.get("privacy.privacy_mode", False):
                return True  # Filter everything in privacy mode

        # Check specific filters
        filters_to_check = []

        if not self.settings or self.settings.get("privacy.filter_passwords", True):
            filters_to_check.append("password_indicators")
            filters_to_check.append("api_key")
            filters_to_check.append("private_key")

        if not self.settings or self.settings.get("privacy.filter_credit_cards", True):
            filters_to_check.append("credit_card")

        if not self.settings or self.settings.get("privacy.filter_ssn", True):
            filters_to_check.append("ssn")

        return self.is_sensitive_content(content, filters_to_check)

    def should_exclude_app(self, app_name: Optional[str]) -> bool:
        """
        Check if application should be excluded

        Args:
            app_name: Application name

        Returns:
            True if app should be excluded
        """
        if not app_name:
            return False

        if not self.settings:
            # Default excluded apps
            default_excluded = [
                "1Password", "LastPass", "Bitwarden", "KeePassXC",
                "Terminal", "iTerm", "KeyChain Access"
            ]
            return app_name in default_excluded

        excluded_apps = self.settings.get("privacy.excluded_apps", [])
        return app_name in excluded_apps

    def sanitize_content(
        self,
        content: str,
        replacement: str = "[REDACTED]"
    ) -> str:
        """
        Remove sensitive data from content

        Args:
            content: Text to sanitize
            replacement: Replacement text for sensitive data

        Returns:
            Sanitized content
        """
        sanitized = content

        for data_type, patterns in self.PATTERNS.items():
            for pattern in patterns:
                sanitized = re.sub(pattern, replacement, sanitized, flags=re.IGNORECASE)

        return sanitized

    def get_redacted_preview(
        self,
        content: str,
        max_length: int = 100
    ) -> str:
        """
        Get a safe preview of potentially sensitive content

        Args:
            content: Content to preview
            max_length: Maximum length of preview

        Returns:
            Safe preview text
        """
        # Sanitize first
        sanitized = self.sanitize_content(content)

        # Truncate
        if len(sanitized) > max_length:
            sanitized = sanitized[:max_length] + "..."

        return sanitized

    def validate_content_safety(self, content: str) -> Dict[str, Any]:
        """
        Comprehensive content safety check

        Args:
            content: Content to validate

        Returns:
            Dictionary with safety information
        """
        detected_types = self.detect_sensitive_types(content)

        return {
            "is_safe": len(detected_types) == 0,
            "detected_types": detected_types,
            "should_filter": self.should_filter_content(content),
            "risk_level": self._calculate_risk_level(detected_types)
        }

    def _calculate_risk_level(self, detected_types: List[str]) -> str:
        """
        Calculate risk level based on detected sensitive data

        Args:
            detected_types: List of detected sensitive data types

        Returns:
            Risk level: "none", "low", "medium", "high"
        """
        if not detected_types:
            return "none"

        high_risk = ["credit_card", "ssn", "password_indicators", "private_key", "api_key"]
        medium_risk = ["phone", "email"]

        if any(t in high_risk for t in detected_types):
            return "high"
        elif any(t in medium_risk for t in detected_types):
            return "medium"
        else:
            return "low"

    def get_safe_display_content(
        self,
        content: str,
        max_length: int = 50,
        show_sensitive: bool = False
    ) -> str:
        """
        Get safe content for display in UI

        Args:
            content: Original content
            max_length: Maximum display length
            show_sensitive: Whether to show sensitive data (for authorized users)

        Returns:
            Safe display string
        """
        if not show_sensitive and self.is_sensitive_content(content):
            return f"[SENSITIVE CONTENT - {len(content)} characters]"

        # Truncate for display
        if len(content) > max_length:
            return content[:max_length] + "..."

        return content

    def create_content_report(self, content: str) -> Dict[str, Any]:
        """
        Create detailed report about content

        Args:
            content: Content to analyze

        Returns:
            Detailed report dictionary
        """
        detected = self.detect_sensitive_types(content)
        validation = self.validate_content_safety(content)

        return {
            "content_length": len(content),
            "detected_sensitive_types": detected,
            "risk_level": validation["risk_level"],
            "should_filter": validation["should_filter"],
            "is_safe_to_store": not validation["should_filter"],
            "redacted_preview": self.get_redacted_preview(content, 100),
            "safe_display": self.get_safe_display_content(content, 50)
        }
