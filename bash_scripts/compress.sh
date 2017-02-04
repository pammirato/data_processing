#!/bin/bash

#usage:  ./compress.sh parent/
#
# compress all .png images in parent/rgb/ and saves the 
# compressed images in parent/jpg_rgb/


input_dir=$1/"rgb"/
output_dir=$1/"jpg_rgb"/

rm -rf $output_dir
mkdir -p $output_dir

for image in $(ls $input_dir); do
  convert -compress JPEG $input_dir$image $output_dir${image/png/jpg} 
done

