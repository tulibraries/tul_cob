#!/bin/bash

# Takes single argument - path to the xml files you want to transform

case "$OSTYPE" in
  darwin*)  SEDTYPE="BSD" ;; 
  bsd*)     SEDTYPE="BSD" ;;
  linux*)   SEDTYPE="LINUX" ;;
  *)        SEDTYPE="LINUX" ;;
esac


PATH_TO_MARCXMLS=$1

if  [ -f /proc/cpufinfo ]; then
  NUM_PROCESSES=`grep -c ^processor /proc/cpuinfo`
else
  NUM_PROCESSES=1
fi

if [[ $SEDTYPE == "BSD" ]]; then
  find $PATH_TO_MARCXMLS -name "*.xml"| xargs -t -n 1 -P $NUM_PROCESSES sed -i '' "s~<collection><record>~<collection xmlns=\"http://www.loc.gov/MARC21/slim\"><record>~"
fi

if [[ $SEDTYPE == "LINUX" ]]; then
  find $PATH_TO_MARCXMLS -name "*.xml"| xargs -t -n 1 -P $NUM_PROCESSES sed -i "s~<collection><record>~<collection xmlns=\"http://www.loc.gov/MARC21/slim\"><record>~"
fi

exit $?
