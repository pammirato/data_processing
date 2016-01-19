#!/bin/bash



for i in $(ls $1); do
  ./compress.sh $1/$i/"rgb/" $1/$i/"jpg_rgb/"
done
