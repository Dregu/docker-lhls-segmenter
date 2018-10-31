FROM ubuntu:bionic

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends ca-certificates javascript-common git nodejs npm varnish cron && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get -y clean && \
    rm -r /var/lib/apt/lists/*

RUN git clone --branch master --depth 1 https://github.com/dregu/webserver-chunked-growingfiles.git /opt/webserver && \
    cd /opt/webserver && \
    npm install

RUN git clone --branch master --depth 1 https://github.com/dregu/transport-stream-online-segmenter.git /opt/segmenter && \
    cd /opt/segmenter && \
    npm install

COPY varnish.vcl /etc/varnish/default.vcl

COPY clean_media /etc/cron.d/
RUN chmod 0644 /etc/cron.d/clean_media
RUN crontab /etc/cron.d/clean_media

COPY entrypoint.sh /root
RUN chmod +x /root/entrypoint.sh

# varnish port
EXPOSE 6081/tcp

# TS tcp stream inbound
EXPOSE 1234/tcp

# files will go here
VOLUME /media

ENTRYPOINT ["/root/entrypoint.sh"]
