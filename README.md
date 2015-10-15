# git-openssl-shellscript
Shellscript to compile git with OpenSSL

### git-openssl.sh

There are at times when you need to use git with https instead of ssh (behind firewalls where ssh is not allowed but https is, for instance). There is a gnutls issue that prevents communication with some https behind such firewalls or unusual proxy configurations, etc. You will typically see an error such as this:
```
fatal: unable to access 'http://you@path.to/arbitrary/repository/git-openssl-shellscript.git': gnutls_handshake() failed: Illegal parameter
```
The only way to resolve this is by re-compiling git with `openssl` instead of `gnutls`.

This shellscript does that by downloading the source for git, switching it to `openssl` and and then building it. If you are using a managed version of git (eg: through ubuntu's package manager) you will have to re-run the script every time you recieve an updated version of git because the managed version will overwrite your compiled version.

### git-openssl-experimental.sh
This script is better than the other one, in that it pulls git source code directly from it's head repository and then compiles it. This gives you the benefit of using the most recent stable version which solves a lot of issues, in and of itself. It also compiles git-credential-gnome-keyring so credentials are using the keyring by default. It adds convienience to not having to retype passwords and security by not storing them in cleartext.

That being said, it is experimental. Use at your own peril. If things go south, just purge all git and re-install or use the regular shellscript

## For both scripts
Compiling and running the tests to ensure functionailty can take a significant portion of time. Pass the ```-skiptests``` argument to the script you run. Tests will be skipped and the script will procede without them.