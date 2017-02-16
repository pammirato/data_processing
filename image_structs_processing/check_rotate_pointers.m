function [] = check_rotate_pointers(scene_name)
%assigns pointers in each image struct to the image structs that are 
% clockwise and counter clockwise 
%to it. This represents a rotation in the scene. Only structs from the same cluster 
% are considered

%TODO - test

%CLEANED - yes 
%TESTED - no

%clearvars;

%initialize contants, paths and file names, etc. 
init;


%% USER OPTIONS

%scene_name = 'Kitchen_Living_08_1'; %make this = 'all' to run all scenes
model_number = '0';
%use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
%custom_scenes_list = {};%populate this 

%% SET UP GLOBAL DATA STRUCTURES


%get the names of all the scenes
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};


%determine which scenes are to be processed 
if(iscell(scene_name))
  %if we are using the custom list of scenes
  all_scenes = scene_name;
elseif(~strcmp(scene_name, 'all'))
  %if not using custom, or all scenes, use the one specified
  all_scenes = {scene_name};
end




%% MAIN LOOP -for each scene, assign the pointers for each image in that scene

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


  %load image_structs for all images
  image_structs_file =  load(fullfile(meta_path, RECONSTRUCTION_RESULTS, ...
                                'colmap_results', ...
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


  for jl=1:length(image_structs)
    cur_struct = image_structs(jl);
    cur_name = cur_struct.image_name;

    ccw = cur_struct.rotate_ccw;
    cw = cur_struct.rotate_cw;

    ccw_struct = image_structs_map(ccw);
    cw_struct = image_structs_map(cw);

    assert(strcmp(cur_name,ccw_struct.rotate_cw));
    assert(strcmp(cur_name,cw_struct.rotate_ccw));

  end%jl

  
end%for il,  each scene

end%function




