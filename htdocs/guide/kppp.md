% Write your own PPP(oE) client with kernel mode tunneling

# Introduction

In this post we're going to explore how PPPoE works
and how to write your own kernel-aware client for it.

If you've ever configured a PPP connection on a regular router
using something like OpenWrt, you are probably familiar
with the components that make it work.

There's `pppd`, the main program. It establishes a connection
and provides you with the `ppp0` interface.
To do so it delegates some mystery work to the kernel.
It also needs a user mode .so plugin for PPPoE support.

# PPPoE vs. PPP

PPP stands for Point-to-Point Protocol. It first became popular
with dial-up connections. The serial line you used to connect
to the modem was guaranteed to be a connection between exactly
two machines.

PPP is still in use today by many DSL and some G.PON connections.
The modems now usually come with two Ethernet ports
for your downstream devices. Due to the nature of any Ethernet link
this means that the connection between your router and the ISP
is no longer guaranteed to be P2P.

PPPoE establishes a point-to-point session over Ethernet,
allowing PPP to be used on Ethernet links. PPP frames are encapsulated
in PPPoE packets.

PPPoE knows five packet types. It uses a four-way handshake to connect:

```
1. C -> (Ethernet broadcast) : PPPoE Active Discovery Initiation           (PADI)
2. (all servers) -> C        : PPPoE Active Discovery Offer                (PADO)
3. C -> S (any of the offers): PPPoE Active Discovery Request              (PADR)
4. S -> C                    : PPPoE Active Discovery Session-confirmation (PADS)
```

A PPP session is then started with a different EtherType.

Either side can force the session to be terminated at any time
by sending a `PPPoE Active Discovery Terminate (PADT)`.
This usually happens after the higher level PPP session is terminated
or if PPP termination fails or is unavailable (which it is in early phases).

# How PPP works

PPP itself is simply a collection of protocols that can affect the state
of other protocols.

There are different types of PPP protocols:

* LCP
* Authentication
* NCPs
* Data Link Layer

LCP as well as most (if not all) NCPs are option negotiation protocols.
They consist of the following packets:

* Configure-Request
* Configure-Ack
* Configure-Nak
* Configure-Reject
* Terminate-Request
* Terminate-Ack
* Code-Reject

Both sides send a Configure-Request with configuration options.

If a peer can't accept a value but has a suggestion for a valid value,
it replies with a Configure-Nak containing all options this applies to.
The sender may then use some or all of the suggested values and retry,
or give up.

