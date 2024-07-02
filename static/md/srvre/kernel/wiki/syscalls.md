---
title: "Syscalls - SRVRE Kernel Wiki"
date: "Wed Jun 19 2024"
---

System calls are the most fundamental interface between processes
and the kernel. They provide access to kernel APIs such as the
[VFS](/md/srvre/kernel/wiki/vfs.md).

Calling convention
==================

A syscall is invoked by executing the `ecall` instruction with the argument
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

The following syscalls are currently available.
Detailed descriptions follow after the summary table.

| Number | Name           |
| :----: | :------------- |
| 100000 | uprint         |
| 100001 | open           |
| 100002 | close          |
| 100003 | provideStream  |
| 100004 | provideFile    |
| 100005 | provideHook    |
| 100006 | mkdir          |
| 100007 | provideDirHook |
| 100008 | remove         |
| 100009 | read           |
| 100010 | write          |

uprint (#100000)
----------------

Signature:
```
uprint(str_addr: usize, len: usize) void
```

**WARNING:** This system call will be removed in a future version.

Prints the string at `str_addr` to the debug console,
preceeded by "User message: " and succeeded by "\n".

* `str_addr` is the memory address of the first character of the string
* `len` is the length of the string in bytes

open (#100001)
--------------

Signature:
```
open(path_c: [*:0]const u8, data: usize) Result(usize)
```

Opens the resource at `path_c`, returning a handle to a descriptor
(or a driver-specific return value) or an error.
All but the last component of the path must already exist
and support holding sub-resources.

* `path_c` is a null-terminated POSIX path
* `data` is either passed to the driver or used to decide
how to open the resource (i.e. read-only, read-write, append etc.)

close (#100002)
---------------

Signature:
```
close(handle: usize) void
```

Closes the resource descriptor identified by `handle`.
This system call cannot fail, invalid handles are silently ignored.

* `handle` is a handle to a resource descriptor

provideStream (#100003)
-----------------------

Signature:
```
provideStream(
    path_c: [*:0]const u8,
    readFn: ?*const fn (buffer: []u8) Result(usize),
    writefn: ?*const fn (bytes: []const u8) Result(usize),
) Result(void)
```

Provides a [stream resource](/md/srvre/kernel/wiki/vfs.md#stream)
at `path_c`. This system call can fail. The callbacks are optional,
omitting them causes their respective operations to raise a
"\*NotSupported" error.
All but the last component of the path must already exist
and support holding sub-resources.

* `path_c` is a null-terminated POSIX path
* `readFn` is the callback to invoke when a process tries to read from the resource
* `writeFn` is the callback to invoke when a process tries to write to the resource

provideFile (#100004)
---------------------

Signature:
```
provideFile(
    path_c: [*:0]const u8,
    openFn: *allowzero const fn (pid: u16) Result(*anyopaque),
    readFn: ?*const fn (context: *anyopaque, buffer: []u8) Result(usize),
    writeFn: ?*const fn (context: *anyopaque, bytes: []const u8) Result(usize),
    closeFn: ?*const fn (context: *anyopaque) void,
) Result(void)
```

Provides a [file resource](/md/srvre/kernel/wiki/vfs.md#file)
at `path_c`. This system call can fail. All callbacks excluding `openFn`
are optional, omitting them causes their respective operations to raise a
"\*NotSupported" error with the exception of `close` which will still work
without invoking a custom callback.
All but the last component of the path must already exist
and support holding sub-resources.

* `path_c` is a null-terminated POSIX path
* `openFn` is the callback to invoke when a process tries to open the resource,
returning a pointer to a driver-specific context data structure which is passed
to the other callbacks but never exposed to any other processes by the kernel,
or an error; You may store the process ID in this context object if required
* `readFn` is the callback to invoke when a process tries to read from the resource
* `writeFn` is the callback to invoke when a process tries to write to the resource
* `closeFn` is the callback to invoke when a process closes the resource

provideHook (#100005)
---------------------

Signature:
```
provideHook(
    path_c: [*:0]const u8,
    callback: *allowzero const fn (pid: u16, data: usize) Result(usize),
) Result(void)
```

Provides a [hook resource](/md/srvre/kernel/wiki/vfs.md#hook)
at `path_c`. This system call can fail.
All but the last component of the path must already exist
and support holding sub-resources.

* `path_c` is a null-terminated POSIX path
* `callback` is the callback to invoke when a process tries to open the resource,
returning a driver-specific integer value or an error; This callback gets access
to the `data` parameter passed to the [open](#open) syscall by the process

mkdir (#100006)
---------------

Signature:
```
mkdir(path_c: [*:0]const u8, options: usize) Result(void)
```

**WARNING:** This system call is currently not implemented and will cause a kernel panic.
**WARNING:** The options will be removed before this version is released.

Creates a [directory](/md/srvre/kernel/wiki/vfs.md#directory)
at `path_c`. This system call can fail.
All but the last component of the path must already exist
and support holding sub-resources, unless the `full` option is set
which creates missing components as directories unless they already exist
as non-directory resources (which raises an error).

* `path_c` is a null-terminated POSIX path
* `options` is a bit field holding any combination of the following flags:
	* `full` (1): Create all required components as directories if possible (comparable to `mkdir -p` on Linux)

provideDirHook (#100007)
------------------------

Signature:
```
provideDirHook(
    path_c: [*:0]const u8,
    provideFn: *allowzero const fn (inode: Inode) Result(void),
    findFn: *allowzero const fn (name: []const u8) ?Inode,
    removeFn: *allowzero const fn (name: []const u8) Result(void),
) Result(void)
```

Creates a [directory hook](/md/srvre/kernel/wiki/vfs.md#directory-hook)
at `path_c`. This system call can fail.
All but the last component of the path must already exist
and support holding sub-resources.

* `path_c` is a null-terminated POSIX path
* `provideFn` is the callback to invoke when any "provide\*" syscall provides a direct sub-resource of this resource
* `findFn` is the callback to invoke to get a sub-resource by name if it exists
* `removeFn` is the callback to invoke when the [remove](#remove-100008) syscall removes a direct sub-resource of this resource

remove (#100008)
----------------

Signature:
```
remove(path_c: [*:0]const u8) Result(void)
```

**WARNING:** This system call is currently not implemented and will cause a kernel panic.

Removes a [resource](/md/srvre/kernel/wiki/vfs.md#resources)
from the [VFS](/md/srvre/kernel/wiki/vfs.md).

* `path_c` is a null-terminated POSIX path

read (#100009)
--------------

Signature:
```
read(handle: usize, buffer: [*]u8, len: usize) Result(usize)
```

Reads up to `len` bytes from the resource referenced by `handle` into `buffer`,
returning how many bytes were read or an error.
A return value of zero indicates that there is no more data to be read
or that `len` is zero.

* `handle` is a handle to a resource descriptor
* `buffer` is the buffer to read into
* `len` is the maximum number of bytes to read and **must not be larger than the length of the buffer to prevent buffer overflows**

write (#100010)
---------------

Signature:
```
write(handle: usize, bytes: [*]const u8, len: usize) Result(usize)
```

Writes up to `len` bytes from `bytes` to the resource referenced by `handle`,
returning how many bytes were written or an error.
A return value of zero indicates that `len` is zero.

* `handle` is a handle to a resource descriptor
* `bytes` is the buffer to write from
* `len` is the maximum number of bytes to write and **must not be larger than the length of the buffer to prevent buffer underflows**

[Return to Wiki Main Page](/md/srvre/kernel/wiki.md)

[Return to Index Page](/md/index.md)
