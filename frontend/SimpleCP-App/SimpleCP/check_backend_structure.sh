#!/bin/bash

# Backend Structure Diagnostic Script
# Checks if your Python backend has all required files

echo ""
echo "============================================================"
echo "🔍 SIMPLECP BACKEND STRUCTURE DIAGNOSTIC"
echo "============================================================"
echo ""

# Find project root
if [ -d "/Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP" ]; then
    PROJECT_ROOT="/Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP"
else
    PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
fi

echo "📁 Project Root: $PROJECT_ROOT"
echo ""

# Check backend directory
echo "1️⃣ CHECKING BACKEND DIRECTORY:"
if [ -d "$PROJECT_ROOT/backend" ]; then
    echo "   ✅ backend/ directory exists"
else
    echo "   ❌ backend/ directory NOT FOUND"
    exit 1
fi
echo ""

# Check main.py
echo "2️⃣ CHECKING MAIN.PY:"
if [ -f "$PROJECT_ROOT/backend/main.py" ]; then
    echo "   ✅ backend/main.py exists"
    echo "   📄 First 10 lines:"
    head -n 10 "$PROJECT_ROOT/backend/main.py" | sed 's/^/      /'
else
    echo "   ❌ backend/main.py NOT FOUND"
    exit 1
fi
echo ""

# Check for imports in main.py
echo "3️⃣ CHECKING IMPORTS IN MAIN.PY:"
if grep -q "from api.server import" "$PROJECT_ROOT/backend/main.py"; then
    echo "   ⚠️  Found: from api.server import ..."
    echo "   This requires backend/api/server.py to exist"
elif grep -q "import uvicorn" "$PROJECT_ROOT/backend/main.py"; then
    echo "   ✅ Found: import uvicorn (direct FastAPI setup)"
else
    echo "   ℹ️  No recognizable import pattern found"
fi
echo ""

# Check api/ directory
echo "4️⃣ CHECKING API DIRECTORY:"
if [ -d "$PROJECT_ROOT/backend/api" ]; then
    echo "   ✅ backend/api/ directory exists"
    echo "   📂 Contents:"
    ls -la "$PROJECT_ROOT/backend/api" | tail -n +4 | sed 's/^/      /'
else
    echo "   ⚠️  backend/api/ directory NOT FOUND"
    echo "   This is required if main.py imports from api.server"
fi
echo ""

# Check api/__init__.py
echo "5️⃣ CHECKING API/__INIT__.PY:"
if [ -f "$PROJECT_ROOT/backend/api/__init__.py" ]; then
    echo "   ✅ backend/api/__init__.py exists (Python package)"
else
    echo "   ❌ backend/api/__init__.py NOT FOUND"
    echo "   Python won't recognize 'api' as a package without this"
fi
echo ""

# Check api/server.py
echo "6️⃣ CHECKING API/SERVER.PY:"
if [ -f "$PROJECT_ROOT/backend/api/server.py" ]; then
    echo "   ✅ backend/api/server.py exists"
    echo "   📄 First 10 lines:"
    head -n 10 "$PROJECT_ROOT/backend/api/server.py" | sed 's/^/      /'
else
    echo "   ❌ backend/api/server.py NOT FOUND"
    echo "   This is required if main.py imports from it"
fi
echo ""

# Check requirements.txt
echo "7️⃣ CHECKING REQUIREMENTS.TXT:"
if [ -f "$PROJECT_ROOT/backend/requirements.txt" ]; then
    echo "   ✅ backend/requirements.txt exists"
    echo "   📄 Contents:"
    cat "$PROJECT_ROOT/backend/requirements.txt" | sed 's/^/      /'
else
    echo "   ⚠️  backend/requirements.txt NOT FOUND"
fi
echo ""

# Check venv
echo "8️⃣ CHECKING VIRTUAL ENVIRONMENT:"
if [ -d "$PROJECT_ROOT/.venv" ]; then
    echo "   ✅ .venv/ directory exists"
    
    if [ -f "$PROJECT_ROOT/.venv/bin/python3" ]; then
        echo "   ✅ Python executable: $PROJECT_ROOT/.venv/bin/python3"
        PYTHON_VERSION=$("$PROJECT_ROOT/.venv/bin/python3" --version 2>&1)
        echo "   📊 Version: $PYTHON_VERSION"
    else
        echo "   ❌ Python executable NOT FOUND in venv"
    fi
