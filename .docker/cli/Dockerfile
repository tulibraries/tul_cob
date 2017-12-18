FROM tulcob_app:latest

RUN apt-get update -qq \
      && apt-get install -y vim ctags tmux \
      && apt-get clean \
      && cd; wget -qO - https://raw.github.com/dkinzer/.vim/master/deploy.sh | bash

WORKDIR /tul_cob

CMD ["bash"]
