%description of file 


%TODO  - what to add next

%initialize contants, paths and file names, etc. 
clearvars;
init;



%% USER OPTIONS

scene_name = 'Kitchen_Living_02_1_vid_3'; %make this = 'all' to run all scenes
use_custom_scenes = 1;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Den_den2', 'Den_den3','Den_den4' };%populate this 


recognition_system_name = 'ssd_bigBIRD';



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
fid_bb_map = fopen('/playpen/ammirato/Data/RohitMetaMetaData/big_bird_cat_map_ric.txt', 'rt');

line = fgetl(fid_bb_map);
while(ischar(line))
  line = strsplit(line);
  %obj_cat_map(line{1}) = str2double(line{2}); 
  obj_cat_map(line{2}) = line{1};
  line = fgetl(fid_bb_map);
end
fclose(fid_bb_map);



%% MAIN LOOP

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);
  
  mkdir(fullfile(meta_path, RECOGNITION_DIR, recognition_system_name, ...
                    BBOXES_BY_IMAGE_CLASS_DIR));


  %get names of all images in the scene
  all_image_names = get_names_of_X_for_scene(scene_name, 'rgb_images');

  %for each image, get its recognition output and and format it
  for j=1:length(all_image_names)
  
    %get the image name and change the extenstion for the .mat
    cur_image_name = all_image_names{j};
    cur_mat_name = strcat(cur_image_name(1:10), '.mat');


    if(strcmp(recognition_system_name, 'fast_rcnn'))
    %fast-rcnn is easy, just save it as a struct   

 
      %load the file 
      cur_recognition_file = load(fullfile(meta_path, RECOGNITION_DIR, ...
                           recognition_system_name, BBOXES_BY_IMAGE_CLASS_DIR, cur_mat_name));

      %get the detection structs
      cur_rec_struct = cur_recognition_file.dets;
   
      %save it as a struct 
      save(fullfile(meta_path, RECOGNITION_DIR, recognition_system_name, ...
                    BBOXES_BY_IMAGE_CLASS_DIR, cur_mat_name), '-struct', 'cur_rec_struct');
     elseif(strcmp(recognition_system_name, 'ssd_coco'))
    %fast-rcnn is easy, just save it as a struct   

 
      %load the file 
      cur_rec_struct = load(fullfile(meta_path, RECOGNITION_DIR, ...
                           recognition_system_name, BBOXES_BY_IMAGE_CLASS_DIR, cur_mat_name));

      all_categories = fieldnames(cur_rec_struct);

      for kl =1:length(all_categories)
        cur_value = cur_rec_struct.(all_categories{kl});
    
        cur_rec_struct.(all_categories{kl}) = double(cur_value);
      end
      
   
      %save it as a struct 
      save(fullfile(meta_path, RECOGNITION_DIR, recognition_system_name, ...
                    BBOXES_BY_IMAGE_CLASS_DIR, cur_mat_name), '-struct', 'cur_rec_struct');
     elseif(strcmp(recognition_system_name, 'ssd_bigBIRD'))
    %fast-rcnn is easy, just save it as a struct   

 
      %load the file 
      try
      cur_rec_struct = load(fullfile(meta_path, RECOGNITION_DIR, ...
                           recognition_system_name, 'output_boxes',  ...
                            strcat(scene_name, '_', cur_mat_name)));
      catch
        continue;
      end
                          
                          

      dets = cur_rec_struct.dets;
     % dets(:,[1 3]) = dets(:, [1 3]) * 1920/600;
     % dets(:,[2 4]) = dets(:, [2 4]) * 1080/338;
      
      cur_rec_struct = struct();
       
      cat_ids = unique(dets(:,6));
      
      cat_names = cell(1,length(cat_ids));
      for kl=1:length(cat_ids)
        cur_cat_id = cat_ids(kl);
        cat_name = obj_cat_map(num2str(cur_cat_id));
        cur_rec_struct.(cat_name) = dets(dets(:,6)==cur_cat_id,:);
      end


      
   
      %save it as a struct 
      save(fullfile(meta_path, RECOGNITION_DIR, recognition_system_name, ...
                    BBOXES_BY_IMAGE_CLASS_DIR, cur_mat_name), '-struct', 'cur_rec_struct');
     
     
    end%if, check recognition system
  end%for j, each image name
end%for i,  each scene


