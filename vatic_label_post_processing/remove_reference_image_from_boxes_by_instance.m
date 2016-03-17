%  removes the reference image label from bounding boxes output




%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_Density_1by1'; %make this = 'all' to run all scenes
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

  %get a list of all the instances in the scene
  all_instance_names = get_names_of_X_for_scene(scene_name,'instance_labels'); 


  %for each instance, remove the reference image label 
  for j=1:length(all_instance_names)
    cur_instance_name = all_instance_names{j};
    
    %load the boxes for this instance
    cur_instance_labels_file = load(fullfile(scene_path,LABELING_DIR, ...
                                              BBOXES_BY_INSTANCE_DIR, cur_instance_name));
    cur_instance_labels = cur_instance_labels_file.annotations;

    first_label = cur_instance_labels{1};

    if(strcmp(first_label.frame, '0000000000.png'))
      cur_instance_labels = cur_instance_labels(2:end);
      
      cur_instance_labels_file.num_frames = length(cur_instance_labels);
      cur_instance_labels_file.annotations = cur_instance_labels;

      save(fullfile(scene_path,LABELING_DIR, BBOXES_BY_INSTANCE_DIR, cur_instance_name), ...
                     '-struct','cur_instance_labels_file');

    end%if strcmp

  end%for j, each instance 
end%for each scene


