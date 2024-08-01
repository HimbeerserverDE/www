---
title: "init - SRVRE Kernel Wiki"
date: "Thu Aug 1 2024"
---

The init executable is responsible for the transition to userspace
by starting essential drivers (such as disk drivers) and bootstrapping programs
(e.g. another init system or user login service).
It is launched as the last step of the
[startup procedure](/md/srvre/kernel/wiki/startup.md).

The executable is embedded in the kernel binary in order to alleviate the need
for in-kernel drivers, requiring a kernel rebuild to apply changes and making
compiling the kernel without it impossible (and pointless).

Further essential programs (including drivers) required by the init executable
can be embedded within it or loaded using an embedded storage (disk or network)
driver.

The kernel expects a statically linked ELF executable and starts it with PID 1
(PID 0 is a pseudo-ID used as the address space identifier (ASID) of kernel
memory).

Example programs are provided in the `examples/` directory.

[Return to Wiki Main Page](/md/srvre/kernel/wiki.md)

[Return to Index Page](/md/index.md)
