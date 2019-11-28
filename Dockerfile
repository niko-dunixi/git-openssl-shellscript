FROM golang:1.13.4 as git-compiler-helper
ADD ./git-compiler-helper /root/git-compiler-helper
WORKDIR /root/git-compiler-helper
RUN go get -d ./...
RUN go build -o /root/git-latest-url-finder.run .

FROM ubuntu:latest as git-compiler
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install build-essential autoconf dh-autoreconf -y
RUN apt-get install libcurl4-openssl-dev tcl-dev gettext \
  asciidoc libexpat1-dev libz-dev -y
RUN apt-get install curl -y
RUN mkdir -p /root/src
WORKDIR /root/src
COPY --from=git-compiler-helper \
  /root/git-latest-url-finder.run \
  /root/git-latest-url-finder.run
RUN /root/git-latest-url-finder.run > git-tar-url.txt && \
  echo "$(cat git-tar-url.txt)" && \
  curl -L --retry 5 --url "$(cat git-tar-url.txt)" --output "git-source.tar.gz" && \
  # curl -o "git-source.tar.gz" && \
  tar -xf "git-source.tar.gz" --strip 1
RUN make configure
RUN CFLAGS="-static" ./configure --with-openssl
RUN make
RUN ls ./*
RUN cp ./git /bin/git
ENTRYPOINT [ "git" ]