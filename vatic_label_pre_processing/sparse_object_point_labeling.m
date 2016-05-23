%make a sparse labeling of objects in the scene
%
%move through all the images in the scene, and choose points to label
%the idea is to feed this data to another script, which will find all the images
%that see each of the points labeled with this script. So only a few points per object are 
%needed, then all other images that see that object can be found with another script


%TODO  - get rid of text files


%initialize contants, paths and file names, etc. 
init;


%%USER OPTIONS

scene_name = 'FB341';
%kinect_to_use = '1';

%how big to draw label dot(box) on image
label_box_size = 10;


%% set scene specific data structures

%where to get the images from
scene_path = fullfile(ROHIT_BASE_PATH, scene_name);
meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

%where to write our output to
write_path = fullfile(meta_path, LABELING_DIR, DATA_FOR_LABELING_DIR);

%create the directory if it doesn't exist
mkdir(write_path);

%holds the points the user clicked on in world coordinates.
points = cell(0);
labels = cell(0);
images_used = cell(0);

%get the names of all the images in the scene
image_names = get_names_of_X_for_scene(scene_name,'rgb_images');

%index of image name to show
cur_image_index = 1;
%inputted label or command to move to another image
move_commmand  = '';
while cur_image_index <= length(image_names)
  rgb_name =  image_names{cur_image_index};
  
  %load the rgb and depth image 
  rgb_image = imread(fullfile(scene_path,RGB,rgb_name));
  depth_image = imread(fullfile(scene_path, HIGH_RES_DEPTH, ... 
                        strcat(rgb_name(1:8),'03.png') ));
    
 
  %display depth image overlayed onto rgb image 
  imshow(rgb_image);     % display image
  hold on;           % and keep it there while we plot
  h = imagesc(depth_image);
  set(h,'AlphaData',.5);
  title(rgb_name);

  %get the user click
  [xi, yi, but] = ginput(1);
  x = floor(xi);
  y = floor(yi);
  try%make sure the point is in the image, and depth > 0
    if(depth_image(y,x) == 0)
      disp('ZERO DEPTH');
      %continue;
    end
  catch 
  end
  hold off;
  
  move_command = input(strcat('Enter object label(h for help)(', ...
                         num2str(cur_image_index), '/', num2str(length(image_names)), ...
                           '):'), 's');
  

  if(strcmp(move_command,''))
    %if nothing was inputted do nothing, and prompt again
    continue;
  elseif(strcmp(move_command, 'q'))
      disp('ending...');
      break;
  elseif(strcmp(move_command,'n')) %move to next image
      cur_image_index = cur_image_index+1;   
  elseif(strcmp(move_command,'p')) %previous image
      cur_image_index = cur_image_index-1;
  elseif(strcmp(move_command,'m')) %move X images
      num_to_move = input('How many images to move: ', 's');
      num_to_move = str2num(num_to_move);
      cur_image_index = cur_image_index + num_to_move;
  elseif(strcmp(move_command,'f'))
      num_to_move = 50;
      cur_image_index = cur_image_index + num_to_move;
  elseif(strcmp(move_command,'g'))
      num_to_move = 100;
      cur_image_index = cur_image_index + num_to_move;
  elseif(strcmp(move_command,'b'))
      num_to_move = 20;
      cur_image_index = cur_image_index + num_to_move;
  elseif(strcmp(move_command,'v'))
      num_to_move = 10;
      cur_image_index = cur_image_index + num_to_move;
  elseif(strcmp(move_command,'h'))
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
    disp('	v - move forward 10 images ');
    disp('	b - move forward 20 images ');
	
  %at this point, the move_commnand must be a label, so store everything
  else
    %store this labeled point, image name, and get a label from the user
    points{end+1} = [x y depth_image(y,x)];
    images_used{end+1} = image_names{cur_image_index};
    labels{end+1} = move_command; 
   end
end%for i images

close all;




%% SAVE ALL THE INPUTTED LABELS
%append the new labeled points to the text file for this scene

%only add a header if this is the first time writing to the file
header = 1;
if(exist(fullfile(write_path ,ALL_LABELED_POINTS_FILE),'file'))
    header = 0;
end
    
%open the file    
fid = fopen(fullfile(write_path ,ALL_LABELED_POINTS_FILE), 'at');

%write the header
if(header)
    fprintf(fid, ['%%Points of interest in images, two lines per point' '\n' ...
             '%%IMAGE_FILE_NAME X Y DEPTH' '\n' ...
             '%%OBJECT_LABEL' '\n' ]);
end   


%write each point, as specifed in the header
for i=1:length(points)
  cur_point = points{i};
  if(length(cur_point) <2)%something wrong with point
      continue;
  end
  
  fprintf(fid, [images_used{i}  ' ' ... 
                num2str(cur_point(1)) ' ' ...
                num2str(cur_point(2)) ' ' ... 
                num2str(cur_point(3)) '\n' ... 
                 labels{i}, '\n']);
end%for i points
fclose(fid);



