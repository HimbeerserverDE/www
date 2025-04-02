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

Scheduled downtime: Network transition
======================================

I am switching to a new network provider that does not offer static addressing.
All publicly reachable hosts will become unreachable over the course of April
14th, 2025 and are not going to be restored until at least April 18th, 2025. A
request for my own PI (provider-independent) IPv6 space is in progress but
unlikely to complete in time. There may be intermittent outages until the
transition to the new address space has been completed, and IPv4 support is
going to be added in the process. Interlinks to [dn42](https://dn42.eu) are
also planned. If you are interested in peering, please [contact
me](/md/contact.md).

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
