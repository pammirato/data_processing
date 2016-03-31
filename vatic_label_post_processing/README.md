This directory has files for post processing bounding boxes obtained
from image labeling tool [image_vatic](https://github.com/pammirato/image_vatic).
_It is assumed the images were pre-processed using the scripts in the 
vatic-preprocessing directory_



TODO  - make everything work for a subset of the instances, so more can be added

 
For a single scene(set of images), use the following **procedure**:

1. get the .mat files from vatic _dump_ 
1. put the .mat files in SCENE/labels/bounding-boxes-by-instance/
1. run **remove-reference-images-from-boxes-by-instance** for the scene
1. run **change-vatic-label-frame-names** for the scene
1. run **combine-instance-vatic-outputs** for the scene
1. run **transform-vatic-output** for the scene
1. run **convert-vatic-output-to-final-format** for the scene
1. run **convert-boxes-by-instance-to-boxes-by-image** for the scene
1. run **interpolate-boxes** for the scene
  * this may output images that need to be labeled in order to complete interpolation
  * label these images using **vis-bounding-boxes** in _visualizations_ directory
  * if these images do not actually have the instance, use **vis-images-that-see-label** in _visualizations_ directory to double check and remove them.

  
