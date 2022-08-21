FROM alpine:latest

RUN apk add --no-cache bash build-base git openssh ruby ruby-dev supervisor thttpd \
    && gem install bundler
RUN adduser --disabled-password --uid=1000 --shell=/usr/bin/git-shell jekyll \
    && passwd -d jekyll
RUN rm /etc/motd

COPY ./files/sshd_config /etc/ssh/sshd_config
COPY ./files/supervisord.conf /etc/supervisord.conf
COPY ./files/thttpd.conf /etc/thttpd.conf
COPY ./files/jekyll-post-receive.sh /libexec/jekyll-post-receive.sh
COPY ./files/start.sh /libexec/start.sh

USER root
CMD ["/libexec/start.sh"]
