# E2E tests with OrbStack
.PHONY: install lint clean help
.PHONY: e2e-test e2e-test-debian e2e-test-ubuntu e2e-test-alpine e2e-test-rocky e2e-cleanup
.PHONY: e2e-test-upgrade e2e-test-upgrade-debian e2e-test-upgrade-ubuntu e2e-test-upgrade-alpine e2e-test-upgrade-rocky e2e-test-upgrade-all
.PHONY: e2e-test-uninstall e2e-test-uninstall-debian e2e-test-uninstall-ubuntu e2e-test-uninstall-alpine e2e-test-uninstall-rocky e2e-test-uninstall-all

help:
	@echo "make install                   - Install dependencies"
	@echo "make lint                      - Run linters"
	@echo "make clean                     - Cleanup all VMs and caches"
	@echo ""
	@echo "make e2e-test                  - Run install tests on all distros"
	@echo "make e2e-test-debian           - Test install on Debian"
	@echo "make e2e-test-ubuntu           - Test install on Ubuntu"
	@echo "make e2e-test-alpine           - Test install on Alpine"
	@echo "make e2e-test-rocky            - Test install on Rocky Linux"
	@echo ""
	@echo "make e2e-test-upgrade-all      - Test upgrade on all distros"
	@echo "make e2e-test-upgrade-debian   - Test upgrade on Debian"
	@echo "make e2e-test-upgrade-ubuntu   - Test upgrade on Ubuntu"
	@echo "make e2e-test-upgrade-alpine   - Test upgrade on Alpine"
	@echo "make e2e-test-upgrade-rocky    - Test upgrade on Rocky Linux"
	@echo ""
	@echo "make e2e-test-uninstall-all    - Test uninstall on all distros"
	@echo "make e2e-test-uninstall-debian - Test uninstall on Debian"
	@echo "make e2e-test-uninstall-ubuntu - Test uninstall on Ubuntu"
	@echo "make e2e-test-uninstall-alpine - Test uninstall on Alpine"
	@echo "make e2e-test-uninstall-rocky  - Test uninstall on Rocky Linux"
	@echo ""
	@echo "make e2e-cleanup               - Cleanup all e2e VMs"

install:
	uv sync --group dev
	uv run ansible-galaxy collection install -r requirements.yml

lint:
	uv run yamllint .
	uv run ansible-lint

clean:
	./e2e/scripts/cleanup.sh || true
	rm -rf .venv __pycache__

# E2E Install Tests
e2e-test:
	./e2e/scripts/test-all.sh

e2e-test-debian:
	./e2e/scripts/test-install.sh debian

e2e-test-ubuntu:
	./e2e/scripts/test-install.sh ubuntu

e2e-test-alpine:
	./e2e/scripts/test-install.sh alpine

e2e-test-rocky:
	./e2e/scripts/test-install.sh rocky

# E2E Upgrade Tests
e2e-test-upgrade-all:
	./e2e/scripts/test-all.sh --test=upgrade

e2e-test-upgrade-debian:
	./e2e/scripts/test-upgrade.sh debian

e2e-test-upgrade-ubuntu:
	./e2e/scripts/test-upgrade.sh ubuntu

e2e-test-upgrade-alpine:
	./e2e/scripts/test-upgrade.sh alpine

e2e-test-upgrade-rocky:
	./e2e/scripts/test-upgrade.sh rocky

# E2E Uninstall Tests
e2e-test-uninstall-all:
	./e2e/scripts/test-all.sh --test=uninstall

e2e-test-uninstall-debian:
	./e2e/scripts/test-uninstall.sh debian

e2e-test-uninstall-ubuntu:
	./e2e/scripts/test-uninstall.sh ubuntu

e2e-test-uninstall-alpine:
	./e2e/scripts/test-uninstall.sh alpine

e2e-test-uninstall-rocky:
	./e2e/scripts/test-uninstall.sh rocky

e2e-cleanup:
	./e2e/scripts/cleanup.sh
