% Password Generator

This page generates a few passwords *on the server* and displays them to the user.
The code can be found [on GitHub](https://github.com/HimbeerserverDE/www/blob/master/cgi-bin/password_generator.lua).

# Security issue

**This generator is extremely insecure.**

For convenience reasons the generator internally uses Lua's `math.random`
and seeds it with cryptographically secure random data.

It gets this data by reading 64 bytes from `/dev/random`
and adding their ASCII codes together in a loop.
In this step the number of possible seeds is reduced
from `256^64` to just `256*64`.

It is trivial to use this knowledge to generate all possible seeds
and the passwords generated from them.
This only takes about a second even on my slow machine. The list
can then be used in a dictionary attack.

**DO NOT USE THIS! A proper generator like the one in KeePassXC
is a much more secure and convenient option!**

# 32 Letters, digits, punctuation characters
* `${strongest1}`
* `${strongest2}`
* `${strongest3}`
* `${strongest4}`
* `${strongest5}`

# 32 Letters, digits
* `${strong1}`
* `${strong2}`
* `${strong3}`
* `${strong4}`
* `${strong5}`

# 32 Letters
* `${medium1}`
* `${medium2}`
* `${medium3}`
* `${medium4}`
* `${medium5}`

# 16 Letters, digits
* `${weak1}`
* `${weak2}`
* `${weak3}`
* `${weak4}`
* `${weak5}`

[Return to Index Page](/cgi-bin/index.lua)
