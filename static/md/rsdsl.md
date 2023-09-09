---
title: The rsdsl Project
---

About
=====

The rsdsl project is a collection of Rust programs
that form a customized, yet simple router for Vodafone Germany DSL connections.
It is designed to run on [Rustkrazy](/md/rustkrazy.md).

Repositories
============

Up-to-date versions of all components and some common or forked libraries
can be found on [my own git server](https://git.himbeerserver.de/rsdsl)
or on [GitHub](https://github.com/rsdsl).

Platforms
=========

All Rustkrazy platforms should be supported,
but testing is currently limited to the Raspberry Pi 3B.

Why
===

You may wonder why one would rewrite an entire router
when there are existing solutions for it.
OpenWrt is one such option. I had been using it for months
without any major issues. However the majority of its components
are written in C, a memory unsafe programming language.
It is also quite complex for what it does.
On top of this writing custom protocol implementations is a lot of fun.

The network structure and ISP were about to change anyway.
This is why I decided to build rsdsl for the new network.

Hardware
========

The LAN side of the router is connected via its builtin Ethernet interface.
It is connected to a VLAN capable switch
and tagged VLAN (802.1q) is enabled on the port.

The WAN connection is done using a USB to Ethernet dongle
that connects to a dedicated DSL modem.
The modem takes care of tagging the packets with VLAN ID 7.

Operation diagram
=================

Here's the core concept of how the components work together.

```
+-------+    +------+       +--------+
|  ISP  |    | dnsd | <---> | dhcp4d |
+-------+    +------+       +--------+
    ^
    |
	|    ip6 ll  +---------+   aftr   +--------+
	| +--------->|  dhcp6  |--------->| dslite |
	| |          +---------+          +--------+
    | |            |                      ^
    V |            V ip6 prefix           |
+--------+ ip4   +----------+  ip4 conf   |
| pppoe2 | ----> | netlinkd |<------------+
+--------+ conf  +----------+
    |              ^ |
	V ip4 addr     | |
+------+           | |
| 6in4 | ----------+ | ip6 conf
+------+             |
    ^                |
    |                V
+-----+          +-------+        +------------+
| ntp |          | radvd |        | netfilterd |
+-----+          +-------+        +------------+
```

Components
==========

To make the router work a small number of components are needed.
These are either background services or oneshot setup commands.
Some of them are optional depending on the environment the router is used in
and personal preference.

pppoe2
------

This is the second most important program running on the system.
It is what connects to the outside world.
To do so it utilizes the PPPoE standard, only implementing a bare minimum.
PPP has a wide variety of authentication protocols to choose from, out of which
this implementation supports CHAP-MD5 and PAP.
With this ISP only CHAP is used in practice.
If the session disconnects or can't be established in the first place
the client will retry until it succeeds.
It uses IPCP to establish a native IPv4 connection to the provider.
A link-local native IPv6 connection is established using IPv6CP.

Once connected the service creates a virtual network interface called `ppp0`.
It lets the kernel handle the PPPoE encapsulation which surprisingly doesn't
provide a significant performance boost compared to the old unoptimized
userspace implementation. It caps out at about 90 megabits per second
with an average of 80. This is acceptable for a 100/40 plan.

The client does not configure the interface or even bring it up on its own.
This is the responsibility of netlinkd. It does however write
the IP(v6)CP results to `/tmp/pppoe.ip_config` in a JSON format.
This includes the assigned address as well as the primary
and secondary DNS servers. The IPv6 information also contains
the link-local address of the ISP peer. Both sections are optional.

To establish the connection the client uses a JSON configuration file
located at `/data/pppoe.conf` containing the username and password
for the connection. This is backwards compatible to the old config
that contained the physical interface to run on.
This field is now simply ignored.

netlinkd
--------

This is easily the most essential part of the entire project.
It is responsible for configuring the network interfaces, routing
and other network related settings. Most of them require communication
with the kernel via the netlink protocol (the route protocol to be exact)
which is what the `ip` command from iproute2 uses.

It first configures the LAN interface and VLANs with a static IPv4 address each.
In addition to this all LAN side networks are configured with the static
link-local IPv6 address `fe80::1/64`. The kernel can potentially configure
an additional EUI-64 based link-local address.
It then waits for the WAN config to become available in the aforementioned
`/tmp/pppoe.ip_config` file. It also monitors the file for changes
in case `pppoe2` reconnects. The public IPv4 address usually changes
when reconnecting but it's somewhat inconsistent.
The local IPv6 link-local address of the WAN connection is always random
for the sake of simplicity, but making it static wouldn't provide any benefits
anyway.

The WAN interface is then configured with the public IPv4 address as a /32,
assuming there is native IPv4 connectivity.
This is because unlike DHCP the IPCP does not provide subnet mask information.
Therefore we must not assume that there even is a subnet.
In recent versions the routing has become much simpler.
A single default route sends all traffic down the `ppp0` interface
without a gateway. This is a point-to-point link after all.

If native IPv6 is available the link-local address if configured
as a /64. A default route is also created. Just like the IPv4 route
the IPv6 route doesn't use a gateway and instead relies on the interface alone.

Once `dhcp6` provides or updates its lease `netlinkd` picks it up
and subnets the prefix to as many /64s as it needs.
This is done sequentially rather than using the VLAN ID (or zero)
as the subnet ID, allowing small prefixes (e.g. /61) to work
but I'd like to switch `6in4` and IPv4 to the same layout for consistency.
The subnets are then assigned to the interfaces, reserving the first one
for the WAN side (instead of respecting a PD exclude hint if present).

The router has no other way to get clean IPv6 connectivity for itself
since neither SLAAC nor DHCPv6 can be used to obtain a single WAN address.
It could use one of its LAN side addresses but having a dedicated WAN address
is cleaner and very handy when implementing DS-Lite.

Recent versions allow devices behind the router to access the DSL modem
at `192.168.1.1`.
This was made possible by adding the IPv4 address `192.168.1.2/24`
to the `eth1` interface and setting up NAT for it.
Yes, I'm just as surprised about this subnet choice as you are, but it works.
This extra configuration step is necessary with DSL modems since they can't
see inside the PPPoE session. They use the underlying Ethernet link
for administrative access.

netfilterd
----------

Netfilter is a kernel system for packet filtering, logging, mangling and more.
It's basically the Linux firewall. The popular `iptables` and `nftables` tools
use it as their backend.
Packet filtering is not strictly required for the internet connection to work,
but with IPv4 NAT is. Having this component also allows for port forwarding rules
to exist. On top of this it is used to secure the internal networks
from the outside world and from each other with some exceptions.
See the [source code](https://github.com/rsdsl/netfilterd/blob/master/src/main.rs)
for the exact ruleset.

Notably ICMP and ICMPv6 are always allowed for debugging purposes.
IPv4 NAT is done on outbound traffic as normal.
This does not apply to DS-Lite traffic since the AFTR is perfectly capable of
handling NAT for us as per RFC 6333. Avoiding double NAT helps reduce
the overhead introduced by such a carrier-grade NAT solution
and is comparable to IPv6 privacy wise.

This alone does make the IPv4 internet reachable
but some services still won't work.
The reason is the MTU of PPPoE connections. Since PPP(oE) is a tunneling
protocol there is some overhead that reduces the effective maximum packet size.
In this case it is reduced from 1500 (Ethernet maximum) to 1492.
The clients do not know about this and will happily set the TCP MSS
which is dependent on the MTU and tells the peer the packet size
we can deal with to its maximum value. The MSS is generally 40 bytes smaller
than the MTU, leading to a maximum of 1460. This is too much for our WAN tunnel
to handle though. If the server sends a huge response the ISP will have to
drop it. For whatever reason automatic path MTU discovery (PMTUD) doesn't work.

My first idea to solve this was to tell clients about the lower MTU using DHCP.
This worked on some devices but Apple in particular ignores this option.
For this reason I removed the MTU option from DHCP and implemented
a hack called "MSS clamping". This is a firewall rule that changes
any TCP packets by setting their MSS to the minimum of the MTU of the
interface the packet came from and the one it is routed to.
Now all services should be reachable.

This MSS clamping is applied to other WAN interfaces as well
so DS-Lite and 6in4 should work flawlessly too.

dhcp4d
------

Network clients need a way to configure themselves. Some devices don't support
manual configuration. Even if they did it's annoying to manage
and the subnetting scheme can't easily be changed later.
This DHCPv4 server hands out IPv4 addresses of the correct subnet
with a lease time of 12 hours. The leases are stored
at `/data/dhcp4d.leases_INTERFACE` in a JSON format.
If a lease file gets corrupted for any reason it is discarded
and overwritten with the current state from memory
or an empty structure if there is none.
The server keeps track of client IDs and hostnames if sent.
These are stored in their corresponding lease data structure.

The addresses are generated based on the client ID. For this reason
the same client will usually end up with the same address every time
even if it expired. Collisions are handled by generating a new address
until no collisions are left.

The only gateway and DNS server advertised is the router itself.

dhcp6
-----

A link-local IPv6 connection over PPP is of no use on its own.
The router needs a prefix for downstream clients as well as a means of
discovering a DS-Lite AFTR. This is where DHCPv6 comes into play.

If a native IPv6 connection has been established this service requests
a prefix delegation of size /56, the DNS servers and the AFTR name.
The result is written to `/tmp/dhcp6.lease` in a simple JSON format
but only two DNS servers are included in the file.
The valid and preferred lifetimes are stored as well but not used
as of now. The AFTR is optional.

The client automatically renews the lease after the time sent by the server
has passed. If this fails it starts over.

dnsd
----

Having an internal DNS resolver is not required but it does have one major
advantage. It is aware of the DHCP leases. Broken lease files are ignored,
leaving the task of fixing them to `dhcp4d`.
If an A record is queried the resolver checks the lease database in memory
for the hostname. If it finds a lease it reports it back to the client
without ever forwarding the request to the hardcoded upstream server.
The ISP provided nameservers are ignored for simplicity reasons.
This program is fully capable of resolving AAAA records
and accepting IPv6 packets. The network design makes it impossible
to resolve local AAAA records though.
~~It also results in NXDOMAIN errors below the IPv4 address in nslookups
if no IPv6 addresses exist for a given hostname.~~
Amazingly it doesn't add any measurable latency.
If a local hostname is present on multiple interfaces,
the interface the request originated from is prioritised
when choosing the response.

dslite
------

Dual Stack Lite is a common transition mechanism found in Germany.
It is used to provide IPv4 connectivity to IPv6-only customers
using carrier-grade NAT. Unfortunately this comes with many disadvantages
related to performance and accessing the network via IPv4.

The rsdsl project comes with a DS-Lite implementation to ensure
the availability of IPv4. Without it most services won't work.

DS-Lite is always configured if available but a default route is only created
if there is no native IPv4 connection.

The AFTR is discovered using DHCPv6. The lease file contains the FQDN.
If this is unset no tunnel is configured.
DHCPv6 is not capable of providing a resolved IPv6 address.
The client uses the IPv6 DNS servers provided by the ISP
to resolve the FQDN and use it as the remote tunnel endpoint.
The ISP servers are used because the hostname may not be available
to public resolvers.

The tunnel is a simple 4in6 tunnel using the WAN side IPv6 address
as its local endpoint. The internal address is `192.0.0.2/29`
and the default route uses `192.0.0.1` as the gateway.

### VoIP

Many ISPs provide phone service. Nowadays VoIP is very common for this.
My previous ISP did not have IPv6 capable VoIP gateways.
This has changed. The servers of the new ISP support both protocols.

This is a problem if your client is still stuck on IPv4. The particular one
I'm using is the Cisco SPA112 hardware appliance. A firmware update
adding IPv6 support was promised but the product has reached its end of life
without ever receiving such an update.

Once native IPv4 is lost there will be connectivity issues
affecting at least inbound calls. A possible solution is to run a simple proxy
on the router that translates the port ranges for SIP and RTP to the WAN side
IPv6 address of the router, essentially forming a bidirectional port mapper.
Of course any other form of dual-stack capable proxy should work as well.

Or maybe the ISP is going to assign private IPv4 addresses for this purpose?
This is unlikely but it would also work. A solution on the AFTR side
would likely be possible too.

ntp
---

Some services on the router (namely `6in4`) require a somewhat accurate
system clock in order to establish encrypted connections.
This simple NTP client waits for the PPPoE connection to come up
and makes up to 3 attempts to get the time from a basic NTP server
(no support for NTPv4 or SNTP). The fractional part is ignored for simplicity.
If the unix epoch and the actual time are mixed in your logs this is why.

6in4
----

~~Since the ISP doesn't offer native IPv6~~ This service
configures the local endpoint of a
Hurricane Electric / [tunnelbroker.net](https://tunnelbroker.net) tunnel.
The configuration has to be provided to it at `/data/he6in4.conf`
in a simple JSON format. It needs to contain the tunnel server
IPv4 address, the peering /64 from the configuration page,
the routed /64, the routed /48 (this is NOT optional) as well as
the update URL for the endpoint address.

This program only works if native IPv4 is available.
If native IPv6 is available it still establishes the tunnel
but doesn't add a default route. This ~~hopefully won't~~ doesn't break anything.
~~We'll see once native IPv6 becomes available here.~~
I'd recommend against using this if native connectivity is provided
by your ISP.

On startup a virtual tunnel interface named `he6in4` is created
and configured. In addition to this the LAN interfaces including VLANs
are automatically configured with predictable subnets
and the first IPv6 address from their subnet.
The subnets are assigned from the routed /48 with the exception of
the unVLANed LAN interface which is additionally assigned the
routed /64.
The tunneling once again takes place in kernel mode
and is unsurprisingly more efficient than PPPoE.
However this is negated by the fact that many tunnel servers
have terrible or unstable latency.

The MTU of the tunnel is limited to 1472 instead of 1480 for the reasons
mentioned above. This needs to be set in the tunnelbroker configuration menu.

This program also takes care of calling the update URL
to inform HE of our current IPv4 address. It needs DNS resolution (see code)
and NTP to work.

radvd
-----

Just like with IPv4 our client hosts need a way to get the IPv6 configuration.
The most compatible and convenient way of achieving this is through SLAAC.
This service periodically multicasts Router Advertisements (RA)
to the local networks, advertising itself as the gateway and DNS server.
It also sends a multicast if it receives a Router Solicitation (RS)
from a connecting host. Unicast is not used here out of laziness.

Interesting observations
========================

IPv4 dynamicness
----------------

The public IPv4 address doesn't seem to change if the connection
is re-established as quickly as possible. This is not reliable.
Most of the time it changes if reconnecting takes more than a few seconds.
Again this is behavior that cannot be relied on.
When it changes all octets completely change in most cases. In most other cases
only the last octet is changed.

~~I don't know about IPv6 yet.~~

The IPv6 prefix is similarly dynamic.

IPv6 support
------------

Dialing PPPoE with invalid credentials yields a public /56 IPv6 prefix
and a default gateway. However this is of no use as the ISP blocks all traffic
due to the invalid credentials. Using the correct credentials
results in a Protocol-Reject on IPv6CP negotiation if attempted
and the AC doesn't send a Configure-Request of its own.

The ISP's web portal says `Configuration: IPv4`. Apparently other values
include ~~`Dual Stack`~~ `IPv6/v4 public` and `DS Lite`, though they seem to be
quite rare. According to the forums even the employees don't know what's going
to be used for new contracts, but `Dual Stack` is never the default.

Since the AC I'm connected to seems to be IPv6 capable I'm going to ask
for Dual Stack to be enabled. Just to be safe I implemented DS-Lite.
You never know if they stick to your orders and being prepared is certainly
better than suddenly being unable to reach half of the internet.

*Update: IPv6 is available but is disabled by default.
See [IPv6 mit Vodafone DSL](/md/guide/vf6.md) (DE) for details.*

[Return to Index Page](/md/index.md)
