# r2 notes (7.1.5-bc250rocm-r2, 2026-09-16)

Base: vanilla `linux-7.1.tar.xz` + `patch-7.1.5.xz` from kernel.org
(no Alpine aports patches; Alpine `main` has no `linux-stable` dir yet).

Config: Alpine `lts.x86_64.config` seed + `olddefconfig`, with
`CONFIG_LOCALVERSION="-bc250rocm-r2"` and
`# CONFIG_X86_DECODER_SELFTEST is not set` (the selftest host tool
`insn_sanity` misresolves `<asm/byteorder.h>` to stale
`linux-headers-7.0.0` on Alpine musl/gcc15; unrelated to BC250).

Patch port: `0000` (40CU) applied by hand (7.1 already includes
`<linux/module.h>` in `gfx_v10_0.c`); `0001`/`0002` apply clean;
`0003`/`0004` (runlist) apply clean. All `*_uses_kiq`, `execute_queues_cpsch`,
`KFD_SCHED_POLICY_NO_HWS`, KFD call sites confirmed present in 7.1.

Artifacts: `vmlinuz-7.1.5-bc250rocm-r2` (15,021,056 bytes),
`initramfs-7.1.5-bc250rocm-r2` (gzip, SDMA navi12 substitution inside),
`/lib/modules/7.1.5-bc250rocm-r2`, GRUB one-shot `bc250-rocm-r2-kernel`,
then promoted to `GRUB_DEFAULT=bc250-rocm-r2-kernel`.

Gates on r2: rocminfo gfx1013 GPU agent OK; torch smoke
(`cuda` True, `['gfx1013']`, GEMM OK); 50-step train bit-identical
(`1.029231 / 1.004733 / 0.985372`); llama gate OK
(95.8 t/s prompt, 40.6 t/s gen); SDMA 4 KiB-16 MiB sweep 6/6 OK
with `HSA_ENABLE_SDMA=1`. PPL corpus unavailable (no wikitext file on
board); reference stays `63.9747` from r1.
