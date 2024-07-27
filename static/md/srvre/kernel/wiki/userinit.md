---
title: "userinit - SRVRE Kernel Wiki"
date: "Wed Jun 19 2024"
---

The userinit is responsible for the transition to userspace
by providing essential drivers (such as potentially temporary disk drivers)
and bootstrapping programs (including the init system).
It is the last step of the
[startup procedure](/md/srvre/kernel/wiki/startup.md).

The kernel cannot be built if a userinit cannot be accessed at a predefined
path. This is because it is embedded into the kernel binary so that it can be
accessed without requiring any in-kernel drivers.

A userinit is an uncompressed `tar(1)` blob.
The kernel searches for an `init` executable at its root
(ignoring file permissions). This file is executed to hand over control
to userspace and is typically responsible for starting essential drivers,
accessing persistent storage and starting essential processes to allow
user login. It runs with full permission potential and no user identity.

See the repository [README.md](https://git.himbeerserver.de/srvre/kernel.git/about/#create-a-userinit)
for instructions on how to create a userinit.

[Return to Wiki Main Page](/md/srvre/kernel/wiki.md)

[Return to Index Page](/md/index.md)
