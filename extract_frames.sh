#!/bin/sh

extract_frames() {
  NO_OF_FRAMES=30
  DURATION=$(ffprobe -v error -show_entries format=duration -sexagesimal -of default=noprint_wrappers=1:nokey=1 "$1")
  HOUR=$(echo $DURATION | cut -d ':' -f 1)
  MIN=$(echo $DURATION | cut -d ':' -f 2)
  SEC=$(echo $DURATION | cut -d ':' -f 3 | cut -d '.' -f 1)
  for s in $(shuf -i 0-$SEC -n$NO_OF_FRAMES)
  do
    m=$(shuf -i 0-$MIN -n1)
    h=$(shuf -i 0-$HOUR -n1)
    time=$(printf "%02d:%02d:%02d" $h $m $s)   
    echo $time
  done
}

time=$(extract_frames "$1" | sort)
echo $time

for TIME in $time
do
  name=$(echo $TIME | tr ":" "_")
  ffmpeg -ss $TIME -i "$1" -update true -frames:v 1 "$1_$name.jpg"
done
