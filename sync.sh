#!/bin/bash -e

while inotifywait -r /home/dan/dev/dwtong/algae/*; do
  rsync -avz /home/dan/dev/dwtong/algae ash:/home/we/dust/code/
done
