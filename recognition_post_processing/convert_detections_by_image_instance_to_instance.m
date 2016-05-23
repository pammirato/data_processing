%converts recognition output from category level to instance level.
%finds the box from the category each instance belongs to with the 
%highest score that has iou with the the ground truth for that instance



%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_2cm_paths'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


recognition_system_name = 'fast_rcnn';

class_name = 'all';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_classes = 0;
custom_classes_list = {};

instance_name = 'chair5.mat';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_instances = 0;
custom_instances_list = {};


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
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  
  %get names of all instances that were labeled in the scene         
  all_instance_names = get_names_of_X_for_scene(scene_name, 'instance_labels');
 
  all_image_names = get_names_of_X_for_scene(scene_name, 'rgb_images');

  instance_arrays = cell(length(all_instance_names), length(all_image_names));  

   %decide which labels to process    
  if(use_custom_instances && ~isempty(custom_instances_list))
    all_instance_names = custom_instances_list;
  elseif(strcmp(instance_name,'bigBIRD'))
    temp = dir(fullfile(BIGBIRD_BASE_PATH));
    temp = temp(3:end);
    all_instance_names = {temp.name};
  elseif(strcmp(instance_name, 'all'))
    all_instance_names = all_instance_names;
  else
    all_instance_names = {instance_name};
  end
 


  %for each label, process  all the images that see it
  for j=1:length(all_image_names) 

    %get the class level detections         
    cur_image_name = all_image_names{j};
    cur_mat_name = strcat(cur_image_name(1:10), '.mat');  

    %get the index of the image(number, asdfas)
    cur_image_index = str2num(cur_image_name(1:6));

    if(cur_image_index == 799)
       breakp=1;
    end
 
    %now save the detections by instance for this image
    cur_image_detections = load(fullfile(meta_path, RECOGNITION_DIR, recognition_system_name, ...
                                         BBOXES_BY_IMAGE_INSTANCE_DIR, cur_mat_name));



    for k=1:length(all_instance_names)
      cur_instance_name = all_instance_names{k};
      %remove the .mat
      cur_instance_name = cur_instance_name(1:end-4);

      cur_instance_bbox = cur_image_detections.(cur_instance_name); 

      cur_instance_struct = struct('image_name', cur_image_name, 'bbox', cur_instance_bbox);

      instance_arrays{k,cur_image_index} = cur_instance_struct ; 
    end%for k, each instance name 


  end% for j, each label_name



  %now for each instance, save the detections
  for j=1:length(all_instance_names)
    cur_instance_name = all_instance_names{j};

    detections = cell2mat(instance_arrays(j,:));
    save(fullfile(meta_path, RECOGNITION_DIR, recognition_system_name, ...
                  BBOXES_BY_INSTANCE_DIR, cur_instance_name),'detections');
  end%for j, each instance name

end%for i,  each scene


