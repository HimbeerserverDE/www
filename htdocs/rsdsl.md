% The rsdsl Project

# About
The rsdsl project is a collection of Rust programs
that form a customized, yet simple router for Vodafone Germany DSL connections.
It is designed to run on [Rustkrazy](/cgi-bin/rustkrazy.lua).

# Repositories
Up-to-date versions of all components and some common or forked libraries
can be found on [my own git server](https://git.himbeerserver.de/?a=project_list;pf=rsdsl)
or on [GitHub](https://github.com/rsdsl).

# Platforms
All Rustkrazy platforms should be supported,
but testing is currently limited to the Raspberry Pi 3B.

# Why
You may wonder why one would rewrite an entire router
when there are existing solutions for it.
OpenWrt is one such option. I had been using it for months
without any major issues. However the majority of its components
are written in C, a memory unsafe programming language.
It is also quite complex for what it does.
On top of this writing custom protocol implementations is a lot of fun.

The network structure and ISP were about to change anyway.
This is why I decided to build rsdsl for the new network.

# Hardware
The LAN side of the router is connected via its builtin Ethernet interface.
It is connected to a VLAN capable switch
and tagged VLAN (802.1q) is enabled on the port.

The WAN connection is done using a USB to Ethernet dongle
that connects to a dedicated DSL modem.
The modem takes care of tagging the packets with VLAN ID 7.

# Operation diagram
Here's the core concept of how the components work together.

```
+-------+    +------+       +--------+
|  ISP  |    | dnsd | <---> | dhcp4d |
+-------+    +------+       +--------+
    ^
    |
	V
+-------+ ip4   +----------+       +------------+     +-----+
| pppoe | ----> | netlinkd |       | netfilterd |     | ntp |
+-------+ conf  +----------+       +------------+     +-----+
    |               ^
	V ip4 addr      |
+------+            |
| 6in4 | -----------+ ip6 conf
+------+            |
                    |
                    V
                +-------+
                | radvd |
                +-------+
```

# Components
To make the router work a small number of components are needed.
These are either background services or oneshot setup commands.
Some of them are optional depending on the environment the router is used in
and personal preference.

## pppoe
This is the second most important program running on the system.
It is what connects to the outside world.
To do so it utilizes the PPPoE standard, only implementing a bare minimum.
PPP has a wide variety of authentication protocols to choose from, out of which
this implementation supports CHAP-MD5 and PAP.
With this ISP only CHAP is used in practice.
If the session disconnects or can't be established in the first place
the client will retry until it succeeds.
It currently does not have support for native IPv6 via IPv6CP and DHCPv6
since the ISP doesn't support it yet. It uses IPCP to establish an IPv4-only
native session to the provider.

Once connected the service creates a virtual network interface called `rsppp0`.
It handles the PPPoE tunneling in userspace which is surprisingly efficient
even on a slow RPi CPU. It caps out at about 90 megabits per second
with an average of 80. This is acceptable for a 100/40 plan.

The client does not configure the interface or even bring it up on its own.
This is the responsibility of netlinkd. It does however write the IPCP results
to `/tmp/pppoe.ip_config` in a JSON format. This includes the assigned address,
the default gateway and the primary and secondary DNS servers.

To establish the connection the client uses a JSON configuration file
located at `/data/pppoe.conf` containing the username and password
for the connection as well as the physical interface to run on.

## netlinkd
This is easily the most essential part of the entire project.
It is responsible for configuring the network interfaces, routing
and other network related settings. Most of them require communication
with the kernel via the netlink protocol (the route protocol to be exact)
which is what the `ip` command from iproute2 uses.

It first configures the LAN interface and VLANs with a static IPv4 address each.
It then waits for the WAN config to become available in the aforementioned
`/tmp/pppoe.ip_config` file. It also monitors the file for changes
in case `pppoe` reconnects (the public IPv4 address usually changes when reconnecting
but it's somewhat inconsistent).

The WAN interface is then configured with the public IPv4 address as a /32.
This is because unlike DHCP the IPCP does not provide subnet mask information.
Therefore we must not assume that there even is a subnet.
This leads to a problem as the kernel won't be able to reach the default gateway
since no route to it exists. Because of this we add a route to the default gateway
as a /32 and use `rsppp0` as the device. This route is created with scope "link",
telling the kernel that the address is only one hop away. This allows it
to be used as a gateway in the default route.

## netfilterd
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

## dhcp4d
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

## dnsd
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
It also results in NXDOMAIN errors below the IPv4 address in nslookups
if no IPv6 addresses exist for a given hostname.
Amazingly it doesn't add any measurable latency.
If a local hostname is present on multiple interfaces,
the interface the request originated from is prioritised
when choosing the response.

## ntp
Some services on the router require a somewhat accurate system clock
in order to establish encrypted connections. This simple NTP client
waits for the PPPoE connection to come up and makes up to 3 attempts
to get the time from a basic NTP server (no support for NTPv4 or SNTP).
The fractional part is ignored for simplicity.
If the unix epoch and the actual time are mixed in your logs
this is why.

## 6in4
Since the ISP doesn't offer native IPv6 this service
configures the local endpoint of a
Hurricane Electric / [tunnelbroker.net](https://tunnelbroker.net) tunnel.
The configuration has to be provided to it at `/data/he6in4.conf`
in a simple JSON format. It needs to contain the tunnel server
IPv4 address, the peering /64 from the configuration page,
the routed /64, the routed /48 (this is NOT optional) as well as
the update URL for the endpoint address.

On startup a virtual tunnel interface named `he6in4` is created
and configured. In addition to this the LAN interfaces including VLANs
are automatically configured with predictable subnets
and the first IPv6 address from their subnet.
The subnets are assigned from the routed /48 with the exception of
the unVLANed LAN interface which is additionally assigned the
routed /64.
The tunneling once again takes place in userspace
and is even more efficient than PPPoE. The reason is that I haven't
been able to reverse the rtnetlink API enough to create tunnel interfaces yet.

The MTU of the tunnel is limited to 1472 instead of 1480 for the reasons
mentioned above. This also needs to be set in the tunnelbroker configuration
menu.

This program also takes care of calling the update URL
to inform HE of our current IPv4 address. It needs DNS resolution (see code)
and NTP to work.

## radvd
Just like with IPv4 our client hosts need a way to get the IPv6 configuration.
The most compatible and convenient way of achieving this is through SLAAC.
This service periodically multicasts Router Advertisements (RA)
to the local networks, advertising itself as the gateway and DNS server.
It also sends a multicast if it receives a Router Solicitation (RS)
from a connecting host. Unicast is not used here out of laziness.

# Interesting observations
## IPv4 dynamicness
The public IPv4 address doesn't seem to change if the connection
is re-established as quickly as possible. This is not reliable.
Most of the time it changes if reconnecting takes more than a few seconds.
Again this is behavior that cannot be relied on.
When it changes all octets completely change in most cases. In most other cases
only the last octet is changed.

## IPv6 support
Dialing PPPoE with invalid credentials with an IPv6 capable client
yields a public /56 IPv6 prefix and a default gateway.
However this is of no use as the ISP blocks all traffic
due to invalid credentials.
Using the correct credentials results in a Protocol-Reject on IPv6CP
negotiation if attempted and the AC doesn't send a Configure-Request
of its own.

[Return to Index Page](/cgi-bin/index.lua)
