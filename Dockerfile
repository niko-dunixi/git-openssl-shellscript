FROM ubuntu:latest as git-compiler
# Optional curl options like --insecure in case you're behind a corporate proxy.
ARG CURL_OPTIONS=''
# no interactions with apt possible
ENV DEBIAN_FRONTEND=noninteractive
# update apt
RUN apt-get update -qq -y;
# Install stuff for git itself
RUN apt-get install -qq -y --no-install-recommends \
    zlib1g \
    libcurl4 \
    perl \
    libpcre3 \
    libexpat1 \
    liberror-perl \
    libc6;
# Install meta-things for building on the end-user's machine
RUN apt-get install -qq -y --no-install-recommends \
    build-essential \
    autoconf \
    dh-autoreconf \
    # @see https://help.ubuntu.com/community/CheckInstall
    checkinstall \
    curl \
    # @see https://stedolan.github.io/jq/tutorial/
    jq;
# Install dev stuff for git
RUN apt-get install -qq -y --no-install-recommends \
    libcurl4-openssl-dev \
    tcl-dev \
    gettext \
    asciidoc \
    libexpat1-dev \
    libz-dev \
    libssl-dev;
# prepare source dir
RUN mkdir -p /root/src;
WORKDIR /root/src
# download & extract source tar
RUN curl ${CURL_OPTIONS} \
        --location \
        --fail \
        # assuming the top-most tag is the most recent version
        $(curl ${CURL_OPTIONS} --silent --fail 'https://api.github.com/repos/git/git/tags' | jq '.[0].tarball_url' | tr -d '"') \
    | tar xz --strip 1;
# configure & compile git with OpenSSL
RUN make configure; \
    ./configure --prefix=/usr --with-openssl; \
    make;
# create debian package
RUN checkinstall \
        --default \
        --type=debian \
        --pkgname=git-openssl \
        --pkgversion=$(./git --version | cut -d " " -f 3) \
        --pkgarch=$(dpkg --print-architecture) \
        --conflicts=git \
        --requires="libcurl4,zlib1g \(\>= 1:1.2.0\),perl,libpcre3,libexpat1 \(\>= 2.0.1\),liberror-perl,libc6" \
        --recommends="less,patch,ssh-client,ca-certificates" \
        make install;
# move created .deb file to a more scriptable filename
RUN cp -v ./git-openssl_$(./git --version | cut -d " " -f 3)-1_$(dpkg --print-architecture).deb /root/git-openssl.deb;

# install package on plain ubuntu
FROM ubuntu:latest
COPY --from=git-compiler \
    /root/git-openssl.deb \
    /root/git-openssl.deb
RUN apt-get update -qq -y; \
    apt-get install -qq -y --no-install-recommends \
        libcurl4 \
        perl \
        libexpat1 \
        liberror-perl \
        ca-certificates; \
    apt-get clean;
RUN dpkg -i /root/git-openssl.deb
ENTRYPOINT [ "git" ]
