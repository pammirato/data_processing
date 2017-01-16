%Mkaes a list of all not reconstructed images that need to be hand labeled.
%Just assumes non of the not reconstructed images have been hand labeled yet
% ASSUMES the non reconstructed images have already been interpolated and have image structs


%TODO - 

%CLEANED - no 
%TESTED - no
clearvars;

%initialize contants, paths and file names, etc. 
init;

%% USER OPTIONS

scene_name = 'Home_03_2'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


method = 1;  % 0 - non reconstructed images
             % 1 - all images (for missing boxes check)



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
  scene_name = all_scenes{il}
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


  if(method == 0)
    %load the structs for the reconstructed images and make a map
    recon_struct_file = load(fullfile(meta_path,RECONSTRUCTION_RESULTS, 'colmap_results',...
                         model_number, 'image_structs.mat'));
     
    image_structs = recon_struct_file.image_structs;
    scale = recon_struct_file.scale;

  %  image_structs_map = make_image_structs_map(image_structs); 

    %create text file to write all non reconstructed names in
    fid_names = fopen(fullfile(meta_path, LABELING_DIR, HAND_LABEL_NAMES), 'wt');

    %for each image struct, see if it was not reconstructed, if so write out image name
    for jl=1:length(image_structs)

      cur_struct = image_structs(jl);


      %if there is no rotation matrix, this image was not reconstructed
      if(isempty(cur_struct.R))
        %write the image index(1:10) name to file
        cur_name = cur_struct.image_name;
        cur_index_name = cur_name(1:10);%skip the extension
        fprintf(fid_names, '%s\n', cur_index_name);
      end 
    end%for jl, each image struct
    fclose(fid_names);%close file


  elseif(method == 1)
    %create text file to write all non reconstructed names in
    fid_names = fopen(fullfile(meta_path, LABELING_DIR, MISSING_BOXES_NAMES), 'wt');

    all_image_names = get_scenes_rgb_names(scene_path);

    %for each image struct, see if it was not reconstructed, if so write out image name
    for jl=1:length(all_image_names)

      cur_name = all_image_names{jl};
      fprintf(fid_names, '%s\n', cur_name);
    end%for jl, each image struct
    fclose(fid_names);%close file


  end%if method
end%for il, each scene




