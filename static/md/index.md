---
title: Himbeer's website
---

This is my personal website I use to publish my projects,
[guides](/md/guides.md), [contact info](/md/contact.md) and more.

Notable projects include a [reverse proxy for Minetest](/md/mt/proxy.md), the
[rustkrazy](/md/rustkrazy.md) appliance platform and a [dyndns
client](https://git.himbeerserver.de/dyndns-rs.git/about) for INWX with
reasonable IPv6 prefix updating.

Most of my current efforts are directed towards the [SRVRE Operating
System](/md/srvre.md) and a private systems programming language (public
release planned).

A curated archive of the first version of this website is available. See
[Archive](#archive) for more information.

Reduced availability
====================

My first semester at university is starting. Because of this my public activity
is going to change in the following ways:

* Longer response times to bug reports and feature requests
* Less (and less frequent) work on all projects
* Focus on personal projects, temporarily moving most repos to maintenance mode
* No more work on rsdsl for reliability reasons
* Difficulty resolving server issues remotely

*Be warned that this website may disappear at any time if I lose remote access
to it. I am prepared to restore it to a different server if I find a suitable
hosting solution. It will eventually come back, even if it takes several
years.*

*Most methods of contacting me rely on this server. If you don't get a response
or if the server is unavailable, please resort to using the contact email
address. PGP encryption is encouraged.*

The university network has IPv6 and seemingly allows inbound traffic, enabling
access to this server. However I do not have internet in my apartment (mainly
for economic reasons) and the cellular connection does not support IPv6. There
is a student association that offers free, low-end VPSes with dual stack
connectivity so it may be possible to build a tunnel.

Since I'm going without home internet for the coming months I'm only going to
be reachable while I'm on university grounds. I'm going to shift large file
transfers (system updates, VM images, backups, ...) into these periods, but I
will only be able to work offline (with pre-downloaded assets if possible) for
a significant part of my spare time and use on-demand dialing on the cellular
connection, breaking instant messaging. Expect delays of at least 2 days even
for trivial changes.

The server is going to get a fiber connection over the course of the next three
years. This involves switching do a different ISP in April 2025. Unfortunately
an employee told me that the PPPoE session gets disconnected every 24 hours and
a new IPv6 prefix is assigned every time. Not only is this expensive to
implement and disruptive, but it also means that dynamic DNS is now a strict
necessity. Until now it was only needed because the DSL connection drops every
two weeks (not intentionally, it is physically unreliable), but this change
means that everything is going to go unreachable after just a few hours if it
fails. Because of this I'm opposed to switching ISPs remotely and will most
likely have to visit.

If the server goes down, I'm most likely not going to be able to restore it
remotely and it may be several months before I can fix it in person. If this
happens I might move to a university-provided VPS. This has inspired me to
create a chat application that makes use of (dynamic) DNS for peer-to-peer
connectivity.  I actually have a peer-to-peer command-line chat application
already but it uses a central server to handle address exchange and isn't
suitable for everyday use.

Services / Quick Links
======================

All of these services are only available via IPv6.
See [this post](/md/ipv6.md) for why I'm doing this and why you should
enable or even force it on your own servers too.

* [Guides](/md/guides.md)
* [Git](https://git.himbeerserver.de)
* XMPP (TCP ports 5222 + 5223)
* Matrix (HTTPS/TCP port 443)

* [mt-multiserver-proxy](/md/mt/proxy.md)
* [mt-multiserver-chatcommands](/md/mt/proxy.md#commands)
* [rustkrazy](/md/rustkrazy.md)
* [rsdsl](/md/rsdsl.md)
* [SRVRE](/md/srvre.md)
* [SRVRE Kernel](/md/srvre/kernel.md)
* [SRVRE Kernel Wiki](/md/srvre/kernel/wiki.md)

Archive
=======

The following pages were deemed worthy of being republished. They were once
part of the very first version of this website. Most of its contents is
withheld, mostly for privacy reasons and because the server-side code is
dangerously bad. A full copy is kept on cold storage. Version 2 is likely
permanently gone, depending on whether access to old server backups is
successful. Check this page again in a few weeks or months if you're
interested.

All pages are in German. Links are generally broken and the source has been
adapted to work without PHP or logins. Additional links to return to this page
have been added.

*Warning: All pages require JavaScript for their functionality. They will
render correctly without it, but you won't be able to interact with them. The
amount is very small, so you can check it yourself in a matter of seconds if
you want to. Links to external pages also require JavaScript.*

* [Codeknacker](/v1/codeknacker.html): A simple 4-digit code cracking game.
  Binary search is possible. Codes are randomly generated.
* [Hau den Maulwurf](/v1/haudenmaulwurf.html): A poorly written version of
  whack-a-mole. You may also want to check out the superior
  [Elidragon counterpart](https://elidragon.io/projects/whack-a-mole/).
* [Stoppuhr](/v1/stoppuhr.html): A web stopwatch.
* [Timer](/v1/timer.html): A web timer. Uses server-side code for the alarm
  (disclosed on the page) and therefore won't work properly.
  [Alarm sound download](/v1/timervorbei.mp3)
  (**WARNING: Unknown source and license!**)
* [Würfel](/v1/wuerfel.html): A bad implementation of rolling dice on the web.
* [Zeichenprogramm](/v1/zeichenprogramm.html): A coordinate-based web drawing
  program using HTML canvas. One of the first pages ever published. Taken from
  a school lesson with minor changes to the UI (e.g. separating action
  submission and drawing buttons).

More websites you might be interested in
========================================

* [anon5's GitHub](https://github.com/anon55555)
* [Riley](https://dasriley.de) (formerly DerZombiiie)
* [j45](https://j45.dev)
* [Lizzy Fleckenstein](https://lizzy.rs)
* [Elidragon](https://elidragon.io)
* [Michael Stapelberg](https://michael.stapelberg.ch) (distri, gokrazy, i3)
