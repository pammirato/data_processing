function [] = count_images(scene_name, restrict_count)
% Counts number of images in each scene.
%
%INPUTS:
%         scene_name: char array of single scene name, 'all' for all scenes, 
%                     or a cell array of char arrays, one for each desired scene
%         restrict_count: OPTIONAL  0(default) count all images
%                                   1 only count images with a bounding box 
%         label_type: OPTIONAL 'raw_labels'(default) or 'verified_labels'
%
%OUTPUTS:
%
%         image_count_struct: One field per scene -> # images
%                             One 'total' field -> # images summed over all scenes


%TODO - categories

%CLEANED - no 
%TESTED - no


%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

%scene_name = 'all'; %make this = 'all' to run all scenes
model_number = '0';
%use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
%custom_scenes_list = {'Bedroom_01_1', 'Kitchen_Living_01_1', 'Kitchen_Living_02_1', 'Kitchen_Living_03_1', 'Kitchen_Living_04_2', 'Kitchen_05_1', 'Kitchen_Living_06', 'Office_01_1'};%populate this 

if(~exist('restrict_count'))
  restrict_count = 0;
end


label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};

debug =0;

label_type = 'verified_labels';
%% SET UP GLOBAL DATA STRUCTURES

%get the names of all the scenes
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};

%determine which scenes are to be processed 
if(iscell(scene_name)
  %if we are using the custom list of scenes
  all_scenes = scene_name;
elseif(~strcmp(scene_name, 'all'))
  %if not using custom, or all scenes, use the one specified
  all_scenes = {scene_name};
end

instance_name_to_id_map = get_instance_name_to_id_map();
%get the names of all the labels
if(strcmp(label_to_process, 'all'))
  label_names = keys(instance_name_to_id_map);
end

image_count_struct = struct('total', 0);

%% MAIN LOOP
scenes_count_struct = struct();
for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get the names of images in this scene and count them
  image_names = get_scenes_rgb_names(scene_path);
  num_images = length(image_names);

  if(restrict_count)
    valid_image_names = {};

    for jl=1:length(label_names)
      %get the instance name and load its boxes for this scene
      cur_instance_name = label_names{jl};

      try
        cur_instance_boxes = load(fullfile(meta_path, LABELING_DIR, label_type, ...
                                        BBOXES_BY_INSTANCE, strcat(cur_instance_name, '.mat')));
      catch
        continue;
      end 
    
      %get the images that see this instance in this scene
      cur_instance_image_names = cur_instance_boxes.image_names;

      %add any new image names to the list of image names that see at least one of
      %the desired instances
      try
        valid_image_names = unique(cat(1, valid_image_names, cur_instance_image_names));
      catch 
        valid_image_names = unique(cat(2, valid_image_names, cur_instance_image_names));
      end
    end%for jl, each label name
 
    %overwrite the number of images 
    num_images = length(valid_image_names);    
  end%if only count images with desired objects

  %update the global struct
  image_count_struct.(scene_name) = num_images;
  image_count_struct.total = image_count_struct.total + num_images;
end%for i, each scene_name

end

