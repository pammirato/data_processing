% Saves a copy of each image, renamed with its scene_name as a prefix.
% this allows all images to be stored in a single folder, 

%CLEANED - yes 
%TESTED - no


%TODO -  

clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 1;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Den_den2', 'Den_den3', 'Den_den4'};


%where to save all the images
save_base_path = fullfile('/playpen/ammirato/Data/RohitMetaMetaData/all_jpgs');

jpg_images = 1;


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


%make the save folder if it doesn't exist
if(~exist(save_base_path, 'dir'))
  mkdir(save_base_path);
end



%% MAIN LOOP

%for each scene, copy all images and rename the copy
for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get all rgb iamge names (png)
  image_names = get_scenes_rgb_names(scene_name);

  %% MAIN LOOP  for each label find its bounding box in each image
  for jl=1:length(image_names)
    cur_image_name = image_names{jl};

    if(jpg_images) 
      org_file = fullfile(scene_path, JPG_RGB, ...
                      strcat(cur_image_name(1:10), '.jpg'));
      new_file = fullfile(save_base_path, ...
                          strcat(scene_name,'_', cur_image_name(1:10), '.jpg'));
    else
      org_file = fullfile(scene_path, RGB, ...
                        strcat(cur_image_name(1:10), '.png'));
      new_file = fullfile(save_base_path, ...
                          strcat(scene_name,'_', cur_image_name(1:10), '.png'));
    end

    copyfile(org_file, new_file);

    %show progress
    if(mod(jl,50) == 0)
      disp(new_file);
    end 
  end%for jl, each image
end%for i, each scene_name


