#!/bin/bash
set -euo pipefail

source <(grep -E '^CATALOG_COLLECTION=' ./.env)

: "${CATALOG_COLLECTION:?CATALOG_COLLECTION is missing from .env}"

cd ..

git clone --single-branch --branch main git@github.com:tulibraries/ansible-playbook-airflow.git

cd ansible-playbook-airflow

pipenv install
pipenv run ansible-galaxy install -r requirements.yml

printf "%s" "$ANSIBLE_VAULT_PASSWORD" > ~/.vault
chmod 600 ~/.vault

test -s ~/.ssh/conan_the_deployer
ssh-keygen -y -f ~/.ssh/conan_the_deployer > /dev/null
chmod 600 ~/.ssh/conan_the_deployer

unset SSH_AUTH_SOCK
unset SSH_AGENT_PID

pipenv run ansible-playbook -i inventory/prod tul_cob.yml --private-key=~/.ssh/conan_the_deployer -e "collection_name=$CATALOG_COLLECTION"

