#!/bin/bash
set -e

cd ..
git clone --single-branch --branch qa git@github.com:tulibraries/tul_cob_playbook.git # clone deployment playbook
cd tul_cob_playbook
sudo pip install pipenv # install playbook requirements
pipenv install # install playbook requirements
pipenv run ansible-galaxy install -r requirements.yml # install playbook role requirements
echo $ANSIBLE_VAULT_PASSWORD > ~/.vault

# deploy to qa using ansible-playbook
pipenv run ansible-playbook -i inventory/qa playbook.yml --vault-password-file=~/.vault -e 'ansible_ssh_port=9229' --private-key=~/.ssh/.conan_the_deployer --limit=app -e rails_app_git_branch=main -vv
echo "BE AWARE THAT SOLR CONFIG CHANGES WERE NOT DEPLOYED AS PART OF THIS BUILD"
