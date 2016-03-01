%make a sparse labeling of objects in the scene
%
%move through all the images in the scene, and choose points to label
%the idea is to feed this data to another script, which will find all the images
%that see each of the points labeled with this script. So only a few points per object are 
%needed, then all other images that see that object can be found with another script



%usage: 1) make 'room_name' be the parent of rgb/, where rgb/ holds all the images you might label
%
%	2) click a point on an image
%	3) type: 
%		a label - this will be stored with the point, to be saved later
%		q  - to quit and save labels so far
%		n - go to the next image
%		p - go to the previous image
%		m - move some number of images, 
%			enter the number of images after typing 'm' and hitting enter once
%		f - move foward 50 images
%		g - move forward 100 images
%
%


init;

density = 1;

scene_name = 'SN208';
%kinect_to_use = '1';


%should be 1
step_size = int16(1);%dont make this a multiple of 3 or 24 or 25
label_box_size = 10;


%where to get the images from
scene_path = fullfile(BASE_PATH, scene_name);
if(density)
    scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
end
%where to write our output to
write_path = fullfile(scene_path, LABELING_DIR, DATA_FOR_LABELING_DIR);

%create the directory
mkdir(write_path);

%find out how many files exist there
%write_dir = dir(write_path);

%just to make sure we don't overwrite previous lableings
%write_index = length(write_dir)-2;


%file_name = ['points_labels_' num2str(write_index) '.txt'];
%file_name = ['points_labels_' num2str(write_index) '.txt'];

%holds the points the user clicked on in world coordinates.
points = cell(1,1);
labels = cell(1,1);
images_used = cell(1,1);
%num_points = 1;

%load the images
%[rgb_images image_names] = readImages([images_path 'rgb/'], step_size); 
files = dir(fullfile(scene_path,RGB_IMAGES_DIR));
files = files(3:end);

