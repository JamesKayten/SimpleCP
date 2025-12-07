"""
SimpleCP Version Information.

This file is used by setuptools for package versioning.
The canonical version is maintained in backend/version.py.
"""

__version__ = "1.0.0"
__version_info__ = (1, 0, 0)


def main():
    """Display version information (for simplecp-version script)."""
    print(f"SimpleCP v{__version__}")


if __name__ == "__main__":
    main()
