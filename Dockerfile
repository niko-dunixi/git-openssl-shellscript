FROM ubuntu:latest as git-compiler
# Optional curl options like --insecure in case you're behind a corporate proxy.
ARG CURL_OPTIONS=''
# no interactions with apt possible
ENV DEBIAN_FRONTEND=noninteractive
# update apt
RUN apt-get update -qq -y --fix-missing;
# install required packages
RUN apt-get install -qq -y --no-install-recommends \
    build-essential \
    autoconf \
    dh-autoreconf \
    libcurl4-openssl-dev \
    tcl-dev \
    gettext \
    asciidoc \
    libexpat1-dev \
    libz-dev \
    # @see https://help.ubuntu.com/community/CheckInstall
    checkinstall \
    # install curl and jq for downloading
    curl \
    # @see https://stedolan.github.io/jq/tutorial/
    jq;
# prepare source dir
RUN mkdir -p /root/src;
WORKDIR /root/src
# download & extract source tar
RUN curl ${CURL_OPTIONS} \
        --location \
        --fail \
        $(curl ${CURL_OPTIONS} --silent --fail 'https://api.github.com/repos/git/git/tags' | jq '.[0].tarball_url' | tr -d '"') \
    | tar xz --strip 1;
# configure & compile git with OpenSSL
RUN make configure; \
    CFLAGS="-static" ./configure --with-openssl; \
    make;
# create debian package
RUN checkinstall \
        --type=debian \
        --pkgname=git-openssl \
        --pkgversion=$(./git --version | cut -d " " -f 3);
# move created .deb file to a more scriptable filename
RUN mv -v ./git-openssl_$(./git --version | cut -d " " -f 3)-1_amd64.deb ./git-openssl.deb;

# install package on plain ubuntu
FROM ubuntu:latest
COPY --from=git-compiler \
    /root/src/git-openssl.deb \
    /root/git-openssl.deb
RUN dpkg -i /root/git-openssl.deb
