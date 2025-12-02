"""
SimpleCP setup configuration for distribution.
"""
from setuptools import setup, find_packages
from pathlib import Path

# Read version
version = {}
with open("version.py") as f:
    exec(f.read(), version)

# Read README
readme_file = Path(__file__).parent / "README.md"
long_description = readme_file.read_text(encoding="utf-8")

# Read requirements
requirements_file = Path(__file__).parent / "requirements.txt"
requirements = []
with open(requirements_file) as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith("#"):
            requirements.append(line)

setup(
    name="simplecp",
    version=version["__version__"],
    author="Your Name",
    author_email="your.email@example.com",
    description="Production-ready clipboard manager with Python backend and REST API",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/JamesKayten/SimpleCP",
    project_urls={
        "Bug Reports": "https://github.com/JamesKayten/SimpleCP/issues",
        "Documentation": "https://github.com/JamesKayten/SimpleCP/blob/main/README.md",
        "Source": "https://github.com/JamesKayten/SimpleCP",
    },
    packages=find_packages(exclude=["tests", "tests.*", "docs"]),
    py_modules=[
        "clipboard_manager",
        "daemon",
        "logger",
        "monitoring",
        "settings",
        "version",
    ],
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Intended Audience :: Developers",
        "Intended Audience :: End Users/Desktop",
        "Topic :: Utilities",
        "Topic :: Desktop Environment",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Operating System :: MacOS :: MacOS X",
        "Environment :: Console",
        "Environment :: Web Environment",
    ],
    keywords="clipboard manager productivity macos api backend",
    python_requires=">=3.9",
    install_requires=requirements,
    extras_require={
        "dev": [
            "pytest>=7.4.0",
            "pytest-cov>=4.1.0",
            "pytest-asyncio>=0.21.0",
            "pytest-mock>=3.11.0",
            "ruff>=0.1.0",
            "black>=23.0.0",
            "isort>=5.12.0",
            "mypy>=1.5.0",
        ],
        "test": [
            "pytest>=7.4.0",
            "pytest-cov>=4.1.0",
            "httpx>=0.24.0",
            "locust>=2.15.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "simplecp-daemon=daemon:main",
            "simplecp-version=version:main",
        ],
    },
    include_package_data=True,
    package_data={
        "": [
            "*.md",
            ".env.example",
            "LICENSE",
        ],
    },
    zip_safe=False,
)
