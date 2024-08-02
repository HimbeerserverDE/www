---
title: "Hardware information - SRVRE Kernel Wiki"
date: "Fri Aug 2 2024"
---

The HWI (Hardware Info) format is a replacement for device trees.  Its purpose
is to provide information about the underlying hardware in a way that is easier
and more robust to parse. It was created to remove the burden of frequent
debugging of device tree parsing mistakes.

Like device trees, HWI is divided into binary and text formats.

All supported hardware platforms have a HWI blob and corresponding text source
in the kernel source tree. When building the kernel, the binary blob of the
requested platform is embedded within it and read at runtime.

When porting the kernel to a new platform, the relevant information is typically extracted from its device tree manually and translated into the HWI text format by a human and converted to the binary format using the `hwi` tool.

Text format
===========

The text format is a line-separated list of entries. The lines are separated by
a single `\n` character.

Entry format
------------

Entry lines are formatted as follows:

```
<kind> <address> <size> [value]
```

* `kind`: The kind of device the entry describes. See the list below for supported values.
* `address`: The physical base address for memory-mapped I/O.
* `size`: The size of the memory-mapped I/O region.
* `value`: Optional additional (numeric) device-specific data. Defaults to zero.

Numeric values are represented as unsigned 64-bit integers and may be parsed
from non-decimal notations (prefix with "0b" for binary, "0o" for octal or "0x"
for hexadecimal).

The memory-mapped I/O fields are ignored for devices that do not support it and
should preferably be set to zero in such cases.

Device kinds
------------

* `cpus`: MMIO is not supported. `value` holds the timebase frequency (used for interrupt timers).
* `plic`: Platform-Level Interrupt Controller. MMIO is supported. `value` is ignored.
* `pcie`: ECAM PCI(e) controller. MMIO is supported. `value` is ignored.
* `pci`: CAM (legacy) PCI controller. MMIO is supported. `value` is ignored.

Binary format
=============

The binary format consists of several fixed-size entries preceeded by a single
byte indicating the byte order of the entry fields. Each entry is 32 bytes
long, so the number of entries is `(n - 1) / 32` where `n` is the total length
of the blob.

The endianness byte is zero for little endian and non-zero for big endian.

The entries are defined as extern structs and (de)serialized using Zig's
`writeStruct` and `readStructEndian` methods on writers and readers.

```
kind: enum(u32) { cpus, plic, pcie, pci, _ },
// 32 bits of alignment padding (due to being an extern struct)
reg.addr: u64,
reg.len: u64,
value: u64,
```

You can generally expect backward and forward compatiblity of the kernel
implementation including the semantics of features making use of hardware
information.

Conversion tool
===============

The `hwi` conversion tool reads the text format from stdin and writes the
resulting binary representation to stdout. See the
[README](https://git.himbeerserver.de/srvre/kernel.git/about/#translating-device-trees-to-the-hwi-hardware-info-format)
for instructions on how to build and use it.

[Return to Wiki Main Page](/md/srvre/kernel/wiki.md)

[Return to Index Page](/md/index.md)
