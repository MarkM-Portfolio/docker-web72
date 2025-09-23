#!/bin/bash

printf "READY\n";

while read line; do
  echo "Processing Event: $line" >&2;
  killall supervisord
done < /dev/stdin

