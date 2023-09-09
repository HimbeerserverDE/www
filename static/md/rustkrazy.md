---
title: The Rustkrazy Project
---

About
=====

Rustkrazy is heavily inspired by [Gokrazy](https://gokrazy.org).
It can turn your Rust programs into appliances.

Repositories
============

The repositories on [my own git server](https://git.himbeerserver.de/rustkrazy)
and on [GitHub](https://github.com/rustkrazy) are kept up-to-date.

Why
===

Just like Gokrazy this project can help with eliminating
the annoyances of administrating unsafe C software.
The simplicity of the system and reduction of components
to a bare minimum also makes maintenance and updating
much safer and easier.

Supported Platforms
===================

Officially supported and tested platforms:

* x86_64 (tested: QEMU)
* RPi 64-bit (tested: RPi 3B, RPi 4B)

How it works
============

A Rustkrazy image consists of 4 MBR partitions:

* /boot: 256 MiB FAT32 (LBA), contains kernel, cmdline, RPi config.txt, dtbs
and RPi firmware
* /: 256 MiB SquashFS, rootfs A, contains mountpoints, init and user-defined programs
* /: 256 MiB SquashFS, rootfs B, contains mountpoints, init and user-defined programs
* /data: remaining ext4, persistent writable data storage and config for the applications

The MBR is a simple x86 single-stage bootloader that directly accesses specific
sectors of the boot partition. Raspberry Pis use the firmware files instead.

The A/B partitioning scheme allows for a safe update mechanism to be implemented.

Usage
=====

Please refer to the respective repositories of the components
for their documentation. The image related executables have command-line help.

The packer is used to generate images from scratch.
The updater modifies an existing installation over the network.
Regular users won't have to interact with any of the other tools.

The /boot Partition
===================

Since we want a usable environment we need a kernel.
The Linux kernel is a good choice for this.
It resides on the boot partition of the image.
The `packer` and `updater` commands download pre-compiled binaries
from the `kernel` repository to save time.
The upstream Linux kernel from [kernel.org](https://kernel.org) is used.
It is booted with the parameters listed in `/boot/cmdline.txt`
regardless of the platform.
Depending on the platform it's either the MBR or the firmware files
that make booting it possible. On Raspberry Pis it additionally requires
the dtbs that are automatically added to the image.
This filesystem is writable by the running system.

Root A/B
========

There are two root partitions. Only one of them can be active at the same time.
New images use partition A as the active rootfs by default.
Updates using the new `admind` push the new binaries to the inactive root partition
and switch the system to it. This is applied by an automatic reboot.
If anything breaks you can simply switch back to the other partition
to use the old version of your software and overwrite the broken one with your fix.

This not only makes safe auto-updates possible. It makes them feasible.
The kernel and firmware are updated to the latest pre-compiled version in the process.

The / Partitions
================

They contain the mountpoints for other filesystems like /proc, /sys, /dev, /tmp
and /boot. Their /bin directory is home to the user-defined binaries and the init.

The /data Partition
===================

This is the perfect place for non-volatile storage of program information.
If a program cannot work without a configuration file this is where to put it.
It is never touched by system updates, but the different program versions
should be able to deal with their own file formats correctly.

Inits
=====

When building an image you need to specify an init.
For simple single-program images it is often enough to use the program
as the init unless you need access to (special) filesystems.
Otherwise you need a dedicated init. It is always moved to /bin/init
by the image generators. Rustkrazy offers its own
init system implementation but there is no default and you're free
to use whatever you want. The rustkrazy init takes care of mounting
any interesting filesystems not including external media
and restarts services as soon as they exit. It considers all files
in /bin excluding /bin/init (itself) a service.

Git crate names
===============

Cargo needs to know the exact names of the crates to install them.
With crate registries like crates.io this isn't a problem.
However there is no easy way to discover the crate name
from a git URL and it's possible for more than one to exist
per repository.
It is for this reason that the URLs may be succeeded by a percentage sign
and the actual crate name, e.g. `https://github.com/rustkrazy/init.git%rustkrazy_init`.
If omitted the image manipulation commands default to the repository name
which is "init" in our example.

Security
========

All processes on the system run as root by default.
For the time being please consider implementing your own account system
if you need more security.

admind
======

The admind provides an authenticated management API over HTTPS.
It can be used to remotely flash instances using the `updater` program.
It also adds support for remote rebooting, shutdown, switching root partitions,
manually flashing the block device or partitions, reading files and writing files.
Reading files is especially useful since the `rustkrazy_init`
writes program logs and stderr to `/tmp/SERVICE.log` and `/tmp/SERVICE.err`
respectively (separated for simplicity of code) where `SERVICE`
is the binary file name. This API allows you to remotely access the logs
if you need to.

[Return to Index Page](/md/index.md)
