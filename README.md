This project contains MATLAB scripts for building and running experiments on our dataset. 
Our dataset is not yet released.


## Setup
Make sure you set all the __BASE-PATH__ variables in **init.m**. More on init.m and our dataset's
directory structure below.

## Building the Data

This section details how we processed and organized our images and labels for the dataset.
This code can be used to add your own images to our data set.


#### Capture

To catpure our data we use a Kinect v2, and collect the RGB and depth streams. 

We use [libfreenect2](https://github.com/OpenKinect/libfreenect2) and our own version of the ROS interface to Kinect, [iai_kinect2](https://github.com/pammirato/iai_kinect2). We also use *iai_kinect2* to compute high resolution(same as RGB) depth images. 


As long as you have RGB images, a high-res depth image that corresponds to each RGB image, and follow the naming conventions you should be good.

##### File naming conventions
Every image file should have 10 digits then an extension.
The first 6 digits are an index, i.e the first 6 digits = i for the ith image.
The next two dgits are the index of the camera that took the image. This is important for loading camera parameters later.
The last two digits determine the type of the file, if the extension is not enough.

Last two digits:

    01 - rgb image
    02 - raw depth image (low res)
    03 - high res depth image
    04 - filled in high res depth image



Examples:

    0001540101.png  - the 154th image from camera 1, RGB
    0001540103.png  - the 154th image from camera 1, High Res Depth
    0001540101.jpg  - the 154th image from camera 1, RGB, jpg compressed
    0003060301.png  - the 306th image from camera 3, RGB
 

#### Reconstruction
We use the RGB Structure from Motion program [Colmap](https://github.com/colmap/colmap). It will be released soon. All that is really needed is the 3D world **position and direction** of the camera for each image. Instructions on using a system other than colmap are coming.



1. Run colmap
1. Follow the instructions in the **reconstruction-post-processing** directory
1. Follow the instructions in the **image-structs-processing** directory




#### Labeling
We provided bounding box labels for various instances in each scene.
 Obtaining thousands of bounding boxes is very time consuming, so we out-source 
the work to [Amazon Mechanical Turk](https://www.mturk.com/mturk/welcome) via the 
[image-vatic](https://github.com/pammirato/image_vatic) tool. 


There are simple, detailed instructions on how to use this tool to annotate your images in this 
project and image-vatic. 

1. Make sure your images are in the format described above
1. Follow the instructions in the **vatic-label-_pre_-processing** directory
1. Follow the instructions in the **vatic-label-_post_-processing** directory






## Experiments
Experiments are not done yet.







##what else is here?
1. **bash-scripts**  - scripts to help process data, and move it around
1. **visualizations**  - ways to visualize data, labels, experiments, etc. 
1. **test.m**  - an empty script for testing code out
1. **file-exchange-helper-functions** - files from [matlab file exchange](http://www.mathworks.com/matlabcentral/fileexchange/)
1. **helper-functions** - functions used in other scripts, never on their own
1. **templates** - templates for starting new files



#### Directory structure and  init.m
This script initializes constants based on the directory structure and file names.

If you download our dataset, you should only need to change the __BASE-PATH__ variables.

1. **ROHIT-BASE-PATH** - full path to the parent directory of all scene's basic data
  * all images(rbg,depth,etc). image-structs.mat, ground truth labels
  * _rgb_: uncompressed .png rgb images (1920x1080)
  * _raw-depth_: raw depth output from Kinect (512x424)
  * _high-res-depth_: raw depth output from Kinect (512x424)
1. **ROHIT-META-BASE-PATH** - full path to the parent directory of all scene's meta data
  * text files from colmap, recognition systems output, anything else
  * _reconstruction-results_
    * text files from colmap: cameras.txt, points.txt,images.txt
1. **BIGBIRD-BASE-PATH** - full path to the parent directory of all BIGBIRD data
  


**Basic Data**:  everything you need to simulate moving around the scene, and test recognition
  * rgb images
  * jpg rgb images
  * raw depth images
  * high res depth images
  * filled depth images
  * labels
  * image-structs
 
**Meta Data**:  everything else
  *


 
