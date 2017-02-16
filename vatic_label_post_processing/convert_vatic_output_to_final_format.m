function [] = convert_vatic_output_to_final_format(scene_name)
%converts structs from vatic output to a cleaner form 



%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

%scene_name = 'Office_02_1'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 




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

%get a list of all the instances in the scene
instance_name_to_id_map = get_instance_name_to_id_map();



%% MAIN LOOP

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get a list of all the instances in the scene
  all_instance_names = dir(fullfile(meta_path,LABELING_DIR,'output_boxes','*.mat'));
  all_instance_names = {all_instance_names.name};


  %for each instance, add a box to each image's struct that has this instance
  for j=1:length(all_instance_names)
    cur_instance_file_name = all_instance_names{j};
    cur_instance_name = cur_instance_file_name(1:end-4);   

    cur_instance_id = instance_name_to_id_map(cur_instance_name);
    
    %load the boxes for this instance
    cur_instance_labels_file = load(fullfile(meta_path,LABELING_DIR, ...
                                  'output_boxes', cur_instance_file_name));
    cur_instance_labels = cell2mat(cur_instance_labels_file.annotations);


    %get the bounding box and image name
    bboxes = double([cur_instance_labels.xtl; cur_instance_labels.ytl; ...
              cur_instance_labels.xbr;cur_instance_labels.ybr]');
            
    bboxes = [bboxes repmat(cur_instance_id,size(bboxes,1),1)];
    image_names = {cur_instance_labels.frame};

    boxes = bboxes;

    %save the new file
    save(fullfile(meta_path,LABELING_DIR,'output_boxes', ...
                  cur_instance_file_name), 'boxes','image_names');
    save(fullfile(meta_path,LABELING_DIR,'raw_labels', ...
            BBOXES_BY_INSTANCE, cur_instance_file_name), 'boxes','image_names');

  end%for j, each instance name
  %convert_boxes_by_instance_to_image_instance(scene_name,'raw_labels');
end%for each scene


end%function


