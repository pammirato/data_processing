This directory contains scripts for preparing a set of images to be labeled 
with the [image_vatic tool](https://github.com/pammirato/image_vatic).

TODO  - make everything work for a subset of the instances, so more can be added


For a single scene(set of images), use the following **procedure**:

1. run **sparse-object-point-labeling** for the scene
1. run **find-images-that-see-point** for the scene
1. make sure the scene has JPG images
  * if there are not JPG images, run **compress** in bash scripts folder
1. run **gather-reference-images** for the scene
1. edit the reference images (maybe crop image and draw bounding box)
  * this should eventually be added to gather reference images script
1. run **gather-images-for-vatic** for the scene
1. upload the gathered directories/images to the server with vatic
1. **format**, **load**, and **publish**, the images using vatic









