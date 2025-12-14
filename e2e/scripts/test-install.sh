#!/usr/bin/env bash
# Test KubeSolo installation on a specific distro

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
    echo "Usage: $0 <distro> [--keep]"
    echo ""
    echo "Distros: debian, ubuntu, alpine, rocky"
    echo ""
    echo "Options:"
    echo "  --keep    Keep VM after test (don't destroy)"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

DISTRO="$1"
KEEP_VM=false

if [ "$2" == "--keep" ]; then
    KEEP_VM=true
fi

DISTRO_IMAGE=$(get_distro_image "$DISTRO")
if [ -z "$DISTRO_IMAGE" ]; then
    log_error "Unknown distro: $DISTRO"
    log_error "Available: $DISTROS_LIST"
    exit 1
fi

VM_NAME="kubesolo-test-${DISTRO}"

cleanup() {
    if [ "$KEEP_VM" = false ]; then
        log_info "Cleaning up..."
        delete_vm "$VM_NAME" || true
    else
        log_info "Keeping VM '$VM_NAME' for inspection"
    fi
}

trap cleanup EXIT

log_info "=========================================="
log_info "Testing KubeSolo on $DISTRO"
log_info "=========================================="

# Create VM
create_vm "$VM_NAME" "$DISTRO_IMAGE"

# Run install playbook
log_info "Running install playbook..."
run_playbook "$VM_NAME" "$E2E_DIR/playbooks/install.yml"

# Run verify playbook
log_info "Running verify playbook..."
run_playbook "$VM_NAME" "$E2E_DIR/playbooks/verify.yml"

log_info "=========================================="
log_info "Install test PASSED for $DISTRO"
log_info "=========================================="
