#!/usr/bin/env bash
# Common functions for e2e tests

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# VM configurations (compatible with bash 3.x)
get_distro_image() {
    local distro="$1"
    case "$distro" in
        debian) echo "debian:12" ;;
        ubuntu) echo "ubuntu:24.04" ;;
        alpine) echo "alpine:3.22" ;;
        rocky)  echo "rocky:10" ;;
        *)      echo "" ;;
    esac
}

DISTROS_LIST="debian ubuntu alpine rocky"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E2E_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$E2E_DIR")"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create a VM with OrbStack
create_vm() {
    local name="$1"
    local distro="$2"

    if orbctl list -q | grep -q "^${name}$"; then
        log_info "VM '$name' already exists"
        return 0
    fi

    log_info "Creating VM '$name' with distro '$distro'..."
    orbctl create "$distro" "$name"

    # Wait for VM to be ready
    sleep 5

    # Install Python and dependencies for Ansible
    case "$distro" in
        alpine*)
            orb -m "$name" sudo apk add --no-cache python3 sudo bash curl tar iptables procps
            ;;
        debian*|ubuntu*)
            orb -m "$name" sudo apt-get update
            orb -m "$name" sudo apt-get install -y python3 sudo curl tar iptables procps
            ;;
        rocky*|alma*|fedora*)
            orb -m "$name" sudo dnf install -y python3 sudo curl tar iptables procps-ng
            ;;
    esac

    log_info "VM '$name' created and ready"
}

# Delete a VM
delete_vm() {
    local name="$1"

    if ! orbctl list -q | grep -q "^${name}$"; then
        log_info "VM '$name' does not exist"
        return 0
    fi

    log_info "Deleting VM '$name'..."
    orbctl delete "$name" -f
}

# Start a VM
start_vm() {
    local name="$1"

    log_info "Starting VM '$name'..."
    orbctl start "$name"
}

# Stop a VM
stop_vm() {
    local name="$1"

    log_info "Stopping VM '$name'..."
    orbctl stop "$name"
}

# Check if VM exists
vm_exists() {
    local name="$1"
    orbctl list -q | grep -q "^${name}$"
}

# Get VM IP (OrbStack uses hostname resolution)
get_vm_host() {
    local name="$1"
    echo "${name}@orb"
}

# Generate Ansible inventory for a VM
generate_inventory() {
    local name="$1"
    local inventory_file="$E2E_DIR/inventory/${name}.yml"

    cat > "$inventory_file" << EOF
---
all:
  hosts:
    ${name}:
      ansible_host: ${name}@orb
      ansible_connection: ssh
      ansible_user: ${USER}
      ansible_become: true
      ansible_python_interpreter: auto_silent
  children:
    kubesolo_nodes:
      hosts:
        ${name}:
EOF

    echo "$inventory_file"
}

# Run Ansible playbook on a VM
run_playbook() {
    local name="$1"
    local playbook="$2"
    shift 2
    local extra_args="$@"

    local inventory_file
    inventory_file=$(generate_inventory "$name")

    log_info "Running playbook '$playbook' on VM '$name'..."

    ANSIBLE_ROLES_PATH="$PROJECT_DIR/roles" \
    ansible-playbook \
        -i "$inventory_file" \
        "$playbook" \
        $extra_args
}

# Run command on VM
run_on_vm() {
    local name="$1"
    shift
    orb -m "$name" "$@"
}

# Cleanup all test VMs
cleanup_all() {
    log_info "Cleaning up all test VMs..."
    for distro in $DISTROS_LIST; do
        local vm_name="kubesolo-test-${distro}"
        delete_vm "$vm_name" || true
    done
}
