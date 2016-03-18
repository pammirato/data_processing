This directory contains scripts for preparing a set of images to be labeled 
with the [image_vatic tool](https://github.com/pammirato/image_vatic).


For a single scene(set of images), use the following **procedure**:
(a detailed description of each file will follow)


1. run _sparse-object-point-labeling_ for the scene
1. run _find-images-that-see-point_ for the scene
1. make sure the scene has JPG imagesa
  .. if there are not JPG images, run _compress_ in bash scripts folder
1. run _gather-reference-images_ for the scene
1. edit the reference images (maybe crop image and draw bounding box)
  .. this should eventually be added to gather reference images script
1. run _gather-images-for-vatic_ for the scene
1. upload the gathered directories/images to the server with vatic
1. _format_, _load_, and _publish_, the images using vatic

