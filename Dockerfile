FROM ruby:2.3.1
MAINTAINER Kevin Reedy <kreedy@chef.io>

RUN apt-get update && apt-get install -y fakeroot

ADD . /opt/chefdk-build

WORKDIR /opt/chefdk-build/omnibus
RUN bundle install --without development
RUN git config --global user.email "nobody@chef.io" && git config --global user.name "Chef"
RUN bundle exec omnibus build chefdk && bundle exec omnibus clean chefdk

WORKDIR /root
RUN echo 'eval "$(/opt/chefdk/bin/chef shell-init bash)"' >> /root/.bashrc
CMD /bin/bash
