# bc250-linux — branch `bc250-r1`

Kernel patch set that makes the ASRock BC-250 (`1002:13fe`,
`gfx1013:xnack-`) usable for ROCm compute on Alpine `linux-lts` 6.18.50.
Tracked as patches (not a full kernel tree): apply onto the pristine
Alpine source, build the versioned `6.18.50-bc250rocm-test` kernel, boot
it one-shot. Stock Alpine stays the default.

Sibling branch [`bc250-r2`](https://github.com/Naster17/bc250-linux/tree/bc250-r2)
is the same series ported to 7.1.5 (current default boot).

## Why these patches exist

Stock `amdgpu`/`amdkfd` assumes server GPUs. The BC-250 is a harvested
PS5-class APU with three defects from the driver's point of view:

1. **24 of 40 CUs hidden** — firmware harvest mask + SPI dispatch mask.
2. **Stale TLB entries never invalidated** — the PASID sweep matches zero
   VMIDs on gfx10-under-HWS, so freed VAs get reused with old translations.
3. **NULL page crash** on TTM teardown (upstream amdgpu#222).

Each patch below fixes exactly one of these. All are PCI-gated to
`0x13FE` — they are no-ops on any other GPU.

## The patch series (apply in order with `scripts/apply.sh`)

| # | File | Problem | Fix | Boot param |
|---|---|---|---|---|
| 0000 | `0000-bc250-40cu-amdgpu.patch` (duggasco) | Harvest mask hides 16 CUs; SPI dispatches to 3 of 5 WGPs | Clear `CC_GC_SHADER_ARRAY_CONFIG`, set `SPI_PG_ENABLE_STATIC_WGP_MASK` + `RLC_PG_ALWAYS_ON_WGP_MASK` to `0x1f` in `gfx_v10_0_get_cu_info()` | `amdgpu.bc250_cc_write_mode=3` → `simd_count=80` (40 CUs) |
| 0001 | `0001-amdgpu-bc250-pasid-flush-param.patch` | PASID TLB flush via KIQ is never acknowledged, stalls the TU | `gmc.flush_pasid_uses_kiq = false` on BC-250 | `amdgpu.bc250_flush_pasid_kiq=0` |
| 0002 | `0002-amdgpu-ttm-skip-null-pages.patch` | `ttm->pages[i]->mapping = NULL` derefs NULL on teardown → panic | NULL-guard the loop in `amdgpu_ttm_tt_unpopulate()` | none (always on, harmless) |
| 0003 | `0003-bc250-runlist-tlb-flush.patch` (akandr/GabriWar approach) | Nothing invalidates the compute TLB (see above) | New `kfd_bc250_flush_by_runlist()`: rebuild the HWS runlist so firmware reassigns VMIDs (bitmask param) | `bc250_flush_by_runlist=3` (bit 1 = unmap, bit 2 = map) |
| 0004 | `0004-bc250-runlist-callsites.patch` | — | Call sites: `kfd_chardev.c` (map + unmap ioctls), `kfd_svm.c` (SVM map + unmap). Locking: `p->mutex` held, `dqm_lock` free — never call with `dqm_lock` held | — |
| 0005 | `0005-bc250-8core-telemetry.patch` (GabriWar, reference copy) | SMU metrics table is 6-core-wide; 8-core unlock breaks GPU freq reporting | Auto-detect physical core count, pick 8-core hybrid layout, query live GFXCLK; `cs_eight_core_map` override | none needed (auto) |

`0005` is telemetry only — it does not unlock cores. The actual 8-core
unlock is a runtime SMU operation, see `docs/8CORE-UNLOCK.md`.

## Validated boot line (r1)

```text
amdgpu.sg_display=0 mitigations=off amdgpu.gttsize=15200
ttm.pages_limit=3891200 ttm.page_pool_size=3891200
amdgpu.gpu_recovery=0 amdgpu.bc250_cc_write_mode=3
amdgpu.bc250_flush_pasid_kiq=0 amdgpu.bc250_flush_by_runlist=3
```

Plus: `sched_policy=0` (never `2` — wedges sustained compute),
SDMA firmware = navi12 ucode substituted under cyan names **inside the
r1 initramfs only** (stock `/lib/firmware` untouched).

## Build

```sh
./scripts/apply.sh /path/to/pristine-linux-6.18   # dry-runs, then applies
# then: cp Alpine lts.x86_64.config .config
# CONFIG_LOCALVERSION="-bc250rocm-test", olddefconfig,
# make -j$(nproc) bzImage modules
```

See `docs/BUILD.md` for the full recipe (config seed, initramfs
features, GRUB one-shot entry, hash verification, rollback).

## Verify after boot

```sh
uname -r   # 6.18.50-bc250rocm-test
cat /sys/module/amdgpu/parameters/bc250_cc_write_mode        # 3
cat /sys/module/amdgpu/parameters/bc250_flush_pasid_kiq      # 0
cat /sys/module/amdgpu/parameters/bc250_flush_by_runlist     # 3
grep simd_count /sys/class/kfd/kfd/topology/nodes/1/properties  # 80
```

## Safety invariants

1. Stock `vmlinuz-lts` / `initramfs-lts` / modules / firmware untouched.
2. r1 never becomes default without explicit approval (r1 was one-shot;
   default promotion happened only for r2 after full gates).
3. `gpu_recovery=0`, `sched_policy=0`, 40-CU mode 3, TLB params present.
4. A wedged GPU = power cycle; the machine always comes back on stock.
