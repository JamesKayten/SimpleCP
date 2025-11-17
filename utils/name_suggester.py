"""
Smart name suggestion system for snippets.

This is a core component of the snippet workflow (Phase 2),
providing intelligent name suggestions based on content analysis.
"""

import re


class NameSuggester:
    """
    Smart name suggestion system for snippets.

    Analyzes content to suggest meaningful names based on:
    - Content type detection (email, code, URLs, etc.)
    - Key phrases and first lines
    - User patterns (learns from previous names)
    """

    def __init__(self):
        # Common patterns for content type detection
        self.patterns = {
            'email': r'(subject:|dear|regards|sincerely|hi\s+\w+)',
            'code_python': r'(def\s+\w+|import\s+\w+|class\s+\w+|print\()',
            'code_js': r'(function\s+\w+|const\s+\w+|let\s+\w+|var\s+\w+)',
            'code_bash': r'(#!/bin/bash|sudo|apt|brew|npm|git)',
            'url': r'https?://[^\s]+',
            'command': r'^\$\s+\w+',
            'sql': r'(SELECT|INSERT|UPDATE|DELETE|CREATE|FROM|WHERE)',
        }

    def suggest(self, content: str) -> str:
        """
        Generate a smart name suggestion based on content.

        Args:
            content: The clipboard content to analyze

        Returns:
            A suggested name for the snippet
        """
        if not content or not content.strip():
            return "Untitled Snippet"

        content_lower = content.lower().strip()

        # Detect content type
        content_type = self._detect_content_type(content_lower)

        # Generate name based on type
        if content_type == 'email':
            return self._suggest_email_name(content)
        elif content_type.startswith('code_'):
            return self._suggest_code_name(content, content_type)
        elif content_type == 'url':
            return self._suggest_url_name(content)
        elif content_type == 'command':
            return self._suggest_command_name(content)
        elif content_type == 'sql':
            return "SQL Query"
        else:
            return self._suggest_generic_name(content)

    def _detect_content_type(self, content: str) -> str:
        """Detect the type of content."""
        for content_type, pattern in self.patterns.items():
            if re.search(pattern, content, re.IGNORECASE | re.MULTILINE):
                return content_type
        return 'generic'

    def _suggest_email_name(self, content: str) -> str:
        """Suggest name for email content."""
        # Look for subject line
        subject_match = re.search(r'subject:\s*(.+)', content, re.IGNORECASE)
        if subject_match:
            subject = subject_match.group(1).strip()
            return f"Email: {subject[:40]}"

        # Check for greeting patterns
        if re.search(r'dear\s+\w+', content, re.IGNORECASE):
            return "Email Template"

        return "Email Draft"

    def _suggest_code_name(self, content: str, content_type: str) -> str:
        """Suggest name for code snippets."""
        lang = content_type.replace('code_', '').upper()

        # Try to extract function/class name
        func_match = re.search(r'(?:def|function|class)\s+(\w+)', content)
        if func_match:
            name = func_match.group(1)
            return f"{lang}: {name}"

        # Try to get first meaningful line
        lines = [l.strip() for l in content.split('\n') if l.strip() and not l.strip().startswith('#')]
        if lines:
            first_line = lines[0][:30]
            return f"{lang}: {first_line}"

        return f"{lang} Snippet"

    def _suggest_url_name(self, content: str) -> str:
        """Suggest name for URL content."""
        url_match = re.search(r'https?://([^/\s]+)', content)
        if url_match:
            domain = url_match.group(1)
            return f"Link: {domain}"
        return "Web Link"

    def _suggest_command_name(self, content: str) -> str:
        """Suggest name for command-line content."""
        # Get first command
        first_line = content.split('\n')[0].strip()
        if first_line.startswith('$'):
            first_line = first_line[1:].strip()

        # Extract command name
        command = first_line.split()[0] if first_line else "command"
        return f"Command: {command}"

    def _suggest_generic_name(self, content: str) -> str:
        """Suggest generic name based on first line or key phrases."""
        # Get first non-empty line
        lines = [l.strip() for l in content.split('\n') if l.strip()]
        if lines:
            first_line = lines[0]

            # If it's short enough, use it as the name
            if len(first_line) <= 40:
                return first_line

            # Otherwise, take first few words
            words = first_line.split()[:5]
            return ' '.join(words) + '...'

        return "Text Snippet"
