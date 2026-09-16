# bc250-linux

BC-250 (`1002:13fe`, `gfx1013`) kernel patch set for Alpine `linux-lts`
6.18.50, branch `bc250-r1`. Tracked as patches (not a full kernel tree) so
anyone can apply them onto the Alpine source and build the versioned r1
kernel. Stock Alpine stays default; r1 is one-shot only.

## Patches (apply in order)

- `0000-bc250-40cu-amdgpu.patch` - duggasco 40-CU unlock (CC harvest mask
  + SPI dispatch + RLC power), PCI `0x13FE` gated,
  `amdgpu.bc250_cc_write_mode=3`, simd_count=80.
- `0001-amdgpu-bc250-pasid-flush-param.patch` - PASID TLB flush without KIQ
  (`amdgpu.bc250_flush_pasid_kiq=0`).
- `0002-amdgpu-ttm-skip-null-pages.patch` - TTM null-page guard (amdgpu#222).
- Runlist TLB flush (akandr/GabriWar approach, adapted): parameter
  `bc250_flush_by_runlist=3`, implementation in
  `kfd_device_queue_manager.c` + call sites in `kfd_chardev.c`, `kfd_svm.c`.
  Shipped here as `0003-*.patch` + `0004-*.patch` (split from the board
  diff for reviewability; identical content to the deployed tree).

Validated boot params: `3/0/3`, `gpu_recovery=0`, `sched_policy=0`
(never `2`), SDMA firmware = navi12 ucode inside r1 initramfs only.

## 8-CPU question

No CPU topology change exists. The APU exposes 12 x86 threads (6C/12T
Zen); config allows 256. "40CU" is the GPU unlock; there is no 8-CPU
patch and none is needed.
