FROM ruby:2.4.1 as production
RUN \
      wget -qO- https://deb.nodesource.com/setup_9.x | bash - && \
      wget -qO- https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
      echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
      apt-get update -qq && \
      apt-get install -y --force-yes --no-install-recommends \
      nodejs yarn build-essential libpq-dev
RUN mkdir /app
WORKDIR /app
ADD Gemfile .
ADD Gemfile.lock .
RUN bundle install
COPY . .

FROM production as development
RUN apt-get update -qq \
      && apt-get install -y vim ctags tmux \
      && apt-get clean \
      && cd; wget -qO - https://raw.github.com/dkinzer/.vim/master/deploy.sh | bash
ADD Gemfile .
ADD Gemfile.lock .
RUN bundle install
WORKDIR /app
CMD ["bash"]
