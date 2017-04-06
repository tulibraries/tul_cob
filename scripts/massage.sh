#!/bin/bash

# Takes single argument og

PATH_TO_MARCXMLS=$1
NUM_PROCESSES=`grep -c ^processor /proc/cpuinfo`

find $PATH_TO_MARCXMLS -name "*.xml"| xargs -t -n 1 -P 4 sed -i "s~<collection><record>~<collection xmlns=\"http://www.loc.gov/MARC21/slim\"><record>~"

exit $?