---
title: "VFS - SRVRE Kernel Wiki"
date: "Wed Jun 19 2024"
---

The VFS (Virtual File System) is the universal interface between processes
and resources. It is protected by the permission system.

Authorized processes have the ability to access or provide resources.

Resources
=========

A resource is a control or data interface in the file system.
Examples include process metadata and termination, files on storage media
and network protocols. They are uniquely identified by unique POSIX paths,
though it is possible to reuse the same implementation with multiple paths.
There are several different kinds of resources.

Stream
------

A stream is a shared byte stream that can be readable, writable,
both or none. The data will be distributed across all readers
in an unpredictable (but cryptographically insecure) fashion.
Writes can be interleaved. The combination of process authorization
and provider-side implementation decides which directions are available.

Example use cases: Random byte stream, infinite zeroes, null/void

File
----

A file is similar to a stream in that it provides a byte stream
that can be readable, writable, both or none. The main difference
is that the provider can tell the handles to it apart.

Example use cases: Stored files, network sockets, runtime configuration
and control options

Hook
----

A hook performs an action when opened. Resources of this kind
don't allocate a resource descriptor when opened, meaning that they can't
and never need to be closed. The provider can return any `usize` value instead.

Example use cases: Process termination, system shutdown, UNIX time retrieval

Directory
---------

A directory is a collection of resources and managed by the kernel.
Nesting is supported.

Example use cases: Grouping of runtime configuration and control options,
hardware devices, network protocols etc.

Directory hook
--------------

A directory hook functions like a regular directory, but is managed by
a U-mode provider instead of the kernel keeping track of the items
contained within.

Example use cases: Filesystem drivers, network protocols

Builtin resources
=================

The kernel provides the following builtin resources for providers
and other programs to build upon:

`/io`
-----

The `/io` directory provides interfaces for byte-grained, often text-based
communication with the environment the program is running in.

* `/io/debug`: Write-only access to the debug console, usually provided by the SBI (firmware)

`/userinit`
-----------

The `/userinit` directory provides read-only access to the
[userinit](/md/srvre/kernel/wiki/userinit.md) tree.
Its purpose is to make essential drivers and the data required to run them
to the init process.

* `/userinit/init`: The executable started as the init process. There is nothing special about it internally but it's noteworthy enough to be listed here explicitly.

`/process`
----------

The `/process` directory provides information about as well as control
interfaces to processes and threads, including the caller.

### `/process/self`

The `/process/self` subdirectory provides information about as well as control
interfaces to the calling process and thread.

* `/process/self/terminate`: A [hook](#hook) that terminates the current thread. The extra data is ignored. This is likely to be made more powerful in the future.
* `/process/self/id`: A [hook](#hook) that returns the ID of the current process. The extra data is ignored.
* `/process/self/thread_id`: A [hook](#hook) that returns the ID of the current thread within the current process. The extra data is ignored.

Interaction from U-mode
=======================

VFS resources are provided or accessed using
[system calls](/md/srvre/kernel/wiki/syscalls.md):

* [open](/md/srvre/kernel/wiki/syscalls.md#open-100001): Opens a resource, obtaining a resource descriptor handle.
* [close](/md/srvre/kernel/wiki/syscalls.md#close-100002): Closes a resource descriptor handle.
* [provideStream](/md/srvre/kernel/wiki/syscalls.md#providestream-100003): Provides a stream resource.
* [provideFile](/md/srvre/kernel/wiki/syscalls.md#providefile-100004): Provides a file resource.
* [provideHook](/md/srvre/kernel/wiki/syscalls.md#providehook-100005): Provides a hook resource.
* [mkdir](/md/srvre/kernel/wiki/syscalls.md#mkdir-100006): Creates a kernel-managed directory.
* [provideDirHook](/md/srvre/kernel/wiki/syscalls.md#providedirhook-100007): Provides a directory hook.
* [remove](/md/srvre/kernel/wiki/syscalls.md#remove-100008): Removes a resource from the VFS.
* [read](/md/srvre/kernel/wiki/syscalls.md#read-100009): Reads from a resource descriptor handle into a buffer.
* [write](/md/srvre/kernel/wiki/syscalls.md#write-100010): Writes to a resource descriptor handle from a buffer.

[Return to Wiki Main Page](/md/srvre/kernel/wiki.md)

[Return to Index Page](/md/index.md)
