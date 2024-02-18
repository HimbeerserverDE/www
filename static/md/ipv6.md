---
title: IPv6
---

This server is only reachable on the IPv6 internet. Historically I've had
access to a public IPv4 address for most of its lifetime, though I've never
actually used it. The purpose of this page is to explain why I'm doing it
this way and why you should adopt or force IPv6 too.

IPv4 could disappear at any time
================================

It is likely that my ISP is going to force DS-Lite (a form of carrier-grade NAT
over 4in6 tunnels) in the future. If I add IPv4 support now it is possible
for anyone (including myself) to become reliant on it and run into severe
availability problems when it is inevitably shut down. Forcing IPv6 access
makes compatibility the client's responsibility, ensuring that connections
that have been made once will never break.

IPv6 simplifies my network-level firewall ruleset
=================================================

Due to my firewall rules being hardcoded in the
[rsdsl_netfilterd](/md/rsdsl.md#netfilterd) application IPv6 firewalling
is much simpler than IPv4 firewalling. The reason for this is that I can
simply create a rule that accepts all IPv6 traffic to a certain VLAN.
The same rule exists for IPv4 but it requires explicit NAT forwardings
due to internal hosts not being globally addressable. This requires recompiling
for every change to the forwarding rules or unnecessarily complex changes
to the firewall program itself to dynamically load ruleset files
(the library I'm using doesn't implement flushing which makes the logic
a lot more complex and I don't see the need to implement any of this myself
since I can just decide not to support IPv4 at all).

IPv6 is slowly being adopted
============================

These days a significant portion of home internet connections support IPv6.
Depending on where you live even cellular networks may have started
to roll it out. IPv6 is available in many places that I go to
and if it isn't the cellular connection provides a workaround
for small amounts of data. The main categories that still lack IPv6 support
with nearly 100% certainty are public or enterprise networks.

Users that don't have IPv6 at home can sometimes ask for it to be enabled
as was the case with [my own connection](/md/guide/vf6.md) (DE).
If not it may be possible to switch to an ISP that does support it,
use a 6in4 tunnel like [HE's tunnelbroker.net](https://tunnelbroker.net)
or resort to an IPv6-capable proxy, VPN or Tor.

Many services can be hosted without IPv4
========================================

This applies to most (web-based) services (assuming they don't require
connections from IPv4-only third parties). It is perfectly possible
to host a website and git server with HTTPS, SSH and git protocol access
without IPv4.

Federated services usually work very well too, including Matrix,
though there may be issues with things like XMPP that require direct
connections between servers. If information can traverse multiple layer 7 hops
you will effectively always be able to exchange messages between IPv4-only and
IPv6-only servers.

As much as it'd like it to be it currently isn't possible to host email servers
without IPv4. I don't know of any email service that supports IPv6 (webmail
doesn't count, you need to be able to exchange messages with IPv6-only
servers) and my ISP doesn't support reverse DNS for it. In my opinion
email is the most difficult service to host and I hope it gets replaced
by a more mature technology one day.

Why you should enable IPv6 on your servers
==========================================

If your server (VPS or self-hosted) already has an IPv6 connection
or if it can be enabled (Try asking your ISP! It actually works sometimes!)
you should make it available for the following reasons.

To make this work, ensure that the appropriate firewall exceptions
are configured on your router / firewall. While it's true that IPv6
doesn't need NAT forwarding most home routers block incoming traffic
by default unless you create filter rules to allow it. This is often done
using the old port forwarding menu or a similar web UI tab.

Also make sure that your services are binding to IPv6 by using `::`
(or `[::]:PORT`) as the bind address. In most cases this won't disable IPv4
unless you explicitly tell the program to set the `IPV6_V6ONLY` socket option
which only a few programs support. Depending on its programming language
you can also try `*:PORT` if `::` does disable IPv4 support.

Finally you need to set up DNS AAAA records. AAAA records work exactly like
A records do, except you specify an IPv6 address instead of an IPv4 address.
You can have as many A and AAAA records for a single hostname as well as
mix the two record types as you want.

*You don't have to drop IPv4 support entirely if you're already exposing it
unless you want to set an extreme statement like me. However you should
definitely go dual-stack to improve experience and power of users that are
already using IPv6 (which is more common than you probably think and certainly
common enough to be relevant).*

Users without native IPv4
-------------------------

Many home connections are IPv6-only with IPv4 being provided via carrier-grade
NAT solutions like DS-Lite or NAT64. Allowing them to connect via IPv6
directly instead of forcing them to go through the CGNAT gateway
can offer a significant reliability and performance boost since those gateways
are often overloaded and congested. It also has other advantages
like not suffering from reduced MTU sizes in the case of tunnel-based CGNAT
(DS-Lite) or being able to use layer 4 protocols other than TCP and UDP
(e.g. SCTP) which the CGNAT gateways usually don't support.

IP-based blocking / bans
------------------------

The typical CGNAT setup puts about 60 users behind a single,
shared IPv4 address. Because of this you're likely to block or rate-limit
entire neighborhoods. It also reduces your ability to uniquely identify
networks for the purpose of authentication (requiring additional confirmation,
etc.; likely irrelevant for small, personal servers).

It is impossible to work around this without using IPv6. You cannot detect
the presence of CGNAT on a connection (at least there is no intended or
widespread method, but it is probably possible with a lot of trickery).

Since each IPv6 host has at least one public address, you need to apply
bans or rate limits to entire blocks. For full denylisting you'll probably
want to ban the associated /64 subnet. If you adjust your rate limits
you may apply them to /56 or /48 ranges, but I'd advise against taking it
any further than that.
[Let's Encrypt](https://letsencrypt.org/docs/rate-limits/) sets a good example,
though keep in mind they're mainly rate limiting server machines
which typically get larger allocations than home connections (though some
residential ISPs and transition technologies do provide /48 prefixes, including
[HE's tunnelbroker.net](https://tunnelbroker.net)).

Improving IPv6 adoption
-----------------------

Now that IPv6 deployment to home users has reached reasonable percentages
and is steadily progressing, it's time to worry about the server side.
Even a lot of popular websites don't support IPv6 at all with Google being
the only major company that fully implements it.
Just like with social / political issues someone has to start:
In order to use IPv6, other people must do so as well - including you.
By supporting IPv6 you're improving the experience for a substantial portion
of home users and allowing those who wish to go IPv6-only to do so.

Staying on IPv4 for as long as possible only benefits those who are privileged
enough to have a public IPv4 address, creating unfair competition.
Please don't contribute to that.

[Return to Index Page](/md/index.md)
