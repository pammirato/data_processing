instance_names = {'aunt_jemima_original_syrup', 'nature_valley_granola_thins_dark_chocolate',...
                    'nature_valley_sweet_and_salty_nut_roasted_mix_nut', 'red_bull'}; 



scene_name = 'Home_06_1';
label_type = 'verified_labels';

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

    label_path = meta_path;

  %where to save the boxes by instance files
  save_path = fullfile(label_path, LABELING_DIR, label_type,...
                         BBOXES_BY_IMAGE_INSTANCE);
  if(~exist(save_path,'dir'))
   mkdir(save_path);
  end




  %get a list of all the instances in the scene
  instance_name_to_id_map = get_instance_name_to_id_map();

  %get names of all the images in the scene
  all_image_names  = get_scenes_rgb_names(scene_path);

  %make a cell array with one cell for each image
  %in each cell is an array that holds boxes for all instance for 1 image
  label_array = -ones(length(instance_names),6);
  all_arrays = cell(length(all_image_names),1);
  for jl=1:length(all_arrays)
    all_arrays{jl} = label_array;
  end

  %make a map from image name to label array 
  label_array_map = containers.Map(all_image_names,all_arrays);  


  %% populate the structs for each image
  
  %for each instance, add a box to each image's cell that this instance is in
  for jl=1:length(instance_names)
   
    
    
    cur_instance_name = instance_names{jl}; 
    cur_instance_file_name = strcat(cur_instance_name, '.mat');
    cur_instance_file_name2 = strcat(cur_instance_name, '_2.mat');
    cur_instance_id = instance_name_to_id_map(cur_instance_name);
    %disp(cur_instance_name);
 
    %load the boxes for this instance and make a map
    cur_instance_labels= load(fullfile(label_path,LABELING_DIR, label_type, ...
                                  BBOXES_BY_INSTANCE, cur_instance_file_name));
    
    %get the image names and boxes for this instance from the loaded file struct 
    instance_image_names = cur_instance_labels.image_names;
    instance_boxes = cur_instance_labels.boxes; 


    cur_instance_labels2= load(fullfile(label_path,LABELING_DIR, label_type, ...
                                  BBOXES_BY_INSTANCE, cur_instance_file_name2));

    n2 = cur_instance_labels2.image_names;
    b2 = cur_instance_labels2.boxes;
    b2 = cell2mat(b2);
    b2 = reshape(b2,[5,length(n2)])';

    image_names = cat(2,instance_image_names,n2);
    boxes = [instance_boxes; b2];
    
    boxes(:,5) = cur_instance_id;
    
    save(fullfile(label_path,LABELING_DIR, label_type, ...
                                  BBOXES_BY_INSTANCE, cur_instance_file_name),...
                                  'image_names', 'boxes');

  end


end
