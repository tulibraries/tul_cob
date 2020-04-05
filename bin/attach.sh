#!/usr/bin/env bash

if [ -z "$1" ]; then
  app=master_app
else
  app=$1
fi

id=`docker ps | grep $app | cut -d ' ' -f 1`
docker attach $id
