FROM ruby:2.5.7
MAINTAINER "Jerry Zhang" jerry.zhang@datoms.cn 

WORKDIR /usr/src/app
ENV RAILS_ROOT $WORKDIR
RUN mkdir -p $RAILS_ROOT/tmp/pids && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
  		libsodium-dev \
		build-essential && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY Gemfile $WORKDIR

RUN bundle install

COPY . .

RUN bundle update && \
	ln -s $PWD/script/init.sh /bin/init.sh

CMD ["./script/run.sh"]

EXPOSE 3000
