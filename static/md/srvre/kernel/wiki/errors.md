---
title: "Errors - SRVRE Kernel Wiki"
date: "Thu Aug 1 2024"
---

Most system calls return an error union, meaning that `a0`
holds the return value (or a potentially undefined value if there was an error)
while `a1` holds the error code.

Error codes give information about whether the return value
is safe to use, and how or why an operation failed.

If the error code is set to zero, the operation was successful.

On its own, an error code is not useful. The codes assigned to various errors
are not stable across source code changes due to the internal use of Zig's
`@intFromError` builtin function. The only way to receive meaningful
information about an error code is to pass it to the kernel.
Currently the only way to do this is the
[errorName](/md/srvre/kernel/wiki/syscalls.md#errorname-100000) system call
which writes the textual representation of the error to a user-provided buffer
by using `@errorName`. This string can be matched against or printed to the
user.

Errors that originate in a U-mode process are not forwarded by the kernel.
Such information must be transferred in-band using the message passing protocol
of the process.

The following table lists all technical error names (not including Zig standard
library errors) and user-friendly descriptions as well as troubleshooting tips.

| Error                         | Description |
| :---------------------------- | :---------- |
| HartIdOutOfRange              | A hart started with an ID that doesn't fit in an unsigned 16-bit integer. This most likely is a kernel or firmware bug. |
| NoCpusHwInfo                  | The embedded hardware information file does not contain CPU information. Verify that you are building for a valid platform with the correct `.hwi` file and that it is not corrupted. All platforms should have this device. |
| EmptySchedule                 | No processes are scheduled. Since the only option for recovery is a U-mode reboot the kernel panics to notify the user of the incident. This error occurs if all processes are terminated. |
| TooManyThreads                | A process has reached its maximum number of threads and cannot be extended by a new one. This shouldn't be a problem in the real world since thread IDs are of type `usize` which yields a limit of 2⁶⁴ threads per process. |
| TooSmall                      | The binary is smaller than the ELF header size and cannot be executed. Ensure that you are starting a valid ELF file and that it is not corrupted. |
| BadEndian                     | The binary uses a byte order other than the native endianness of the architecture (little endian for riscv64) and cannot be executed. Recompile it for little endian if possible. |
| BadArch                       | The binary was compiled for an unsupported architecture (anything other than RISC-V) and cannot be executed. Recompile it for RISC-V if possible. |
| BadBitLen                     | The binary was compiled for a bit length other than 64-bit and cannot be executed. Recompile it for 64-bit if possible. |
| NotStaticExe                  | The binary is not a statically linked executable and cannot be executed. Link statically if possible. |
| LengthOutOfBounds             | The `filesz` or `memsz` field of an ELF Program Header exceeds the file size or the allocated memory size. The binary is likely malicious and cannot be executed. |
| ReservedMemMapping            | The `vaddr` field of an ELF Program Header overlaps with critical kernel memory. The binary cannot be executed. Support for this may be added in the future. |
| BranchPerms                   | The binary wants certain memory regions to be loaded without any permission bits set. Since RISC-V treats such entries as page table branches this is forbidden and the binary cannot be executed. This shouldn't happen unless you are manually controlling the linking procedure with a linker script that is flawed. |
| WritableCode                  | The binary wants certain memory regions to be loaded with both the "write" and "execute" permission bits set. Modifiable code is a security risk and the binary cannot be executed. Check your compiler/linker settings for the affected program if possible, and make sure to use an up-to-date compiler. |
| ZeroSize                      | The page allocator was invoked with an allocation size of 0. This can currently only be caused by kernel bugs, but processes will gain the ability to allocate heap memory in the future. |
| OutOfMemory                   | The kernel is out of memory and cannot fulfill the allocation request. In-kernel allocations may be hidden from the affected process. Free up memory (e.g. by terminating processes) or upgrade your hardware to fix this. |
| AlreadyTaken                  | A memory page is already marked as taken and cannot be claimed by another call. This error indicates a bug in the page allocator. |
| NotALeaf                      | An attempt was made to map a memory page with the permissions of a page table branch (no permission bits set). This is similar to the `branch_perms` error but isn't caught early. *These errors will be merged in the future.* |
| InterruptOutOfRange           | An attempt to configure or complete an external interrupt with ID 0 was made. This hints at a kernel bug. |
| ContextOutOfRange             | An attempt to interact with an external interrupt context with an ID greater than or equal to 15872 was made. This hints at a kernel bug. |
| ZeroAddressSupplied           | A memory address of zero was passed as a system call parameter that does not support it. The operation was aborted to prevent a kernel panic from casting it to a non-allowzero pointer (required by most internal kernel functions). This is most likely an application bug. |
| OutOfRange                    | A parameter exceeds its maximum allowed bit size (e.g. u16 for process IDs). This hints at an application bug. |
| UnknownSyscall                | A [system call](/md/srvre/kernel/wiki/syscalls.md) with the specified number does not exist. This is a bug or version mismatch in the affected program or the library it uses to issue system calls. |
| ProcessNotFound               | A process with the specified ID could not be found. |
| Failed                        | The SBI (firmware) returned with a general failure status. |
| NotSupported                  | The SBI (firmware) doesn't support the requested feature. This shouln't occur in U-mode programs. Try updating the SBI. |
| InvalidParam                  | The SBI (firmware) got invalid parameters. This is a kernel bug. |
| Denied                        | The kernel was denied from performing an SBI (firmware) operation. This most likely is a kernel bug. |
| InvalidAddr                   | An invalid memory address was passed to the SBI (firmware). Keep in mind that paging is never active in M-mode so any translations *must* be performed by the kernel beforehand. This most likely is a kernel bug but may sometimes be the result of an unchecked access to user memory by the firmware (which is also a kernel bug). |
| AlreadyAvail                  | The SBI (firmware) returned because something is already available. This most likely is a kernel bug. |
| AlreadyStarted                | The SBI (firmware) reported that something (e.g. a hart) is already started. This most likely is a kernel bug. |
| AlreadyStopped                | The SBI (firmware) reported that something (e.g. a hart) is already stopped. This most likely is a kernel bug. |
| NoSharedMem                   | Shared memory is not available, preventing the SBI (firmware) from performing an operation. |
| InvalidState                  | The SBI (firmware) reported that an operation cannot be performed in the current state. |
| BadRange                      | An invalid range was passed to the SBI (firmware), preventing it from performing an operation. |
| SbiUnknown                    | The SBI (firmware) returned with an unknown status. This may be an (unknown) implementation-specific error. |
| MissingKind                   | The device kind (first column) of a hardware information (text format) device is missing. This error can only be raised by the `hwi` tool because the kernel doesn't process the text format. |
| MissingRegAddr                | The MMIO base address (second column) of a hardware information (text format) device is missing. This error can only be raised by the `hwi` tool because the kernel doesn't process the text format. |
| MissingRegLen                 | The MMIO region size (third column) of a hardware information (text format) device is missing. This error can only be raised by the `hwi` tool because the kernel doesn't process the text format. |
| UnknownDevKind                | The device kind (first column) of a hardware information (text format) device is invalid. This error can only be raised by the `hwi` tool because the kernel doesn't process the text format. See the [hardware information documentation](/md/srvre/kernel/wiki/hwi.md) for details. |
| NotJoined                     | The message passing operation requires the caller to be a member of the specified channel, but it is not. |
| WouldBlock                    | The message receiving operation failed because there are no messages to be read. The caller may continuously attempt the operation until a message arrives. |

[Return to Wiki Main Page](/md/srvre/kernel/wiki.md)

[Return to Index Page](/md/index.md)
