FROM ruby:3.2-alpine as production
RUN apk --update add nodejs yarn git build-base bash  mysql-dev sqlite-dev tzdata less shared-mime-info
RUN mkdir /app
WORKDIR /app
COPY . .
RUN bundle install
RUN yarn
CMD ["bash"]

FROM production as development
RUN apk --update add vim
