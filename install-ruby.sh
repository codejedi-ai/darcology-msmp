#!/bin/bash
APP_NAME="infra-coop-takehome"
HOME="/root"
wget https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.2.tar.bz2 &&\
tar -xf ruby-2.7.2.tar.bz2
cd ruby-2.7.2 && ./configure --prefix=/my/ruby/dir && make && make install
#export PATH="/my/ruby/dir/bin:${PATH}"
