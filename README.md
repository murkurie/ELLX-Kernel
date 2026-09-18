# ELLX-Kernel 7.2 Update for Surface Laptop 7 (13.8")

This package contains the complete update kit to rebase [ELLX-Kernel](https://github.com/ProgrammerIn-wonderland/ELLX-Kernel) onto the latest **`linux-qcom-x1e`** kernel tree (Linux 7.2.0 series for Ubuntu 26.04 resolute), with native GitHub Actions ARM64 automated compilation.

---

## Hardware Enablement Overview (Surface Laptop 7 13.8")

| Subsystem | Upstream Linux Status | ELLX-Kernel 7.2 Status | Driver / Implementation |
| :--- | :--- | :--- | :--- |
| **Touchpad & Haptics** | Broken in upstream | **Working** | `spi-hid` (HIDSPI v3 over Qualcomm QSPI 1-4-4, GPI DMA protocol 9) |
| **RGB Camera (Webcam)** | Missing crop & config | **Working** | `ov02c10` driver patch + CSIPHY4 / CAMSS device tree nodes |
| **Display & Retimers** | Type-C power issues | **Working** | Merged upstream in 7.2 (`ps883x` power-off during idle) |
| **Wi-Fi 7 / BT** | Enumeration stall | **Working** | `ath12k` rfkill bypass for Romulus |
| **Battery & EC** | In-tree via SAM | **Working** | Surface Aggregator Module (SSAM) + `qcom_battmgr` |
| **Device Tree (13.8")** | Base present in upstream | **Enriched** | Complete Romulus 13.8" device tree (`x1e80100-microsoft-romulus13.dts`) |

---

## Directory Structure

```
ELLX-Kernel-Update/
├── .github/
│   └── workflows/
│       └── build-arm64-kernel.yml    # Native ARM64 GitHub Actions build workflow
├── patches/                          # Modular, conflict-free patch series for 7.2
│   ├── 0001-ath12k-romulus-enumeration.patch
│   ├── 0002-hid-core-bus-spi.patch
│   ├── 0003-spi-hid-driver.patch
│   ├── 0004-qcom-gpi-dma-qspi.patch
│   ├── 0005-spi-geni-qcom-qspi.patch
│   ├── 0006-ov02c10-camera-sensor.patch
│   ├── 0007-surface-laptop-7-romulus-dt.patch
│   ├── 0008-debian-qcom-x1e-config-annotations.patch
│   ├── 0009-debian-qcom-x1e-disable-stubble.patch
│   └── series                        # Quilt / git-am patch order
├── rebase-and-build.sh               # One-click automated rebase and build script
└── README.md                         # This guide
```

---

## Rebase & Build Methods

### Method 1: Automated Build via GitHub Actions Native ARM64 Runners (Recommended)

GitHub now provides native ARM64 runners (`ubuntu-24.04-arm`). No cross-compilation or QEMU emulation is needed.

1. In your `ELLX-Kernel` repository, copy `.github/workflows/build-arm64-kernel.yml` into `.github/workflows/`:
   ```bash
   mkdir -p .github/workflows
   cp .github/workflows/build-arm64-kernel.yml .github/workflows/
   ```
2. Apply the patch series from `patches/` to your target branch (`7.2-sl7-13.8`).
3. Push the branch to GitHub:
   ```bash
   git push origin 7.2-sl7-13.8
   ```
4. GitHub Actions will launch the native ARM64 runner, compile the kernel in parallel, and attach the `.deb` files (`linux-image-*.deb`, `linux-headers-*.deb`, `linux-modules-*.deb`) directly to the Action run artifacts.
5. To automatically generate a GitHub Release with the `.deb` installers, push a tag:
   ```bash
   git tag v7.2.0-sl7-13.8
   git push origin v7.2.0-sl7-13.8
   ```

---

### Method 2: Rebase & Build via `rebase-and-build.sh`

Run the automated script inside your cloned `ELLX-Kernel` repository:

```bash
chmod +x rebase-and-build.sh
./rebase-and-build.sh
```

The script will:
1. Fetch the latest `linux-qcom-x1e` 7.2 base branch (`7.2.0-jg-1`).
2. Create and switch to branch `7.2-sl7-13.8`.
3. Sequentially apply all 9 modular Surface Laptop 7 patches with `git am`.
4. Ensure the 13.8" device tree (`x1e80100-microsoft-romulus13.dts`) is configured.
5. Run `./debian/rules updateconfigs` to validate packaging annotations.

---

## Installation on Surface Laptop 7 (Ubuntu)

Once the Debian packages have been built (or downloaded from GitHub Releases):

1. **Install the packages**:
   ```bash
   sudo dpkg -i linux-image-7.2.0-*-qcom-x1e_*.deb \
                linux-modules-7.2.0-*-qcom-x1e_*.deb \
                linux-headers-7.2.0-*-qcom-x1e_*.deb
   ```

2. **Verify Device Tree**:
   Ensure GRUB or the bootloader loads `qcom/x1e80100-microsoft-romulus13.dtb`:
   ```bash
   sudo cp /usr/lib/linux-image-*/qcom/x1e80100-microsoft-romulus13.dtb /boot/dtb/
   ```

3. **Extract Firmware (if needed for audio/modem)**:
   ```bash
   sudo apt install qcom-firmware-extract
   sudo qcom-firmware-extract
   ```

4. **Update GRUB & Reboot**:
   ```bash
   sudo update-grub
   sudo reboot
   ```
