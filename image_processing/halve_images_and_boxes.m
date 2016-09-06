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
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Kitchen_Living_01_1'};%populate this 



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





save_base_path = fullfile('/playpen/ammirato/Data/Eunbyung_Data/', scene_name);
ann_save_path = fullfile(save_base_path, 'annotations');
img_save_path = fullfile(save_base_path, 'rgb');
if(~exist(save_base_path, 'dir'))
  mkdir(save_base_path);
  mkdir(ann_save_path);
  mkdir(img_save_path);
end



%% MAIN LOOP

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get the names of all the labels
  if(strcmp(label_to_process, 'all'))
    label_names = get_names_of_X_for_scene(scene_name, 'instance_labels');
  end

  image_names = get_names_of_X_for_scene(scene_name, 'rgb_images');





  %% MAIN LOOP  for each label find its bounding box in each image

  %for each point cloud
  for jl=1:length(image_names)
    
    cur_image_name = image_names{jl};


    cur_instance_boxes = load(fullfile(meta_path, 'labels', 'verified_labels', ...
                         'bounding_boxes_by_image_instance', strcat(cur_image_name(1:10), '.mat')));

    ann_fid = fopen(fullfile(ann_save_path, strcat(cur_image_name(1:10), '_boxes.txt')), 'wt');

    instance_names = fieldnames(cur_instance_boxes); 

    for kl=1:length(instance_names)
      kl_name = instance_names{kl};
      bbox = cur_instance_boxes.(kl_name);

      if(isempty(bbox) || (bbox(5) >2))
        continue;
      end

      cat_id = obj_cat_map(kl_name);

      bbox = floor(bbox ./2);
      bbox(1) = max(bbox(1), 1);
      bbox(2) = max(bbox(2), 1);

      fprintf(ann_fid, '%d %d %d %d %d\n', cat_id, bbox(1), bbox(2),bbox(3),bbox(4));

    end%for kl, each instance name

    fclose(ann_fid);



    img = imread(fullfile(scene_path, 'rgb', cur_image_name));
    img = imresize(img, 2);

    imwrite(img, fullfile(img_save_path, strcat(cur_image_name(1:10), '.jpg')));
  end%for jl, each image
end%for i, each scene_name
