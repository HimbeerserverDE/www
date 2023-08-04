% Write your own ip-tunnel

# Introduction

In this post we're going to explore how to create IP-in-IP tunnels
without writing a userspace encapsulation driver.
The main advantage here is keeping the userspace code clean and simple.

# IP-in-IP tunnels

This is a type of managed tunnel. It works by simply adding an outer IP header
to the datagrams. The local and remote IP addresses have to be configured
beforehand. There is no encryption or handshaking.
It's about as simple as it gets.

You can tunnel a version of IP inside of itself or the other version.
This allows for the following combinations to be implemented:

* IPv4 in IPv4: ipip / 4in4
* IPv6 in IPv6: ip6ip6 / 6in6
* IPv6 in IPv4: sit / 6in4
* IPv4 in IPv6: ipip6 / 4in6

Inter-protocol tunnels are much more common than their intra-protocol variants.
IPv6-in-IPv4 lies at the core of many IPv6 transition mechanisms
including 6in4 using a tunnel broker or legacy 6to4. IPv4-in-IPv6
is a core component of DS-Lite.

These tunnels require kernel support and can be configured
using the `ip tunnel` subcommand.

# So how does it work?

Unlike most other types of network interfaces tunnels don't require netlink
configuration. Creating links like VLANs does require this,
but tunnels don't. Netlink is still used to change configuration parameters
like the IP addresses but it's not involved in providing the creation
and deletion API.

# Let's reimplement it

This could probably be implemented using unsafe Rust code without the need
for C bindings, but they do make our life much easier.

Tunnel control works using the `ioctl` syscall on any dummy IPv4 or IPv6 socket.
You should probably use the outer protocol, though IPv6 might work
for everything.

The control socket is created as follows:

```
int fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
```

not including any error handling. `IPPROTO_IP` is zero.

Here's the `ioctl` we have to prepare:

```
struct ip_tunnel_parm p;

strcpy(p.name, "footnl0");
p.iph.version = 4; // outer protocol
p.iph.ihl = 5;
p.iph.protocol = IPPROTO_IPIP; // inner protocol
p.iph.saddr = /* our address as big-endian u32 */
p.iph.daddr = /* remote address as big-endian u32 */
p.link = if_nametoindex("ppp0"); // parent interface

struct ifreq ifr;

strcpy(ifr.ifr_name, "tunl0"); // default name for our tunnel type
ifr.ifr_ifru.ifru_data = (char *) &p;

ioctl(fd, SIOCADDTUNNEL, &ifr);
```

This will create the tunnel assuming you have the required permissions.
The default interface name for 4in4 is `tunl0`. This is different
for the other tunnel types. From what I understand `sit0`
is used if the inner protocol is IPv6, but if it doesn't work
you'll have to read the iproute2 source code and test it for yourself.
One easy way to do this is making a debug build and attaching `gdb`
to set a breakpoint at the `ioctl` call and inspect the `ifr` struct.

The MTU is set automatically but bringing the interface up
and configuring the internal addressing is up to you.
Also unlike the more complex PPP driver the tunneling code
does not delete the interface when your application exits.
If this is unwanted behavior you need to call a deletion function
before exiting which can even be automated using Rust's destructors.

# Deletion

Initialise a socket like you did when creating the tunnel.
The request and `ioctl` call are different though:

```
struct ip_tunnel_parm p;

strcpy(p.name, "footnl0");

struct ifreq ifr;

strcpy(ifr.ifr_name, "footnl0");
ifr.ifr_ifru.ifru_data = (char *) &p;

ioctl(fd, SIOCDELTUNNEL, &ifr);
```

Thankfully all of this is much simpler than PPP
once you figure out how it works. Have fun with your cleanly created tunnels!

[Return to Guide List](/cgi-bin/guides.lua)

[Return to Index Page](/cgi-bin/index.lua)
