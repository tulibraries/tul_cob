#!/bin/bash
set -e

cd ..
git clone --single-branch --branch qa git@github.com:tulibraries/tul_cob_playbook.git # clone deployment playbook
cd tul_cob_playbook
sudo pip install pipenv # install playbook requirements
pipenv install # install playbook requirements
pipenv run ansible-galaxy install -r requirements.yml # install playbook role requirements
cp .circleci/.vault ~/.vault # setup vault password retrieval from travis envvar
chmod +x ~/.vault  # setup vault password retrieval from travis envvar

# deploy to qa using ansible-playbook
pipenv run ansible-playbook -i inventory/qa/hosts playbook.yml --vault-password-file=~/.vault -e 'ansible_ssh_port=9229' --private-key=~/.ssh/.conan_the_deployer
