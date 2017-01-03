% Sets real-world position of each image_struct by mulitpling the
% reconstructed position by the scale. Should be done after scale is calculated.
%

%TODO  - get rid of jl loop 

%CLEANED - no 
%TESTED - no

clearvars;

%initialize contants, paths and file names, etc. 
init;


%% USER OPTIONS


scene_name = 'all'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 



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
  disp(scene_name);
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


  %load image_structs for all images
  image_structs_file =  load(fullfile(meta_path, RECONSTRUCTION_RESULTS, ...
                                'colmap_results', ...
                                model_number, IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;%just keep track of this to save later

  %apply the scale to get the real world position
  for jl=1:length(image_structs)
    cur_struct = image_structs(jl);
    cur_struct.scaled_world_pos = cur_struct.world_pos * scale;
    image_structs(jl) = cur_struct;
  end%for jl, each image struct

  %save the update image structs  
  save(fullfile(meta_path, RECONSTRUCTION_RESULTS, 'colmap_results', ...
                model_number,  IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE);
end%for il,  each scene


