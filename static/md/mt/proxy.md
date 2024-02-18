---
title: Minetest reverse proxy - mt-multiserver-proxy
---

About
=====

mt-multiserver-proxy is a reverse proxy for the [Minetest](https://minetest.net) game engine
designed for linking multiple Minetest servers together.

This is Minetest's equivalent to projects like BungeeCord or Waterfall for Minecraft.
The proxy can be customized using plugins.

Use cases
=========

mt-multiserver-proxy can be used to build server networks. This makes it possible
to host multiple worlds on the same port or to implement load balancing
using future plugin API features.

Minetest doesn't take full advantage of multi-core CPUs
which is one of the reasons you may be interested in building networks of servers.

This proxy can also aid in implementing
[dimensions](https://github.com/minetest/minetest/issues/4428),
but this requires server-to-server communication of some form
(provided by the proxy or end-to-end).

Builtin alternatives
====================

While Minetest doesn't currently implement server hopping in the engine
there now are ambitions to add this functionality to the upstream project.

Relevant PRs:

* [Server hopping in the engine (#14129)](https://github.com/minetest/minetest/pull/14129)
* [Server-to-server messages (#14226)](https://github.com/minetest/minetest/pull/14226)

The latter would provide server-to-server messaging (for state synchronization like inventories)
without the need for HTTP-based APIs between servers or similar workarounds.

Merging these PRs would make this project obsolete for future Minetest versions.
This official solution is likely going to be more stable and simple.

Getting started
===============

The [README](https://git.himbeerserver.de/mt-multiserver-proxy.git/about/)
is a good place to start with to get into installation and configuration
of the proxy. Documentation on more specific topics is available
in the [doc/](https://git.himbeerserver.de/mt-multiserver-proxy.git/tree/doc) directory.

Minetest version support
========================

Generally the latest proxy version supports the latest stable Minetest version
regardless of the patch number.
See the [README](https://git.himbeerserver.de/mt-multiserver-proxy.git/about/)
for details including the commit hashes for support for old Minetest versions.

Development versions aren't supported and are highly likely to break
without the version mismatch being detected.

Authentication
==============

All authentication happens on the proxy. You can use Minetest databases
in the sqlite3 or postgres formats directly or convert them to the native `files` backend.
The latter has the advantage of being able to connect players to the server
they were previously playing on. Postgres has the advantage of being able to share
the database with other services.

See the [README](https://git.himbeerserver.de/mt-multiserver-proxy.git/about/)
and [documentation](https://git.himbeerserver.de/mt-multiserver-proxy.git/about/doc/auth_backends.md)
for details.

Docker
======

Running the proxy in Docker is supported,
see the [documentation](https://git.himbeerserver.de/mt-multiserver-proxy.git/about/doc/docker.md)
for details.

Minetest server configuration
=============================

You should enable **strict version checking** to ensure that version mismatches get detected
and result in a kick. This likely won't work with Minetest development builds.

The servers need to **allow empty passwords**.
**DO NOT expose them to the public internet!**
If you do, anyone can connect to them directly with any username, bypassing authentication.

Plugins
=======

The proxy supports [standard Go plugins](https://pkg.go.dev/plugin).
It is able to build them against the correct version of itself automatically,
though this is optional.
Consult the [documentation](https://git.himbeerserver.de/mt-multiserver-proxy.git/about/doc/plugins.md)
for further details.

The most notable plugin provides a few useful [chat commands](#commands)
and is the primary control interface for the proxy.
You may write your own if you want to do so.

Server groups
=============

Servers may be declared to be part of a larger group.
Some places like the `DefaultSrv` config option accept groups
in addition to regular servers. This makes load balancing possible
by choosing a random server that's in the group.

Groups cannot be used as fallback servers.

Commands
========

Chat commands are the main interface to the proxy and provided by an
[official plugin](https://git.himbeerserver.de/mt-multiserver-chatcommands.git/about/).
You may replace it if desired.

Chat commands don't use the `/` prefix character by default to prevent overlaps
with Minetest (mod) commands. The default prefix is `>`, but this can be configured
and multi-character prefixes are supported. Replace the leading `>` in the
[summary](#quick-summary) accordingly.

Permissions
-----------

All chat commands provided by the official plugin require individual permissions
to make fine-grained access control possible.
The permission for a command is `cmd_` followed by the command itself.
See the [documentation](https://git.himbeerserver.de/mt-multiserver-proxy.git/about/doc/permissions.md)
for details on how permissions work.

Quick summary
-------------

See the [plugin README](https://git.himbeerserver.de/mt-multiserver-chatcommands.git/about/)
for detailed documentation.

* Proxy shutdown: `>shutdown`
* Get a player's current server `>find <name>`
* Display a player's network address: `>addr <name>`
* Broadcast a message to all players on all servers: `>alert <message>`
* Send a player to a different server: `>send player <server> <name>`
* Send all players on your current server to a different one: `>send current <server>`
* Send all players to a different server: `>send all <server>`
* Send a player to a [server group](#server-groups): `>gsend player <group> <name>`
* Send all players on your current server to a [server group](#server-groups): `>gsend current <group>`
* Send all players to a [server group](#server-groups): `>gsend all <group>`
* Show the player lists of all servers: `>players`
* Reload the config (not recommended): `>reload`
* Get a player's (or your own) group: `>group [name]`
* Get a player's (or your own) permissions: `>perms [name]`
* Get a group's permissions: `>gperms <group>`
* Get your own group's permissions: `>perms`
* List current and remaining servers or switch to one: `>server [server]`
* List current and remaining [server groups](#server-groups) or switch to one: `>gserver [group]`
* Kick a player: `>kick <name> [reason]`
* Ban a player: `>ban <name>`
* Unban a player: `>unban <name | address>`
* Display proxy uptime: `>uptime`
* Show command description(s): `>help [command]`
* Show command usage(s): `>usage [command]`

[Return to Index Page](/md/index.md)
