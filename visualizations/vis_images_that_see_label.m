%for each label, shows all the images that see it, along with a red dot
%on where the object is thought to be. Allows the user to change the location
% of the dot and save it


%TODO  - what to add next

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_Density_2by2_same_chair'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_name = 'bottle1';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_labels = 0;
custom_labels_list = {'chair5','chair6'};


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


   %load image_structs for all images
  image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %make this for easy access to data 
  mat_image_structs = cell2mat(image_structs); 
  
  %make a map from image_name to image struct for easy saving later
  image_structs_map = containers.Map({mat_image_structs.image_name}, image_structs);

 


  %get the map to find all the images that 'see' each label
  label_to_images_that_see_it_map = load(fullfile(meta_path,LABELING_DIR,...
                                      DATA_FOR_LABELING_DIR, ...
                                      LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
   
  label_to_images_that_see_it_map = label_to_images_that_see_it_map.( ...
                                                  LABEL_TO_IMAGES_THAT_SEE_IT_MAP);
  
  %get names of all labels           
  all_labels = label_to_images_that_see_it_map.keys;
  
  %decide which labels to process    
  if(use_custom_labels && ~isempty(custom_labels_list))
    all_labels = custom_labels_list;
  elseif(strcmp(label_name,'bigBIRD'))
    temp = dir(fullfile(BIGBIRD_BASE_PATH));
    temp = temp(3:end);
    all_labels = {temp.name};
  elseif(strcmp(label_name, 'all'))
    all_labels = all_labels;
  else
    all_labels = {label_name};
  end

  %for each label, process  all the images that see it
  for j=1:length(all_labels) %num_labels
         
    label_name = all_labels{j}



    %get the structs with IMAGE_NAME, X, Y, DEPTH for images that see this
    %instance
    try
      label_structs = label_to_images_that_see_it_map(label_name);
    catch
      disp(strcat('could not find ',label_name));
      continue;
    end



    %get names of all images that see this label, and make a map
    mat_label_structs = cell2mat(label_structs);

    image_names = {mat_label_structs.image_name};
    label_structs_map = containers.Map(image_names, label_structs);











    %for visulaization

    cur_image_index = 1;
    cur_image_name  = image_names{cur_image_index};
    cur_image_struct =  image_structs_map(cur_image_name);
    move_command = 'w';
    num_to_play = 0;
    while(cur_image_index <= length(image_names)) 


      %get the rgb image (jpg is fine)
      rgb_image = imread(fullfile(scene_path,RGB, cur_image_name));
      imshow(rgb_image);
      hold on;
      title(cur_image_name);

      %put a red dot where the object is thought to be
      cur_label_struct = label_structs_map(cur_image_name);
      plot(cur_label_struct.x, cur_label_struct.y, 'r.', 'MarkerSize', 40);
       









      %get user input command if a video is not playing
      if((num_to_play == 0))
        move_command = input('Enter move command: ', 's');
      end

      if(move_command == 'q')
          disp('quiting...');
          break;

      elseif(move_command =='w')
          %move forward 
          next_image_name = cur_struct.translate_forward;
          cur_image_index = str2num(next_image_name(1:6));

      elseif(move_command =='s')
          %move backward 
          next_image_name = cur_struct.translate_backward;
          cur_image_index = str2num(next_image_name(1:6));
      
      elseif(move_command =='d')
          %rotate clockwise
          next_image_name = cur_struct.rotate_cw;
          cur_image_index = str2num(next_image_name(1:6));
      elseif(move_command =='a')
          %rotate counter clockwise 
          next_image_name = cur_struct.rotate_ccw;
          cur_image_index = str2num(next_image_name(1:6));

      elseif(move_command =='n')
          %go forward one image 
          cur_image_index = cur_image_index+1;  
     
      elseif(move_command =='p')
          %go backward one image 
          cur_image_index = cur_image_index-1;

      elseif(move_command =='m')
          %let the user decide how much to go(forward or back) 
          num_to_move = input('How many images to move: ', 's');
          num_to_move = str2num(num_to_move);
          
          cur_image_index = cur_image_index + num_to_move;
      elseif(move_command =='f')
          %move forward 50 iamges
          cur_image_index = cur_image_index + 50;
      elseif(move_command =='g')
          %move forward 100 images
          cur_image_index = cur_image_index + 100;
      

      elseif(move_command =='v')
          %play a video of X images
          
          if(num_to_play == 0)%if we are not already playing a video
            num_to_play_s = input('How many images to play: ', 's');
            num_to_play = str2num(num_to_play_s);
          else
            num_to_play = num_to_play -1;
            cur_image_index = cur_image_index +1;
            pause(.1);
          end


      elseif(move_command =='i')
          %edit the current label struct
          disp('click the new label point(right click to delete');
          %get user input 
          [x,y,but] = ginput(1);
      
          %if they left-clicked, update this label struct with the new point 
          if(but==1)
            cur_label_struct.x = x;
            cur_label_struct.y = y;
            label_structs_map(cur_image_name) = cur_label_struct;
          else
            %delete this label struct
            remove(label_structs_map, cur_image_name);
            %display the next image
            cur_image_index = cur_image_index +1;
          end

          %asve the new label structs
          label_to_images_that_see_it_map(cur_label_name) = values(label_structs_map);

 
             
          save(fullfile(meta_path,LABELING_DIR,DATA_FOR_LABELING_DIR, ...
                LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE), 'label_to_images_that_see_it_map');

      elseif(move_command =='h')
        disp('help: ');

        disp('	q  - to quit and save labels so far ');
        disp('	w  - move forward ');
        disp('	s  - move backward ');
        disp('	d  - rotate clockwise');
        disp('	a  - roatate counter clockwise ');
        disp('	n  - go to the next image ');
        disp('	p  - go to the previous image  ');
        disp('	m  - move some number of images,  ');
        disp('		enter the number of images after typing m  and hitting enter once ');
        disp('	f  - move foward 50 images ');
        disp('	g  - move forward 100 images ');
      end    

      %make sure index is in bounds
      if(cur_image_index < 1)
        cur_image_index = 1;
      elseif(cur_image_index > length(image_names))
        cur_image_index = length(image_names);
      end

      %update variables
      cur_image_name = image_names{cur_image_index};
      cur_image_struct = image_structs_map(cur_image_name);

    end %while cur_image_index < 
  end% for j, each label
end%for each scene





