#!/bin/bash

# validate.sh - Infrastructure Validation Script
# Checks all required components are working

echo "=========================================="
echo "Infrastructure Validation Report"
echo "Time: $(date)"
echo "=========================================="

PASS=0
FAIL=0

# Test 1: Service is running
echo -n "Checking service status... "
if systemctl is-active --quiet infra-demo.service; then
    echo "✅ PASS - Service is running"
    ((PASS++))
else
    echo "❌ FAIL - Service is not running"
    ((FAIL++))
fi

# Test 2: Health endpoint works
echo -n "Checking health endpoint... "
HEALTH=$(curl -s http://localhost:8080/health)
if echo "$HEALTH" | grep -q "healthy"; then
    echo "✅ PASS - Health endpoint OK"
    ((PASS++))
else
    echo "❌ FAIL - Health endpoint not responding"
    ((FAIL++))
fi

# Test 3: Timer is active
echo -n "Checking maintenance timer... "
if systemctl is-active --quiet infra-maintenance.timer; then
    echo "✅ PASS - Timer is active"
    ((PASS++))
else
    echo "❌ FAIL - Timer is not active"
    ((FAIL++))
fi

# Test 4: Operator user exists
echo -n "Checking operator user... "
if id operator &>/dev/null; then
    echo "✅ PASS - Operator user exists"
    ((PASS++))
else
    echo "❌ FAIL - Operator user missing"
    ((FAIL++))
fi

# Test 5: Service files exist
echo -n "Checking service files... "
if [ -f /opt/infra-demo/service.py ] && [ -f /opt/infra-demo/infra-demo.env ]; then
    echo "✅ PASS - Service files exist"
    ((PASS++))
else
    echo "❌ FAIL - Service files missing"
    ((FAIL++))
fi

# Test 6: Port 8080 is listening
echo -n "Checking port 8080... "
if ss -tuln | grep -q ":8080"; then
    echo "✅ PASS - Port 8080 is listening"
    ((PASS++))
else
    echo "❌ FAIL - Port 8080 not listening"
    ((FAIL++))
fi

# Summary
echo "=========================================="
echo "Results: $PASS PASSED, $FAIL FAILED"
echo "=========================================="

if [ $FAIL -eq 0 ]; then
    echo "✅ ALL TESTS PASSED - System is ready"
    exit 0
else
    echo "❌ SOME TESTS FAILED - Please review"
    exit 1
fi
