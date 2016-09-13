%assigns points in each image struct to the image structs that clockwise and counter clockwise 
%to it. This represents a rotation in the scene. Only structs from the same cluster 
% are considered

clearvars;

%initialize contants, paths and file names, etc. 
init;


%TODO - test


%% USER OPTIONS

scene_name = 'Kitchen_Living_02_1_vid_3'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Kitchen_05_1','Office_01_1'};%populate this 

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
  image_structs_file =  load(fullfile(meta_path, 'reconstruction_results', ...
                                group_name, 'colmap_results', ...
                                model_number, IMAGE_STRUCTS_FILE));
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


  all_image_names = get_names_of_X_for_scene(scene_name, 'rgb_images');
 

  for jl=1:length(all_image_names)
    cur_image_name = all_image_names{jl};

    index = cell2mat(strfind(image_names, cur_image_name));

    if(~isempty(index))
      continue;
    end

    delete(fullfile(scene_path, 'rgb', cur_image_name));
    delete(fullfile(meta_path, 'recognition_results', 'ssd_bigBIRD', 'output_boxes', ...
              strcat(scene_name, '_', cur_image_name(1:10), '.mat'))); 
     
  end%for jl 

end%for each scene


