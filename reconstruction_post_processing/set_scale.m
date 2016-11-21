%scale the camera positions of the reconstruction to be in milimeters
%uses depth images with the reconstructed points to determine scale 


%TODO  -use multiple point3ds  

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Office_03_1'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


scale = 1100;

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

  num_rgb_images = length(dir(fullfile(scene_path,'rgb', '*.png')));

  %get the image structs and make a map
  %image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results',  ...
                              'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);

  prev_scale = image_structs_file.scale;
  
    %save the new data 
    %save(fullfile(scene_path, IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE); 
    save(fullfile(meta_path,'reconstruction_results','colmap_results',model_number,... 
                     IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE); 
end%for i, each scene
