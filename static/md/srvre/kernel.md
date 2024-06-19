---
title: SRVRE Kernel
---

The microkernel for the SRVRE riscv64 operating system.

Design Goals
============

This kernel aims to be as minimal as possible.
Resources (hardware I/O, configuration, process metadata and control,
file storage etc.) are provided via the file system whereever possible.
Security is achieved using an interactive permission system
that's inheritance-aware and only grants access to the sections of the code
that need it. Errors that are relevant for security are treated in a strict
way. The kernel only provides minimal low-level drivers for permanent hardware
such as PCI(e) or device tree items. Actual drivers run in U-mode and use
the file system to access and provide (I/O) resources under the supervision
of the aforementioned permission system. Namespacing is not planned
as the security architecture is designed to replace it.

Details are yet to be planned and implemented.

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

See the [wiki](/md/srvre/kernel/wiki.md).
It contains information on application development such as the various syscalls
and VFS APIs as well as usage information.

[Return to Index Page](/md/index.md)
