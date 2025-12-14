#!/usr/bin/env bash
# Test KubeSolo upgrade from old version to new version

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
log_info "Testing KubeSolo upgrade on $DISTRO"
log_info "=========================================="

# Create VM
create_vm "$VM_NAME" "$DISTRO_IMAGE"

# Install old version
log_info "Installing old version (v0.2.1)..."
run_playbook "$VM_NAME" "$E2E_DIR/playbooks/install.yml" \
    -e "kubesolo_version=v0.2.1"

# Verify old version installed
log_info "Verifying old version..."
run_playbook "$VM_NAME" "$E2E_DIR/playbooks/verify.yml"

# Upgrade to new version
log_info "Upgrading to new version (v1.0.0)..."
run_playbook "$VM_NAME" "$E2E_DIR/playbooks/install.yml" \
    -e "kubesolo_version=v1.0.0"

# Verify new version
log_info "Verifying new version..."
run_playbook "$VM_NAME" "$E2E_DIR/playbooks/verify.yml"

log_info "=========================================="
log_info "Upgrade test PASSED for $DISTRO"
log_info "=========================================="
