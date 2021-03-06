# Build in a stock Go builder container
FROM golang:1.12-alpine as builder

RUN apk --no-cache add build-base git bzr mercurial gcc linux-headers npm
RUN npm install -g grunt-cli

ENV GENESIS_VERSION 0.2.1
RUN cd /usr/local/bin \
	&& wget https://github.com/benbjohnson/genesis/releases/download/v0.2.1/genesis-v0.2.1-linux-amd64.tar.gz && ls \
	&& tar zxvf genesis-v0.2.1-linux-amd64.tar.gz

ADD . /src/netstats
RUN cd /src/netstats && npm install && grunt && grunt build
RUN cd /src/netstats && make && go build -o /tmp/netstats ./cmd/netstats


# Pull all binaries into a second stage deploy alpine container
FROM alpine:latest

RUN apk add --no-cache ca-certificates
COPY --from=builder /tmp/netstats /usr/local/bin/netstats

WORKDIR /netstats

# Pull MaxMind city database.
RUN wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz \
	&& tar zxvf GeoLite2-City.tar.gz \
	&& mv GeoLite2-City_*/GeoLite2-City.mmdb . \
	&& rm -rf GeoLite2-City_*

CMD ["netstats", "-geodb", "GeoLite2-City.mmdb"]
