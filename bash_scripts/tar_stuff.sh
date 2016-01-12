#!/bin/bash





for i in $(ls $1); do

  tar -cvf $1/$i'.tar' $1/$i 

done


