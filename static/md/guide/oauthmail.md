---
title: "Use OAuth2 email accounts with aerc + mbsync"
date: 2025-01-27
---

My university recently moved their email infrastructure to the Microsoft cloud.
The new setup requires OAuth2 for authentication, traditional IMAP and SMTP
login mechanisms are rejected. There are several tools to work around this such
as [oauth2ms](https://github.com/harishkrupo/oauth2ms) or
[mutt_oauth2.py](https://gitlab.com/muttmua/mutt/-/blob/master/contrib/mutt_oauth2.py)
but none of them worked for me. I was able to obtain a token using my own
registered OAuth2 app on Azure, but the token was rejected at IMAP / SMTP
login.

The obvious solution is to use the web version of Outlook, but that's less than
ideal. Outlook sends HTML-only emails by default and webmail can't be accessed
without a stable internet connection. It's also a second client I have to check
that doesn't integrate with the rest of my email setup at all. Needless to say
I wanted to find a way to keep using my current setup with
[aerc](https://aerc-mail.org/) as my email client and
[mbsync](https://manpages.debian.org/stable/isync/mbsync.1.en.html) for offline
downloading.

Obtaining a refresh token
=========================

This is most easily done by stealing the token from a different email client. I
used Thunderbird with the following method.

1. Install [mitmproxy](https://mitmproxy.org/) and run `mitmweb`. Point your browser to [http://localhost:8081](http://localhost:8081) if it doesn't open automatically.
2. Open Thunderbird and go to Settings > General > Network & Disk Space > Connection > Settings.
3. Select "Manual proxy configuration" and enter localhost and port 8080 as the HTTP proxy. Ensure "Also use this proxy for HTTPS" is checked.
4. Close the dialogue with "OK" and go to Privacy & Security > Security > Certificates > Manage Certificates > Authorities > Import.
5. Import ~/.mitmproxy/mitmproxy-ca-cert.pem and allow it to be used for websites.
6. Go to Account Settings > Actions > Add Mail Account and add your email account as normal.
7. Remove the email account and undo the configuration changes.
8. Go to mitmweb and find a request to https://login.microsoftonline.com/common/oauth2/v2.0/token.
9. Go to the response tab and copy the refresh_token. Write it to a file, e.g. ~/.oauthenticate/email_university.
10. Ensure the permissions are secure: `chmod 700 ~/.oauthenticate` and `chmod 600 ~/.oauthenticate/*`.
11. Go to the request tab and store the client_id somewhere for later reference.

After completing these steps you can uninstall mitmproxy and Thunderbird
assuming you don't need them for any other purposes.

oauthenticate script
====================

The refresh token alone isn't enough to access the account. It needs to be used
to fetch an access token as well as a new refresh token for future use. The
access token can then be presented to the mail server.

Most existing tools require gpg encryption and custom file formats that are
hard to reproduce by hand. Because of this I wrote the
[oauthenticate](https://git.himbeerserver.de/bspwm-setup.git/tree/bin/oauthenticate)
script to work with the tokens directly. It stores the refresh token on disk in
plaintext form. I use full disk encryption, but adding gpg to the equation
would add some extra security against simply copying the file.

In my setup, this script is located at ~/bin/oauthenticate and ~/bin is listed
in PATH.

The script is invoked like so:

```
oauthenticate https://login.microsoftonline.com/common/oauth2/v2.0/token 9e5f94bc-e8a4-4e73-b8be-63364c29d753 ~/.oauthenticate/email_university
```

where 9e5f94bc-e8a4-4e73-b8be-63364c29d753 is Thunderbird's client_id obtained
from the last section. The refresh token is automatically rotated and the
access token is written to the output.

Installing a SASL XOAUTH2 plugin
==================================

mbsync lacks native support for OAuth2. On Arch-based distros you can install
[cyrus-sasl-xoauth2-git](https://aur.archlinux.org/packages/cyrus-sasl-xoauth2-git)
from the AUR. You can also install from
[source](https://github.com/moriyoshi/cyrus-sasl-xoauth2).

Configuring mbsync
==================

Edit your isyncrc and set the following values for your remote account:

```
Host outlook.office365.com
AuthMechs XOAUTH2
PassCmd "oauthenticate https://login.microsoftonline.com/common/oauth2/v2.0/token 9e5f94bc-e8a4-4e73-b8be-63364c29d753 ~/.oauthenticate/email_university"
```

If mbsync is invoked from cron, you may have to set up the environment
variables first or use the absolute path of oauthenticate.

Configuring aerc
================

Edit your accounts.conf and set the following values for your account:

```
outgoing = smtp+xoauth2://username%40universitydomain.tld@smtp.office365.com:587
outgoing-cred-cmd = ~/bin/oauthenticate https://login.microsoftonline.com/common/oauth2/v2.0/token 9e5f94bc-e8a4-4e73-b8be-63364c29d753 ~/.oauthenticate/email_university
```

Other quirks
============

Exchange automatically creates an email in the "Sent Items" folder for
everything sent over SMTP. Additionally I have configured all of my aerc
accounts to copy sent emails to "Sent Items". This results in each sent email
being duplicated. The fix is to remove the `copy-to` directive from the account
configuration.

Conclusion
==========

It's possible that this setup is going to hit rate limits for refreshing the
access token every 10 minutes. Furthermore my university or Microsoft may
decide to disallow standard email clients alltogether, a step many
organizations have already taken. The future for organizational email doesn't
look bright.

While this setup is functional I'm opposed to using OAuth2 at all due to its
complexity and because it's yet another attempt to eliminate the freedom of
choice of email clients. [Even Disroot has announced that they want to move
towards OAuth2](https://disroot.org/en/blog/disnews-24.10) which is highly
concerning. I'll be putting in effort to set up my own mail server to solve my
email issues once and for all.

[Return to Guide List](/md/guides.md)

[Return to Index Page](/md/index.md)
