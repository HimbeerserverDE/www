---
title: "Message passing - SRVRE Kernel Wiki"
date: "Thu Aug 1 2024"
---

Message passing is the most basic mechanism for inter-process communication,
mainly between drivers and their dependants.

Channels
========

All messages are transferred over channels which logically separate their data
flows and destinations. Channels deliver messages to all subscribed processes
(even if another process has already handled a message other processes will
still receive it), but there is no guarantee that a process actually listens
for and handles them and no retransmissions even if there are no channel
members, so senders expecting a response should implement a timeout. This
approach was chosen over an explicit error because the caller will have to wait
before retrying anyway. Messages are only truncated on the receiving end, and
only if the buffer the message is read into is insufficiently sized. Senders do
not have to join the channels they transmit on. The ordering of transmitted
messages is preserved, though they may be interspersed with messages from other
senders or other threads of the sender process.

Messages can be passed on a channel using the
[pass](/md/srvre/kernel/wiki/syscalls.md#join-100010) [system
call](/md/srvre/kernel/wiki/syscalls.md), optionally specifying a single
receiver process by ID if broadcasting is not the desired behavior. The sender
may choose to expose its process ID to enable the receiver to send a unicast
response.

Messages can be received asynchronously using the
[receive](/md/srvre/kernel/wiki/syscalls.md#receive-100011) [system
call](/md/srvre/kernel/wiki/syscalls.md), optionally retrieving the ID of the
sender process or zero if the sender is anonymous. The sender process ID is trustworthy and can be used for security purposes.

Channels can be joined using the
[join](/md/srvre/kernel/wiki/syscalls.md#join-100008) [system
call](/md/srvre/kernel/wiki/syscalls.md) and left using
[leave](/md/srvre/kernel/wiki/syscalls.md#leave-100009).
