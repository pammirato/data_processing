%converts recognition output from category level to instance level.
%finds the box from the category each instance belongs to with the 
%highest score that has iou with the the ground truth for that instance



%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name ='SN208_2cm_paths'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


recognition_system_name = 'fast_rcnn';

class_name = 'all';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_classes = 0;
custom_classes_list = {};

label_name = 'chair1.mat';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_labels = 0;
custom_labels_list = {'chair5','chair6'};


iou_threshold = .5;




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
  all_labels = get_names_of_X_for_scene(scene_name, 'instance_labels');
 
  all_image_names = get_names_of_X_for_scene(scene_name, 'rgb_images');


  %decide which labels to process    
  if(use_custom_labels && ~isempty(custom_labels_list))
    all_labels = custom_labels_list;
  elseif(strcmp(label_name,'bigBIRD'))
    temp = dir(fullfile(BIGBIRD_BASE_PATH));
    temp = temp(3:end);
    all_labels = {temp.name};
  elseif(strcmp(label_name, 'all'))
    all_labels = all_labels;
  else
    all_labels = {label_name};
  end




  %for each label, process  all the images that see it
  for j=1:length(all_image_names) 

    %get the class level detections         
    cur_image_name = all_image_names{j};
    cur_mat_name = strcat(cur_image_name(1:10), '.mat');  
    cur_detections_by_class = load(fullfile(meta_path, RECOGNITION_DIR,  ...
                                   recognition_system_name, BBOXES_BY_IMAGE_CLASS_DIR, ...
                                   cur_mat_name));

    %get the true bbox for this instance in this image
    cur_true_bboxes_by_instance = load(fullfile(scene_path, LABELING_DIR, ...
                                    BBOXES_BY_IMAGE_INSTANCE_DIR, cur_mat_name));  

    %will hold all the detecitons to save
    cur_detections_by_instance = struct();

    for k=1:length(all_labels) 
      cur_instance_name = all_labels{k};
      %get rid of extension
      cur_instance_name = cur_instance_name(1:end-4);

      %set an empty detection for now
      cur_detections_by_instance.(cur_instance_name) = [];


      if(isfield(cur_true_bboxes_by_instance, cur_instance_name))
        cur_instance_true_bbox = cur_true_bboxes_by_instance.(cur_instance_name);    
      else
        %this instance is not in this image so skip it
        continue;
      end

      %get the class name of this instance by removing numbers at the end
      class_of_instance = get_class_name_from_instance_name(cur_instance_name);  
      %get the detections for this class in this image
      detections_for_class = cur_detections_by_class.(class_of_instance);

      %find the detection with the highest score, that has
      %a proper iou(intersection over union) with the true bbox
      cur_detection_for_instance = get_best_scored_intersecting_box(cur_instance_true_bbox, ...
                                                                   detections_for_class, ...
                                                                   iou_threshold); 
      if(~isempty(cur_detection_for_instance))
        cur_detections_by_instance.(cur_instance_name) = cur_detection_for_instance;
      end  

    end%for k, each instance label
 
    %now save the detections by instance for this image
    save(fullfile(meta_path, RECOGNITION_DIR, recognition_system_name, ...
                  BBOXES_BY_IMAGE_INSTANCE_DIR, cur_mat_name), '-struct',...
                  'cur_detections_by_instance');


  end% for j, each label_name
end%for i,  each scene


