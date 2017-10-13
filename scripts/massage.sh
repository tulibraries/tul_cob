#!/bin/bash

# Takes single argument - path to the xml files you want to transform

PATH_TO_MARCXMLS=$1

if  [ -f /proc/cpufinfo ]; then
  NUM_PROCESSES=`grep -c ^processor /proc/cpuinfo`
else
  NUM_PROCESSES=1
fi

find $PATH_TO_MARCXMLS -name "*.xml"| xargs -t -n 1 -P $NUM_PROCESSES sed -i '' "s~<collection><record>~<collection xmlns=\"http://www.loc.gov/MARC21/slim\"><record>~"

exit $?
