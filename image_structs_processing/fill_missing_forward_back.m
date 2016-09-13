%assigns pointers in each image sturct to the image structs that are in front and behind it, 
%representing forward or backward movements. Takes into account  direction of camera for each
%image, and does not assign pointers within a cluster

clearvars;

%initialize contants, paths and file names, etc. 
init;


%TODO  - test
%      - remove dependancy on cluster_ids(min dist apart)







%% USER OPTIONS

scene_name = 'Kitchen_Living_08_1'; %make this = 'all' to run all scenes
%group_name = 'all';
group_name = 'all_minus_boring';
model_number = '0';
use_custom_scenes = 1;%whether or not to run for the scenes in the custom list
%custom_scenes_list = {'Kitchen_Living_02_1','Kitchen_05_1','Kitchen_Living_08_1','Office_01_1', 'Bedroom_01_1'};%populate this 
custom_scenes_list = {'Kitchen_Living_01_1','Kitchen_Living_03_1','Kitchen_Living_03_2','Kitchen_Living_04_2','Kitchen_Living_06'};%populate this 


%whether to threshold on distance, then find the smallest angle, or 
%           threshold on angle, then find the smallest distance
threshold_on_distance = 0;


dir_angle_thresh = 10; %difference between direction of camera at images
move_angle_thresh = 10; %maximum allowed difference between point angle and direction angle
point_angle_thresh = 30;%angle between camera direction of org and vector from org to other point
dist_thresh = 500;%distance threshold in mm, (must be closer than this)


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
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;


  %get a list of all the image file names
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));
  %populate the map
  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end
  
  %find max number of clusters 
  max_cluster_id = max([image_structs.cluster_id]);

  forward_names = {image_structs.translate_forward};
  for jl=1:length(forward_names)
    el = forward_names{jl};
    if(el == -1)
      el = '-1';
      forward_names{jl} = el;
    end
  end
  backward_names = {image_structs.translate_backward};
  for jl=1:length(forward_names)
    el = backward_names{jl};
    if(el == -1)
      el = '-1';
      backward_names{jl} = el;
    end
  end
  left_names = {image_structs.translate_left};
  for jl=1:length(forward_names)
    el = left_names{jl};
    if(el == -1)
      el = '-1';
      left_names{jl} = el;
    end
  end
  right_names = {image_structs.translate_right};
  for jl=1:length(forward_names)
    el = right_names{jl};
    if(el == -1)
      el = '-1';
      right_names{jl} = el;
    end
  end
 

  for jl=1:length(image_names)

    cur_image_name = image_names{jl};
    cur_image_struct = image_structs_map(cur_image_name);


    if(cur_image_struct.translate_forward == -1)
      %see if another image goes backward to this one
      indexa = strfind(backward_names, cur_image_name); 
      index = find(not(cellfun('isempty', indexa))); 
     
      if(~isempty(index))
        f_name = image_structs(index(1)).image_name;
        cur_image_struct.translate_forward = f_name;   
      end
    end%if no forward


    if(cur_image_struct.translate_backward == -1)
      indexa = strfind(forward_names, cur_image_name); 
      index = find(not(cellfun('isempty', indexa))); 
     
      if(~isempty(index))
        f_name = image_structs(index(1)).image_name;
        cur_image_struct.translate_backward = f_name;   
      end
    end%if no 
 
    if(cur_image_struct.translate_left == -1)
      indexa = strfind(right_names, cur_image_name); 
      index = find(not(cellfun('isempty', indexa))); 
     
      if(~isempty(index))
        f_name = image_structs(index(1)).image_name;
        cur_image_struct.translate_left = f_name;   
      end
    end%if no


    if(cur_image_struct.translate_right == -1)
      indexa = strfind(left_names, cur_image_name); 
      index = find(not(cellfun('isempty', indexa))); 
     
      if(~isempty(index))
        f_name = image_structs(index(1)).image_name;
        cur_image_struct.translate_right = f_name;   
      end
    end%if no



    image_structs_map(cur_image_name) = cur_image_struct; 

  end%for jl, each image 
  
  
  
      
  image_structs = cell2mat(image_structs_map.values);
  
  save(fullfile(meta_path, 'reconstruction_results', group_name, ...
                'colmap_results', model_number,  IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE);

end%for each scene


