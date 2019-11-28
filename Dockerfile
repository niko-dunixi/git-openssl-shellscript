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
COPY --from=git-compiler-helper \
  /root/git-latest-url-finder.run \
  /bin/git-latest-url-finder.run
RUN curl -L --retry 5 --url "$(/bin/git-latest-url-finder.run)" --output "git-source.tar.gz" && \
  tar -xf "git-source.tar.gz" --strip 1
RUN make configure
RUN ./configure --with-openssl
RUN make
COPY ./git /bin/git
ENTRYPOINT [ "git" ]