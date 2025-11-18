"""
Setup script for SimpleCP package.

For modern Python packaging, pyproject.toml is preferred.
This setup.py is provided for backward compatibility.
"""

from setuptools import setup, find_packages
from pathlib import Path

# Read the README file
readme_file = Path(__file__).parent / "README.md"
long_description = readme_file.read_text(encoding="utf-8") if readme_file.exists() else ""

# Read requirements
requirements_file = Path(__file__).parent / "requirements.txt"
requirements = []
if requirements_file.exists():
    with open(requirements_file) as f:
        requirements = [line.strip() for line in f if line.strip() and not line.startswith("#")]

# Read development requirements
dev_requirements_file = Path(__file__).parent / "requirements-dev.txt"
dev_requirements = []
if dev_requirements_file.exists():
    with open(dev_requirements_file) as f:
        dev_requirements = [
            line.strip()
            for line in f
            if line.strip() and not line.startswith("#") and not line.startswith("-r")
        ]

setup(
    name="simplecp",
    version="1.0.0",
    author="James Kayten",
    author_email="james@example.com",
    description="Professional clipboard manager with REST API",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/JamesKayten/SimpleCP",
    project_urls={
        "Bug Reports": "https://github.com/JamesKayten/SimpleCP/issues",
        "Source": "https://github.com/JamesKayten/SimpleCP",
        "Documentation": "https://github.com/JamesKayten/SimpleCP/blob/main/README.md",
    },
    packages=find_packages(exclude=["tests", "tests.*", "docs", "scripts"]),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Topic :: Utilities",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Operating System :: MacOS",
        "Framework :: FastAPI",
    ],
    python_requires=">=3.8",
    install_requires=requirements,
    extras_require={
        "dev": dev_requirements,
    },
    entry_points={
        "console_scripts": [
            "simplecp=main:main",
            "simplecp-daemon=daemon:main",
        ],
    },
    include_package_data=True,
    package_data={
        "": ["*.json", "*.md"],
    },
    zip_safe=False,
    keywords="clipboard manager macos api fastapi",
)
