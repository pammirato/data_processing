function [] = remove_reference_image_from_boxes_by_instance(scene_name)
%  removes the reference image label from bounding boxes output




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




%% MAIN LOOP

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path = fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get a list of all the instances in the scene
  instance_name_to_id_map = get_instance_name_to_id_map();
  instance_names = keys(instance_name_to_id_map); 

  output_boxes_path = fullfile(meta_path,LABELING_DIR,'output_boxes');
  output_boxes_names = dir(fullfile(output_boxes_path,'*.mat'));
  output_boxes_names = {output_boxes_names.name};

  %for each instance, remove the reference image label 
  for j=1:length(output_boxes_names)
    cur_instance_name = output_boxes_names{j};
    disp(cur_instance_name);
    
    %load the boxes for this instance
    cur_instance_labels_file = load(fullfile(output_boxes_path, cur_instance_name));
    cur_instance_labels = cur_instance_labels_file.annotations;

    if(isempty(cur_instance_labels))
      disp(['skipping: ' cur_instance_name]);
      continue;
    end

    first_label = cur_instance_labels{1};

    first_frame = first_label.frame;

    %if(strcmp(first_frame(1:10), '0000000000') || frame == 0)
    if((length(first_frame) > 7 && strcmp(first_frame(1:8), '00000000')) || (length(first_frame) ==1 && first_frame ==0))
      cur_instance_labels = cur_instance_labels(2:end);
      disp(['removed_first: ' cur_instance_name]);
      cur_instance_labels_file.num_frames = length(cur_instance_labels);
      cur_instance_labels_file.annotations = cur_instance_labels;

      save(fullfile(output_boxes_path, cur_instance_name), ...
                     '-struct','cur_instance_labels_file');

    end%if strcmp

  end%for j, each instance 
end%for each scene

end%function
