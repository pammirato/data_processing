
%TODO -get rid of image structs map. Just use indexes. (Make it sorted?)


%clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 1;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Kitchen_Living_01_1',...
                      'Kitchen_Living_02_1', 'Kitchen_Living_03_1', ...
                      'Bedroom_01_1'};%populate this 



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
  scene_name = all_scenes{il}
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);




  %get the names of all the labels
  if(strcmp(label_to_process, 'all'))
    label_names = get_names_of_X_for_scene(scene_name, 'instance_labels');
  end

  image_names = get_names_of_X_for_scene(scene_name, 'rgb_images');





  %% MAIN LOOP  for each label find its bounding box in each image

  %for each point cloud
%  image_names = image_names(640:end);
  for jl=1:length(image_names)
    
    cur_image_name = image_names{jl};
    disp(cur_image_name);


    cur_instance_boxes = load(fullfile(meta_path, 'labels', 'verified_labels', ...
                         'bounding_boxes_by_image_instance', strcat(cur_image_name(1:10), '.mat')));


    boxes = [];
    
    instance_names = fields(cur_instance_boxes);
    for kl=1:length(instance_names)
      kl_name = instance_names{kl};
      box = cur_instance_boxes.(kl_name);
      if(isempty(box) | box(5) >2)
        continue;
      end
      
      try
        cat_id = obj_cat_map(kl_name);
      catch
        continue;
      end
      
      boxes(end+1,:) = [box(1:4) cat_id];
      
    end%for kl
    
    save(fullfile(save_base_path, strcat(scene_name, '_', cur_image_name(1:10),'.mat')),'boxes');

  end%for jl, each image
end%for i, each scene_name

