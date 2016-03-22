For processing the output of the colmap reconstruction tool.


Sets up data structures, most important being image-structs, that a lot of other scripts use.





After collecting RGB-D data, use the follow **procedure** to process the images for further use:



1. Run the RGB image with the **colmap** reconstruction tool. 
1. Run **save-image-structs** script for the scene
1. Run **save-points3d** script for the scene
1. Run **scale-reconstruction** script for the scene




It is **very important to scale the reconstruction**, because the initial
output from colmap is in arbitrary units.


There should be no need to tune any parameters in these scripts.
Each should have detailed comments to explain how they work.

