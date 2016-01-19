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

rm -rf $2
mkdir -p $2


for image in $(ls $1); do
  convert -compress JPEG $1$image $2${image/png/jpg} 
done

#for image in $(ls $1); do
#  convert -compress Zip $1$image $2$image 
#done
