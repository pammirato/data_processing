% Renames images so that each image's index( first 6 characters) is equal to that 
% image's index in the list of image names. Really it removes holes in the image indices.
%
% Imagine there are 3 images named '1', '2', '4', '5'.
% This will rename them to be '1', '2', '3', '4'. Image '4' becomes, '3', and '5' becomes '4'.
%


%TODO  -  support rgb and raw_depth at once
%       - move the images back to one directory at end

%CLEANED - yes 
%TESTED - yes 

%initialize contants, paths and file names, etc. init;
init


%% USER OPTIONS

scene_name = 'Office_04_1'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 

image_type = 1;   % 0 - just rgb
                   % 1 - just raw_depth





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


  %get the path to load images from and save to
  if(image_type == 0)
    folder_path = fullfile(meta_path,RECONSTRUCTION_SETUP, 'rgb');
    
    folder_path_new = fullfile(meta_path,RECONSTRUCTION_SETUP, 'rgb_new');% ...
  elseif(image_type == 1)
    folder_path = fullfile(meta_path,RECONSTRUCTION_SETUP, 'raw_depth');
    
    folder_path_new = fullfile(meta_path,RECONSTRUCTION_SETUP, 'raw_new');% ...
  end

  %make the new directory
  mkdir(folder_path_new);

  %get the names of the images to load
  d = dir(fullfile(folder_path, '*.png'));
  org_names = {d.name};

  for jl = 1:length(org_names)

    old_name = org_names{jl};

    %make the new index
    new_index_string = sprintf('%06d', jl);

    %if the new index is different than the old index, save the image witht the new name
    if(~strcmp(old_name(1:6), new_index_string))
      %movefile to new directory so it does not conflict with existing files
      new_name = strcat(new_index_string, old_name(7:end)); 
      movefile(fullfile(folder_path, old_name), fullfile(folder_path_new, new_name));
    end
  end%for jl, each image name
end%for il, each scene


