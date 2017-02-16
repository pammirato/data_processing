#!/bin/bash

#usage:  ./compress.sh parent/
#
# compress all .png images in parent/rgb/ and saves the 
# compressed images in parent/jpg_rgb/


input_dir=$1/"high_res_depth"/
output_dir=$2/"compressed_high_res_depth"/

mkdir -p $output_dir

for image in $(ls $input_dir); do
  /playpen/ammirato/installed_stuff/optipng-0.7.6/src/optipng/optipng $input_dir$image -dir $output_dir
done



input_dir=$3/"high_res_depth"/
output_dir=$4/"compressed_high_res_depth"/

mkdir -p $output_dir

for image in $(ls $input_dir); do
  /playpen/ammirato/installed_stuff/optipng-0.7.6/src/optipng/optipng $input_dir$image -dir $output_dir
done



input_dir=$5/"high_res_depth"/
output_dir=$6/"compressed_high_res_depth"/

mkdir -p $output_dir

for image in $(ls $input_dir); do
  /playpen/ammirato/installed_stuff/optipng-0.7.6/src/optipng/optipng $input_dir$image -dir $output_dir
done
