FROM debian:stable-slim

RUN apt-get update \
    && apt-get upgrade --yes  \
    && apt-get install --yes --no-install-recommends build-essential git openssh-server ruby ruby-dev supervisor nginx \
    && apt-get autoremove \
    && apt-get clean
RUN gem install bundler

RUN adduser --disabled-password --uid=10000 --shell=/usr/bin/git-shell jekyll \
    && passwd -d jekyll
RUN rm /etc/motd

COPY ./files/sshd_config /etc/ssh/sshd_config
COPY ./files/supervisord.conf /etc/supervisord.conf
COPY ./files/nginx.conf /etc/nginx/nginx.conf
COPY ./files/jekyll-post-receive.sh /libexec/jekyll-post-receive.sh
COPY ./files/start.sh /libexec/start.sh

USER root
CMD ["/libexec/start.sh"]