%sort the image file names by time
[~,index] = sortrows({files.date}.'); 
files = files(index); 
clear index;

%load the images
image_names = cell(1,length(files)/step_size);

for i=1:step_size:length(files)
  if(step_size > 1)
    index = floor(i/step_size) + 1;
  else
      index = i;
  end
  image_names{index} = files(i).name;
end%for i files


total_images = num2str(length(image_names));

quit = 0;
image_counter = 1;
point_counter = 1;
while image_counter <= length(image_names)
  rgb_name =  image_names{image_counter};
  
  if(rgb_name(8) ~= kinect_to_use)
      image_counter = image_counter+1; 
      continue;
  end
  
  suffix_index = strfind(rgb_name,'b') + 1;
  
  rgb_image = imread(fullfile(scene_path,RGB_IMAGES_DIR,rgb_name));
%   depth_image = imread(fullfile(scene_path, RAW_DEPTH_IMAGES_DIR, ... 
%                        strcat(rgb_name(1:8),'03.png') ));

  if(exist(fullfile(scene_path, 'filled_depth',strcat(rgb_name(1:8),'04.png') ),'file'))
    depth_image = imread(fullfile(scene_path, 'filled_depth', ... 
                       strcat(rgb_name(1:8),'04.png') ));
  else
    depth_image = imread(fullfile(scene_path, 'raw_depth', ... 
                       strcat(rgb_name(1:8),'03.png') ));
  end
    
  %get one point from the user clicking on the image
  %points{point_counter} = readPoints(rgb_images{image_counter},1);
  %points{point_counter} = readPoints(rgb_image,1);
  
  imshow(rgb_image);     % display image
  hold on;           % and keep it there while we plot
  h = imagesc(depth_image);
  set(h,'AlphaData',.5);

  title(rgb_name);
  [xi, yi, but] = ginput(1);
  x = floor(xi);
  y = floor(yi);
  try
    points{point_counter} = [x y depth_image(y,x)];
  catch ME
        breakp =1;
  end
  hold off;
  
  images_used{point_counter} = image_names{image_counter};
  labels{point_counter} = input(['Enter object label(h for help)(' num2str(image_counter) '/' total_images '):'], 's');

  %add the amera position to get world coordinates 
  %world_points{num_points} = point_3d + camera_positions(i); 

  %num_points = num_points +1; 
  if(strcmp(labels{point_counter},''))
      %get rid of last label and point
      points =points(1:end-1);
      images_used = images_used(1:end-1);
      labels = labels(1:end-1);
  elseif(strcmp(labels{point_counter}, 'q'))
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
  elseif(strcmp(labels{point_counter},'f'))
      %num_to_move = input('How many images to move: ', 's');
      num_to_move = 50;
      
      %get rid of last point, go back to previous next image
      points =points(1:end-1);
      images_used = images_used(1:end-1);
      labels = labels(1:end-1);
      point_counter = point_counter -1;
      
      image_counter = image_counter + num_to_move;
  elseif(strcmp(labels{point_counter},'g'))
      %num_to_move = input('How many images to move: ', 's');
      num_to_move = 100;
      
      %get rid of last point, go back to previous next image
      points =points(1:end-1);
      images_used = images_used(1:end-1);
      labels = labels(1:end-1);
      point_counter = point_counter -1;
      
      image_counter = image_counter + num_to_move;
  elseif(strcmp(labels{point_counter},'b'))
      %num_to_move = input('How many images to move: ', 's');
      num_to_move = 20;
      
      %get rid of last point, go back to previous next image
      points =points(1:end-1);
      images_used = images_used(1:end-1);
      labels = labels(1:end-1);
      point_counter = point_counter -1;
      
      image_counter = image_counter + num_to_move;
  elseif(strcmp(labels{point_counter},'v'))
      %num_to_move = input('How many images to move: ', 's');
      num_to_move = 10;
      
      %get rid of last point, go back to previous next image
      points =points(1:end-1);
      images_used = images_used(1:end-1);
      labels = labels(1:end-1);
      point_counter = point_counter -1;
      
      image_counter = image_counter + num_to_move;
  elseif(strcmp(labels{point_counter},'h'))
	disp('help: ');

	disp('1) click a point on an image ');
	disp('2) type: ');
	disp('	a label - this will be stored with the point, to be saved later ');
	disp('	q  - to quit and save labels so far ');
	disp('	n - go to the next image ');
	disp('	p - go to the previous image  ');
	disp('	m - move some number of images,  ');
	disp('		enter the number of images after typing m  and hitting enter once ');
	disp('	f - move foward 50 images ');
	disp('	g - move forward 100 images ');
	

  elseif(~exist(fullfile('/playpen/ammirato/Data/BigBIRD/',labels{point_counter}),'dir'))
      
    breakp = 1;
    %first draw the label dot
    x_dot_min = max(1,x - label_box_size/2);
    x_dot_max = min(size(rgb_image,2),x + label_box_size/2);
    y_dot_min = max(1,y - label_box_size/2);
    y_dot_max = min(size(rgb_image,1),y + label_box_size/2);


    temp =  rgb_image(y_dot_min:y_dot_max,x_dot_min:x_dot_max,1);
    rgb_image(y_dot_min:y_dot_max,x_dot_min:x_dot_max,1) = 255*ones(size(temp));
    rgb_image(y_dot_min:y_dot_max,x_dot_min:x_dot_max,2) = zeros(size(temp));
    rgb_image(y_dot_min:y_dot_max,x_dot_min:x_dot_max,3) = zeros(size(temp));
    
    imwrite(rgb_image,fullfile('/home/ammirato/Pictures/',strcat(labels{point_counter},'.jpg')));
  end
  point_counter = point_counter +1;
end%for i images

close all;

header = 1;
if(exist(fullfile(write_path ,ALL_LABELED_POINTS_FILE),'file'))
    header = 0;
end
    
    
%write the coordinates of the points to a text file
% if(exist(fullfile(write_path ,ALL_LABELED_POINTS_FILE),'file'))
%     fid = fopen(fullfile(write_path ,'labelded_points_to_add.txt'), 'wt');
% else
    fid = fopen(fullfile(write_path ,ALL_LABELED_POINTS_FILE), 'at');
% end

if(header)
    fprintf(fid, ['%%Points of interest in images, two lines per point' '\n' ...
             '%%IMAGE_FILE_NAME X Y DEPTH' '\n' ...
             '%%OBJECT_LABEL' '\n' ]);
end   

for i=1:length(points)
  cur_point = points{i};
  if(length(cur_point) <2)%something wrong with point
      continue;
  end
  
  %TODO  MAKE 4 DIGITS PAST DECIMAL
  fprintf(fid, [images_used{i} ' ' ... 
                num2str(cur_point(1)) ' ' ...
                num2str(cur_point(2)) ' ' ... 
                num2str(cur_point(3)) '\n' ... 
                 labels{i} '\n']);
end%for i points
%fprintf(fid, '\n');
fclose(fid);



