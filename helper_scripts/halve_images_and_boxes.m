%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object

%TODO -get rid of image structs map. Just use indexes. (Make it sorted?)


clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

scene_name = 'Home_14_1'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
%custom_scenes_list = {'Bedroom_01_1', 'Kitchen_Living_01_1', 'Kitchen_Living_02_1', 'Kitchen_Living_03_1', 'Kitchen_Living_04_2', 'Kitchen_05_1', 'Kitchen_Living_06', 'Office_01_1'};%populate this 
custom_scenes_list = {'Kitchen_Living_03_2', 'Kitchen_Living_08_1'};%populate this 




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


  save_base_path = fullfile('/playpen/ammirato/Data/Eunbyung_Data/', scene_name);
  ann_save_path = fullfile(save_base_path, 'annotations');
  img_save_path = fullfile(save_base_path, 'rgb');
  if(~exist(save_base_path, 'dir'))
    mkdir(save_base_path);
    mkdir(ann_save_path);
    mkdir(img_save_path);
  end



  %% MAIN LOOP  for each label find its bounding box in each image

  %for each point cloud
%  image_names = image_names(640:end);
  count = 0;
  for jl=1:length(image_names)
    
    cur_image_name = image_names{jl};
    if(mod(jl,50) == 0)
      disp(cur_image_name);
    end

    cur_instance_boxes = load(fullfile(meta_path, 'labels', 'verified_labels', ...
                         'bounding_boxes_by_image_instance', strcat(cur_image_name(1:15), '.mat')));

    ann_fid = fopen(fullfile(ann_save_path, strcat(cur_image_name(1:15), '_boxes.txt')), 'wt');

    %instance_names = fieldnames(cur_instance_boxes); 
    boxes = cur_instance_boxes.boxes;
    
    for kl=1:size(boxes,1)
      
      bbox = boxes(kl,:);
      cat_id = bbox(5);
     

      if(isempty(bbox) || (bbox(6) >4))
        continue;
      end
      
      count = count +1;
      
      fprintf(ann_fid, '%d %d %d %d %d\n', cat_id, bbox(1), bbox(2),bbox(3),bbox(4));

    end%for kl, each instance name

    fclose(ann_fid);



    %img = imread(fullfile(scene_path, 'jpg_rgb', strcat(cur_image_name(1:10), '.jpg')));
    img = imread(fullfile(scene_path, 'jpg_rgb', cur_image_name));
    %img = imresize(img, .5);

    imwrite(img, fullfile(img_save_path, strcat(cur_image_name(1:15), '.jpg')));
  end%for jl, each image
  disp(count)
end%for i, each scene_name

