%converts bounding box labels by instance in .mat file to .txt file


%CLEANED - no
%TESTED - no

%TODO  - write all boxes at once for each image (get rid of kl loop)

clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

%where to save the .txt files
save_base_path = fullfile('/playpen/ammirato/data/eunbyung_data/');


scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 

label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};


scale_factor = 1; %can resize boxes for images of different resolution
                  %ex) for images half the size of the original, make this .5 

save_jpgs = 0; %whether or not to also save jpgs images 
                %(useful if you want to scale images and boxes at once)

label_type = 'verified_labels';  %raw_labels - automatically generated labels
                            %verified_labels - boxes looked over by human

debug =0;

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

  instance_name_to_id_map = get_instance_name_to_id_map();
  %get the names of all the labels
  if(strcmp(label_to_process, 'all'))
    label_names = keys(instance_name_to_id_map); 
  end

  image_names = get_scenes_rgb_names(scene_path);


  save_dir = fullfile(save_base_path, scene_name);
  ann_save_path = fullfile(save_dir, 'annotations');
  if(~exist(save_dir, 'dir'))
    mkdir(save_dir);
    mkdir(ann_save_path);
  end

  if(save_jpgs)
    img_save_path = fullfile(save_dir, 'rgb');
    mkdir(img_save_path);
  end
  %% MAIN LOOP  for each label find its bounding box in each image

  %for each image, write out the boxes and possible image
  for jl=1:length(image_names)
    %get the image name 
    cur_image_name = image_names{jl};
    %display progress
    if(mod(jl,50) == 0)
      disp(cur_image_name);
    end

    %load the bounding box annotations
    cur_instance_boxes = load(fullfile(meta_path, LABELING_DIR, label_type, ...
                         BBOXES_BY_IMAGE_INSTANCE, strcat(cur_image_name(1:10), '.mat')));
    cur_instance_boxes = cur_instance_boxes.boxes;

    %open a text file for writing
    ann_fid = fopen(fullfile(ann_save_path, strcat(cur_image_name(1:10), '_boxes.txt')), 'wt');

   
    %write each box  
    for kl=1:size(cur_instance_boxes,1)
     
      %get the current box 
      bbox = cur_instance_boxes(kl,:);

      %scale dimensions of box (not category_id or hardness measure)
      bbox(1:4) = bbox(1:4) * scale_factor; 
    
      %convert vector of numbers to characters
      bbox_string = sprintf('%d ', bbox);
      bbox_string(end) = [];%get rid of trailing space
      fprintf(ann_fid, '%s\n', bbox_string);
    end%for kl, each instance name
    %close file
    fclose(ann_fid);

    %save the jpg, resize if needed
    if(save_jpgs)
      img = imread(fullfile(scene_path, JPG, strcat(cur_image_name(1:10), '.jpg')));
      img = imresize(img, scale_factor);
      imwrite(img, fullfile(img_save_path, strcat(cur_image_name(1:10), '.jpg')));
    end
  end%for jl, each image
end%for i, each scene_name


