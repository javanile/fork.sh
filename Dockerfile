FROM debian:stretch

LABEL version='0.0.3'
LABEL maintainer='Francesco Bianco <info@javanile.org>'

COPY fork.sh /usr/local/bin/

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates git ftp zip unzip openssh-client ftp-upload curl wget \
 && apt-get clean \
 && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* \
 && cd /usr/local/bin \
 && chmod +x entrypoint cat-version \
 && mkdir -p /app

WORKDIR /app

CMD ["fork.sh"]
