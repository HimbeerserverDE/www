---
title: SRVRE Kernel
---

The microkernel for the SRVRE riscv64 operating system.

Design Goals
============

This kernel aims to be as minimal as possible.  Resources (hardware I/O,
configuration, file storage etc.) are controlled and provided by U-mode
processes using channel-based message passing.  Security is achieved using an
interactive permission system (mostly handled by U-mode with the kernel only
providing essential primitives) that's inheritance-aware. Errors that are
relevant for security are treated in a strict way. The kernel only provides
minimal low-level drivers for hardware I/O and critical hardware such as the
PLIC.  Actual drivers run in U-mode and use message passing to access and
provide (I/O) resources under the supervision of the aforementioned permission
system. Namespacing is not planned as the security architecture is designed to
replace it.

Repositories
============

Development happens on the following git repositories:

* [Codeberg](https://codeberg.org/Himbeer/srvre_kernel) (issue tracking)
* [HimbeerGit](https://git.himbeerserver.de/srvre/kernel.git/)

The usual [guidelines](/md/contact.md) for contribution
and issue submission apply.

Supported Platforms
===================

The kernel is being developed and tested for qemu-virt64 and the Lichee Pi 4A.
Contributions adding support (and documentation) for new platforms are welcome.

Quick Start
===========

See the repository
[README.md](https://git.himbeerserver.de/srvre/kernel.git/about/).

Documentation
=============

See the [wiki](/md/srvre/kernel/wiki.md). It contains information on
application development such as the various system calls and message passing
channels assignments and protocols as well as usage information.

[Return to Index Page](/md/index.md)
