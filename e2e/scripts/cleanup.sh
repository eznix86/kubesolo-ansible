#!/usr/bin/env bash
# Cleanup all e2e test VMs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

log_info "Cleaning up all e2e test VMs..."
cleanup_all

log_info "Cleanup complete"
