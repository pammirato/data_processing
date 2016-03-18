This project is contains MATLAB scripts for building and running experiments on our dataset. 
Our dataset is not yet released.

## Building the Data

This section details how we processed and organized our images and labels for the dataset.
This code can be used to add your own images to our data set.


### Capture

To catpure our data we use a Kinect v2, and collect the RGB and depth streams. 

We use [libfreenect2](https://github.com/OpenKinect/libfreenect2) and our own version of the ROS interface to Kinect, [iai_kinect2](https://github.com/pammirato/iai_kinect2). We also use *iai_kinect2* to compute high resolution(same as RGB) depth images. 


As long as you have RGB images, a high-res depth image that corresponds to each RGB image, and follow the naming conventions you should be good.

#### File naming conventions
Every image file should have 10 digits then an extension.
The first 6 digits are and index, i.e the first 6 digits = i for the ith image.
The next two images are the index of the camera that took the image. This is important for loading camera parameters later.
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
    0003060301.jpg  - the 306th image from camera 3, RGB,
 

### Reconstruction
We use the RGB Structure from Motion progrma Colmap. It will be released soon. All that is really needed is the 3D world **position and direction** of the camera for each image. Instructions on using a system other than colmap are coming.





### Labeling












 
