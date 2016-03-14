%saves a map from a label (instance) name, to names of all images that 'see'
%the instance in the scene
% takes as input a list of labeled points and image names, such as the 
%output from sparse labeling script



%TODO  - optimize speed
%      - add parameters for other kinects to be loaded
%      - add loading of 'filled' depth images
%      - get rid of text files


%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_Density_1by1'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_to_process = 'chair4'; %make 'all' for every label
occulsion_threshold = 20000;  %make > 12000 to remove occulsion thresholding 

debug =1;

kinect_to_use = 1;

%size of rgb image in pixels
kImageWidth = 1920;
kImageHeight = 1080;



%% SET UP GLOBAL DATA STRUCTURES


%get the names of all the scenes
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};


%determine which scenes are to be processed 
if(use_custom_scenes && ~isempty(custom_scenes_list))
  %if we are using the custom list of scenes
  all_scenes = custom_scenes_list;
elseif(~strcmp(scene_name, 'all'))
  %if not using custom, or all scenes, use the one specified
  all_scenes = {scene_name};
end




%% MAIN LOOP

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


  %get info about camera position for each image
  image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %get a list of all the image file names
  temp = cell2mat(image_structs);
  image_names = {temp.(IMAGE_NAME)};

  %make a map from image name to image_struct
  image_structs_map = containers.Map(image_names, image_structs);



  %get camera parameters for each kinect
  [intrinsic, distortion, rotation, projection] = get_kinect_parameters(1);    


  %this will store the final  result
  label_to_images_that_see_it_map = containers.Map();

  %prompt user to load all the depth images for this scene ahead of time
  %(a good idea if they have not been loaded and more than one instance is to be processed) 
  load_depths = input('Load all depths?(y/n)' , 's');

  %whether the depths get loaded or not
  depths_loaded = 0;

  %load all the depths
  if((load_depths=='y'))

    %get names of all the rgb images in the scene
    image_names = get_names_of_X_for_scene(scene_name,'rgb_images');

    %will hold all the depth images
    depth_images = cell(1,length(d));

    %for each rgb image, load a depth image
    for i=1:length(image_names)
        rgb_name = image_names{i};

        depth_images{i} = imread(fullfile(scene_path, HIGH_RES_DEPTH, ... 
                 strcat(rgb_name(1:8),'03.png') ));
    end% for i, each image name
    
    depth_img_map = containers.Map(image_names, depth_images);
    
    depths_loaded = 1;
  end%if we should load all the depths)


  %if we are told to not load the depths, see if they were already loaded
  if(load_depths == 'n')
    a = input('Are depths loaded?(y/n)' , 's');
    if(a=='y')
      depths_loaded = 1;
    end
  end



  %% PARSE LABELED POINTS FILE

  %get all the 'inputed', labeled points
  %these are points on instances in the scene, as from sparse_labeling script

  %holds what it says 
  labeled_image_names_and_points = cell(0);
  labels = cell(0);

  %open file with labeled points                
  labeled_points_fid = fopen(fullfile(meta_path, LABELING_DIR, ...
                                 DATA_FOR_LABELING_DIR, ALL_LABELED_POINTS_FILE));
                             
  %move past header
  fgetl(labeled_points_fid);
  fgetl(labeled_points_fid);
  line = fgetl(labeled_points_fid);


  %each labled point has two lines
  %IMAGE_NAME X Y DEPTH
  %INSTANCE_NAME
  line = fgetl(labeled_points_fid);
  while(ischar(line))

    %split line based on space, into IMAGE_NAME X Y DEPTH
    labeled_image_names_and_points{length(labeled_image_names_and_points)+1} = strsplit(line);
    

    %get label
    try %just make sure there is another line
      labels{length(labels)+1} =fgetl(labeled_points_fid);
    catch
      %get rid of last entry
      labeled_image_names_and_points = labeled_image_names_and_points(1:end-1);   
    end 
    %get next labeled point
    line =fgetl(labeled_points_fid);
  end%while there is another line



  %% MAIN LOOP

  %for every labeled point, find all other images that see that point
  for j=1:length(labeled_image_names_and_points)
     
    %get the next point, image, and label       
    cur_data = labeled_image_names_and_points{j};
    labeled_image_name = cur_data{1};
    labeled_point = floor([str2double(cur_data{2}) str2double(cur_data{3})])';
    depth = str2double(cur_data{4});
    label = labels{j}
   
    %this will throw off later calculations and lead to incorrect positions 
    if(depth == 0)
        continue;
    end
    
   
    %make sure we want to process this label 
    if(~strcmp(label_to_process,'all'))
      if(~strcmp(label_to_process,label))
        continue;
      end
    end
    


    %% CONVERT POINT FROM PIXELS TO WORLD COORDINATES

    %get the data for the labeled image
    image_struct = image_structs_map(labeled_image_name);

    %set up variables for equation
    K = intrinsic;
    t = image_struct.(TRANSLATION_VECTOR);
    R = image_struct.(ROTATION_MATRIX);
    C = image_struct.(SCALED_WORLD_POSITION);

    %apply scaling so everything is in world coordinates
    t = t*scale;

    %calculate the world cordinates
    world_coords = R' * depth * pinv(K) *  [labeled_point;1] - R'*t;


    %%FIND IMAGES THAT SEE THAT 3D Point

    %store name, and location of the labeled point in each image
    found_image_names = cell(0);
    found_points  =cell(0);

    %for each possible image, see if it contains the labeled point
    for k=1:length(image_names)
      cur_name = image_names{k};

      %skip the labeled image    
      if(strcmp(cur_name,labeled_image_name))
          continue;
      end

      %get the camera infor for this image
      cur_image_struct = image_structs_map(cur_name);
     
      %same setup as above 
      K = intrinsic; 
      R = cur_image_struct.(ROTATION_MATRIX);
      t = cur_image_struct.(TRANSLATION_VECTOR);
      t = t * scale;


      %re-orient the point to see if it is viewable by this camera
      P = [R t];
      oriented_point = P * [world_coords;1];
      %make sure z is positive
      if(oriented_point(3) < 0)
        continue;
      end

      %project the world point onto this image
      M = K * [R t];
      cur_image_point = M * [world_coords;1];

      %acccount for homogenous coords
      cur_image_point = cur_image_point / cur_image_point(3);
      cur_image_point = cur_image_point(1:2);

      %make sure the point is in the image
      if(cur_image_point(1) < 1 ||  cur_image_point(2) < 1 || ...
             cur_image_point(1) > kImageWidth || cur_image_point(2) > kImageHeight)
         continue;
      end 


      %%OCCULSION FILTERING
      %attempt to filter out images where the labeled instance is occuled
      %at the labeled point. 

      %make sure distance from camera to world_coords is similar to depth of
      %projected point in the depth image

      %get the depth image
      if(~depths_loaded)
        depth_image = imread(fullfile(scene_path, HIGH_RES_DEPTH, ... 
                       strcat(cur_name(1:8),'03.png') ));
      else
        depth_image = depth_img_map(cur_name);
      end
      %get the depth of the projected point
      cur_depth = depth_image(floor(cur_image_point(2)), floor(cur_image_point(1)));

      %get the distance from the camera to the labeled point in 3D
      camera_pos = cur_image_struct.(SCALED_WORLD_POSITION);
      world_dist = pdist2(camera_pos', world_coords');

      %if the depth == 0, then keep this image as we can't tell
      %otherwise see if the difference in depth vs. distance is greater than the threshold
      if(abs(world_dist - cur_depth) > occulsion_threshold  && cur_depth >0)
        continue;
      end


     %we found an image that 'sees' the labeled point! save its info
     found_image_names{length(found_image_names)+1} = cur_name; 
     found_points{length(found_points)+1} = [floor(cur_image_point(1)) floor(cur_image_point(2)) cur_depth];
     

    end%for k, each image name

    
    %% DEBUG OPTION
    
    %show some visualization of the found points if debug option is set 
    if(debug)  
      display = input('Display found images/points?(y/n)' , 's');


      if(display == 'y')
        %how lond to pause between each image shown
        pause_length = input(strcat('Enter seconds to pause between images', ...
                             '(0 for keyboard movement): '),'s');
        pause_length = str2num(pause_length);

        %show the images/points as a video
        if(pause_length > 0)

          %preload all the images
          images = cell(1,length(found_image_names));
          for i=1:length(images)
            images{i} = imread(fullfile(scene_path,RGB,found_image_names{i})); 
          end

          for i=1:length(images)
            %show the image
            imshow(images{i});
            hold on;
            %plot the found point on the image
            cur_point = found_points{i};
            plot(cur_point(1),cur_point(2),'b.', 'MarkerSize',100);
            pause(pause_length); 
            hold off;
          end

        else%let user move through images using keyboard

          %which image to display
          cur_image_index = 1;
          move_command = 'n';

          while(cur_image_index < length(found_image_names) ) 
            %show the image
            imshow(imread(fullfile(scene_path,RGB, ...
                     found_image_names{cur_image_index}))); 
     
            %plot the found point on the image 
            hold on;
            cur_point = found_points{cur_image_index};     
            plot(cur_point(1),cur_point(2),'b.','MarkerSize',30); 
            title(num2str(cur_point(3)));
            hold off;
            

            %get the command for where to move
            move_command = input(['Enter move command(' num2str(cur_image_index) '/' ...
                                    num2str(length(found_image_names)) '):' ], 's');

            if(strcmp(move_command, 'q'))
              disp('quiting...');
              break;
            elseif(strcmp(move_command,'n'))
              %move forward one image 
              cur_image_index = cur_image_index+1;   
            elseif(strcmp(move_command,'p'))
              %move backward one image 
              cur_image_index = cur_image_index-1;
            elseif(strcmp(move_command,'f'))
              %move forward 50 iamges
              num_to_move = 50;
              cur_image_index = cur_image_index + num_to_move;
            end 

            %make sure image index stays in array
            if(cur_image_index < 1)
              cur_image_index =1;
            elseif(cur_image_index > length(found_image_names))
              cur_image_name = length(found_image_names);
            end
          end %while cur_image_index < 
        end%if pause >0
      end%if display == y
    end % if debug
      
    
    
    %%POPULATE LABEL_TO_IMAGES_THAT_SEE_IT_MAP

    %store the info about the points/images we just found     

    %add in the hand labeled point
    found_image_names{length(found_image_names)+1} = labeled_image_name; 
    found_points{length(found_points)+1} = [point depth];
    
    %make a struct for each found point/image 
    cur_structs_array = cell(1,length(found_points));
    
    for j=1:length(cur_structs_array)
        cur_pt = found_points{j};
        
        cur_structs_array{j} = struct(IMAGE_NAME, found_image_names{j}, ...
                                      X, cur_pt(1),  Y, cur_pt(2), ...
                                      DEPTH, cur_pt(3));
    end%for j 
    
    
    %if the current label has already been used in the map
    %then merge these images and points to the old ones.
    if(isKey(label_to_images_that_see_it_map, label))
        
      %get the values that are already in the map
      old_structs_array = label_to_images_that_see_it_map(label);
      
      %just compare the names with 'unique' fucntion
      temp = cell2mat(old_structs_array);
      old_names = {temp.(IMAGE_NAME)};
      clear temp;
      
      [unique_names, iold, ifound] = union(old_names,found_image_names,'stable');
      
      %remove duplicates
      cur_structs_array = cur_structs_array(ifound); 
      
      %append the two non-intersecting lists
      new_structs_array = {old_structs_array{:} cur_structs_array{:}};
      
      %now sort the new array by image name
      temp = cell2mat(new_structs_array);
      all_names = {temp.image_name};
      [a,b] = sort(all_names);
      c = cell(1,length(new_structs_array));
      for kk=1:length(c)
          c(kk) = new_structs_array(b(kk));
      end
      new_structs_array = c;
      
      %update the map
      label_to_images_that_see_it_map(label) = new_structs_array;
        
    else%the current label hasn't been used yet, just add the points in
      % sort the structs array by image name
      temp = cell2mat(cur_structs_array);
      all_names = {temp.image_name};
      [a,b] = sort(all_names);
      c = cell(1,length(cur_structs_array));
      for kk=1:length(c)
          c(kk) = cur_structs_array(b(kk));
      end
      cur_structs_array = c;
      
      %update the map
      label_to_images_that_see_it_map(label) = cur_structs_array;
    end%if isKey
  end %for j , every labeled point from file 


  %% SAVE FILE
  %save label_to_images_that_see_it_map, making sure not to overwrite old data
  if(exist(fullfile(meta_path,LABELING_DIR, ...
           DATA_FOR_LABELING_DIR,LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE),'file'))
      
    %store current data 
    cur_values = label_to_images_that_see_it_map.values;
    cur_keys = label_to_images_that_see_it_map.keys;
    
    %load previous data 
    label_to_images_that_see_it_map = load(fullfile(meta_path,LABELING_DIR, ...
         DATA_FOR_LABELING_DIR,LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
    label_to_images_that_see_it_map = label_to_images_that_see_it_map.label_to_images_that_see_it_map;
    
    %%add in each new key,value pair
    for j=1:length(cur_keys)
     label_to_images_that_see_it_map(cur_keys{j}) = cur_values{j};
    end
  end

  %save it!
  save(fullfile(meta_path,LABELING_DIR, ...
      DATA_FOR_LABELING_DIR,LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE), ...
      LABEL_TO_IMAGES_THAT_SEE_IT_MAP);

end%for i, each scene_name

