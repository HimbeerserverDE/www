---
title: "Syscalls - SRVRE Kernel Wiki"
date: "Thu Aug 1 2024"
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

| Number | Name                                   |
| :----: | :------------------------------------- |
| 100000 | [errorName](#errorname-100000)         |
| 100001 | [consoleWrite](#consoleWrite-100001)   |
| 100002 | [launch](#launch-100002)               |
| 100003 | [end](#end-100003)                     |
| 100004 | [terminate](#terminate-100004)         |
| 100005 | [processId](#processid-100005)         |
| 100006 | [threadId](#threadid-100006)           |
| 100007 | [devicesByKind](#devicesbykind-100007) |
| 100008 | [join](#join-100008)                   |
| 100009 | [leave](#leave-100009)                 |
| 100010 | [pass](#pass-100010)                   |
| 100011 | [receive](#receive-100011)             |

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
consoleWrite(bytes: [*]const u8, len: usize) !usize
```

Writes the provided `bytes` directly to the debug console,
returning how many bytes were written or an error.

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
processId() u16
```

Returns the ID of the calling process.

threadId (#100006)
------------------

Signature:
```
threadId() usize
```

Returns the ID of the calling thread within the calling process.

devicesByKind (#100007)
-----------------------

Signature:
```
devicesByKind(kind: hwinfo.DevKind, devices: [*]hwinfo.Dev, len: usize) !usize
```

Finds hardware devices of the specified kind and writes them to the provided
output array in the order they appear in the [HWI](/md/srvre/kernel/wiki/hwi.md)
blob, returning how many devices were found and written.

If the specified maximum length of the array is reached, no further matches
are searched for.

* `kind` is the device kind to filter for
* `devices` is the output array the matching devices are placed in
* `len` is the (maximum) length of the output array

join (#100008)
--------------

Signature:
```
join(channel: usize) !void
```

Joins the specified [message passing](/md/srvre/kernel/wiki/msgpass.md) channel
if permitted, allowing messages to be received. If the calling process is
already a member of the channel, this is a no-op.

See the message passing documentation for details.

* `channel` is the ID of the channel to join

leave (#100009)
---------------

Signature:
```
leave(channel: usize) void
```

Leaves the specified [message passing](/md/srvre/kernel/wiki/msgpass.md)
channel, preventing further messages from being received. If the calling
process is not a member of the channel, this is a no-op.

See the message passing documentation for details.

* `channel` is the ID of the channel to leave

pass (#100010)
--------------

Signature:
```
pass(channel: usize, receiver: u16, identify: bool, bytes: [*]const u8, len: usize) !void
```

Passes the provided bytes on the specified channel if permitted. If the
`receiver` argument is non-zero, only the process with the matching ID will
receive the message. Otherwise all channel members will receive the message.
By default the receiver(s) will see zero as the sender process ID. If desired
(e.g. for unicast responses), the `identify` argument may be set to true to
inform receivers of the real ID.  Guarantees that the message is not truncated
if the operation finishes successfully.

* `channel` is the ID of the channel to pass the message on
* `receiver` is the ID of the process to unicast the message to or zero for broadcast
* `identify` specifies whether to expose the calling process ID to the receiver(s)
* `bytes` is a pointer to the message payload
* `len` is the length of the message payload

receive (#100011)
-----------------

Signature:
```
receive(channel: usize, sender: ?*u16, buffer: [*]u8, len: usize) !usize
```

Writes the most recent message on the specified channel to the provided buffer
if permitted, returning the length of the message payload. The message is
truncated if the buffer is not large enough. If `sender` is non-null, the ID of
the sender process is written to the value it points to in order to enable
unicast responses. A value of zero indicates that the sender is anonymous. This
value is trustworthy. The operation fails if the calling process is not a
member of the channel (see [join](#join-100008)) or if there are no messages to
be read (`channel.Error.WouldBlock`). Guarantees that the message has not been
truncated if the operation finishes successfully and the buffer size was
sufficient.

* `channel` is the ID of the channel to receive the message from
* `sender` is an optional pointer used to provide the ID of the sender process to the caller
* `buffer` is a pointer to the output buffer for the message payload
* `len` is the length of the output buffer, limiting how many bytes of the message can be read

[Return to Wiki Main Page](/md/srvre/kernel/wiki.md)

[Return to Index Page](/md/index.md)
