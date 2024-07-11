---
title: "Errors - SRVRE Kernel Wiki"
date: "Thu Jul 11 2024"
---

Most system calls return a `Result`, meaning that `a0`
holds the return value (or an undefined value if there was an error)
while `a1` holds the status code.

Status codes give information about whether the return value
is safe to use, what its meaning is and how or why an operation failed.

Driver callbacks often return a `Result` to the calling process.
The caller cannot determine whether the source of an error
is the kernel or a U-mode driver.

The following table lists all status codes, their technical names
and user-friendly descriptions as well as some troubleshooting tips.

| Status Code | Name                             | Error Variant                 | Description |
| ----------: | :------------------------------- | :---------------------------- | :---------- |
|           0 | success                          | N/A                           | The operation completed successfully, see its documentation for return value semantics. |
|           1 | hart_id_out_of_range             | HartIdOutOfRange              | A hart started with an ID that doesn't fit in an unsigned 16-bit integer. This most likely is a kernel or firmware bug. |
|           2 | no_cpus_hw_info                  | NoCpusHwInfo                  | The embedded hardware information file does not contain CPU information. Verify that you are building for a valid platform with the correct `.hwi` file and that it is not corrupted. All platforms should have this device. |
|           3 | no_tar_file_initializer          | NoTarFileInitializer          | The kernel is unable to open a [userinit](/md/srvre/kernel/wiki/userinit.md) member file because the `open` callback did not receive the initializer (file (meta)data) configured when providing the [VFS resource](/md/srvre/kernel/wiki/vfs.md#resources). This error should never occur and indicates a kernel bug. |
|           4 | no_console                       | NoConsole                     | The kernel is unable to write to the debug console because it failed to locate one. This error only applies to the `/io/debug` resource and should not occur if the kernel has booted far enough to start a process unless there is a firmware issue or limitation. |
|           5 | empty_schedule                   | EmptySchedule                 | No processes are scheduled. Since the only option for recovery is a U-mode reboot the kernel panics to notify the user of the incident. This error occurs if all processes are terminated. |
|           6 | no_init                          | NoInit                        | The [userinit](/md/srvre/kernel/wiki/userinit.md) does not contain an `init` file in its *root directory*. Therefore the kernel is unable to locate the init system and cannot continue, resulting in a panic. Follow the [instructions](https://git.himbeerserver.de/srvre/kernel.git/about/#create-a-userinit) *precisely* to create a [userinit](/md/srvre/kernel/wiki/userinit.md) that does contain an init system at the correct path.
|           7 | too_many_threads                 | TooManyThreads                | A process has reached its maximum number of threads and cannot be extended by a new one. This can happen to processes trying to create a new thread within themselves, but it can also be the result of calling into a driver that has reached this limit. This shouldn't be a problem in the real world since thread IDs are of type `usize` which yields a limit of 2⁶⁴ threads per process. |
|           8 | too_many_resource_descriptors    | TooManyResourceDescriptors    | The calling process has reached its maximum number of resource descriptor handles (2⁶⁴ - 1) and cannot open more resources. This shouldn't be a problem in the real world and can be solved by closing handles that are no longer needed. |
|           9 | bad_rd_handle                    | BadRdHandle                   | The resource descriptor handle is invalid, meaning that it doesn't refer to an open resource. This can happen if errors aren't handled (correctly) or when trying to use the return value of a [hook resource](/md/srvre/kernel/wiki/vfs.md#hook). This error hints at a bug in the caller. |
|          10 | bad_endian                       | BadEndian                     | The binary uses a byte order other than the native endianness of the architecture (little endian for riscv64) and cannot be executed. Recompile it for little endian if possible. |
|          11 | bad_arch                         | BadArch                       | The binary was compiled for an unsupported architecture (anything other than RISC-V) and cannot be executed. Recompile it for RISC-V if possible. |
|          12 | bad_bit_len                      | BadBitLen                     | The binary was compiled for a bit length other than 64-bit and cannot be executed. Recompile it for 64-bit if possible. |
|          13 | not_static_exe                   | NotStaticExe                  | The binary is not a statically linked executable and cannot be executed. Link statically if possible. |
|          14 | size_mismatch                    | SizeMismatch                  | *Cannot occur and will be removed.* |
|          15 | mem_overrun                      | MemOverrun                    | The `filesz` or `memsz` field of an ELF Program Header exceeds the file size or the allocated memory size. The binary is likely malicious. |
|          16 | branch_perms                     | BranchPerms                   | The binary wants certain memory regions to be loaded without any permission bits set. Since RISC-V treats such entries as page table branches this is forbidden and the binary cannot be executed. This shouldn't happen unless you are manually controlling the linking procedure with a linker script that is flawed. |
|          17 | zero_size                        | ZeroSize                      | The page allocator was invoked with an allocation size of 0. This can currently only be caused by kernel bugs, but processes will gain the ability to allocate heap memory in the future. |
|          18 | out_of_memory                    | OutOfMemory                   | The kernel is out of memory and cannot fulfill the allocation request. In-kernel allocations may be hidden from the affected process. Free up memory (e.g. by terminating processes) or upgrade your hardware to fix this. |
|          19 | out_of_range                     | OutOfRange                    | *Cannot occur and will be removed.* |
|          20 | double_free                      | DoubleFree                    | *Cannot occur and will be removed.* |
|          21 | already_taken                    | AlreadyTaken                  | A memory page is already marked as taken and cannot be claimed by another call. This error indicates a bug in the page allocator. |
|          22 | not_a_leaf                       | NotALeaf                      | An attempt was made to map a memory page with the permissions of a page table branch (no permission bits set). This is similar to the `branch_perms` error but isn't caught early. *These errors will be merged in the future.* |
|          23 | no_plic                          | NoPlic                        | *Cannot occur and will be removed.* |
|          24 | plic_incompatible                | PlicIncompatible              | *Cannot occur and will be removed.* |
|          25 | no_plic_reg                      | NoPlicReg                     | *Cannot occur and will be removed.* |
|          26 | interrupt_out_of_range           | InterruptOutOfRange           | An attempt to configure or complete an external interrupt with ID 0 was made. This hints at a kernel or driver bug. |
|          27 | context_out_of_range             | ContextOutOfRange             | An attempt to interact with an external interrupt context with an ID greater than or equal to 15872 was made. This hints at a kernel or driver bug. |
|          28 | unimplemented                    | Unimplemented                 | The requested feature is unimplemented in this version and cannot be used. This hints at a bug or version mismatch in the affected program. *Currently cannot occur.* |
|          29 | unknown_syscall                  | UnknownSyscall                | A [system call](/md/srvre/kernel/wiki/syscalls.md) with the specified number does not exist. This is a bug or version mismatch in the affected program or the library it uses to issue system calls. |
|          30 | no_pci_controller                | NoPciController               | There is no PCI(e) controller on the current platform according to the embedded hardware information file. *This error is likely going to be replaced with an optional in the future.* |
|          31 | sbi_failed                       | Failed                        | The SBI (firmware) returned with a general failure status. |
|          32 | sbi_not_supported                | NotSupported                  | The SBI (firmware) doesn't support the requested feature. This shouln't occur in U-mode programs. Try updating the SBI. |
|          33 | sbi_invalid_param                | InvalidParam                  | The SBI (firmware) got invalid parameters. This is a kernel bug. |
|          34 | sbi_denied                       | Denied                        | The kernel was denied from performing an SBI (firmware) operation. This most likely is a kernel bug. |
|          35 | sbi_invalid_addr                 | InvalidAddr                   | An invalid memory address was passed to the SBI (firmware). Keep in mind that paging is never active in M-mode so any translations *must* be performed by the kernel beforehand. This most likely is a kernel bug but may sometimes be the result of an unchecked access to user memory by the firmware (which is also a kernel bug). |
|          36 | sbi_already_avail                | AlreadyAvail                  | The SBI (firmware) returned because something is already available. This most likely is a kernel bug. |
|          37 | sbi_already_started              | AlreadyStarted                | The SBI (firmware) reported that something (e.g. a hart) is already started. This most likely is a kernel bug. |
|          38 | sbi_already_stopped              | AlreadyStopped                | The SBI (firmware) reported that something (e.g. a hart) is already stopped. This most likely is a kernel bug. |
|          39 | sbi_no_shared_memory             | NoSharedMem                   | Shared memory is not available, preventing the SBI (firmware) from performing an operation. |
|          40 | sbi_unknown                      | Unknown                       | The SBI (firmware) returned with an unknown status. This may be an implementation-specific error. |
|          41 | hwi_missing_kind                 | MissingKind                   | The device kind (first column) of a hardware information (text format) device is missing. This error can only be raised by the `hwi` tool because the kernel doesn't process the text format. |
|          42 | hwi_missing_reg_addr             | MissingRegAddr                | The MMIO base address (second column) of a hardware information (text format) device is missing. This error can only be raised by the `hwi` tool because the kernel doesn't process the text format. |
|          43 | hwi_missing_reg_len              | MissingRegLen                 | The MMIO region size (third column) of a hardware information (text format) device is missing. This error can only be raised by the `hwi` tool because the kernel doesn't process the text format. |
|          44 | hwi_unknown_dev_kind             | UnknownDevKind                | The device kind (first column) of a hardware information (text format) device is invalid. This error can only be raised by the `hwi` tool because the kernel doesn't process the text format. See the [hardware information documentation](/md/srvre/kernel/wiki/hwi.md) for details. |
|          45 | not_found                        | NotFound                      | The resource at the specified path could not be found. In most cases the underlying issue originates in U-mode. |
|          46 | relative_path_not_allowed        | RelativePathNotAllowed        | A relative path was passed to an operation that cannot process it. *The concept of relative paths and working directories may be introduced in the future, but this needs further planning.* |
|          47 | not_a_directory                  | NotADirectory                 | An attempt was made to access a non-directory resource as a directory. Directory hooks count as directories for this error description. |
|          48 | no_absolute_containing_directory | NoAbsoluteContainingDirectory | A relative or root path was passed to an operation that requires an absolute path where the last component is contained within a directory (or directory hook). Try canonicalizing the path manually before passing it to the kernel. |
|          49 | too_many_references              | TooManyReferences             | An inode has reached the maximum number of resource descriptors referencing it (2⁶⁴) and cannot be opened anymore. Close existing resource descriptors to it to fix this. This shouldn't be a problem in the real world. |
|          50 | read_not_supported               | ReadNotSupported              | The resource pointed to by a resource descriptor handle does not support reading despite read access being permitted for the calling process. This is likely an issue with the affected program (specifically its error handling) or a version mismatch between it and the driver/kernel. |
|          51 | write_not_supported              | WriteNotSupported             | The resource pointed to by a resource descriptor handle does not support writing despite write access being permitted for the calling process. This is likely an issue with the affected program (specifically its error handling) or a version mismatch between it and the driver/kernel. |
|          52 | in_use                           | InUse                         | An inode cannot be modified or removed because it is currently referenced by at least one resource descriptor. Close all resource descriptors to it and try again. |
| 2⁶⁴ - 1 = 18446744073709551615 | unknown                 | Unknown                       | An error that isn't listed above occured (e.g. a Zig standard library error). |
