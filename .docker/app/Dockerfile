FROM ruby:2.7.2-alpine3.13 as production
RUN apk --update add nodejs yarn git build-base bash  mysql-dev sqlite-dev tzdata less shared-mime-info
RUN mkdir /app
WORKDIR /app
COPY . .
RUN bundle install
RUN yarn
CMD ["bash"]

FROM production as development
RUN apk --update add vim
