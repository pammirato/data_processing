#!/bin/bash

ALL_DATA_PATH="/playpen/ammirato/Data/RohitData/"

RGB="/rgb"
UNREG="/unreg_depth"
RAW="/raw_depth"

TAR_DIR="tar_files"

TAR_EXTENSION=".tar"

RGB_FILENAME="rgb.tar"
HIGH_RES_FILENAME="high_res_depth.tar"
RAW_FILENAME="raw_depth.tar"

function scp_dir {

#  sshpass -p 'asd123$%^QWE' scp $1/$RGB_FILENAME bvisionserver1:/playpen2/ammirato/data/RohitData/$2/
  #sshpass -p 'asd123$%^QWE' scp $1/$HIGH_RES_FILENAME bvisionserver1:/playpen2/ammirato/data/RohitData/$2/
  sshpass -p 'asd123$%^QWE' scp $1/$RAW_FILENAME bvisionserver1:/playpen2/ammirato/data/RohitData/$2/

  #sshpass -p 'asd123$%^QWE' scp $1/$TAR_DIR/$RGB_FILENAME bvisionserver1:/playpen2/ammirato/data/RohitData/$2"_"$RGB_FILENAME
}



#for each room
for i in $(ls $ALL_DATA_PATH); do
  
  echo $i
  scp_dir $ALL_DATA_PATH$i $i

done





