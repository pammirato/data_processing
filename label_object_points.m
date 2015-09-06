%hopefully get some 3D points in world coordinates that the user
%labels as part of an object, so we can later find all the images
%that see those 3D points, and thus see the object


%this would hange for evey object
object_name = 'cup';

%where to get the images from
images_path = '/home/ammirato/Data/kitchenette2/camera1/';
%where to write our output to
write_path = '/home/ammirato/object_points/'

%camera paramters
focal_length = .0001;

%holds the points the user clicked on in world coordinates.
world_points = cell(1,1);
num_points = 1;

%load the images
rgb_images = readImages([path 'rgb/']); 
depth_images = readImages([path 'depth/']); 

%would hold the camera positions of each rgb image in world coordinates
%get this similar to the visualize positions file
%though they need to have a scale!!!!!
camera_positions;


for i=1:1%length(images)

  %get one point from the user clicking on the image
  pt = readPoints(rgb_images{i},1);

  %get the depth of that pixel
  depth_image = depth_images{i};
  depth_at_point = depth_image(pt(1,1), pt(2,1));  

  %get the 3D point relative to the camera
  %using pin hole camera model?
  point_3d = camera_to_3d(pt', depth_at_point, focal_length);

  %add the amera position to get world coordinates 
  %world_points{num_points} = point_3d + camera_positions(i); 

  num_points = num_points +1; 
  
 
end%for i images


%write the coordinates of the points to a text file
fid = fopen([write_path object_name], 'w');

for i=1:length(world_points)
  cur_point = world_points{i};
  fwrite(fid, [num2str(cur_point(1,1) ',' ...
               num2str(cur_point(1,2) ',' ...
               num2str(cur_point(1,3)] ); 



end%for i world_points





