FROM debian:buster

LABEL version="0.0.3"
LABEL maintainer="Francesco Bianco <info@javanile.org>"

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates git zip unzip openssh-client curl wget gettext && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

COPY fork.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/fork.sh

WORKDIR /app

RUN git config --global credential.helper cache && \
    git config --global credential.helper 'store --file /app/.git/credentials'

CMD ["fork.sh"]
