#!/bin/bash

# Make all port 49917 related scripts executable

echo "Making scripts executable..."

chmod +x kill_backend.sh
chmod +x diagnose_backend.sh
chmod +x configure_backend_port.sh
chmod +x test_port_setup.sh
chmod +x check_backend_port_config.sh

echo "✅ All scripts are now executable"
echo ""
echo "Available scripts:"
echo "  ./kill_backend.sh                  - Kill process on port 49917"
echo "  ./diagnose_backend.sh              - Diagnose backend issues"
echo "  ./configure_backend_port.sh        - Check backend port configuration"
echo "  ./test_port_setup.sh               - Test complete setup"
echo "  ./check_backend_port_config.sh     - Verify backend configuration"
echo ""
