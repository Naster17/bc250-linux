# 8-core CPU unlock (not a kernel patch)

The BC-250 ships as a 6-core part (12 threads). The other two Zen 2 cores
are not fused off: they are masked by SMU register `SMN 0x0115A870`
(`0x77` stock = cores 3+7 masked, `0xFF` = all 8 cores).

## Key facts

- This is an **SMU mailbox / runtime operation**, not a kernel source
  change. Tool: `GabriWar/bc250-core-cu-unlock` (`bc250-8core-unlock.sh`
  `{status,apply,install}`), via SMU message `0x98` over PCI `00:00.0`
  index/data `0xB8`/`0xBC`. Needs `setpci` + root.
- The mask is set live but topology only re-enumerates on **warm reboot**.
  Cold boot (power removed) reverts to `0x77` - the built-in escape hatch.
- Stop `cyan-skillfish-governor-smu` before any status/apply: it shares the
  same index/data pair and can corrupt the access mid-sequence.
- After unlock: update ACPI (`mendesrr/bc250-acpi-fix-updated-8c`, CPUs
  12-15 need C-states), re-validate overclock/undervolt, expect GPU freq
  reporting quirks (monitoring only).
- Health: per-core `stress-ng --verify` clean on the documented board;
  always run `test-cores.sh` on your own silicon.

## Kernel side (in this repo's series)

`GabriWar` `kernel/patches/0001-bc250-8core-telemetry.patch` fixes SMU
telemetry on 8-core layouts (auto-detects core count, 8-core hybrid
metrics table, `cs_eight_core_map` override, live GFXCLK query). It does
**not** unlock cores - it makes the driver report correctly once the SMU
mask is set. Kept in sync here as `kernel-patches/0005-*.patch`
(reference copy; authoritative source is the GabriWar repo).

## Status on our board (2026-09-16)

- Mask reads `0xFF` (UNLOCKED) but the running kernel still sees 6 cores /
  12 threads: firmware has not re-enumerated yet (warm reboot pending).
- r1 kernel + ROCm stack validation (torch, llama, GEMM gates) was all
  done in this 6-core-visible state. Do the 8-core warm reboot + re-gate
  before claiming 8-core validation.

Refs: `elektricM/amd-bc250-docs` → System → 8 Core CPU Unlock;
`Forbidden-Darkness/AMD-BC-250-UEFI-v2.2-Firmware-Menu-Script`;
`mendesrr/bc250-acpi-fix-updated-8c`; `bc250-collective/bc250-acpi-fix`.
