#!/bin/sh

extract_frames_v2() {
  ALL_FRAMES=$(ffprobe -select_streams v -show_streams "$1" 2>/dev/null | grep nb_frames | sed -e 's/nb_frames=//')
  for s in $(shuf -i 0-$ALL_FRAMES -n$2)
  do
    echo $s
  done
}

frames=$(extract_frames_v2 "$1" $2 | sort)
echo $frames

for frame in $frames
do
  ffmpeg -i "$1" -vf "select=eq(n\,$frame)" -vframes 1 "$1_$name_$frame.jpg"
done