else
    echo "   ❌ .venv/ directory NOT FOUND"
    echo "   Run: python3 -m venv .venv"
fi
echo ""

# Try to run Python import check
echo "9️⃣ TESTING PYTHON IMPORTS:"
if [ -f "$PROJECT_ROOT/.venv/bin/python3" ]; then
    cd "$PROJECT_ROOT/backend"
    
    # Test basic imports
    echo "   Testing: import fastapi, uvicorn, pydantic_settings"
    if "$PROJECT_ROOT/.venv/bin/python3" -c "import fastapi, uvicorn, pydantic_settings; print('OK')" 2>/dev/null; then
        echo "   ✅ Core dependencies installed"
    else
        echo "   ❌ Missing core dependencies"
        echo "   Run: pip install -r backend/requirements.txt"
    fi
    
    # Test api.server import
    if [ -f "$PROJECT_ROOT/backend/api/server.py" ]; then
        echo "   Testing: from api.server import run_server"
        if "$PROJECT_ROOT/.venv/bin/python3" -c "from api.server import run_server; print('OK')" 2>/dev/null; then
            echo "   ✅ api.server module loads successfully"
        else
            echo "   ❌ api.server module import failed"
            echo "   Error:"
            "$PROJECT_ROOT/.venv/bin/python3" -c "from api.server import run_server" 2>&1 | sed 's/^/      /'
        fi
    fi
else
    echo "   ⚠️  Cannot test - Python not found"
fi
echo ""

# Summary
echo "============================================================"
echo "📊 SUMMARY"
echo "============================================================"
echo ""

# Determine backend type
if grep -q "from api.server import" "$PROJECT_ROOT/backend/main.py" 2>/dev/null; then
    echo "Backend Type: 🔷 Modular (uses api/server.py)"
    echo ""
    echo "Required Files:"
    echo "   • backend/main.py .............. $([ -f "$PROJECT_ROOT/backend/main.py" ] && echo '✅' || echo '❌')"
    echo "   • backend/api/__init__.py ...... $([ -f "$PROJECT_ROOT/backend/api/__init__.py" ] && echo '✅' || echo '❌')"
    echo "   • backend/api/server.py ........ $([ -f "$PROJECT_ROOT/backend/api/server.py" ] && echo '✅' || echo '❌')"
    echo ""
    
    if [ ! -f "$PROJECT_ROOT/backend/api/server.py" ]; then
        echo "❌ PROBLEM: Backend expects api/server.py but it doesn't exist"
        echo ""
        echo "💡 SOLUTIONS:"
        echo ""
        echo "   Option 1: Create the missing api/ structure"
        echo "   -----------"
        echo "   mkdir -p backend/api"
        echo "   touch backend/api/__init__.py"
        echo "   # Then create backend/api/server.py with run_server() function"
        echo ""
        echo "   Option 2: Simplify main.py to not use api/server"
        echo "   -----------"
        echo "   # Edit backend/main.py to directly define FastAPI app"
        echo "   # Remove: from api.server import run_server"
        echo "   # Add: app = FastAPI() and uvicorn.run() directly"
    fi
else
    echo "Backend Type: 🔶 Standalone (all-in-one main.py)"
    echo ""
    echo "Required Files:"
    echo "   • backend/main.py .............. $([ -f "$PROJECT_ROOT/backend/main.py" ] && echo '✅' || echo '❌')"
    echo ""
fi

echo ""
echo "Python Dependencies:"
if [ -f "$PROJECT_ROOT/.venv/bin/python3" ]; then
    if "$PROJECT_ROOT/.venv/bin/python3" -c "import fastapi, uvicorn, pydantic_settings" 2>/dev/null; then
        echo "   ✅ All core packages installed"
    else
        echo "   ❌ Missing packages - run: pip install -r backend/requirements.txt"
    fi
else
    echo "   ❌ venv not set up - run: python3 -m venv .venv"
fi

echo ""
echo "============================================================"
echo ""
