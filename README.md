# git-openssl-shellscript
Shellscript to compile git with OpenSSL

### compile-git-with-openssl.sh

There are at times when you need to use git with https instead of ssh (behind firewalls where ssh is not allowed but https is, for instance). There is a gnutls issue that prevents communication with some https behind such firewalls or unusual proxy configurations, etc. You will typically see an error such as this:
```
fatal: unable to access 'http://you@path.to/arbitrary/repository.git': gnutls_handshake() failed: Illegal parameter
```
The only way to resolve this is by re-compiling git with `openssl` instead of `gnutls`.
hii ra bala chudu okasari

This shellscript does that by downloading the source for git, switching it to `openssl` and and then building it. If you are using a managed version of git (eg: through ubuntu's package manager) you will have to re-run the script every time you recieve an updated version of git because the managed version will overwrite your compiled version (it's honestly better to just uninstall it first, otherwise you're going to be fighting with `apt` with every git update)
