---
title: "Syscalls - SRVRE Kernel Wiki"
date: "Wed Jun 19 2024"
---

System calls are the most fundamental interface between processes
and the kernel. They provide access to kernel APIs such as the
[VFS](/md/srvre/kernel/wiki/vfs.md).

Calling convention
==================

A syscalls is invoked by executing the `ecall` instruction with the argument
registers set to the following values:

| Register | Friendly name | Meaning        |
| :------: | :-----------: | :------------- |
|   x10    |      a0       | Argument #0    |
|   x11    |      a1       | Argument #1    |
|   x12    |      a2       | Argument #2    |
|   x13    |      a3       | Argument #3    |
|   x14    |      a4       | Argument #4    |
|   x15    |      a5       | Argument #5    |
|   x16    |      a6       | Reserved       |
|   x17    |      a7       | Syscall number |

After the `ecall` instruction returns the results can be found in the following
registers:

| Register | Friendly name | Meaning         |
| :------: | :-----------: | :-------------- |
|   x10    |      a0       | Return value #0 |
|   x11    |      a1       | Return value #1 |

List
====

* TODO (none yet)

[Return to Wiki Main Page](/md/srvre/kernel/wiki.md)

[Return to Index Page](/md/index.md)
