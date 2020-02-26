FROM ruby:2.6.5-alpine3.11 as production
RUN apk --update add nodejs yarn git build-base bash  mysql-dev sqlite-dev tzdata
RUN mkdir /app
WORKDIR /app
COPY . .
RUN bundle install
CMD ["bash"]

FROM production as development
RUN apk --update add vim ctags tmux \
      && cd; wget -qO - https://raw.github.com/dkinzer/.vim/master/deploy.sh | bash
