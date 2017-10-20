function [] = make_hand_label_image_list(scene_name)
%Mkaes a list of all not reconstructed images that need to be hand labeled.
%Just assumes non of the not reconstructed images have been hand labeled yet
% ASSUMES the non reconstructed images have already been interpolated and have image structs


%TODO - 

%CLEANED - no 
%TESTED - no
%clearvars;

%initialize contants, paths and file names, etc. 
init;

%% USER OPTIONS

%scene_name = 'Home_04_2'; %make this = 'all' to run all scenes
model_number = '0';
%use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
%custom_scenes_list = {};%populate this 


method = 1;  % 0 - non reconstructed images
             % 1 - all images (for missing boxes check)



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

%% MAIN LOOP
for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il}
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


    %create text file to write all non reconstructed names in
    fid_names = fopen(fullfile(meta_path, LABELING_DIR, MISSING_BOXES_NAMES), 'wt');

    all_image_names = get_scenes_rgb_names(scene_path);

    blank_struct = struct('image_name','a');
    image_structs = repmat(blank_struct,1,length(all_image_names));
    %for each image struct, see if it was not reconstructed, if so write out image name
    for jl=1:length(all_image_names)

      cur_name = all_image_names{jl};
      cur_struct = struct();
      cur_struct.image_name = cur_name;
      image_structs(jl) = cur_struct;
    end%for jl, each image struct

    scale = 0;

      save(fullfile(meta_path,RECONSTRUCTION_RESULTS,'colmap_results',...
                 '0', 'image_structs.mat'),IMAGE_STRUCTS, SCALE);

end%for il, each scene




