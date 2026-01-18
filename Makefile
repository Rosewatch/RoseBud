build-image:
	cd distro/src; \
	docker run --privileged --rm -v `pwd`:/distro --device /dev/loop-control ghcr.io/guysoft/custompios:devel build

build-shell-bundle:
	cd desktop; \
	make build-bundle

build-shell-full:
	cd desktop; \
	make full-build

run-shell:
	cd desktop; \
	make build-run

build-os: build-shell-full copy-shell build-image

copy-shell:
	mkdir -p distro/src/modules/rosedistro/filesystem/home/pi/rosewatch && \
	cp desktop/build/src/shell/rosewatch distro/src/modules/rosedistro/filesystem/home/pi/rosewatch/rosewatch && \
	cp -r desktop/scripts distro/src/modules/rosedistro/filesystem/home/pi/rosewatch/scripts && \
	cp -r desktop/apps distro/src/modules/rosedistro/filesystem/home/pi/rosewatch/apps

# ============================================================================
# RoseDistro (NixOS-based) Targets
# ============================================================================
# These targets build the NixOS-based distribution using Nix flakes.
# Requires: Nix with flakes enabled, QEMU aarch64 emulation
#
# Quick setup on Fedora:
#   sh <(curl -L https://nixos.org/nix/install) --daemon
#   echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
#   sudo dnf install qemu-user-static qemu-system-aarch64
#   sudo systemctl restart systemd-binfmt
# ============================================================================

ROSEDISTRO_DIR := ../RoseDistro

# Build the complete NixOS SD card image
nixos-image:
	cd $(ROSEDISTRO_DIR) && ./build.sh image

# Build only the rosewatch application (for testing)
nixos-app:
	cd $(ROSEDISTRO_DIR) && ./build.sh app

# Build only the GPIO daemon (for testing)
nixos-gpio:
	cd $(ROSEDISTRO_DIR) && ./build.sh gpio

# Enter NixOS development shell
nixos-shell:
	cd $(ROSEDISTRO_DIR) && ./build.sh shell

# Clean NixOS build artifacts
nixos-clean:
	cd $(ROSEDISTRO_DIR) && ./build.sh clean

# Flash NixOS image to SD card (set DEVICE env var)
# Usage: make nixos-flash DEVICE=/dev/sdX
nixos-flash:
ifndef DEVICE
	$(error DEVICE is not set. Usage: make nixos-flash DEVICE=/dev/sdX)
endif
	cd $(ROSEDISTRO_DIR) && DEVICE=$(DEVICE) ./build.sh flash

# Full NixOS build (alias for nixos-image)
nixos: nixos-image

# ============================================================================
# QEMU Emulation Targets
# ============================================================================
# Run the built NixOS image in QEMU for testing without real hardware.
# Requires: qemu-system-aarch64, edk2-aarch64 (UEFI firmware)
#
# Install on Fedora:
#   sudo dnf install qemu-system-aarch64 edk2-aarch64
# ============================================================================

# Run QEMU emulator with SDL display
nixos-emulate:
	cd $(ROSEDISTRO_DIR) && ./build.sh emulate

# Run QEMU emulator (alias)
nixos-run: nixos-emulate

# Setup persistent QEMU disk from image
nixos-emu-setup:
	cd $(ROSEDISTRO_DIR) && ./build.sh emu-setup

# Run QEMU in snapshot mode (no persistent changes)
nixos-emu-snapshot:
	cd $(ROSEDISTRO_DIR) && ./build.sh emu-snapshot

# Run QEMU headless (serial console only)
nixos-emu-headless:
	cd $(ROSEDISTRO_DIR) && HEADLESS=1 ./build.sh emulate

# Run QEMU with VNC display
nixos-emu-vnc:
	cd $(ROSEDISTRO_DIR) && VNC=1 ./build.sh emulate

# Build and run (convenience target)
nixos-build-run: nixos-image nixos-emu-setup nixos-emulate

# Help for NixOS targets
nixos-help:
	@echo "RoseDistro (NixOS) Targets:"
	@echo ""
	@echo "Build Targets:"
	@echo "  nixos-image        Build SD card image"
	@echo "  nixos-app          Build only rosewatch app"
	@echo "  nixos-gpio         Build only GPIO daemon"
	@echo "  nixos-shell        Enter development shell"
	@echo "  nixos-clean        Clean build artifacts"
	@echo "  nixos-flash        Flash to SD card (requires DEVICE=...)"
	@echo ""
	@echo "Emulation Targets:"
	@echo "  nixos-emulate      Run in QEMU with SDL display"
	@echo "  nixos-run          Alias for nixos-emulate"
	@echo "  nixos-emu-setup    Setup/refresh QEMU disk image"
	@echo "  nixos-emu-snapshot Run QEMU without saving changes"
	@echo "  nixos-emu-headless Run QEMU with serial console only"
	@echo "  nixos-emu-vnc      Run QEMU with VNC display"
	@echo "  nixos-build-run    Build image and run in QEMU"
	@echo ""
	@echo "Examples:"
	@echo "  make nixos-flash DEVICE=/dev/sdb"
	@echo "  make nixos-build-run"
	@echo "  make nixos-emu-headless"
	@echo ""
	@echo "QEMU Notes:"
	@echo "  - SSH forwarded to localhost:2222"
	@echo "  - Exit: Ctrl+A X (serial) or close window (SDL)"
	@echo "  - Set QEMU_MEM=4G for more memory"

.PHONY: nixos-image nixos-app nixos-gpio nixos-shell nixos-clean nixos-flash nixos nixos-help
.PHONY: nixos-emulate nixos-run nixos-emu-setup nixos-emu-snapshot nixos-emu-headless nixos-emu-vnc nixos-build-run
