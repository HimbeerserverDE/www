---
title: "Startup - SRVRE Kernel Wiki"
date: "Thu Aug 1 2024"
---

When the kernel starts up on the boot hart it performs the following steps:

1. Initialize the SBI console
2. Enable all interrupts
3. Configure Sv39 paging
4. Configure the PLIC (Platform-Level Interrupt Controller) if present
6. Start the embedded [init executable](/md/srvre/kernel/wiki/init.md)

It is legal for the init process to terminate, but only if there is at least
one process left on the hart. This is likely to change in the future.

All other harts remain passive and do not execute S-mode (or U-mode) code.
This is going to change when SMP is implemented.

Any errors during system startup will result in a kernel panic.

[Return to Wiki Main Page](/md/srvre/kernel/wiki.md)

[Return to Index Page](/md/index.md)
