#!/bin/bash
#
# SimpleCP Test Runner
# Run different test suites with various options
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}SimpleCP Test Runner${NC}"
echo -e "${BLUE}==================================${NC}\n"

# Function to print usage
usage() {
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  all          Run all tests (default)"
    echo "  unit         Run unit tests only"
    echo "  api          Run API tests only"
    echo "  integration  Run integration tests only"
    echo "  performance  Run performance tests only"
    echo "  coverage     Run tests with coverage report"
    echo "  fast         Run quick smoke tests"
    echo "  watch        Run tests in watch mode"
    echo "  benchmark    Run performance benchmarks"
    echo "  load         Run load tests with Locust"
    echo "  help         Show this help message"
    echo ""
    exit 1
}

# Check if pytest is installed
if ! command -v pytest &> /dev/null; then
    echo -e "${RED}Error: pytest not installed${NC}"
    echo "Install with: pip install -r requirements.txt"
    exit 1
fi

# Parse command line argument
COMMAND=${1:-all}

case "$COMMAND" in
    all)
        echo -e "${GREEN}Running all tests...${NC}\n"
        pytest tests/ -v --tb=short
        ;;

    unit)
        echo -e "${GREEN}Running unit tests...${NC}\n"
        pytest tests/unit -v -m unit --tb=short
        ;;

    api)
        echo -e "${GREEN}Running API tests...${NC}\n"
        pytest tests/unit/test_api_endpoints.py -v -m api --tb=short
        ;;

    integration)
        echo -e "${GREEN}Running integration tests...${NC}\n"
        pytest tests/integration -v -m integration --tb=short
        ;;

    performance)
        echo -e "${GREEN}Running performance tests...${NC}\n"
        pytest tests/performance -v -m performance --tb=short
        ;;

    coverage)
        echo -e "${GREEN}Running tests with coverage...${NC}\n"
        pytest --cov=. --cov-report=html --cov-report=term-missing --cov-branch
        echo -e "\n${GREEN}Coverage report generated:${NC} htmlcov/index.html"
        ;;

    fast)
        echo -e "${GREEN}Running fast smoke tests...${NC}\n"
        pytest tests/ -v -m smoke --tb=short
        if [ $? -eq 0 ]; then
            echo -e "\n${GREEN}Quick validation passed! ✓${NC}"
        fi
        ;;

    watch)
        echo -e "${GREEN}Running tests in watch mode...${NC}\n"
        echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"
        if command -v pytest-watch &> /dev/null; then
            pytest-watch tests/ -- -v --tb=short
        else
            echo -e "${RED}Error: pytest-watch not installed${NC}"
            echo "Install with: pip install pytest-watch"
            exit 1
        fi
        ;;

    benchmark)
        echo -e "${GREEN}Running performance benchmarks...${NC}\n"
        if command -v pytest-benchmark &> /dev/null; then
            pytest tests/performance -v --benchmark-only --benchmark-autosave
            echo -e "\n${GREEN}Benchmark results saved${NC}"
        else
            echo -e "${RED}Error: pytest-benchmark not installed${NC}"
            echo "Install with: pip install pytest-benchmark"
            exit 1
        fi
        ;;

    load)
        echo -e "${GREEN}Running load tests with Locust...${NC}\n"
        if ! command -v locust &> /dev/null; then
            echo -e "${RED}Error: locust not installed${NC}"
            echo "Install with: pip install locust"
            exit 1
        fi

        # Check if daemon is running
        if ! curl -s http://localhost:49917/health > /dev/null; then
            echo -e "${YELLOW}Warning: API server not running${NC}"
            echo "Start with: python daemon.py"
            echo ""
            read -p "Start server now? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Starting server in background..."
                python daemon.py &
                SERVER_PID=$!
                sleep 3
            else
                exit 1
            fi
        fi

        echo -e "${BLUE}Starting Locust web UI...${NC}"
        echo -e "Visit: ${GREEN}http://localhost:8089${NC}"
        echo ""
        locust -f tests/performance/locustfile.py --host=http://localhost:49917

        # Cleanup
        if [ ! -z "$SERVER_PID" ]; then
            kill $SERVER_PID
        fi
        ;;

    help)
        usage
        ;;

    *)
        echo -e "${RED}Error: Unknown option '$COMMAND'${NC}\n"
        usage
        ;;
esac

# Exit with pytest's exit code
exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo -e "\n${GREEN}✓ All tests passed!${NC}"
else
    echo -e "\n${RED}✗ Some tests failed${NC}"
fi

exit $exit_code
