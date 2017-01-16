%%%%  NOT NEEDED, NOT USED


% converts bounding box labels that are organized in structs by string instance names
% to arrays with numeric ids for each instance
%
%  New boxes follow the following format:
%
%   [xmin ymin xmax ymax cat_id hardness ...]
%
%   where the first 4 numbers are the coordinates of the box in the image
%   cat_id is the integer ID of the category(instance or class level)
%   hardness is some measure of difficult for detection
%   ... and possible other numbers


%TODO  - delete this file 

%CLEANED - yes 
%TESTED - no

clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Home_03_1'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Kitchen_Living_01_1','Kitchen_Living_02_1','Kitchen_Living_03_1','Kitchen_Living_03_2','Kitchen_Living_04_2','Kitchen_Living_06','Kitchen_Living_08_1','Kitchen_05_1', 'Office_01_1'};%populate this 

label_type = 'raw_labels';  %raw_labels - automatically generated labels
                            %verified_labels - boxes looked over by human

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

%for each scene, do the conversion
for il=1:length(all_scenes)

  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %where to save the boxes by instance files
  save_path = fullfile(meta_path, LABELING_DIR, label_type,...
                         BBOXES_BY_INSTANCE);
  if(~exist(save_path,'dir'))
   mkdir(save_path);
  else
    %copyfile(fullfile(meta_path, LABELING_DIR,label_type), ...
    %        fullfile(meta_path, LABELING_DIR, strcat(label_type, '_orig')));
  end


  instance_name_to_id_map = get_instance_name_to_id_map();


  %get the names of all the images that have a file for boxes
  labeled_image_names = dir(fullfile(meta_path,LABELING_DIR,label_type, ...
                             BBOXES_BY_IMAGE_INSTANCE,'*.mat'));
  labeled_image_names = {labeled_image_names.name};



  %for each image, convert from struct to array
  for jl=1:length(labeled_image_names)

    cur_image_name = labeled_image_names{jl};
    cur_file = load(fullfile(meta_path, LABELING_DIR, label_type,...
                      BBOXES_BY_IMAGE_INSTANCE, ...
                      strcat(cur_image_name(1:10), '.mat'))); 

    %get all the possible labels and make a matrix to hold conversions
    labels = fieldnames(cur_file);
    all_arrays = -ones(length(labels), 6);
    box_counter = 0;
    for kl=1:length(labels)
      %get the current name and id of this instance
      cur_instance_name = labels{kl};
      
      try
        cur_instance_id = instance_name_to_id_map(cur_instance_name);
      catch
        disp(cur_instance_name);
        cur_instance_id = -1;
      end
      %get the labeled bounding box, skip if it is empty(instance is not
      %present)
      bbox = cur_file.(cur_instance_name);
      if(isempty(bbox))
        continue;
      end
      
      box_counter = box_counter +1;
      all_arrays(box_counter,:) = [bbox(1:4) cur_instance_id -1];
    end%for kl
    
    all_arrays(box_counter+1:end,:) = [];
    
    
    boxes = all_arrays;
    save(fullfile(meta_path, LABELING_DIR, label_type,...
                      BBOXES_BY_IMAGE_INSTANCE, ...
                      strcat(cur_image_name(1:10), '.mat')), 'boxes'); 
    



  end%for jl, each labeled image name
end%for i, each scene_name

