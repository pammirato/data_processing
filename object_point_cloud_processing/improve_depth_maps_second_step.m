%Make new depth images for each rgb image


%TODO  - add in mesh


%CLEANED - no
%TESTED - no
%clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Office_04_1'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 

similar_point_dist_thresh = .001;
slice_dists = [300:100:200];
dir_angle_threshs = [30:30:90];
num_pcs_to_use = 40;
max_valid_depth = 7000;

debug =0;

kinect_to_use = 1;
%size of rgb image in pixels
kImageWidth = 1920;
kImageHeight = 1080;




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
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %% get info about camera position for each image
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %remove image structs that were not reconstructed. These will be hand labeled
  no_R_inds = cellfun('isempty', {image_structs.R});
  no_R_structs = image_structs(no_R_inds);
  image_structs = image_structs(~no_R_inds);

  %get a list of all the image file names
  image_names = {image_structs.(IMAGE_NAME)};


  depths_loaded = 0;

  %% get info about camera position for each image
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %remove image structs that were not reconstructed. These will be hand labeled
  no_R_inds = cellfun('isempty', {image_structs.R});
  no_R_structs = image_structs(no_R_inds);
  image_structs = image_structs(~no_R_inds);

  %get a list of all the image file names
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));
  %populate the map
  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end

  %image_names = {'0006460101.png', '0006810101.png'};
  %image_names = image_names(370:end);
  for jl= 1:length(image_names) 
    
    
    %% get the image name, position/direction info 
    cur_image_name = image_names{jl};
    cur_image_struct = image_structs_map(cur_image_name);
    disp(cur_image_name);
    if(depths_loaded)
      cur_depth_img = depth_img_map(cur_image_name);
    else
      cur_depth_img = imread(fullfile(scene_path, 'high_res_depth', strcat(cur_image_name(1:8), ...
                        '03.png')));
    end

    depth_img = cur_depth_img;



    pc_depth_img = imread(fullfile(meta_path, 'improved_depths2', ...
                          strcat(cur_image_name(1:8), '05.png')));
    

    depth_img = cur_depth_img;

    %% TODO  - keep depth image values that are less than point cloud values
      %good_depth_flags = (depth_img>0) & ((depth_img<pc_depth_img) | (depth_img<2000));
      good_depth_flags = (depth_img>0) & (depth_img<pc_depth_img);
      thresh_depth = double(depth_img) .* double(good_depth_flags);
      thresh_pc_depth = double(pc_depth_img) .* double(~good_depth_flags);
      new_depth = uint16(thresh_depth + thresh_pc_depth);
      xyz = new_depth;
%      new_depth = regionfill(new_depth, (new_depth == 0));


    imwrite(new_depth, fullfile(meta_path, 'improved_depths3', ...
              strcat(cur_image_name(1:8), '05.png')));
    %imwrite(new_depth, fullfile(meta_path, 'improved_depths', ...
    %          strcat(cur_image_name(1:8), '05.png')));
  end%for jl, each image name

end%for i, each scene_name

