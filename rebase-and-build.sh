#!/usr/bin/env bash
# ==============================================================================
# ELLX-Kernel Surface Laptop 7 (13.8") Rebase & Build Script
# Rebase custom Surface Linux patches onto the latest linux-qcom-x1e tree
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_DIR="${SCRIPT_DIR}/patches"

UPSTREAM_REPO="https://github.com/zensanp/linux-book4-edge.git"
UPSTREAM_BRANCH="x1e80100-book4e-7.2-14-tmp"
NEW_BRANCH="7.2-sl7-13.8"

echo "=== 1. Checking Git Status ==="
if [ ! -d ".git" ]; then
    echo "Error: Must be run from the root of the kernel git repository."
    exit 1
fi

echo "=== 2. Configuring Upstream Remote ==="
if ! git remote get-url upstream >/dev/null 2>&1; then
    git remote add upstream "${UPSTREAM_REPO}"
fi
git fetch upstream "${UPSTREAM_BRANCH}"

echo "=== 3. Checking out Rebase Target Branch ==="
git checkout -B "${NEW_BRANCH}" "upstream/${UPSTREAM_BRANCH}"

echo "=== 4. Applying Surface Laptop 7 (13.8\") Patch Series ==="
while IFS= read -r patch || [ -n "$patch" ]; do
    # Skip comments and empty lines
    [[ "$patch" =~ ^#.*$ ]] && continue
    [[ -z "$patch" ]] && continue

    echo "--> Applying patch: ${patch}"
    if git am --3way "${PATCH_DIR}/${patch}"; then
        echo "    [OK] Applied ${patch}"
    else
        echo "    [FAIL] Conflict applying ${patch}. Resolve and run 'git am --continue'"
        exit 1
    fi
done < "${PATCH_DIR}/series"

echo "=== 5. Verifying Romulus 13.8\" Device Tree ==="
if [ -f "arch/arm64/boot/dts/qcom/x1e80100-microsoft-romulus13.dts" ]; then
    echo "    [OK] x1e80100-microsoft-romulus13.dts is present."
else
    echo "    [WARN] Creating x1e80100-microsoft-romulus13.dts..."
    cat << 'EOF' > arch/arm64/boot/dts/qcom/x1e80100-microsoft-romulus13.dts
// SPDX-License-Identifier: BSD-3-Clause
/*
 * Copyright (c) 2024 Qualcomm Innovation Center, Inc. All rights reserved.
 */

/dts-v1/;

#include "x1e80100-microsoft-romulus.dtsi"

/ {
	model = "Microsoft Surface Laptop 7 (13.8 inch)";
	compatible = "microsoft,romulus13", "qcom,x1e80100";
};
EOF
    git add arch/arm64/boot/dts/qcom/x1e80100-microsoft-romulus13.dts
    git commit -m "arm64: dts: qcom: Ensure x1e80100-microsoft-romulus13.dts is present"
fi

echo "=== 6. Updating Ubuntu Kernel Packaging Configurations ==="
if [ -f "debian/rules" ]; then
    sed -i 's/do_stubble\s*=\s*true/do_stubble = false/' debian.qcom-x1e/rules.d/arm64.mk || true
    chmod +x debian/rules
    fakeroot ./debian/rules clean || true
    ./debian/rules updateconfigs || true
    git add debian.qcom-x1e/config/annotations debian.qcom-x1e/config/arm64/*.config debian.qcom-x1e/rules.d/arm64.mk || true
    git commit -m "debian.qcom-x1e: sync annotations and disable stubble for 7.2" || true
fi

echo "=============================================================================="
echo " Rebase complete on branch '${NEW_BRANCH}'!"
echo " Next Steps:"
echo " 1. Push branch to GitHub: git push -u origin ${NEW_BRANCH}"
echo " 2. The native ARM64 runner on GitHub Actions will automatically compile"
echo "    the kernel and produce downloadable .deb packages."
echo " 3. Or build locally with:"
echo "    export DEB_BUILD_OPTIONS=\"parallel=\$(nproc)\""
echo "    fakeroot ./debian/rules binary-headers binary-qcom-x1e do_skip_checks=true do_stubble=false"
echo "=============================================================================="