If a peer can't accept a value because it must not be set
(this often applies to boolean options that don't have a value)
it replies with a Configure-Reject containing all options this applies to.
The sender may then unset some or all of the options and retry,
or give up.

If the configuration is acceptable, the peer replies with a Configure-Ack
containing the same options.

If a peer decides to close the protocol, it sends a Terminate-Request
with optional data (e.g. reason string). If it receives a Terminate-Ack
or doesn't receive one after multiple retransmissions,
it closes the protocol anyway.

A Code-Reject signals an error condition likely caused by a bug
or incompatible protocol versions which don't actually exist.

## Link Control Protocol (LCP)

LCP configures link information. This usually includes reducing the MRU
and exchanging magic numbers. In addition to this most ISPs request
authentication.

LCP has more packets than the ones mentioned above:

* Protocol-Reject
* Echo-Request
* Echo-Reply
* Discard-Request

A Protocol-Reject is sent in response to an invalid or unsupported NCP
or authentication protocol being used. It tells the sender to stop
trying to use that protocol.

An Echo-Request is replied to with an Echo-Reply. If no reply is received
the sender usually terminates the connection after a few attempts.
These packets contain the magic number of the sender.
This can be used to detect error conditions like a link that's looped back.
See [RFC 1661](https://rfc-editor.org/rfc/rfc1661) for details.
Both sides are free to choose not to send Echo-Requests.

A Discard-Request is a no-op and can be used to analyze link performance.

### Common options

With PPPoE both peers exchange a Maximum Receive Unit (MRU) of 1492
instead of the default 1500. This option is used to ask the peer
to send smaller packets. PPPoE actually violates the PPP RFC
because a peer is still required to be able to receive the full
1500 bytes in case link synchronization is lost.
However this doesn't cause any issues in the real world
since packets of that size are only exchanged while the link is synchronized.

The value 1492 is the result of this calculation:

```
MRU	= Ethernet_MTU - PPP_header_size - PPPoE_header_size
	= 1500 - 2 - 6
	= 1500 - 8
	= 1492
```

The magic number is a random non-zero value as described in the RFC
that is unique to each peer.

The authentication option can be unset for no authentication
or set to one of the various authentication protocols
and detailed configuration data for it.
The most common protocols are PAP and CHAP.
CHAP requires the option to contain a hashing algorithm,
this is usually set to MD5 (password authentication for internet access
is unnecessary anyway).

## Authentication

This is skipped if no authentication is required according to the LCP exchange.

If authentication fails, the authentication protocol attempts to
notify the client before using LCP to terminate the connection.

### Password Authentication Protocol (PAP)

This is a very simple protocol and extremely common.
You simply send your credentials in plain text and the server tells you
if you were right.

### Challenge-Handshake Authentication Protocol (CHAP)

CHAP is also quite common and usually uses MD5 as its hashing algorithm.
The server sends a challenge which is just a long random sequence of bytes.
The client then calculates `H(challenge|packet id|password)`
where `H` is the hash function. A `|` denotes a concatenation.
The `packet id` is the identifier (a kind of sequence number)
of the challenge packet.

The client then responds with the calculated hash and the username.
The server replies, telling it if the password was correct.

## Network Control Protocols (NCPs)

Once the PPP link has been established and authenticated
at least one network protocol needs to be configured.
There's a whole collection of these but we only care about IPCP and IPv6CP.

Once an NCP enters the 'Opened' state its corresponding data protocol
may be used to exchange traffic.

### Internet Protocol Control Protocol (IPCP)

This is the configuration protocol for native IPv4.
Both peers request the configuration options they want to use for themselves.

For the ISP server this is the default gateway address,
although it is technically not needed since the link is guaranteed
to be point-to-point anyway.

The client implementation requests the IP address `0.0.0.0`
and optionally sets both DNS servers to zero as well.
The ISP then nak's this configuration, suggesting the actual values.
The client requests these values and receives an ack.

### Internet Protocol Version 6 Control Protocol (IPv6CP)

This is similar to IPCP but it only exchanges 64-bit interface identifiers
that are used with the `fe80::/64` link-local prefix.
This connection does not provide internet connectivity
but it can be used to obtain a prefix using DHCPv6-PD
as well as the default gateway using regular RAs.
DHCPv6 provides additional information like DNS servers
or an AFTR address for use with DS-Lite.

Notice that the router itself doesn't receive a WAN address?
This is normal behavior for some reason.
You can either make use of a LAN side address if your router assigns them
to itself, or you can derive a WAN address from your delegated prefix.

# So how do we implement a client?

There are two ways in which we can do this.
The first one is handling everything in userspace
and offering a TUN device to the OS.
This is what [rsdsl_pppoe](https://github.com/rsdsl/pppoe.git) does.
However the overhead is quite substantial, even in Rust.
Its safety constraints also make efficient packet tunneling very challenging.
The current implementation suffers from bufferbloat so the latency increases
to more than 400 ms as soon as the the connection is under load.

The Linux kernel has native support for both PPP and PPPoE.
However this seems to be made specifically for `pppd`
and there is pretty much no documentation at all, and trust me -
reading kernel code is not fun. Nonetheless I found out how it works
and made a sys crate for it.

Kernel mode tunneling is likely to be more performant
and significantly simplifies the code base. Here's how it works.

# Kernel mode PPPoE

For this to work the kernel has to have support. Most distros use modules
for this, but a minimal platform like [rustkrazy](/cgi-bin/rustkrazy.lua)
needs to compile native support into the kernel
by setting the following options:

```
CONFIG_PPP=y
CONFIG_PPPOE=y
```

We will still have to handle the aforementioned configuration protocols
and packets but the kernel is going to take care of the interface
and data transmission and reception.

Due to its complexity the kernel interfacing is handled by C bindings
which are seemingly safely wrapped by Rust code.
Since we want to know how the kernel interface works
we're going to look at the C code.

Control of this feature is done using sockets.

## Discovery socket

This is going to be used internally for PPPoE discovery packets.
The socket is created like this:

```
int sock = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_PPP_DISC));

int broadcast = 1;
setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof broadcast);
```

not including error handling. The broadcast option is needed
because PADI packets are sent to the broadcast MAC address.

Next an `ioctl` call is used to get the hardware address of the interface:

```
struct ifreq ifr;

memset(ifr.ifr_name, 0, IFNAMSIZ);
strncpy(ifr.ifr_name, "eth1", IFNAMSIZ - 1);

ioctl(sock, SIOCGIFHWADDR, &ifr);
```

resulting in the MAC address being stored in `ifr.ifr_hwaddr.sa_data`.

Another `ioctl` is used to get the index of the interface
since `bind` requires an index rather than a name:

```
ioctl(sock, SIOCGIFINDEX, &ifr);
```

which is then used to bind actually bind the socket:

```
struct sockaddr_ll sa;

sa.sll_family = AF_PACKET;
sa.sll_protocol = htons(ETH_P_PPP_DISC);
sa.sll_ifindex = ifr.ifr_ifindex;

bind(sock, (struct sockaddr *) &sa, sizeof sa);
```

This socket can then be converted to Rust's `socket2::Socket`
and used normally.

## Session initialization

Once PPPoE has established a session we need to actually get the kernel
to tunnel traffic. To do this we first create a transport socket
for the PPP frames:

```
int sock = socket(AF_PPPOX, SOCK_STREAM, PX_PROTO_OE);

struct sockaddr_pppox sp;

sp.sa_family = AF_PPPOX;
sp.sa_protocol = PX_PROTO_OE;
sp.sa_addr.pppoe.sid = htons(/* pppoe_session_id */);
memcpy(sp.sa_addr.pppoe.dev, "eth1", 4 + 1);
memcpy(sp.sa_addr.pppoe.remote, /* server_mac */, 6);

connect(sock, (const struct sockaddr *) &sp, sizeof sp);
```

This is a so-called generic PPP channel which is simply a transport
for PPP frames that automatically handles PPPoE headers.
To actually use it we need its channel ID:

```
int chindex;
ioctl(sock, PPPIOCGCHAN, &chindex);
```

Next we open a control file descriptor that's going to be attached
to the PPP channel:

```
int ctlfd = open("/dev/ppp", O_RDWR);

ioctl(ctlfd, PPPIOCATTCHAN, &chindex);
```

This is where LCP and authentication packets will arrive. However
the full PPP header is included (PPPoE is not).

Finally we create a generic PPP unit. This is the actual `ppp0` interface
and it's where the traffic actually ends up. We create it and connect it
to the channel we created earlier as its transport:

```
int pppdevfd = open("/dev/ppp", O_RDWR);

int ifunit = -1;
ioctl(pppdevfd, PPPIOCNEWUNIT, &ifunit);
ioctl(ctlfd, PPPIOCCONNECT, &ifunit);
```

This is where the NCPs are going to arrive.

In summary we now have a socket for discovery packets
as well as two PPP file descriptors for link synchronization and authentication
as well as the network configuration protocols.
What's cool is that the kernel automatically creates a working `ppp0`
interface for us. It's down initially but it can manually be brought up
and configured with the addresses by [netlinkd](https://github.com/rsdsl/netlinkd.git).

This was very frustrating to find out and took a long time.
Have fun writing your own kernel mode PPPoE clients using this knowledge.

[Return to Guide List](/cgi-bin/guides.lua)

[Return to Index Page](/cgi-bin/index.lua)
