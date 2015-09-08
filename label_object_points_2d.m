%hopefully get some 3D points in world coordinates that the user
%labels as part of an object, so we can later find all the images
%that see those 3D points, and thus see the object


%this would hange for evey object
room_name = 'kitchenette2';
file_name = [room_name 'points_labels.txt']

%where to get the images from
images_path = ['/home/ammirato/Data/' room_name '/'];
%where to write our output to
write_path = ['/home/ammirato/Data/object_points/' room_name '/'];
mkdir(write_path);

%holds the points the user clicked on in world coordinates.
points = cell(1,1);
labels = cell(1,1);
images_used = cell(1,1);
%num_points = 1;

%load the images
[rgb_images image_names] = readImages([images_path 'rgb/'], 10); 

quit = 0;
image_counter = 1;
point_counter = 1;
while image_counter <= length(rgb_images)

  %get one point from the user clicking on the image
  points{point_counter} = readPoints(rgb_images{image_counter},1);
  images_used{point_counter} = image_names{image_counter};
  labels{point_counter} = input('Enter object label(q to quit):', 's');

  %add the amera position to get world coordinates 
  %world_points{num_points} = point_3d + camera_positions(i); 

  %num_points = num_points +1; 
  if(strcmp(labels{point_counter}, 'q'))
      disp('ending...');
      %get rid of that last point
      points =points(1:end-1);
      images_used = images_used(1:end-1);
      labels = labels(1:end-1);
      point_counter = point_counter -1;
      break;
  elseif(strcmp(labels{point_counter},'n'))
      %get rid of last point, move to next image
      points =points(1:end-1);
      images_used = images_used(1:end-1);
      labels = labels(1:end-1);
      point_counter = point_counter -1;
      
      image_counter = image_counter+1;   
  elseif(strcmp(labels{point_counter},'p'))
      %get rid of last point, go back to previous next image
      points =points(1:end-1);
      images_used = images_used(1:end-1);
      labels = labels(1:end-1);
      point_counter = point_counter -1;
      
      image_counter = image_counter-1;
  elseif(strcmp(labels{point_counter},'m'))
      num_to_move = input('How many images to move: ', 's');
      num_to_move = str2num(num_to_move);
      
      %get rid of last point, go back to previous next image
      points =points(1:end-1);
      images_used = images_used(1:end-1);
      labels = labels(1:end-1);
      point_counter = point_counter -1;
      
      image_counter = image_counter + num_to_move;
  %else
     %done move to next image
   %   i = i-1;
  end
  point_counter = point_counter +1;
end%for i images

close all;

%write the coordinates of the points to a text file
fid = fopen([write_path file_name], 'wt');

fprintf(fid, ['%%Points of interest in images, two lines per point' '\n' ...
             '%%IMAGE_FILE_NAME X Y' '\n' ...
             '%%OBJECT_LABEL' '\n' ]);
             

for i=1:length(points)
  cur_point = points{i};
  fprintf(fid, [images_used{i} ' ' ... 
                num2str(cur_point(1)) ' ' ...
                num2str(cur_point(2)) '\n' ... 
                 labels{i} '\n']);
end%for i points

fclose(fid);



