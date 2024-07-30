---
title: "Syscalls - SRVRE Kernel Wiki"
date: "Wed Jun 19 2024"
---

System calls are the most fundamental interface between processes
and the kernel. They provide access to kernel APIs such as
[message passing](/md/srvre/kernel/wiki/msgpass.md).

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
|   x10    |      a0       | Return value    |
|   x11    |      a1       | Error code      |

The operation was successful if and only if the error code is zero.
Any other value indicates an [error](/md/srvre/kernel/wiki/errors.md).
Error codes are not stable across source code changes due to the use of Zig's
`@intFromError` cast. You may however pass such an error code to
[errorName](#errorname-100000) to retrieve its name.

List
====

The following syscalls are currently available.
Detailed descriptions follow after the summary table.

| Number | Name                                 |
| :----: | :----------------------------------- |
| 100000 | [errorName](#errorname-100000)       |
| 100001 | [consoleWrite](#consoleWrite-100001) |
| 100002 | [launch](#launch-100002)             |
| 100003 | [end](#end-100003)                   |
| 100004 | [terminate](#terminate-100004)       |
| 100005 | [processId](#processid-100005)       |
| 100006 | [threadId](#threadid-100006)         |

errorName (#100000)
-------------------

Signature:
```
errorName(code: u16, buffer: [*]u8, len: usize) !usize
```

Possible errors:
```
ZeroAddressSupplied
ErrorCodeOutOfRange
```

Writes the name matching an error code to a buffer.
If the name exceeds the length of the buffer the remaining bytes are truncated.

An error code of zero (success) will result in an empty string.

* `code` is the error code to get the name of
* `buffer` is a pointer to the output buffer
* `len` is the length of the buffer in bytes

consoleWrite (#100001)
----------------

Signature:
```
consoleWrite(bytes: [*]const u8, len: usize) void
```

Writes the string at `bytes` directly to the debug console.

* `bytes` is a pointer to the string
* `len` is the length of the string in bytes

launch (#100002)
----------------

Signature:
```
launch(bytes: [*]align(@alignOf(std.elf.Elf64_Ehdr)) const u8, len: usize) !usize
```

Maps the provided ELF into memory and starts its entry point in a new process,
returning its ID.

The bytes need to have the same alignment as the ELF header (currently 8).

* `bytes` is a pointer to the ELF data
* `len` is the length of the ELF data in bytes

end (#100003)
-------------

Signature:
```
end() noreturn
```

Terminates the calling thread. If the calling thread is the main thread (ID 0)
of the calling process, the entire process is terminated.
This may change in the future.

terminate (#100004)
-------------------

Signature:
```
terminate(pid: u16, tid: usize) !void
```

Possible errors:
```
PidOutOfRange
ProcessNotFound
```

Terminates the specified thread. If the thread is the main thread (ID 0)
of the process, the entire process is terminated.
This may change in the future.

* `pid` is the ID of the process to apply the termination to
* `tid` is the ID of the thread to terminate within the process

processId (#100005)
-------------------

Signature:
```
processId() usize
```

Returns the ID of the calling process.

threadId (#100006)
------------------

Signature:
```
threadId() usize
```

Returns the ID of the calling thread within the calling process.

[Return to Wiki Main Page](/md/srvre/kernel/wiki.md)

[Return to Index Page](/md/index.md)
