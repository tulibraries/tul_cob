FROM ruby:2.6.5-alpine3.11
RUN apk --update add nodejs yarn git build-base bash  mysql-dev sqlite-dev tzdata
RUN mkdir /app
WORKDIR /app
COPY . .
RUN ls config/*example | xargs -I{} echo {} |  cut -d '.' -f-2 | xargs -I{} cp {}.example {}
CMD ["bash"]
