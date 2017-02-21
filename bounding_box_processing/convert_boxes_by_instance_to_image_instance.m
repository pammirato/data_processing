function [] = convert_boxes_by_instance_to_image_instance(scene_name, label_type)
% converts bounding box labels that are organized so that there is one file 
% per instance to a format that has one file per image. Box labels for
% all instances in the image are in the new file.
%
% It assumed boxes follow the following format:
%
%   [xmin ymin xmax ymax cat_id hardness]
%
%   where the first 4 numbers are the coordinates of the box in the image
%   cat_id is the integer ID of the category(instance or class level)
%   hardness is some measure of difficult for detection
%
% INPUTS:
%     scene_name - the name of the scene(s) that the boxes are in 
%                   - 'all' for all scenes
%                   - {'scene1', 'scene2',...} cell array of names for multiple scenes
%     label_type - OPTIONAL 
%                 (default) -'raw_labels' - auto generated boxes
%                           -'verified_labels' - human verified boxes
%     label_loc - OPTIONAL -where the boxes are located
%                 (default) - 'meta'  - in the meta path
%                           - 'scene' - in the scene path 
%


%TODO  - allow just one or custom instances


%CLEANED - yes 
%TESTED - yes 

%initialize contants, paths and file names, etc. init;
init;


%% USER OPTIONS

%whether or not to run for the scenes in the custom list
if(strcmp(class(scene_name), 'cell'))
  use_custom_scenes = 1;  custom_scenes_list = scene_name; 
else
  use_custom_scenes = 0;
end

%set default label_type if not inputted by user
if(nargin <2)
  label_type = 'raw_labels'; 
end

if(nargin <3)
  label_loc = 'meta'; %which path to use: scene or meta 
end
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

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path = fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  if(strcmp(label_loc,'meta'))
    label_path = meta_path;
  else
    label_path = scene_path;
  end


  %where to save the boxes by instance files
  save_path = fullfile(label_path, LABELING_DIR, label_type,...
                         BBOXES_BY_IMAGE_INSTANCE);
  if(~exist(save_path,'dir'))
   mkdir(save_path);
  end




  %get a list of all the instances in the scene
  instance_name_to_id_map = get_instance_name_to_id_map();
  instance_names = keys(instance_name_to_id_map);

  %get names of all the images in the scene
  all_image_names  = get_scenes_rgb_names(scene_path);

  %make a cell array with one cell for each image
  %in each cell is an array that holds boxes for all instance for 1 image
  label_array = -ones(length(instance_names),6);
  all_arrays = cell(length(all_image_names),1);
  for jl=1:length(all_arrays)
    all_arrays{jl} = label_array;
  end

  %make a map from image name to label array 
  label_array_map = containers.Map(all_image_names,all_arrays);  


  %% populate the structs for each image
  
  %for each instance, add a box to each image's cell that this instance is in
  for jl=1:length(instance_names)
   
    
    
    cur_instance_name = instance_names{jl}; 
    cur_instance_file_name = strcat(cur_instance_name, '.mat');
    cur_instance_id = instance_name_to_id_map(cur_instance_name);
    %disp(cur_instance_name);
 
    %load the boxes for this instance and make a map
    try
      cur_instance_labels= load(fullfile(label_path,LABELING_DIR, label_type, ...
                                  BBOXES_BY_INSTANCE, cur_instance_file_name));
    catch
      %this instance may not be in this scene, so skip it
      continue;
    end
    %get the image names and boxes for this instance from the loaded file struct 
    instance_image_names = cur_instance_labels.image_names;
    instance_boxes = cur_instance_labels.boxes; 


    %for each instance label, add it to the corresponding image struct
    for kl=1:length(instance_image_names)

      %get the name of the image for this label and the box
      cur_image_name = instance_image_names{kl};
      cur_image_name = strcat(cur_image_name(1:10),'.jpg');
      bbox = instance_boxes(kl,:);

      if(length(bbox) < 6)
        bbox = [bbox 0];
      end
     
      %make sure the box is labeled correctly 
      try
      assert(bbox(5) == cur_instance_id);
      catch
        bbox(5) = cur_instance_id;
      end
      
      
      %get the label array for this image, add this label, update the  map
      try
      cur_label_array = label_array_map(cur_image_name);
      catch
        breakp=1;
      end
      cur_label_array(bbox(5), :) = bbox; 
      label_array_map(cur_image_name) = cur_label_array;
    end% for k, each image name 
  end%for j, each instance 

  %now save each label array for each image to its own file
  for jl=1:length(all_image_names)
    %get the image name and label array 
    cur_image_name = all_image_names{jl};
    cur_label_array = label_array_map(cur_image_name);

    %remove 'empty' boxes (boxes for instances that are not in the image)
    empty_boxes = cur_label_array(:,1) == -1;
    cur_label_array(empty_boxes,:) = [];

    %save the boxes
    boxes = cur_label_array;    
    save(fullfile(save_path,strcat(cur_image_name(1:10),'.mat')), 'boxes');
                  

  end %for jl, each image
end%for il,  each scene
end%function



