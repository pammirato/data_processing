#!/bin/bash


#ORG_PATH="/home/ammirato/old_Data/";

#COMPRESS_PATH="/home/ammirato/Data/";

#ROOM_NAME="FB341_2";

JPG=".jpg";
SLASH="/";


#${filename/str*./operations.}

#for image in $(ls $ORG_PATH$ROOM_NAME); do
#  convert -compress Zip $ORG_PATH$ROOM_NAME$image $COMPRESS_PATH$ROOM_NAME$image 
#done

input_dir=$1/"rgb"/
output_dir=$1/"jpg_rgb"/

rm -rf $output_dir
mkdir -p $output_dir



for image in $(ls $input_dir); do
  convert -compress JPEG $input_dir$image $output_dir${image/png/jpg} 
done

#for image in $(ls $1); do
#  convert -compress Zip $1$image $2$image 
#done
