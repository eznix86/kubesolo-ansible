# Deploy KubeSolo with Ansible

Author: <https://github.com/eznix86>

Deploy [KubeSolo](https://github.com/portainer/kubesolo) - Portainer's ultra-lightweight single-node Kubernetes distribution for edge and IoT devices.

Easily bring up KubeSolo on machines running:

- [X] Debian
- [X] Ubuntu
- [X] RHEL Family (CentOS, Rocky Linux, Alma Linux, Fedora)
- [X] Alpine Linux
- [X] Arch Linux
- [X] openSUSE
- [X] Void Linux

on processor architectures:

- [X] x86_64 (amd64)
- [X] aarch64 (arm64)
- [X] armv7l (arm)
- [X] riscv64

with init systems:

- [X] systemd
- [X] OpenRC
- [X] SysV init
- [X] s6
- [X] runit
- [X] upstart

## System requirements

The control node must have Ansible 2.10+ (ansible-core 2.10+)

All managed nodes must have:
- Passwordless SSH access
- Root access (or a user with sudo privileges)
- No Docker installed (conflicts with containerd)
- RFC 1123 compliant hostname (lowercase)

## Installation

### With ansible-galaxy

```bash
ansible-galaxy collection install git+https://github.com/eznix86/kubesolo-ansible.git
```

Alternatively, add to your `requirements.yml`:

```yaml
collections:
  - name: https://github.com/eznix86/kubesolo-ansible.git
    type: git
    version: main
```

Then install:

```bash
ansible-galaxy collection install -r requirements.yml
```

### From source

```bash
git clone https://github.com/eznix86/kubesolo-ansible.git
cd kubesolo-ansible
```

## Usage

First, create an inventory file `inventory.yml`:

```yaml
all:
  children:
    kubesolo_nodes:
      hosts:
        edge-01:
          ansible_host: 192.168.1.101
        edge-02:
          ansible_host: 192.168.1.102
  vars:
    ansible_user: root
```

Then create a playbook `site.yml`:

```yaml
---
- name: Deploy KubeSolo
  hosts: kubesolo_nodes
  become: true
  roles:
    - kubesolo
```

Run the playbook:

```bash
# If installed with ansible-galaxy
ansible-playbook site.yml -i inventory.yml

# If running from cloned repository
ANSIBLE_ROLES_PATH=./roles ansible-playbook site.yml -i inventory.yml
```

## Upgrading

To upgrade KubeSolo, update the version and run the playbook:

```yaml
---
- name: Upgrade KubeSolo
  hosts: kubesolo_nodes
  become: true
  roles:
    - role: kubesolo
      kubesolo_version: "v1.1.0"
```

## Uninstalling

```yaml
---
- name: Uninstall KubeSolo
  hosts: kubesolo_nodes
  become: true
  roles:
    - role: kubesolo
      kubesolo_state: absent
      kubesolo_remove_data: true
```

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `kubesolo_state` | `present` | State: `present`, `absent`, or `upgraded` |
| `kubesolo_version` | `v1.0.0` | KubeSolo version to install |
| `kubesolo_mode` | `standard` | Mode: `standard` or `minimal` (for embedded systems) |
| `kubesolo_path` | `/var/lib/kubesolo` | Data directory path |
| `kubesolo_install_path` | `/usr/local/bin/kubesolo` | Binary installation path |
| `kubesolo_run_mode` | `service` | Run mode: `service`, `daemon`, or `foreground` |
| `kubesolo_apiserver_extra_sans` | `[]` | Extra SANs for API server certificate |
| `kubesolo_local_storage` | `false` | Enable local storage provisioner |
| `kubesolo_debug` | `false` | Enable debug logging |
| `kubesolo_pprof_server` | `false` | Enable pprof server |
| `kubesolo_proxy` | `""` | HTTP proxy URL |
| `kubesolo_remove_data` | `false` | Remove data directory on uninstall |

### Portainer Edge Integration

| Variable | Default | Description |
|----------|---------|-------------|
| `kubesolo_portainer_edge_id` | `""` | Portainer Edge ID |
| `kubesolo_portainer_edge_key` | `""` | Portainer Edge Key |
| `kubesolo_portainer_edge_async` | `false` | Enable async Edge mode |

## Kubeconfig

After installation, the kubeconfig is available at:

```
/var/lib/kubesolo/pki/admin/admin.kubeconfig
```

To use it:

```bash
export KUBECONFIG=/var/lib/kubesolo/pki/admin/admin.kubeconfig
kubectl get nodes
```

## Minimal Mode

For embedded/busybox systems, use minimal mode:

```yaml
- role: kubesolo
  kubesolo_mode: minimal
```

This creates a simple init script and `kubesolo-ctl` helper:

```bash
kubesolo-ctl start
kubesolo-ctl stop
kubesolo-ctl status
kubesolo-ctl restart
```

## Local Testing

E2E tests use [OrbStack](https://orbstack.dev/) for lightweight Linux VMs on macOS:

```bash
# Install dependencies
make install

# Run tests on specific distro
make e2e-test-debian
make e2e-test-ubuntu
make e2e-test-alpine
make e2e-test-rocky

# Run all install tests
make e2e-test

# Run upgrade tests
make e2e-test-upgrade-all

# Run uninstall tests
make e2e-test-uninstall-all

# Cleanup VMs
make e2e-cleanup
```

## Troubleshooting

### Check Service Status

```bash
# systemd
systemctl status kubesolo

# OpenRC
rc-service kubesolo status

# SysV init
service kubesolo status
```

### View Logs

```bash
# systemd
journalctl -u kubesolo -f

# Other init systems
tail -f /var/log/kubesolo.log
```

## License

MIT

## Links

- [KubeSolo](https://github.com/portainer/kubesolo)
- [Portainer](https://www.portainer.io/)
- [Issue Tracker](https://github.com/eznix86/kubesolo-ansible/issues)
