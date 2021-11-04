#!/bin/bash
set -e

# Load App Envs
source ./.env

# Get Airflow Deployment Scripts.
cd ..
git clone --single-branch --branch main https://github.com/tulibraries/ansible-playbook-airflow.git
cd ansible-playbook-airflow

# Install requirements
sudo pip install pipenv
pipenv install
pipenv run ansible-galaxy install -r requirements.yml # install playbook role requirements
echo $ANSIBLE_VAULT_PASSWORD > ~/.vault

# Run
pipenv run ansible-playbook -i inventory/prod tul_cob.yml --private-key=~/.ssh/conan_the_deployer -e collection_name=$CATALOG_COLLECTION
