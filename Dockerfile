FROM ruby:alpine
MAINTAINER insertEFFECT <info@inserteffect.com>

COPY cleanup.rb /usr/local/bin/docker-registry-cleanup

ENTRYPOINT docker-registry-cleanup
