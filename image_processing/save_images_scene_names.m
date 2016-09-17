%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object

%TODO -get rid of image structs map. Just use indexes. (Make it sorted?)


%clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 1;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Den_den2', 'Den_den3', 'Den_den4'};





label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};



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





%load mapping from bigbird name ot category id
obj_cat_map = containers.Map();
fid_bb_map = fopen('/playpen/ammirato/Data/RohitMetaMetaData/big_bird_cat_map.txt', 'rt');

line = fgetl(fid_bb_map);
while(ischar(line))
  line = strsplit(line);
  obj_cat_map(line{1}) = str2double(line{2}); 
  line = fgetl(fid_bb_map);
end
fclose(fid_bb_map);




  save_base_path = fullfile('/playpen/ammirato/Data/RohitMetaMetaData/', 'labels', 'output_labels');
  if(~exist(save_base_path, 'dir'))
    mkdir(save_base_path);
  end



%% MAIN LOOP

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


  image_names = get_names_of_X_for_scene(scene_name, 'rgb_images');

  %% MAIN LOOP  for each label find its bounding box in each image

  %for each point cloud
%  image_names = image_names(640:end);
  for jl=1:length(image_names)
    cur_image_name = image_names{jl};
    org_file = fullfile(scene_path, 'jpg_rgb', ...
                      strcat(cur_image_name(1:10), '.jpg'));

    new_file = fullfile('/playpen/ammirato/Data/RohitMetaMetaData/jpgs/', ...
                          strcat(scene_name,'_', cur_image_name(1:10), '.jpg'));
    %new_file = fullfile(save_base_path, ...
    %                      strcat(scene_name, cur_image_name(1:10), '.jpg'));


    copyfile(org_file, new_file);

    if(mod(jl,50) == 0)
      disp(new_file);    
    end 
  end%for jl, each image
end%for i, each scene_name

