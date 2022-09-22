#
# Ubuntu Dockerfile
#
# https://github.com/dockerfile/ubuntu
#

# Pull base image.
FROM ubuntu:18.04
ARG APP_NAME=infra-coop-takehome
ARG RUBY_VERSION=ruby-2.7.2
# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list &&\
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential openssl libssl-dev zlib1g-dev libsqlite3-dev&& \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu curl git htop man unzip vim wget openssl libffi-dev &&\
  rm -rf /var/lib/apt/lists/*

#RUN \
#  wget https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.2.tar.bz2 &&\
#  tar -xf ruby-2.7.2.tar.bz2

COPY install-ruby.sh ./
RUN chmod +x install-ruby.sh
RUN ./install-ruby.sh

# Set environment variables.
EXPOSE 5000


ENV HOME /root
# Define working directory.
WORKDIR /root

COPY ${APP_NAME}/ ./${APP_NAME}/


ENV PATH="/my/ruby/dir/bin:${PATH}"
COPY install-app.sh ./
RUN chmod +x install-app.sh
RUN ./install-app.sh

COPY start-app.sh ./
RUN chmod +x start-app.sh


# Define default command.
CMD ["./start-app.sh"]
