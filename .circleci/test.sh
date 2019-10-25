#!/usr/bin/env bash

# Not sure why yarn is not accessible here after adding to build step.
curl -o- -L https://yarnpkg.com/install.sh | bash
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

bundle exec rubocop
RELEVANCE=y bundle exec rake ci
yarn test
