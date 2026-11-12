# bc250-linux

BC-250 kernel: patched **Linux 7.1.5-bc250rocm-r2** source snapshot with the
amdgpu/amdkfd **gfx1013** compute quirks, plus the **r3** patch series and
provenance.

## Provenance (important)

This is **not a pristine upstream fork**. The r2 source is an already-patched
snapshot imported from the legacy build (Alpine Linux 7.1 base). The `main`
branch preserves that exact snapshot (single import commit `6f57bb40d`), so the
running kernel is reproducible by anchor hashes.

- Kernel identity: `7.1.5-bc250rocm-r2` (r3: `7.2.10-bc250rocm-r3`).
- Tracked source files: 93,517. Compiled objects, `vmlinux*`, `bzImage`,
  `System.map`, the signing private key, and the generated initramfs are excluded.

## r3 patch series

The r3 delta (6 patches) lives in the umbrella repo:
[`bc250-stack/patches/kernel-r3`](https://github.com/Naster17/bc250-stack/tree/main/patches/kernel-r3):

1. drm/amdgpu: retain explicit BC-250 quirks and restore display behavior.
2. drm/amdkfd: retain BC-250 runlist workaround with calibrated timing.
3. drm/amdgpu: invalidate BC-250 compute VMM translations.
4. drm/amdkfd: retain BC-250 queue eviction on SVM CPU unmap.
5. drm/amdkfd: defer BC-250 SVM runlist invalidation until safe.
6. drm/amd/display: clear only implemented HPD IRQ sources.

Full provenance, anchor hashes, and configuration notes:
[`bc250-stack/docs/KERNEL.md`](https://github.com/Naster17/bc250-stack/blob/main/docs/KERNEL.md).

## Verified source anchors (r2)

| File | SHA-256 |
| --- | --- |
| `.config` | `2ba383b4c6e519ca4cd441e7e19432f68d40551a4793ba926e3ab1f06a6f1d0c` |
| `Makefile` | `fb9e8ab7d6cf8a948f599e1adb4ac9cfcdf9fb3b5d73dcbec29b19abccea98b9` |
| `drivers/gpu/drm/amd/amdgpu/gfx_v10_0.c` | `fe44a207d763e99b0e4abe574e2a2e0d813c089d4c2e0210ea482a027bcd6898` |
| `drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c` | `263c5d83b1f1fd6ba575ee9bfc8e098ca9783ad775dd86d14a85778fa532e72a` |
| `drivers/gpu/drm/amd/amdgpu/amdgpu_ttm.c` | `389cb7ffcd70255d16f9dd941cf61d01c3cb447f85a968a9ab6fa5174fd9b444` |

Board-support repositories and runtime unlocks are retained separately; this
import is not proof that all optional unlock patches are applied.
