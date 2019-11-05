#!/usr/bin/env bash

# Not sure why yarn is not accessible here after adding to build step.
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

if [ -z "$(which yarn)" ]; then
  curl -o- -L https://yarnpkg.com/install.sh | bash
fi

bundle exec rubocop
RELEVANCE=y bundle exec rake ci
yarn test
