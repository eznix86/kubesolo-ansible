#!/usr/bin/env bash
# Run all e2e tests on all distros

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
    echo "Usage: $0 [--parallel] [--test=<test>]"
    echo ""
    echo "Options:"
    echo "  --parallel       Run tests in parallel (one per distro)"
    echo "  --test=<test>    Run specific test (install, upgrade, uninstall)"
    echo "                   Default: install"
    exit 1
}

PARALLEL=false
TEST_TYPE="install"

for arg in "$@"; do
    case $arg in
        --parallel)
            PARALLEL=true
            ;;
        --test=*)
            TEST_TYPE="${arg#*=}"
            ;;
        --help)
            usage
            ;;
    esac
done

FAILED=""
PASSED=""

run_test() {
    local distro="$1"
    local test_script="$SCRIPT_DIR/test-${TEST_TYPE}.sh"

    if [ ! -f "$test_script" ]; then
        log_error "Test script not found: $test_script"
        return 1
    fi

    log_info "Running $TEST_TYPE test on $distro..."
    if "$test_script" "$distro"; then
        return 0
    else
        return 1
    fi
}

log_info "=========================================="
log_info "Running $TEST_TYPE tests on all distros"
log_info "=========================================="

if [ "$PARALLEL" = true ]; then
    # Run tests in parallel (bash 3.x compatible)
    pids=""
    distro_order=""
    for distro in $DISTROS_LIST; do
        run_test "$distro" &
        pids="$pids $!"
        distro_order="$distro_order $distro"
    done

    # Wait for all tests
    i=0
    for pid in $pids; do
        distro=$(echo $distro_order | cut -d' ' -f$((i+2)))
        if wait "$pid"; then
            PASSED="$PASSED $distro"
        else
            FAILED="$FAILED $distro"
        fi
        i=$((i+1))
    done
else
    # Run tests sequentially
    for distro in $DISTROS_LIST; do
        if run_test "$distro"; then
            PASSED="$PASSED $distro"
        else
            FAILED="$FAILED $distro"
        fi
    done
fi

log_info "=========================================="
log_info "Test Results"
log_info "=========================================="

if [ -n "$PASSED" ]; then
    log_info "PASSED:$PASSED"
fi

if [ -n "$FAILED" ]; then
    log_error "FAILED:$FAILED"
    exit 1
fi

log_info "All tests passed!"
